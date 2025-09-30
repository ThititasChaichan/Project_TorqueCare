import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMotoPage extends StatefulWidget {
  const AddMotoPage({super.key});

  @override
  State<AddMotoPage> createState() => _AddMotoPageState();
}

class _AddMotoPageState extends State<AddMotoPage> {
  final _formKey = GlobalKey<FormState>();

  /// ตัวแปรเก็บค่า dropdown
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? brand;
  String? model;
  String? year;
  String? fuelType;

  /// dropdown lists
  List<String> brands = [];
  List<String> models = [];
  List<String> years = [];

  final distanceCtrl = TextEditingController();
  final plateCtrl = TextEditingController();

  final fuelTypes = ['เบนซิน', 'แก๊สโซฮอล์', 'ดีเซล', 'ไฟฟ้า', 'อื่นๆ'];

  @override
  void initState() {
    super.initState();
    _loadBrands();
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
      model = null;
      years = [];
      year = null;
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
      year = null;
    });
  }

  Future<void> _saveMoto() async {
    if (!_formKey.currentState!.validate()) return;

    final motoData = {
      'brand': brand,
      'model': model,
      'year': year,
      'fuelType': fuelType,
      'distance': int.tryParse(distanceCtrl.text.trim()) ?? 0,
      'plate': plateCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId) // doc ของผู้ใช้
          .collection('motos') // sub-collection ของรถผู้ใช้
          .add(motoData);
      Navigator.pop(context, motoData);
      // ✅ แสดง snackbar บอกสำเร็จ
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกสำเร็จ!')));

      // ✅ รีเซ็ต form + dropdown
      _formKey.currentState!.reset(); // reset TextFormField
      distanceCtrl.clear(); // clear distance
      setState(() {
        brand = null;
        model = null;
        year = null;
        fuelType = null;
        models = [];
        years = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  @override
  void dispose() {
    distanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มข้อมูลจักรยานยนต์')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Brand
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'ยี่ห้อ'),
                value: brand,
                items: brands
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) {
                  setState(() => brand = v);
                  if (v != null) _loadModels(v);
                },
                validator: (v) => v == null ? 'กรุณาเลือกยี่ห้อ' : null,
              ),
              const SizedBox(height: 16),

              /// Model
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'รุ่น'),
                value: model,
                items: models
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  setState(() => model = v);
                  if (v != null && brand != null) _loadYears(brand!, v);
                },
                validator: (v) => v == null ? 'กรุณาเลือกรุ่น' : null,
              ),
              const SizedBox(height: 16),

              /// Year
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'ปี'),
                value: year,
                items: years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => year = v),
                validator: (v) => v == null ? 'กรุณาเลือกปี' : null,
              ),
              const SizedBox(height: 16),

              /// Fuel type
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'ชนิดเชื้อเพลิง'),
                value: fuelType,
                items: fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => fuelType = v),
                validator: (v) => v == null ? 'กรุณาเลือกชนิดเชื้อเพลิง' : null,
              ),
              const SizedBox(height: 16),

              /// Distance
              TextFormField(
                controller: distanceCtrl,
                decoration: const InputDecoration(labelText: 'ระยะทาง (กม.)'),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกระยะทาง' : null,
              ),
              const SizedBox(height: 32),

              /// Plate
              TextFormField(
                controller: plateCtrl,
                decoration: const InputDecoration(labelText: 'ป้ายทะเบียน'),
                keyboardType: TextInputType.text,
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกป้ายทะเบียน' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveMoto,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
