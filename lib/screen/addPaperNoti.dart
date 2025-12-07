// Imports (เหมือนเดิม)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddPaperNotificationScreen extends StatefulWidget {
  const AddPaperNotificationScreen({super.key});

  @override
  State<AddPaperNotificationScreen> createState() =>
      _AddPaperNotificationScreenState();
}

class _AddPaperNotificationScreenState
    extends State<AddPaperNotificationScreen> {
  // --- Form and State Variables ---
  final _formKey = GlobalKey<FormState>();
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? motosId = FirebaseAuth
      .instance
      .currentUser
      ?.email; // **ยังคงเป็นอีเมล แต่อย่าใช้ในการ query motos/{id}**
  bool _loading = false;

  // Selected Values
  String? _selectedPaperType;
  String? _selectedMotorcycleModel;
  double? _selectedPrice;
  DateTime? _selectedDate;
  DateTime? _selectedExpiryDate;

  // Predefined Lists
  final List<String> _papers = [
    'พ.ร.บ.',
    'ภาษีประจำปี',
    'ใบขับขี่ ',
    'ตรวจสภาพรถ',
    'ประกันภัย',
  ];
  List<String> _motorcycleModelsList = [];

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadMotorcycleModels();
  }

  // --- Helper Method: ค้นหา Document ID ของมอเตอร์ไซค์ ---
  Future<String?> _getMotosIdFromName(String modelName) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      final QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('motos')
          .get();

      // หา Document ID ที่ตรงกับชื่อที่แสดง (Model (Year))
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final model = data['model']?.toString() ?? '';
        final year = data['year']?.toString() ?? '';
        final fullName = year.isNotEmpty ? '$model ($year)' : model;

        if (fullName == modelName) {
          return doc.id; // ส่งคืน Document ID ของรถที่เลือก
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding motosId: $e');
      return null;
    }
  }

  // --- Data Loading Methods (เหมือนเดิม) ---
  Future<void> _loadMotorcycleModels() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      debugPrint('Loading motorcycles for user: $userId');

      final QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('motos')
          .orderBy('model')
          .get();

      debugPrint('Found ${query.docs.length} motorcycles');

      final models = query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final model = data['model']?.toString() ?? '';
        final year = data['year']?.toString() ?? '';
        final fullName = year.isNotEmpty ? '$model ($year)' : model;

        debugPrint('Motorcycle found: $fullName');
        return fullName;
      }).toList();

      if (mounted) {
        setState(() => _motorcycleModelsList = models);
      }
    } catch (e) {
      debugPrint('Error loading motorcycle models: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ไม่สามารถโหลดข้อมูลรถได้: $e')));
      }
    }
  }

  // --- Selection Methods (เหมือนเดิม) ---
  Future<void> _selectPrice(BuildContext context, bool unused) async {
    final TextEditingController controller = TextEditingController(
      text: _selectedPrice?.toString(),
    );
    final double? result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ระบุราคา'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'โปรดใส่ราคา'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                Navigator.of(ctx).pop(null);
                return;
              }
              final parsed = double.tryParse(text);
              Navigator.of(ctx).pop(parsed);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
    if (result != null && context.mounted) {
      setState(() => _selectedPrice = result.toDouble());
    }
  }

  Future<void> _selectDate(BuildContext context, bool isExpiryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && context.mounted) {
      setState(() {
        if (isExpiryDate) {
          _selectedExpiryDate = picked;
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  // --- Form Methods (ถูกแก้ไข) ---
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaperType == null ||
        _selectedMotorcycleModel == null ||
        _selectedPrice == null ||
        _selectedDate == null ||
        _selectedExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกข้อมูลให้ครบถ้วน')),
      );
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบอีกครั้ง')),
        );
      }
      return;
    }

    setState(() => _loading = true);

    try {
      // 1. ค้นหา Document ID ของมอเตอร์ไซค์ที่เลือก
      final selectedMotosId = await _getMotosIdFromName(
        _selectedMotorcycleModel!,
      );
      if (selectedMotosId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'ไม่พบ Document ID ของรถที่เลือก โปรดลองใหม่อีกครั้ง',
              ),
            ),
          );
        }
        return;
      }

      // 2. สร้าง Reference สำหรับ Collection 'Data'
      final dataCollectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('motos')
          .doc(selectedMotosId) // ใช้ Document ID ของรถที่ค้นหาได้
          .collection('Data');

      // 3. สร้างเอกสารใหม่ (Auto-ID) ใน Collection 'Data'
      // นี่คือการสร้าง ID สำหรับ Data/{dataId} โดยอัตโนมัติ
      final newDataDocRef = await dataCollectionRef.add({});

      // 4. บันทึกข้อมูลจริงลงใน Subcollection 'Paper' ภายใต้เอกสารใหม่ที่เพิ่งสร้าง
      // โครงสร้างที่ได้: users/{userId}/motos/{motosId}/Data/{Auto-ID}/Paper/{Auto-ID}
      await newDataDocRef.collection('Paper').add({
        'paper_type': _selectedPaperType,
        'model': _selectedMotorcycleModel,
        'price': _selectedPrice,
        'date': _selectedDate,
        'expiry_date': _selectedExpiryDate,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': currentUserId,
        'motos_id': selectedMotosId,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
        _clearForm();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedPaperType = null;
      _selectedMotorcycleModel = null;
      _selectedPrice = null;
      _selectedDate = null;
      _selectedExpiryDate = null;
    });
    _formKey.currentState?.reset();
  }

  // --- UI Builder Methods (เหมือนเดิม) ---
  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          validator: (value) => value == null ? 'กรุณาเลือก$label' : null,
        ),
      ],
    );
  }

  Widget _buildPriceField({
    required String label,
    required num? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
                Text(value == null ? 'โปรดใส่$label' : value.toString()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
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
                Text(
                  value == null
                      ? 'เลือก$label'
                      : DateFormat('dd/MM/yyyy').format(value),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Main Build Method (เหมือนเดิม) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มการแจ้งเตือนเอกสาร')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDropdown(
                      label: 'โปรดเลือกรายการเอกสาร',
                      items: _papers,
                      value: _selectedPaperType,
                      onChanged: (val) =>
                          setState(() => _selectedPaperType = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      label: 'รถจักรยานยนต์',
                      items: _motorcycleModelsList,
                      value: _selectedMotorcycleModel,
                      onChanged: (val) =>
                          setState(() => _selectedMotorcycleModel = val),
                    ),
                    const SizedBox(height: 16),
                    _buildPriceField(
                      label: 'ราคา',
                      value: _selectedPrice,
                      onTap: () => _selectPrice(context, false),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'วันที่',
                      value: _selectedDate,
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'วันที่หมดอายุ',
                      value: _selectedExpiryDate,
                      onTap: () => _selectDate(context, true),
                    ),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
