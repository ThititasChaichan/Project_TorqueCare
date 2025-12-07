import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Addevent extends StatefulWidget {
  final Map<String, dynamic> existingData;
  const Addevent({super.key, required this.existingData});

  @override
  State<Addevent> createState() => _AddeventState();
}

class _AddeventState extends State<Addevent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  String? userId;
  String? motoId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    motoId = widget.existingData['id']; // ต้องส่ง id ของรถเข้ามา
  }

  Future<void> _saveMoto() async {
    if (!_formKey.currentState!.validate()) return;

    final eventData = {
      "title": titleController.text,
      "date": dateController.text,
      "detail": detailController.text,
      "createdAt": Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('motos')
          .doc(motoId)
          .collection("events")
          .add(eventData);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกสำเร็จ!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      dateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Event')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('เหตุการณ์ใหม่'),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'ชื่อเหตุการณ์',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกชื่อเหตุการณ์' : null,
              ),
              const SizedBox(height: 8),
              const Text('วันที่'),
              const SizedBox(height: 8),
              TextFormField(
                controller: dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'วันที่',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณาเลือกวันที่' : null,
              ),
              const SizedBox(height: 8),
              const Text('รายละเอียดเหตุการณ์'),
              const SizedBox(height: 8),
              TextFormField(
                controller: detailController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'เพิ่มรายละเอียด',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _saveMoto, child: const Text('บันทึก')),
            ],
          ),
        ),
      ),
    );
  }
}
