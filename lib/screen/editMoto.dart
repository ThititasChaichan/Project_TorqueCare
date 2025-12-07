import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:moto/moto_provider.dart';

class EditMotoPage extends StatefulWidget {
  final String motoId;
  final Map<String, dynamic>? existingData;

  const EditMotoPage({super.key, required this.motoId, this.existingData});
  

  @override
  State<EditMotoPage> createState() => _EditMotoPageState();
}

class _EditMotoPageState extends State<EditMotoPage> {
  Map<String, dynamic>? existingData;

  final _formKey = GlobalKey<FormState>();

  // dropdown values
  String? brand;
  String? model;
  String? year;
  String? fuelType;

  // lists
  List<String> brands = [];
  List<String> models = [];
  List<String> years = [];
  final fuelTypes = ['เบนซิน', 'แก๊สโซฮอล์', 'ดีเซล', 'ไฟฟ้า', 'อื่นๆ'];

  // controllers
  late TextEditingController distanceCtrl;
  late TextEditingController plateController;

  bool _loading = false;

  @override
  void initState() {
    
    super.initState();
    distanceCtrl = TextEditingController();
    plateController = TextEditingController();
    _loadBrands();

    if (widget.existingData != null) {
      existingData = Map<String, dynamic>.from(widget.existingData!);
      _applyExisting();
    } else {
      fetchExistingData();
    }
  }

  void _applyExisting() {
    brand = existingData?['brand'];
    model = existingData?['model'];
    year = existingData?['year']?.toString();
    fuelType = existingData?['fuelType'];
    distanceCtrl.text = (existingData?['distance'] ?? '').toString();
    plateController.text = existingData?['plate'] ?? '';

    // if brand/model present, load dependent lists
    if (brand != null) {
      // รอให้ models โหลดเสร็จก่อน แล้วค่อยโหลด years
      _loadModels(brand!).then((_) async {
        if (model != null && models.contains(model)) {
          await _loadYears(brand!, model!);
          // ถ้า year ที่เก็บมาไม่อยู่ใน years ให้เคลียร์
          if (year != null && !years.contains(year)) year = null;
        }
        setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _loadBrands() async {
    final snap = await FirebaseFirestore.instance.collection('motodata').get();
    setState(() {
      brands = snap.docs.map((d) => d.id).toList();
    });
  }

  Future<void> _loadModels(String brandId) async {
    final snap = await FirebaseFirestore.instance
        .collection('motodata')
        .doc(brandId)
        .collection('models')
        .get();
    setState(() {
      models = snap.docs.map((d) => d.id).toList();
      // ถ้า model เดิมไม่อยู่ในรายการ ให้ล้างค่า model
      if (model != null && !models.contains(model)) model = null;
      // อย่าเคลียร์ year ที่นี่ — ให้ _loadYears() จัดการแทน
    });
  }

  Future<void> _loadYears(String brandId, String modelId) async {
    final snap = await FirebaseFirestore.instance
        .collection('motodata')
        .doc(brandId)
        .collection('models')
        .doc(modelId)
        .collection('years')
        .get();
    setState(() {
      years = snap.docs.map((d) => d.id).toList();
      if (year != null && !years.contains(year)) year = null;
    });
  }

  Future<void> fetchExistingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('motos')
          .doc(widget.motoId)
          .get();

      if (doc.exists) {
        existingData = Map<String, dynamic>.from(doc.data() ?? {});
        existingData!['id'] = doc.id;
        _applyExisting();
      }
    } catch (e) {
      // ignore/log
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _loading = true);

    final updateData = {
      'brand': brand,
      'model': model,
      'year': year,
      'fuelType': fuelType,
      'distance': int.tryParse(distanceCtrl.text.trim()) ?? 0,
      'plate': plateController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('motos')
          .doc(widget.motoId)
          .update(updateData);

      final updatedMoto = {
        ...?existingData,
        ...updateData,
        'id': widget.motoId,
      };

      try {
        context.read<MotoProvider>().setMoto(updatedMoto);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกเรียบร้อย')));
        Navigator.pop(context, updatedMoto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // เพิ่มฟังก์ชันลบรถ
  Future<void> _deleteMoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text(
          'คุณต้องการลบรถคันนี้จริงหรือไม่? การกระทำนี้ไม่สามารถย้อนกลับได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('motos')
          .doc(widget.motoId)
          .delete();

      // อัปเดต provider ถ้ามี
      try {
        context.read<MotoProvider>().setMoto({});
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ลบข้อมูลรถเรียบร้อย')));
        Navigator.of(context).pop({'deleted': true, 'id': widget.motoId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    distanceCtrl.dispose();
    plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลจักรยานยนต์'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'ลบรถ',
            icon: const Icon(Icons.delete),
            onPressed: _deleteMoto,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'ยี่ห้อ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: brand,
                      items: brands
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => brand = v);
                        if (v != null) _loadModels(v);
                      },
                      validator: (v) => v == null ? 'กรุณาเลือกยี่ห้อ' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'รุ่น',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: model,
                      items: models
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => model = v);
                        if (v != null && brand != null) _loadYears(brand!, v);
                      },
                      validator: (v) => v == null ? 'กรุณาเลือกรุ่น' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'ปี',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: year,
                      items: years
                          .map(
                            (y) => DropdownMenuItem(value: y, child: Text(y)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => year = v),
                      validator: (v) => v == null ? 'กรุณาเลือกปี' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'ชนิดเชื้อเพลิง',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: fuelType,
                      items: fuelTypes
                          .map(
                            (f) => DropdownMenuItem(value: f, child: Text(f)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => fuelType = v),
                      validator: (v) =>
                          v == null ? 'กรุณาเลือกชนิดเชื้อเพลิง' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: distanceCtrl,
                      maxLength: 9,
                      decoration: InputDecoration(
                        labelText: 'ระยะทาง (กม.)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกระยะทาง' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: plateController,
                      maxLength: 10,
                      decoration: InputDecoration(
                        labelText: 'ป้ายทะเบียน',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      validator: (v) => v == null || v.isEmpty
                          ? 'กรุณากรอกป้ายทะเบียน'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('บันทึก'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
