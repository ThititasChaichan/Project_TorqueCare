import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart'; // แก้ Error: debugPrint
import 'package:cloud_firestore/cloud_firestore.dart'; // แก้ Error: FirebaseFirestore, QuerySnapshot, Timestamp
import 'package:firebase_auth/firebase_auth.dart'; // แก้ Error: FirebaseAuth
import 'package:intl/intl.dart'; // แก้ Error: DateFormat

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _scheduledKeysPrefix = 'noti_scheduled_';

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings: initSettings);

    await _requestAndroidPermissions();
  }

  Future<void> _requestAndroidPermissions() async {
    final impl = _plugin.resolvePlatformSpecificImplementation;
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        impl<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    await androidPlugin.requestNotificationsPermission();
    await androidPlugin.requestExactAlarmsPermission();
  }

  String _scheduleKey(String docId, String suffix) =>
      '${_scheduledKeysPrefix}${docId}_$suffix';

  Future<bool> _isAlreadyScheduled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> _markAsScheduled(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  Future<void> clearScheduledKeys(String docId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final suffix in ['overdue', '7', '3', '0']) {
      await prefs.remove(_scheduleKey(docId, suffix));
    }
  }

  Future<void> clearAllScheduledFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs
        .getKeys()
        .where((k) => k.startsWith(_scheduledKeysPrefix))
        .toList();
    for (final k in allKeys) {
      await prefs.remove(k);
    }
  }

  static const NotificationDetails _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'moto_channel_id',
      'Moto Notifications',
      channelDescription: 'แจ้งเตือนเอกสารและบริการรถมอเตอร์ไซค์',
      icon: 'ic_notification',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  Future<void> showOverdueNotificationOnce({
    required int id,
    required String docId,
    required String title,
    required String body,
  }) async {
    final key = _scheduleKey(docId, 'overdue');
    if (await _isAlreadyScheduled(key)) return;

    // ✅ v17+: show() ใช้ named parameters ทั้งหมด
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
    await _markAsScheduled(key);
  }

  Future<void> scheduleNotificationOnce({
    required int id,
    required String docId,
    required String daysSuffix,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final key = _scheduleKey(docId, daysSuffix);
    if (await _isAlreadyScheduled(key)) return;

    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    // ✅ v17+: zonedSchedule() ใช้ named parameters ทั้งหมด
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzDate,
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$docId|$daysSuffix',
    );

    await _markAsScheduled(key);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notifDetails,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<List<Map<String, dynamic>>> fetchAndScheduleNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return []; // ถ้ายังไม่ได้ล็อกอิน ให้คืนค่าลิสต์ว่าง

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

      // ดึงข้อมูลทั้งหมดเหมือนที่คุณเขียนไว้
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

      // เรียงลำดับวันที่
      tempList.sort((a, b) {
        final Timestamp? tA = a['expiry_date'] as Timestamp?;
        final Timestamp? tB = b['expiry_date'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tA.compareTo(tB);
      });

      // ตั้งเวลาแจ้งเตือน (Schedule) ใหม่ทั้งหมด
      final DateTime now = DateTime.now();
      for (var data in tempList) {
        final Timestamp? expiryTimestamp = data['expiry_date'] as Timestamp?;
        if (expiryTimestamp == null) continue;

        final DateTime expiryDate = expiryTimestamp.toDate();
        final String type = data['type'] ?? '';
        final String docId = data['docId'] ?? '';

        if (expiryDate.isBefore(now)) {
          await showOverdueNotificationOnce(
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
            // ตั้งเวลาให้แจ้งเตือนตอน 09:00 น. ของวันนั้นๆ
            scheduleTime = DateTime(
              scheduleTime.year,
              scheduleTime.month,
              scheduleTime.day,
              9,
              0,
            );

            if (scheduleTime.isAfter(now)) {
              await scheduleNotificationOnce(
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

      return tempList; // คืนค่าลิสต์เพื่อให้ NotificationScreen นำไปแสดงผล
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      return [];
    }
  }
}
