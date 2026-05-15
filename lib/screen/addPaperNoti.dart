import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddPaperNotificationScreen extends StatefulWidget {
  final String motoId;
  final String motoLabel;
  final Map<String, dynamic>? existingData; // ถ้ามี = mode แก้ไข
  final String? docPath; // path ใน Firestore สำหรับแก้ไข/ลบ

  const AddPaperNotificationScreen({
    super.key,
    required this.motoId,
    required this.motoLabel,
    this.existingData,
    this.docPath,
  });

  @override
  State<AddPaperNotificationScreen> createState() =>
      _AddPaperNotificationScreenState();
}

class _AddPaperNotificationScreenState
    extends State<AddPaperNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool get _isEditMode => widget.existingData != null;

  String? _selectedPaperType;
  double? _selectedPrice;
  DateTime? _selectedExpiryDate;

  final List<String> _papers = [
    'พ.ร.บ.',
    'ภาษีประจำปี',
    'ใบขับขี่',
    'ตรวจสภาพรถ',
    'ประกันภัย',
  ];

  @override
  void initState() {
    super.initState();
    // ถ้าเป็น mode แก้ไข ให้ pre-fill ข้อมูลเดิม
    if (_isEditMode) {
      final data = widget.existingData!;
      _selectedPaperType = data['type'];
      _selectedPrice = (data['price'] as num?)?.toDouble();
      final Timestamp? ts = data['expiry_date'] as Timestamp?;
      _selectedExpiryDate = ts?.toDate();
    }
  }

  Future<void> _selectPrice() async {
    final controller = TextEditingController(
      text: _selectedPrice?.toStringAsFixed(0),
    );
    final double? result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ระบุราคา'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'โปรดใส่ราคา'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedPrice = result);
    }
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() => _selectedExpiryDate = picked);
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaperType == null || _selectedExpiryDate == null) {
      _showSnackBar('กรุณาเลือกประเภทและวันหมดอายุ');
      return;
    }

    final bool requiresPrice = ['พ.ร.บ.', 'ภาษีประจำปี', 'ประกันภัย']
        .contains(_selectedPaperType);
    if (requiresPrice && _selectedPrice == null) {
      _showSnackBar('กรุณาระบุราคา');
      return;
    }

    // ใบขับขี่ไม่ต้องผูกกับรถ แต่ประเภทอื่นต้องมี motoId
    final bool requiresMoto = _selectedPaperType != 'ใบขับขี่';
    if (requiresMoto && widget.motoId.isEmpty) {
      _showSnackBar('ไม่พบข้อมูลรถ กรุณาเลือกรถก่อน');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final notificationData = {
        'price': _selectedPrice,
        'expiry_date': Timestamp.fromDate(_selectedExpiryDate!),
        'createdAt': Timestamp.now(),
      };

      if (_isEditMode && widget.docPath != null) {
        // mode แก้ไข — update document เดิม
        await FirebaseFirestore.instance
            .doc(widget.docPath!)
            .update(notificationData);
      } else {
        // mode เพิ่มใหม่
        final category = 'เอกสาร';
        final type = _selectedPaperType!;

        CollectionReference colRef;
        if (requiresMoto) {
          colRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('motos')
              .doc(widget.motoId)
              .collection('notifications')
              .doc(category)
              .collection(type);
        } else {
          colRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(category)
              .collection(type);
        }
        await colRef.add(notificationData);
      }

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar(
            _isEditMode ? 'แก้ไขข้อมูลสำเร็จ!' : 'บันทึกการแจ้งเตือนสำเร็จ!');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteData() async {
    if (widget.docPath == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบรายการ "${_selectedPaperType ?? ''}" นี้ใช่ไหม?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.doc(widget.docPath!).delete();
      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('ลบรายการสำเร็จ');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ประเภทการดำเนินการ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaperType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _papers
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: _isEditMode
              ? null // ตอนแก้ไขไม่ให้เปลี่ยนประเภท
              : (val) => setState(() => _selectedPaperType = val),
          validator: (v) => v == null ? 'กรุณาเลือกประเภท' : null,
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ราคา',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectPrice,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedPrice == null
                    ? 'โปรดใส่ราคา'
                    : '${_selectedPrice!.toStringAsFixed(0)} บาท'),
                const Icon(Icons.edit, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วันที่หมดอายุ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectExpiryDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedExpiryDate == null
                    ? 'เลือกวันหมดอายุ'
                    : DateFormat('dd/MM/yyyy').format(_selectedExpiryDate!)),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showPrice = ['พ.ร.บ.', 'ภาษีประจำปี', 'ประกันภัย']
        .contains(_selectedPaperType);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'แก้ไขการแจ้งเตือน' : 'เพิ่มการแจ้งเตือน'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'ลบรายการ',
              onPressed: _deleteData,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // แสดงรถที่ผูกอยู่ (read-only)
                    if (widget.motoLabel.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007A35).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF007A35).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.motorcycle,
                                color: Color(0xFF007A35)),
                            const SizedBox(width: 8),
                            Text(
                              widget.motoLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF007A35),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    if (_selectedPaperType != null) ...[
                      if (showPrice) ...[
                        _buildPriceField(),
                        const SizedBox(height: 16),
                      ],
                      _buildDateField(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: const Color(0xFF007A35),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            _isEditMode ? 'บันทึกการแก้ไข' : 'บันทึกข้อมูล',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}