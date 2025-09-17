import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPaperNotificationScreen extends StatefulWidget {
  const AddPaperNotificationScreen({super.key});

  @override
  State<AddPaperNotificationScreen> createState() =>
      _AddPaperNotificationScreenState();
}

class _AddPaperNotificationScreenState
    extends State<AddPaperNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _loading = false;

  Future<void> _submitNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เพิ่มการแจ้งเตือนสำเร็จ')),
        );
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      debugPrint('Error adding notification: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เกิดข้อผิดพลาดในการเพิ่ม')),
        );
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มการแจ้งเตือน'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'หัวข้อ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกหัวข้อ'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'ข้อความ',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) => value == null || value.isEmpty
                          ? 'กรุณากรอกข้อความ'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitNotification,
                        icon: const Icon(Icons.send),
                        label: const Text('เพิ่มการแจ้งเตือน'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: Colors.grey,
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
