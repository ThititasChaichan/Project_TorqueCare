import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LineNotificationService {
  // นำ Token จากเว็บ LINE Developers มาใส่ตรงนี้
  static final String _channelAccessToken =
      dotenv.env['LINE_CHANNEL_ACCESS_TOKEN'] ?? '';

  static Future<void> sendWelcomeMessage(String lineUserId) async {
    const String url = 'https://api.line.me/v2/bot/message/push';
    final Map<String, dynamic> body = {
      "to": lineUserId,
      "messages": [
        {
          "type": "text",
          "text":
              "🎉 ยินดีต้อนรับสู่แอปจัดการมอเตอร์ไซค์! ระบบผูกบัญชีสำเร็จแล้ว ต่อจากนี้ระบบจะแจ้งเตือนการซ่อมบำรุงผ่านช่องทางนี้ครับ 🏍️",
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_channelAccessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('❌ ส่งข้อความล้มเหลว: ${response.body}');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการยิง API: $e');
    }
  }

  static Future<void> sendMaintenanceAlert({
    required String lineUserId,
    required String itemName,
    required double cost,
  }) async {
    const String url = 'https://api.line.me/v2/bot/message/push';
    final Map<String, dynamic> body = {
      "to": lineUserId,
      "messages": [
        {
          "type": "text",
          "text":
              "🛠️ บันทึกการซ่อมบำรุงเรียบร้อย!\n\n📌 รายการ: $itemName\n💰 ค่าใช้จ่าย: ฿${cost.toStringAsFixed(2)}\n\nอย่าลืมดูแลรถจักรยานยนต์อย่างสม่ำเสมอนะครับ 🏍️",
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_channelAccessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        print('❌ ส่งข้อความซ่อมบำรุงล้มเหลว: ${response.body}');
      } else {
        print('✅ ส่งข้อความซ่อมบำรุงเข้า LINE สำเร็จ');
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการยิง API (Maintenance): $e');
    }
  }

  /// ส่งข้อความสรุปรายการที่ใกล้หมดอายุ หรือเลยกำหนด เข้า LINE
  static Future<bool> sendExpirationSummary({
    required String lineUserId,
    required List<Map<String, dynamic>> items,
  }) async {
    if (items.isEmpty) return false;

    // จัดกลุ่มรายการตามชื่อรถ (motoLabel)
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in items) {
      final label = (item['motoLabel'] as String?)?.isNotEmpty == true
          ? '🏍️ ${item['motoLabel']}'
          : '🪪 ข้อมูลเอกสารผู้ขับขี่';
      grouped.putIfAbsent(label, () => []).add(item);
    }

    final buffer = StringBuffer();
    buffer.writeln('🔔 แจ้งเตือนจาก TorqueCare');
    buffer.writeln('--------------------------------');
    buffer.writeln('⚠️ พบรายการที่ใกล้ถึงกำหนด / เลยกำหนด:');

    grouped.forEach((groupName, itemList) {
      buffer.writeln('\n$groupName');
      for (final it in itemList) {
        final type = it['type'] ?? 'รายการ';
        final status = it['statusText'] ?? '';
        final dateStr = it['dateStr'] ?? '';
        buffer.writeln(' • $type: $status ($dateStr)');
      }
    });

    buffer.writeln('\n--------------------------------');
    buffer.writeln('💡 อย่าลืมตรวจเช็คและดำเนินการเพื่อความปลอดภัยในการขับขี่นะครับ 🏍️💨');

    return sendCustomTextMessage(
      lineUserId: lineUserId,
      text: buffer.toString(),
    );
  }

  /// ส่งข้อความ Text แบบกำหนดเองเข้า LINE
  static Future<bool> sendCustomTextMessage({
    required String lineUserId,
    required String text,
  }) async {
    const String url = 'https://api.line.me/v2/bot/message/push';
    final Map<String, dynamic> body = {
      "to": lineUserId,
      "messages": [
        {
          "type": "text",
          "text": text,
        },
      ],
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_channelAccessToken',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ ส่งข้อความแจ้งเตือนเข้า LINE สำเร็จ');
        return true;
      } else {
        print('❌ ส่งข้อความ LINE ล้มเหลว (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ เกิดข้อผิดพลาดในการยิง API (sendCustomTextMessage): $e');
      return false;
    }
  }
}
