import 'package:flutter/material.dart';
// import 'package:moto/screen/login.dart';
import 'package:moto/screen/splash.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // ตั้ง SplashScreen เป็นหน้าหลัก
      routes: {
        // '/': (context) => LoginField(),
        '/': (context) => SplashScreen(), // Splash เป็นหน้าแรก
        '/home': (context) => BaseLayout(
          body: HomeScreen(),
          activeIndex: 0,
        ), // สร้าง HomeScreen เพิ่มเอง
      },
    );
  }
}
