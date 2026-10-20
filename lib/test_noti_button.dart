import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto/line_notification_service.dart';
import 'package:moto/notification_service.dart';

class TestNotiButton extends StatelessWidget {
  const TestNotiButton({super.key});

  Future<void> _handleTestNoti(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ กรุณาล็อกอินด้วยบัญชีหลักก่อน')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กำลังตรวจสอบรายการและส่งแจ้งเตือนเข้า LINE... ⏳'),
        ),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc.data()?['isLineLinked'] != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ คุณยังไม่ได้ผูกบัญชี LINE กรุณากดผูกบัญชีก่อน'),
            ),
          );
        }
        return;
      }

      // บังคับตรวจสอบและส่งแจ้งเตือนวันหมดอายุจริง
      final result = await NotificationService().checkAndSendLineNotifications(
        force: true,
      );

      final count = result['count'] as int?;
      if (count != null && count > 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ ส่งการแจ้งเตือน $count รายการเข้า LINE เรียบร้อย!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // หากไม่มีรายการที่ใกล้หมดอายุจริง ให้เสนอส่งตัวอย่างจำลอง
        final lineUserId = userDoc.data()?['lineUserId'];
        if (context.mounted && lineUserId != null) {
          final sendDemo = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('ไม่มีรายการใกล้หมดอายุจริง 🎉'),
              content: const Text(
                'ปัจจุบันยังไม่มีเอกสารหรือบริการที่ใกล้หมดอายุใน 7 วันนี้\n\nต้องการให้ระบบส่ง "ข้อความจำลองตัวอย่าง" เข้า LINE เพื่อดูรูปแบบการแจ้งเตือนหรือไม่?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ไม่ส่ง'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ส่งตัวอย่างเข้า LINE'),
                ),
              ],
            ),
          );

          if (sendDemo == true) {
            await LineNotificationService.sendExpirationSummary(
              lineUserId: lineUserId,
              items: [
                {
                  'type': 'พ.ร.บ.',
                  'motoLabel': 'Honda Forza 350 (1กข 9999)',
                  'dateStr': '20/10/2026',
                  'statusText': '⏳ อีก 3 วัน',
                },
                {
                  'type': 'ถ่ายน้ำมันเครื่อง',
                  'motoLabel': 'Honda Forza 350 (1กข 9999)',
                  'dateStr': '15/10/2026',
                  'statusText': '⚠️ เลยกำหนดแล้ว 2 วัน',
                },
                {
                  'type': 'ใบขับขี่',
                  'motoLabel': '',
                  'dateStr': '24/10/2026',
                  'statusText': '⏳ อีก 7 วัน',
                },
              ],
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '✅ ส่งข้อความตัวอย่างเข้า LINE สำเร็จ! เปิดเช็คใน LINE ได้เลยครับ',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print("Error in Test Noti: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleTestNoti(context),
      icon: const Icon(Icons.notifications_active),
      label: const Text('ทดสอบแจ้งเตือนวันหมดอายุผ่าน LINE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // ใช้สีเขียวให้ล้อกับ LINE
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
