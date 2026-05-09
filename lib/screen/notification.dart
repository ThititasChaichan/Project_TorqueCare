import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'addPaperNoti.dart';
import 'addServiceNoti.dart';
import 'widget.dart'; // ไฟล์ที่มี ExpandableFab

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<Map<String, dynamic>> _menuItems = const [
    {"icon": Icons.edit_document, "text": "Paper"},
    {"icon": Icons.construction_rounded, "text": "Service"},
  ];

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications(); // โหลดข้อมูลเมื่อเปิดหน้าจอ
  }

  // --- ฟังก์ชันโหลดและจัดเรียงข้อมูล ---
  // --- ฟังก์ชันโหลดและจัดเรียงข้อมูล (อัปเกรดความเร็ว ใช้ Future.wait) ---
  Future<void> _fetchNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    List<Map<String, dynamic>> tempList = [];
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    final Map<String, List<String>> notificationStructure = {
      'เอกสาร': [
        'พ.ร.บ.',
        'ภาษีประจำปี',
        'ใบขับขี่',
        'ตรวจสภาพรถ',
        'ประกันภัย',
      ],
      'บริการ': [
        'ถ่ายน้ำมันเครื่อง',
        'เปลี่ยนยาง',
        'เปลี่ยนผ้าเบรก',
        'เช็คระยะ',
      ],
    };

    try {
      // 1. ดึงข้อมูลรถทั้งหมดมาก่อน
      final motosQuery = await userRef.collection('motos').get();
      final List<String> motoIds = motosQuery.docs
          .map((doc) => doc.id)
          .toList();

      // สร้าง List สำหรับเก็บ "งาน" ที่ต้องวิ่งไปดึงข้อมูลพร้อมๆ กัน
      List<Future<QuerySnapshot>> fetchTasks = [];
      // สร้าง List สำหรับเก็บว่างานไหนคือหมวดหมู่ไหน/ประเภทอะไร เพื่อให้แมปข้อมูลถูกตอนดึงเสร็จ
      List<Map<String, String>> taskMetadatas = [];

      // 2. จัดเตรียมงาน (แต่ยังไม่เริ่มดึงข้อมูล)
      for (var entry in notificationStructure.entries) {
        final category = entry.key;
        final types = entry.value;

        for (String type in types) {
          // เตรียมงานระดับ User (ไม่ผูกกับรถ)
          fetchTasks.add(
            userRef
                .collection('notifications')
                .doc(category)
                .collection(type)
                .get(),
          );
          taskMetadatas.add({'category': category, 'type': type});

          // เตรียมงานระดับ Moto (ผูกกับรถ)
          for (String motoId in motoIds) {
            fetchTasks.add(
              userRef
                  .collection('motos')
                  .doc(motoId)
                  .collection('notifications')
                  .doc(category)
                  .collection(type)
                  .get(),
            );
            taskMetadatas.add({'category': category, 'type': type});
          }
        }
      }

      // 3. สั่งให้ทุกงานวิ่งไปดึงข้อมูล "พร้อมกัน" (Parallel Fetching) - จุดนี้แหละที่ทำให้เร็วขึ้นมาก!
      final List<QuerySnapshot> results = await Future.wait(fetchTasks);

      // 4. นำผลลัพธ์ที่ได้พร้อมๆ กัน มาแกะใส่ tempList
      for (int i = 0; i < results.length; i++) {
        final querySnapshot = results[i];
        final metadata = taskMetadatas[i];

        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          data['type'] = metadata['type'];
          data['category'] = metadata['category'];
          tempList.add(data);
        }
      }

      // 5. จัดเรียงวันที่ (ใกล้หมดอายุขึ้นก่อน)
      tempList.sort((a, b) {
        final Timestamp? tA = a['expiry_date'] as Timestamp?;
        final Timestamp? tB = b['expiry_date'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tA.compareTo(tB);
      });

      setState(() {
        _notifications = tempList;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- จัดการตอนกดเลือกเมนู ---
  Future<void> _handleMenuSelected(BuildContext context, int index) async {
    Widget page;
    switch (index) {
      case 0:
        page = const AddPaperNotificationScreen();
        break;
      case 1:
        page = const AddServiceNotificationScreen();
        break;
      default:
        page = const Scaffold(body: Center(child: Text("Unknown")));
    }

    // รอจนกว่าหน้า Add จะถูก pop กลับมา (พร้อมส่งค่า true ถ้าบันทึกสำเร็จ)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    // ถ้ารีเทิร์นกลับมาเป็น true ให้ทำการโหลดข้อมูลใหม่
    if (result == true) {
      _fetchNotifications();
    }
  }

  // --- สร้าง UI สำหรับแสดงผลแต่ละ Item ---
  Widget _buildNotificationItem(Map<String, dynamic> data) {
    final type = data['type'] ?? 'ไม่ระบุประเภท';
    final model = data['model'] ?? '';
    final Timestamp? expiryTimestamp = data['expiry_date'] as Timestamp?;

    DateTime? expiryDate = expiryTimestamp?.toDate();
    bool isExpiredOrClose = false;
    String dateText = 'ไม่มีวันหมดอายุ';

    if (expiryDate != null) {
      dateText = DateFormat('dd MMM yyyy').format(expiryDate);
      // เช็คว่าหมดอายุแล้วหรือเหลือน้อยกว่า 30 วันหรือเปล่า
      if (expiryDate.difference(DateTime.now()).inDays <= 30) {
        isExpiredOrClose = true;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 0, 122, 53),
          child: Icon(Icons.description, color: Colors.white),
        ),
        title: Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(model.isNotEmpty ? model : 'ข้อมูลส่วนตัว'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'วันหมดอายุ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              dateText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                // ถ้าใกล้หมด/หมดแล้ว ให้เป็นสีแดง เพื่อแจ้งเตือน
                color: isExpiredOrClose ? Colors.red : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // พื้นที่แสดงรายการแจ้งเตือน
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? const Center(child: Text('ไม่มีรายการแจ้งเตือน'))
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 10,
                      bottom: 80,
                    ), // เผื่อที่ให้ปุ่ม FAB
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
          ),

          // ปุ่ม ExpandableFab
          ExpandableFab(
            menuItems: _menuItems,
            onItemSelected: (index) => _handleMenuSelected(context, index),
          ),
        ],
      ),
    );
  }
}
