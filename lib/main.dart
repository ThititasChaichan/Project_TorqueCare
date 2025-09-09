import 'package:flutter/material.dart';
// import 'package:moto/screen/login.dart';
import 'package:moto/screen/splash.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/BaseLayout.dart';

void main() {
  runApp(MyApp());
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
