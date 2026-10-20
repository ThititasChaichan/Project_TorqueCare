import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto/screen/splash.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../test_noti_button.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> {
  final _usernameController = TextEditingController();
  File? _imageFile;
  String? _photoUrl;
  bool _loading = false;
  final _picker = ImagePicker();
  bool _isLineLinked = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        _usernameController.text = data['username'] ?? '';
        setState(() {
          _photoUrl = data['photoUrl'];
          _isLineLinked = data['isLineLinked'] ?? false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    String? imageUrl;

    // ถ้ามีการเลือกไฟล์ใหม่ ให้ upload ขึ้น Firebase Storage
    if (_imageFile != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child(
          'profile_images/${user.uid}.jpg',
        );
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint("Upload failed: $e");
      }
    }

    // อัปเดต Firestore
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    await userDoc.update({
      'username': _usernameController.text.trim(),
      if (imageUrl != null) 'photoUrl': imageUrl,
    });

    setState(() {
      _loading = false;
      if (imageUrl != null) {
        _photoUrl = imageUrl;
        _imageFile = null;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  ImageProvider _buildAvatarImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_photoUrl != null && _photoUrl!.isNotEmpty) {
      return NetworkImage(_photoUrl!);
    } else {
      return const AssetImage('assets/default_avatar.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จัดการบัญชี'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _buildAvatarImage(),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึก'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (_isLineLinked) {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ยืนยันการยกเลิก'),
                            content: const Text(
                              'คุณต้องการยกเลิกการผูกบัญชี LINE ใช่หรือไม่?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('ยกเลิก'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('ยืนยัน'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await context
                              .read<AuthProvider>()
                              .unlinkLineForNotifications(context);
                          await _loadUserData(); // รีโหลดสถานะหลัง unlink
                        }
                      } else {
                        await context
                            .read<AuthProvider>()
                            .linkLineForNotifications(context);
                        await _loadUserData(); // รีโหลดสถานะหลัง link
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/Line_Rounded_Solid_icon.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isLineLinked
                                ? 'ยกเลิกการผูกบัญชี LINE'
                                : 'ผูกบัญชี LINE',
                            style: TextStyle(
                              color: _isLineLinked ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLineLinked) ...[
                    const SizedBox(height: 10),
                    const SizedBox(
                      width: double.infinity,
                      child: TestNotiButton(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('ออกจากระบบ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
