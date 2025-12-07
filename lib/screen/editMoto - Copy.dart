import 'package:flutter/material.dart';
import 'package:moto/screen/BaseLayout.dart';
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

class _EditMotoStateTemp {} // placeholder to mark replaced content

class _EditMotoPageState extends State<EditMotoPage> {
  Map<String, dynamic>? existingData;

  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController plateController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    brandController = TextEditingController();
    modelController = TextEditingController();
    plateController = TextEditingController();

    // If existing data passed in widget, use it; otherwise fetch from Firestore
    if (widget.existingData != null) {
      existingData = Map<String, dynamic>.from(widget.existingData!);
      _fillControllers();
    } else {
      fetchExistingData();
    }
  }

  void _fillControllers() {
    brandController.text = existingData?['brand'] ?? '';
    modelController.text = existingData?['model'] ?? '';
    plateController.text = existingData?['plate'] ?? '';
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
        if (mounted) {
          setState(() {
            _fillControllers();
          });
        }
      }
    } catch (e) {
      // ignore or log
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveChanges() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not signed in')),
        );
      }
      return;
    }

    final brand = brandController.text.trim();
    final model = modelController.text.trim();
    final plate = plateController.text.trim();

    if (brand.isEmpty || model.isEmpty || plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final updateData = {
        'brand': brand,
        'model': model,
        'plate': plate,
      };

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

      // อัปเดต provider ถ้าจำเป็น
      try {
        context.read<MotoProvider>().setMoto(updatedMoto);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกเรียบร้อย')),
        );
        Navigator.pop(context, updatedMoto);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    brandController.dispose();
    modelController.dispose();
    plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลรถ'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(labelText: 'ยี่ห้อ'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelController,
                    decoration: const InputDecoration(labelText: 'รุ่น'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: plateController,
                    decoration: const InputDecoration(labelText: 'ทะเบียน'),
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
    );
  }
}
