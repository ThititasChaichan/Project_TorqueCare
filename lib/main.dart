import 'package:flutter/material.dart';
import 'package:moto/screen/splash.dart';
import 'moto_provider.dart';
import 'auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'screen/motoProfile.dart';
import 'notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // 1. Initialize LINE & Firebase ให้เรียบร้อย
  await LineSDK.instance.setup('2008276410');
  await Firebase.initializeApp();
  await NotificationService().init();

  runApp(
    // 2. นำ MultiProvider กลับมาครอบแอปไว้
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MotoProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      // 3. ใช้ AuthGate เป็นประตูด่านแรกแทนการเปิดหน้า MotoProfilePage ตรงๆ
      home: const AuthGate(),
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
