import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:moto/screen/splash.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBarforthispage(context: context, title: 'Setting'),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Divider(height: 50, color: const Color.fromARGB(255, 0, 0, 0)),
              SizedBox(
                child: Container(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  padding: EdgeInsets.all(8),
                  child: Text(
                    ' ตั้งค่า',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ), // เส้นแบ่ง

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.settings, size: 25),
              label: Text('ตั้งค่า', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                elevation: 0,
              ),
            ),
          ),
          Divider(height: 5, color: const Color.fromARGB(255, 182, 182, 182)),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.settings, size: 25),
              label: Text('ตั้งค่า', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                elevation: 0,
              ),
            ),
          ),
          Divider(height: 5, color: const Color.fromARGB(255, 182, 182, 182)),

          SizedBox(height: 30),

          SizedBox(
            width: 150,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SplashScreen()),
                );
              },
              // icon: Icon(Icons.settings, size: 25),
              label: Text('Log Out', style: TextStyle(fontSize: 22)),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                alignment: Alignment.center,
                side: BorderSide(
                  color: Color.fromARGB(255, 255, 0, 0),
                  width: 2,
                ),
                overlayColor: const Color.fromARGB(255, 255, 0, 0),
                shadowColor: Color.fromARGB(255, 255, 0, 0),
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                foregroundColor: const Color.fromARGB(255, 255, 0, 0),
                // elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

PreferredSizeWidget buildCustomAppBarforthispage({
  required BuildContext context,
  required String title,
}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(80.0),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 182, 182, 182),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(
              Icons.menu,
              size: 30,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryanimation) =>
                      BaseLayout(body: HomeScreen(), activeIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryanimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
          ),
          SvgPicture.asset('assets/SVG_logo.svg', height: 100),
          // Icon(Icons.star, color: const Color.fromARGB(255, 0, 0, 0)),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: const Color.fromARGB(255, 0, 0, 0),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}
