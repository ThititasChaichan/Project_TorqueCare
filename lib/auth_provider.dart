import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moto/line_notification_service.dart'; // นำเข้า LineNotificationService

class AuthProvider extends ChangeNotifier {
  UserProfile? _lineUserProfile;

  UserProfile? get lineUserProfile => _lineUserProfile;

  Future<void> linkLineForNotifications(BuildContext context) async {
    try {
      // 1. เด้งหน้า LINE เพื่อขอแค่ User ID (ไม่เกี่ยวกับการสร้างบัญชี Firebase)
      final result = await LineSDK.instance.login(scopes: ["profile"]);
      final lineId = result.userProfile!.userId;

      // 2. เช็คว่าตอนนี้ล็อกอินแอปด้วยบัญชีหลัก (Google) UID อะไรอยู่
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาล็อกอินด้วยบัญชีหลักก่อน')),
        );
        return;
      }

      // 3. เอา LINE ID ไปแปะใน Firestore ของ "UID เดิม" (ข้อมูลรถจะยังอยู่ครบถ้วน)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(
            {
              'lineUserId':
                  lineId, // รหัสนี้แหละที่จะเอาไว้ให้ Cloud Functions ยิงข้อความ
              'isLineLinked': true,
            },
            SetOptions(merge: true),
          ); // merge: true คือจุดสำคัญที่ทำให้ข้อมูลรถเดิมไม่ถูกเขียนทับ
      await LineNotificationService.sendWelcomeMessage(lineId);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ผูกบัญชีสำเร็จ 🎉'),
          content: const Text(
            'ระบบได้เชื่อมต่อกับ LINE ของคุณแล้ว กรุณาตรวจสอบข้อความต้อนรับในแอป LINE ของคุณ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ผูกบัญชี LINE สำหรับรับการแจ้งเตือนสำเร็จ!'),
        ),
      );
    } catch (e) {
      print("Error linking LINE: $e");
    }
  }

  Future<void> unlinkLineForNotifications(BuildContext context) async {
    try {
      // 1. สั่ง Logout จาก LINE SDK เพื่อลบเซสชันแคชในเครื่อง
      // (สำคัญมาก: ถ้าไม่ทำขั้นตอนนี้ รอบหน้าพอกดผูกบัญชี มันจะไม่ถามรหัสใหม่ แต่จะจำ User เดิมทันที)
      await LineSDK.instance.logout();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // 2. ลบข้อมูล lineUserId ออกจาก Firestore ของบัญชีหลัก
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
            // ใช้ FieldValue.delete() เพื่อลบ key นี้ทิ้งไปเลย ป้องกันข้อมูลค้าง
            'lineUserId': FieldValue.delete(),
            'isLineLinked': false,
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยกเลิกการผูกบัญชี LINE เรียบร้อยแล้ว')),
      );
    } catch (e) {
      print("Error unlinking LINE: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการยกเลิกผูกบัญชี')),
      );
    }
  }

  // Future<void> loginWithLine(BuildContext context) async {
  //   try {
  //     // 1. ขอสิทธิ์และดึงข้อมูลจาก LINE SDK
  //     final result = await LineSDK.instance.login(
  //       scopes: ["profile", "openid"],
  //     );

  //     _lineUserProfile = result.userProfile;
  //     notifyListeners();

  //     final lineId = _lineUserProfile!.userId;
  //     final displayName = _lineUserProfile!.displayName;

  //     // 2. แปลง LINE ID เป็น Email และ Password เสมือนเพื่อใช้กับ Firebase
  //     // สร้างรูปแบบอีเมลเฉพาะตัวของแอป และรหัสผ่านที่เดายาก
  //     final String mockEmail = "$lineId@motoapp.com";
  //     final String mockPassword = "Moto_${lineId}_2026!";

  //     final auth = FirebaseAuth.instance;
  //     UserCredential? userCredential;

  //     try {
  //       // 3.1 พยายามล็อกอินด้วยอีเมลจำลอง (สำหรับคนที่เคยสมัครแล้ว)
  //       userCredential = await auth.signInWithEmailAndPassword(
  //         email: mockEmail,
  //         password: mockPassword,
  //       );
  //     } on FirebaseAuthException catch (e) {
  //       // 3.2 ถ้ายังไม่เคยมีบัญชี (เข้าใช้งานครั้งแรก) ให้สร้างบัญชีใหม่
  //       if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
  //         userCredential = await auth.createUserWithEmailAndPassword(
  //           email: mockEmail,
  //           password: mockPassword,
  //         );
  //       } else {
  //         rethrow; // ถ้าเป็น Error อื่นๆ ให้โยนออกไปเข้า Catch ตัวหลัก
  //       }
  //     }

  //     // 4. บันทึกข้อมูล Profile ลง Firestore Database เพื่อใช้อ้างอิงในแอป
  //     if (userCredential != null) {
  //       final firestore = FirebaseFirestore.instance;
  //       await firestore.collection('users').doc(lineId).set({
  //         'displayName': displayName,
  //         'pictureUrl': _lineUserProfile!.pictureUrl,
  //         'lineUserId': lineId,
  //         'firebaseUid':
  //             userCredential.user!.uid, // เก็บ UID ของ Firebase ผูกไว้ด้วย
  //         'lastLogin': FieldValue.serverTimestamp(),
  //         'role': 'user',
  //       }, SetOptions(merge: true));
  //     }

  //     print("✅ ผูกบัญชี LINE และล็อกอินเข้า Firebase Auth สำเร็จ!");
  //   } on PlatformException catch (e) {
  //     // ดักจับ Error จากฝั่งแอปหรือเวลาผู้ใช้กดยกเลิก
  //     print("❌ เกิดข้อผิดพลาดจากระบบ: ${e.message}");
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text('การเชื่อมต่อ LINE ถูกยกเลิก')));
  //   } catch (e) {
  //     // ดักจับ Error อื่นๆ ในระบบ
  //     print("❌ เกิดข้อผิดพลาดที่ไม่รู้จัก: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('เกิดข้อผิดพลาดในการยืนยันตัวตน')),
  //     );
  //   }
  // }
}
