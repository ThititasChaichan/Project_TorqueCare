import 'package:firebase_auth/firebase_auth.dart';
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
  bool _loading = false;

  // Selected Values
  String? _selectedCategory = 'เอกสาร'; // หมวดหมู่หลัก
  String? _selectedPaperType; // ประเภทการดำเนินการ
  String? _selectedMotorcycleModel;
  double? _selectedPrice;
  DateTime? _selectedDate;
  DateTime? _selectedExpiryDate;

  // Predefined Lists
  final List<String> _categories = ['เอกสาร'];
  final List<String> _papers = [
    'พ.ร.บ.',
    'ภาษีประจำปี',
    'ใบขับขี่',
    'ตรวจสภาพรถ',
    'ประกันภัย',
  ];
  List<String> _motorcycleModelsList = [];

  @override
  void initState() {
    super.initState();
    _loadMotorcycleModels();
  }

  // --- Helper Method ---
  Future<String?> _getMotosIdFromName(String modelName) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      final QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('motos')
          .get();

      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final model = data['model']?.toString() ?? '';
        final year = data['year']?.toString() ?? '';
        final fullName = year.isNotEmpty ? '$model ($year)' : model;

        if (fullName == modelName) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error finding motosId: $e');
      return null;
    }
  }

  // --- Data Loading Methods ---
  Future<void> _loadMotorcycleModels() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('motos')
          .orderBy('model')
          .get();

      final models = query.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final model = data['model']?.toString() ?? '';
        final year = data['year']?.toString() ?? '';
        final fullName = year.isNotEmpty ? '$model ($year)' : model;
        return fullName;
      }).toList();

      if (mounted) {
        setState(() => _motorcycleModelsList = models);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // --- Selection Methods ---
  Future<void> _selectPrice(BuildContext context) async {
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

  // --- Form Methods ---
  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null ||
        _selectedPaperType == null ||
        _selectedDate == null ||
        _selectedExpiryDate == null) {
      _showErrorSnackBar('กรุณาเลือกข้อมูล วันที่ และ วันหมดอายุ ให้ครบถ้วน');
      return;
    }

    bool requiresMotorcycle = _selectedPaperType != 'ใบขับขี่';
    bool requiresPrice = [
      'พ.ร.บ.',
      'ภาษีประจำปี',
      'ประกันภัย',
    ].contains(_selectedPaperType);

    if (requiresMotorcycle && _selectedMotorcycleModel == null) {
      _showErrorSnackBar('กรุณาเลือกรถจักรยานยนต์');
      return;
    }

    if (requiresPrice && _selectedPrice == null) {
      _showErrorSnackBar('กรุณาระบุราคา');
      return;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() => _loading = true);

    try {
      String? selectedMotosId;

      if (requiresMotorcycle) {
        selectedMotosId = await _getMotosIdFromName(_selectedMotorcycleModel!);
        if (selectedMotosId == null) {
          _showErrorSnackBar('ไม่พบข้อมูลรถที่เลือก');
          setState(() => _loading = false);
          return;
        }
      }

      // ข้อมูล Data ที่จะบันทึกใน Document สุดท้าย
      final notificationData = {
        'model': _selectedMotorcycleModel,
        'price': _selectedPrice,
        'date': _selectedDate,
        'expiry_date': _selectedExpiryDate,
        'createdAt': Timestamp.now(),
      };

      // โครงสร้าง: notifications > เอกสาร > (ประเภทการดำเนินการ) > (Data)
      if (selectedMotosId != null) {
        // กรณีมีรถ (บันทึกใต้ motosId)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('motos')
            .doc(selectedMotosId)
            .collection('notifications') // Collection: notifications
            .doc(_selectedCategory) // Document: เอกสาร
            .collection(
              _selectedPaperType!,
            ) // Collection: ประเภทการดำเนินการ (เช่น พ.ร.บ.)
            .add(notificationData); // Document: Data (Auto-ID)
      } else {
        // กรณีไม่มีรถ เช่น ใบขับขี่ (บันทึกใต้ user โดยตรง)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications') // Collection: notifications
            .doc(_selectedCategory) // Document: เอกสาร
            .collection(_selectedPaperType!) // Collection: ประเภทการดำเนินการ
            .add(notificationData); // Document: Data (Auto-ID)
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการแจ้งเตือนสำเร็จ!')),
        );
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // --- UI Builder Methods ---
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

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ราคา',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectPrice(context),
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
                  _selectedPrice == null
                      ? 'โปรดใส่ราคา'
                      : _selectedPrice.toString(),
                ),
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

  Widget _buildDynamicFormFields() {
    List<Widget> formFields = [];

    if (_selectedCategory == 'เอกสาร') {
      formFields.add(
        _buildDropdown(
          label: 'ประเภทการดำเนินการ',
          items: _papers,
          value: _selectedPaperType,
          onChanged: (val) {
            setState(() {
              _selectedPaperType = val;
            });
          },
        ),
      );
      formFields.add(const SizedBox(height: 16));

      if (_selectedPaperType != null) {
        bool showMotorcycleField = _selectedPaperType != 'ใบขับขี่';
        bool showPriceField = [
          'พ.ร.บ.',
          'ภาษีประจำปี',
          'ประกันภัย',
        ].contains(_selectedPaperType);

        if (showMotorcycleField) {
          formFields.add(
            _buildDropdown(
              label: 'รถจักรยานยนต์',
              items: _motorcycleModelsList,
              value: _selectedMotorcycleModel,
              onChanged: (val) =>
                  setState(() => _selectedMotorcycleModel = val),
            ),
          );
          formFields.add(const SizedBox(height: 16));
        }

        if (showPriceField) {
          formFields.add(_buildPriceField());
          formFields.add(const SizedBox(height: 16));
        }

        formFields.add(
          _buildDateField(
            label: 'วันที่',
            value: _selectedDate,
            onTap: () => _selectDate(context, false),
          ),
        );
        formFields.add(const SizedBox(height: 16));
        formFields.add(
          _buildDateField(
            label: 'วันที่หมดอายุ',
            value: _selectedExpiryDate,
            onTap: () => _selectDate(context, true),
          ),
        );
        formFields.add(const SizedBox(height: 24));

        formFields.add(
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: formFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มการแจ้งเตือน')),
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
                      label: 'หมวดหมู่',
                      items: _categories,
                      value: _selectedCategory,
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _selectedPaperType = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_selectedCategory != null) _buildDynamicFormFields(),
                  ],
                ),
              ),
            ),
    );
  }
}
