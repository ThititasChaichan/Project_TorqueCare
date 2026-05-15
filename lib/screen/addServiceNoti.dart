import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddServiceNotificationScreen extends StatefulWidget {
  final String motoId;
  final String motoLabel;
  final Map<String, dynamic>? existingData;
  final String? docPath;

  const AddServiceNotificationScreen({
    super.key,
    required this.motoId,
    required this.motoLabel,
    this.existingData,
    this.docPath,
  });

  @override
  State<AddServiceNotificationScreen> createState() =>
      _AddServiceNotificationScreenState();
}

class _AddServiceNotificationScreenState
    extends State<AddServiceNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool get _isEditMode => widget.existingData != null;

  String? _selectedServiceType;
  double? _selectedPrice;
  DateTime? _selectedExpiryDate;
  int? _selectedKm; // ระยะกิโลเมตรถัดไปที่ต้องเปลี่ยน

  final List<String> _services = [
    'ถ่ายน้ำมันเครื่อง',
    'เปลี่ยนยาง',
    'เปลี่ยนผ้าเบรก',
    'เช็คระยะ',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final data = widget.existingData!;
      _selectedServiceType = data['type'];
      _selectedPrice = (data['price'] as num?)?.toDouble();
      _selectedKm = (data['next_km'] as num?)?.toInt();
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

  Future<void> _selectKm() async {
    final controller = TextEditingController(
      text: _selectedKm?.toString(),
    );
    final int? result = await showDialog<int?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ระยะที่ต้องเปลี่ยนครั้งถัดไป'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'เช่น 5000',
            suffixText: 'กม.',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedKm = result);
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

    if (_selectedServiceType == null) {
      _showSnackBar('กรุณาเลือกประเภทบริการ');
      return;
    }
    if (_selectedExpiryDate == null && _selectedKm == null) {
      _showSnackBar('กรุณาใส่วันหมดอายุ หรือระยะกิโลเมตร อย่างน้อย 1 อย่าง');
      return;
    }
    if (widget.motoId.isEmpty) {
      _showSnackBar('ไม่พบข้อมูลรถ กรุณาเลือกรถก่อน');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    try {
      final notificationData = <String, dynamic>{
        'price': _selectedPrice,
        'next_km': _selectedKm,
        'expiry_date': _selectedExpiryDate != null
            ? Timestamp.fromDate(_selectedExpiryDate!)
            : null,
        'createdAt': Timestamp.now(),
      };

      if (_isEditMode && widget.docPath != null) {
        await FirebaseFirestore.instance
            .doc(widget.docPath!)
            .update(notificationData);
      } else {
        // path: users/{uid}/motos/{motoId}/notifications/บริการ/{type}/{autoId}
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('motos')
            .doc(widget.motoId)
            .collection('notifications')
            .doc('บริการ')
            .collection(_selectedServiceType!)
            .add(notificationData);
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
        content:
            Text('ต้องการลบรายการ "${_selectedServiceType ?? ''}" นี้ใช่ไหม?'),
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
        const Text('ประเภทบริการ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedServiceType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: _services
              .map((item) =>
                  DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: _isEditMode
              ? null
              : (val) => setState(() => _selectedServiceType = val),
          validator: (v) => v == null ? 'กรุณาเลือกประเภทบริการ' : null,
        ),
      ],
    );
  }

  Widget _buildTappableField({
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
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
                Text(value),
                suffixIcon ??
                    const Icon(Icons.edit, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditMode ? 'แก้ไขการแจ้งเตือน' : 'เพิ่มการแจ้งเตือนบริการ'),
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
                          color: const Color(0xFF0057A8).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  const Color(0xFF0057A8).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.motorcycle,
                                color: Color(0xFF0057A8)),
                            const SizedBox(width: 8),
                            Text(
                              widget.motoLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0057A8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildDropdown(),
                    const SizedBox(height: 16),
                    if (_selectedServiceType != null) ...[
                      _buildTappableField(
                        label: 'ราคา (ไม่บังคับ)',
                        value: _selectedPrice == null
                            ? 'โปรดใส่ราคา'
                            : '${_selectedPrice!.toStringAsFixed(0)} บาท',
                        onTap: _selectPrice,
                      ),
                      const SizedBox(height: 16),
                      _buildTappableField(
                        label: 'ระยะกิโลเมตรถัดไป (ไม่บังคับ)',
                        value: _selectedKm == null
                            ? 'โปรดใส่ระยะกิโลเมตร'
                            : '$_selectedKm กม.',
                        onTap: _selectKm,
                      ),
                      const SizedBox(height: 16),
                      _buildTappableField(
                        label: 'วันหมดอายุ (ไม่บังคับ)',
                        value: _selectedExpiryDate == null
                            ? 'เลือกวันหมดอายุ'
                            : DateFormat('dd/MM/yyyy')
                                .format(_selectedExpiryDate!),
                        onTap: _selectExpiryDate,
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '* ต้องใส่อย่างน้อย 1 อย่าง ระหว่างวันหมดอายุ หรือ ระยะกิโลเมตร',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveData,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: const Color(0xFF0057A8),
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