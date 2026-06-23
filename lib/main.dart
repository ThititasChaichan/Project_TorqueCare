import 'package:flutter/material.dart';
import 'package:moto/screen/splash.dart';
import 'moto_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'screen/motoProfile.dart';
import 'notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LineSDK.instance.setup('2008276410');
  await Firebase.initializeApp(); // อย่าลืม init Firebase
  // await NotificationService().init();

  final notifService = NotificationService();
  await notifService.init();

  // ✅ ตรวจ reboot: pending alarms หาย แต่ flag ยังอยู่
  final plugin = FlutterLocalNotificationsPlugin();
  final pending = await plugin.pendingNotificationRequests();
  final prefs = await SharedPreferences.getInstance();
  final hasFlags = prefs.getKeys()
      .any((k) => k.startsWith('noti_scheduled_'));

  if (pending.isEmpty && hasFlags) {
    await notifService.clearAllScheduledFlags();
  }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MotoProvider())],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // ใช้ AuthGate แทนการเปิด login ทันที
      routes: {
        '/home': (_) => MotoProfilePage(), // หรือหน้า home
        '/login': (_) => const SplashScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // ใช้ StreamBuilder ติดตามการเปลี่ยนแปลงของผู้ใช้
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ระหว่างรอโหลด session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ถ้ามี user อยู่แล้ว → ไปหน้า home
        if (snapshot.hasData) {
          return MotoProfilePage(); // หรือหน้า home
        }

        // ถ้าไม่มี → ไปหน้า login
        return const SplashScreen();
      },
    );
  }
}

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'My App',
//       debugShowCheckedModeBanner: false,
//       initialRoute: '/', // ตั้ง SplashScreen เป็นหน้าหลัก
//       routes: {
//         // '/': (context) => LoginField(),
//         '/': (context) => SplashScreen(), // Splash เป็นหน้าแรก
//         '/home': (context) => BaseLayout(
//           body: HomeScreen(),
//           activeIndex: 0,
//         ), // สร้าง HomeScreen เพิ่มเอง
//       },
//     );
//   }
// }
