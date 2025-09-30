import 'package:flutter/material.dart';
// import 'package:moto/screen/login.dart';
import 'package:moto/screen/splash.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screen/login.dart';
import 'screen/motoProfile.dart'; // หรือ home page ของคุณ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // อย่าลืม init Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // ใช้ AuthGate แทนการเปิด login ทันที
      routes: {
        '/home': (_) =>  MotoProfilePage(), // หรือหน้า home
        '/login': (_) => const LoginField(),
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
          return  MotoProfilePage(); // หรือหน้า home
        }

        // ถ้าไม่มี → ไปหน้า login
        return const LoginField();
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
