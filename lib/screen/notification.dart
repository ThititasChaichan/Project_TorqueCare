import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../moto_provider.dart';
import '../notification_service.dart';
import 'uiverse_loader.dart';
import 'addPaperNoti.dart';
import 'addServiceNoti.dart';
import 'widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

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
    _fetchNotifications();
  }

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
      final motosQuery = await userRef.collection('motos').get();
      final List<String> motoIds = motosQuery.docs
          .map((doc) => doc.id)
          .toList();

      List<Future<QuerySnapshot>> fetchTasks = [];
      List<Map<String, String>> taskMetadatas = [];

      for (var entry in notificationStructure.entries) {
        final category = entry.key;
        final types = entry.value;

        for (String type in types) {
          fetchTasks.add(
            userRef
                .collection('notifications')
                .doc(category)
                .collection(type)
                .get(),
          );
          taskMetadatas.add({'category': category, 'type': type, 'motoId': ''});

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
            taskMetadatas.add({
              'category': category,
              'type': type,
              'motoId': motoId,
            });
          }
        }
      }

      final List<QuerySnapshot> results = await Future.wait(fetchTasks);

      for (int i = 0; i < results.length; i++) {
        final querySnapshot = results[i];
        final metadata = taskMetadatas[i];

        for (var doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id;
          data['type'] = metadata['type'];
          data['category'] = metadata['category'];
          data['motoId'] = metadata['motoId'];

          if (metadata['motoId']!.isNotEmpty) {
            data['docPath'] =
                'users/$uid/motos/${metadata['motoId']}/notifications/${metadata['category']}/${metadata['type']}/${doc.id}';
          } else {
            data['docPath'] =
                'users/$uid/notifications/${metadata['category']}/${metadata['type']}/${doc.id}';
          }
          tempList.add(data);
        }
      }

      tempList.sort((a, b) {
        final Timestamp? tA = a['expiry_date'] as Timestamp?;
        final Timestamp? tB = b['expiry_date'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tA.compareTo(tB);
      });

      final Map<String, Map<String, dynamic>> dedupMap = {};
      for (var data in tempList) {
        final key = '${data['category']}_${data['type']}';
        dedupMap[key] = data;
      }
      tempList = dedupMap.values.toList();

      for (var data in tempList) {
        final Timestamp? expiryTimestamp = data['expiry_date'] as Timestamp?;
        if (expiryTimestamp == null) continue;

        final DateTime expiryDate = expiryTimestamp.toDate();
        final String type = data['type'] ?? '';
        final String docId = data['docId'] ?? '';
        final DateTime now = DateTime.now();

        if (expiryDate.isBefore(now)) {
          await NotificationService().showOverdueNotificationOnce(
            id: '${docId}overdue'.hashCode.abs(),
            docId: docId,
            title: '⚠️ เลยกำหนดแล้ว: $type',
            body:
                'หมดอายุตั้งแต่ ${DateFormat('dd/MM/yyyy').format(expiryDate)} โปรดรีบดำเนินการ',
          );
        } else {
          final String body =
              'จะหมดอายุในวันที่ ${DateFormat('dd/MM/yyyy').format(expiryDate)} โปรดเตรียมตัวดำเนินการ';
          final schedules = [
            {'days': 7, 'label': '(อีก 7 วัน)', 'suffix': '7'},
            {'days': 3, 'label': '(อีก 3 วัน)', 'suffix': '3'},
            {'days': 0, 'label': '(วันนี้!)', 'suffix': '0'},
          ];

          for (var schedule in schedules) {
            final int days = schedule['days'] as int;
            final String suffix = schedule['suffix'] as String;

            DateTime scheduleTime = expiryDate.subtract(Duration(days: days));
            scheduleTime = DateTime(
              scheduleTime.year,
              scheduleTime.month,
              scheduleTime.day,
              9,
              0,
            );

            if (scheduleTime.isAfter(now)) {
              await NotificationService().scheduleNotificationOnce(
                id: '$docId$suffix'.hashCode.abs(),
                docId: docId,
                daysSuffix: suffix,
                title: 'ใกล้หมดอายุ: $type ${schedule['label']}',
                body: body,
                scheduledDate: scheduleTime,
              );
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _notifications = tempList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleMenuSelected(BuildContext context, int index) async {
    final moto = context.read<MotoProvider>().selectedMoto;
    final String motoId = moto?['id'] ?? '';
    final String motoLabel = moto != null
        ? '${moto['brand'] ?? ''} ${moto['model'] ?? ''}'.trim()
        : '';

    Widget page;
    switch (index) {
      case 0:
        page = AddPaperNotificationScreen(motoId: motoId, motoLabel: motoLabel);
        break;
      case 1:
        page = AddServiceNotificationScreen(
          motoId: motoId,
          motoLabel: motoLabel,
        );
        break;
      default:
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (result == true) {
      _fetchNotifications();
    }
  }

  Future<void> _handleEdit(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final String category = data['category'] ?? '';
    final String motoId = data['motoId'] ?? '';
    final String motoLabel = data['model'] ?? '';

    Widget page;
    if (category == 'เอกสาร') {
      page = AddPaperNotificationScreen(
        motoId: motoId,
        motoLabel: motoLabel,
        existingData: data,
        docPath: data['docPath'],
      );
    } else {
      page = AddServiceNotificationScreen(
        motoId: motoId,
        motoLabel: motoLabel,
        existingData: data,
        docPath: data['docPath'],
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (result == true) {
      _fetchNotifications();
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> data) {
    final type = data['type'] ?? 'ไม่ระบุประเภท';
    final category = data['category'] ?? '';
    final Timestamp? expiryTimestamp = data['expiry_date'] as Timestamp?;
    final DateTime? expiryDate = expiryTimestamp?.toDate();

    bool isExpiredOrClose = false;
    String dateText = 'ไม่มีวันหมดอายุ';

    if (expiryDate != null) {
      dateText = DateFormat('dd MMM yyyy').format(expiryDate);
      if (expiryDate.difference(DateTime.now()).inDays <= 30) {
        isExpiredOrClose = true;
      }
    }

    final IconData categoryIcon = category == 'บริการ'
        ? Icons.construction_rounded
        : Icons.description;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category == 'บริการ'
              ? const Color(0xFF0057A8)
              : const Color(0xFF007A35),
          child: Icon(categoryIcon, color: Colors.white),
        ),
        title: Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
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
                    color: isExpiredOrClose ? Colors.red : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.grey),
              onPressed: () => _handleEdit(context, data),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('แจ้งเตือน')),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? Center(child: UiverseLoader())
                : _notifications.isEmpty
                ? const Center(child: Text('ไม่มีรายการแจ้งเตือน'))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
          ),
          ExpandableFab(
            menuItems: _menuItems,
            onItemSelected: (index) => _handleMenuSelected(context, index),
          ),
          // เอาปุ่มนี้ไปแปะไว้ตรงไหนก็ได้ในหน้าแอป (เช่น ใน AppBar หรือ FloatingActionButton)
          ElevatedButton(
            onPressed: () async {
              final plugin = FlutterLocalNotificationsPlugin();
              const details = NotificationDetails(
                android: AndroidNotificationDetails(
                  'moto_test_channel',
                  'Test Channel',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              );

              try {
                // เทส 1: สั่งเด้งทันที! (ใช้ Named Parameters ทั้งหมด)
                await plugin.show(
                  id: 888,
                  title: 'เทส 1: แจ้งเตือนทันที',
                  body: 'ถ้านี่เด้ง แปลว่าสิทธิ์แจ้งเตือนผ่านแล้ว!',
                  notificationDetails: details,
                );
                print('ยิงเทส 1 ทันทีแล้ว!');

                // เทส 2: ตั้งเวลา 1 นาทีแบบดิบๆ (ใช้ Named Parameters ทั้งหมด)
                // เทส 2: ตั้งเวลา 10 วินาที
                await plugin.zonedSchedule(
                  id: 999,
                  title: 'เทส 2: มาแล้วเว้ยย!',
                  body: 'รอแค่ 10 วินาทีก็เด้งแล้ว',
                  scheduledDate: tz.TZDateTime.now(
                    tz.local,
                  ).add(const Duration(seconds: 10)),
                  notificationDetails: details,
                  androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                );
                print('ยิงเทส 2 ล่วงหน้า 10 วินาทีแล้ว! (รอจับเวลา)');
              } catch (e) {
                print('พังครับ! Error: $e');
              }
            },
            child: const Text('ทดสอบขั้นเด็ดขาด'),
          ),
        ],
      ),
    );
  }
}
