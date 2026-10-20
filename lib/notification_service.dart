import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/material.dart'; // แก้ Error: debugPrint
import 'package:cloud_firestore/cloud_firestore.dart'; // แก้ Error: FirebaseFirestore, QuerySnapshot, Timestamp
import 'package:firebase_auth/firebase_auth.dart'; // แก้ Error: FirebaseAuth
import 'package:intl/intl.dart'; // แก้ Error: DateFormat
import 'line_notification_service.dart';

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
      '$_scheduledKeysPrefix${docId}_$suffix';

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
    for (final suffix in [
      'overdue',
      '7',
      '3',
      '0',
      'line_overdue',
      'line_7',
      'line_3',
      'line_0',
    ]) {
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

  /// ส่งการแจ้งเตือนเข้า LINE ด้วยข้อความและเงื่อนไขเดียวกับ Local Notification
  Future<void> sendLineAlertOnce({
    required String docId,
    required String suffix,
    required String title,
    required String body,
    String? motoLabel,
  }) async {
    final key = _scheduleKey(docId, 'line_$suffix');
    if (await _isAlreadyScheduled(key)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['isLineLinked'] == true) {
        final lineUserId = userDoc.data()?['lineUserId'] as String?;
        if (lineUserId == null || lineUserId.isEmpty) return;

        final buffer = StringBuffer();
        buffer.writeln('🔔 $title');
        buffer.writeln('--------------------------------');
        if (motoLabel != null && motoLabel.isNotEmpty) {
          buffer.writeln('🏍️ รถ: $motoLabel');
        }
        buffer.writeln('📅 $body');

        final success = await LineNotificationService.sendCustomTextMessage(
          lineUserId: lineUserId,
          text: buffer.toString(),
        );

        if (success) {
          await _markAsScheduled(key);
        }
      }
    } catch (e) {
      debugPrint("Error sending direct LINE alert: $e");
    }
  }

  Future<void> showOverdueNotificationOnce({
    required int id,
    required String docId,
    required String title,
    required String body,
    String? motoLabel,
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

    // ยิงเข้า LINE ควบคู่กันตามเงื่อนไขเดียวกับ Notification ของแอป
    await sendLineAlertOnce(
      docId: docId,
      suffix: 'overdue',
      title: title,
      body: body,
      motoLabel: motoLabel,
    );
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
      final DateTime today = DateTime(now.year, now.month, now.day);
      for (var data in tempList) {
        final Timestamp? expiryTimestamp = data['expiry_date'] as Timestamp?;
        if (expiryTimestamp == null) continue;

        final DateTime expiryDate = expiryTimestamp.toDate();
        final DateTime expiryDay =
            DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        final int diffDays = expiryDay.difference(today).inDays;
        final String type = data['type'] ?? '';
        final String docId = data['docId'] ?? '';
        final String? motoLabel = data['motoLabel'] ?? data['model'];

        // ถ้าเลยกำหนด หรือเป็นวันนี้ที่เวลาหมดอายุผ่านไปแล้ว
        if (diffDays < 0 || (diffDays == 0 && expiryDate.isBefore(now))) {
          await showOverdueNotificationOnce(
            id: '${docId}overdue'.hashCode.abs(),
            docId: docId,
            title: '⚠️ เลยกำหนดแล้ว: $type',
            body:
                'หมดอายุตั้งแต่ ${DateFormat('dd/MM/yyyy').format(expiryDate)} โปรดรีบดำเนินการ',
            motoLabel: motoLabel,
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

            // ถ้ารอบแจ้งเตือนตรงกับวันปัจจุบัน (7 วัน, 3 วัน หรือวันนี้!) -> ส่ง LINE ทันที
            if (diffDays == days) {
              await sendLineAlertOnce(
                docId: docId,
                suffix: suffix,
                title: 'ใกล้หมดอายุ: $type ${schedule['label']}',
                body: body,
                motoLabel: motoLabel,
              );
            }

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

  /// ตรวจสอบรายการที่ใกล้หมดอายุ และส่งแจ้งเตือนสรุปเข้า LINE
  /// [force] ถ้าเป็น true จะบังคับส่งแม้จะเคยส่งไปแล้วในวันนั้น (เหมาะสำหรับปุ่มทดสอบ)
  Future<Map<String, dynamic>> checkAndSendLineNotifications({
    bool force = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'success': false, 'message': 'ยังไม่ได้เข้าสู่ระบบ'};
    }

    try {
      // 1. ตรวจสอบว่าผู้ใช้ผูก LINE หรือยัง
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final isLineLinked = userData?['isLineLinked'] == true;
      final lineUserId = userData?['lineUserId'] as String?;

      if (!isLineLinked || lineUserId == null || lineUserId.isEmpty) {
        return {'success': false, 'message': 'ยังไม่ได้ผูกบัญชี LINE'};
      }

      // 2. ตรวจสอบว่าวันนี้เคยส่งแจ้งเตือนไปหรือยัง (ส่งแค่วันละ 1 ครั้ง)
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastSentDate = prefs.getString('last_line_expiry_noti_date');

      if (!force && lastSentDate == todayStr) {
        debugPrint("LINE notification already sent today ($todayStr)");
        return {
          'success': true,
          'message': 'วันนี้ส่งแจ้งเตือนเข้า LINE แล้ว',
          'skipped': true,
        };
      }

      // 3. ดึงข้อมูลรถทั้งหมดของผู้ใช้เพื่อนำมาแสดงชื่อรถ
      final motosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('motos')
          .get();

      final Map<String, String> motoLabelMap = {};
      final List<String> motoIds = [];
      for (var doc in motosSnapshot.docs) {
        final data = doc.data();
        final brand = data['brand'] ?? '';
        final model = data['model'] ?? '';
        final plate = data['plate'] ?? '';
        motoLabelMap[doc.id] = '$brand $model ($plate)'.trim();
        motoIds.add(doc.id);
      }

      // 4. สแกนรายการแจ้งเตือนทั้งหมด (เอกสาร + บริการ)
      final Map<String, List<String>> structure = {
        'เอกสาร': ['พ.ร.บ.', 'ภาษีประจำปี', 'ใบขับขี่', 'ตรวจสภาพรถ', 'ประกันภัย'],
        'บริการ': ['ถ่ายน้ำมันเครื่อง', 'เปลี่ยนยาง', 'เปลี่ยนผ้าเบรก', 'เช็คระยะ'],
      };

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      List<Future<QuerySnapshot>> tasks = [];
      List<Map<String, String>> metas = [];

      for (var entry in structure.entries) {
        final category = entry.key;
        for (var type in entry.value) {
          // ระดับผู้ใช้ (เช่น ใบขับขี่)
          tasks.add(
            userRef
                .collection('notifications')
                .doc(category)
                .collection(type)
                .get(),
          );
          metas.add({'category': category, 'type': type, 'motoId': ''});

          // ระดับรถแต่ละคัน
          for (var motoId in motoIds) {
            tasks.add(
              userRef
                  .collection('motos')
                  .doc(motoId)
                  .collection('notifications')
                  .doc(category)
                  .collection(type)
                  .get(),
            );
            metas.add({'category': category, 'type': type, 'motoId': motoId});
          }
        }
      }

      final results = await Future.wait(tasks);
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final List<Map<String, dynamic>> expiringItems = [];

      for (int i = 0; i < results.length; i++) {
        final snapshot = results[i];
        final meta = metas[i];

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final expiryTimestamp = data['expiry_date'] as Timestamp?;
          if (expiryTimestamp == null) continue;

          final expiryDate = expiryTimestamp.toDate();
          final expiryDay =
              DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
          final diffDays = expiryDay.difference(today).inDays;

          // แจ้งเตือนเมื่อ:
          // - เลยกำหนดแล้ว (ไม่เกิน 7 วันย้อนหลัง)
          // - หรือกำลังจะหมดอายุในอีก 7 วันข้างหน้า
          if (diffDays <= 7 && diffDays >= -7) {
            String statusText;
            if (diffDays < 0) {
              statusText = '⚠️ เลยกำหนดแล้ว ${diffDays.abs()} วัน';
            } else if (diffDays == 0) {
              statusText = '🚨 ถึงกำหนดวันนี้!';
            } else {
              statusText = '⏳ อีก $diffDays วัน';
            }

            final motoId = meta['motoId'] ?? '';
            final motoLabel =
                motoId.isNotEmpty ? (motoLabelMap[motoId] ?? '') : '';

            expiringItems.add({
              'type': meta['type'],
              'category': meta['category'],
              'motoLabel': motoLabel,
              'expiryDate': expiryDate,
              'dateStr': DateFormat('dd/MM/yyyy').format(expiryDate),
              'diffDays': diffDays,
              'statusText': statusText,
            });
          }
        }
      }

      // เรียงลำดับ: รายการที่ด่วนที่สุดขึ้นก่อน
      expiringItems.sort(
        (a, b) => (a['diffDays'] as int).compareTo(b['diffDays'] as int),
      );

      if (expiringItems.isEmpty) {
        return {
          'success': true,
          'message': 'ไม่มีรายการที่ใกล้หมดอายุใน 7 วันนี้ 🎉',
          'count': 0,
        };
      }

      // 5. ส่งข้อความสรุปเข้า LINE
      final sentSuccess = await LineNotificationService.sendExpirationSummary(
        lineUserId: lineUserId,
        items: expiringItems,
      );

      if (sentSuccess) {
        await prefs.setString('last_line_expiry_noti_date', todayStr);
        return {
          'success': true,
          'message':
              'ส่งการแจ้งเตือนเข้า LINE สำเร็จ (${expiringItems.length} รายการ)',
          'count': expiringItems.length,
        };
      } else {
        return {
          'success': false,
          'message': 'ไม่สามารถส่งข้อความเข้า LINE API ได้',
        };
      }
    } catch (e) {
      debugPrint("Error in checkAndSendLineNotifications: $e");
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: $e'};
    }
  }
}
