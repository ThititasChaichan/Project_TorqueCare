import 'package:flutter/material.dart';
// import 'package:moto/screen/BaseLayout.dart';
// import 'package:moto/screen/home.dart';

class LoginField extends StatelessWidget {
  const LoginField({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 320,
              child: TextFormField(
                maxLength: 10,
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                decoration: InputDecoration(
                  labelText: 'User',
                  counterStyle: TextStyle(
                    color: Colors.white, // เปลี่ยนเป็นสีที่ต้องการ
                    fontSize: 12,
                  ),

                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: TextFormField(
                maxLength: 10,
                obscureText: true,
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                decoration: InputDecoration(
                  counterStyle: TextStyle(
                    color: Colors.white, // เปลี่ยนเป็นสีที่ต้องการ
                    fontSize: 12,
                  ),
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 255, 255, 255),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            SizedBox(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white, width: 2),
                ),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/home');
                  // Navigator.pushReplacement(
                  //   context,
                  //   PageRouteBuilder(
                  //     transitionDuration: Duration(seconds: 1),
                  //     pageBuilder: (_, animation, __) =>
                  //         BaseLayout(body: HomeScreen(), activeIndex: 0),
                  //     transitionsBuilder: (_, animation, __, child) {
                  //       // Slide จากขวา
                  //       final slide =
                  //           Tween<Offset>(
                  //             begin: Offset(0.0, 1.0),
                  //             end: Offset.zero,
                  //           ).animate(
                  //             CurvedAnimation(
                  //               parent: animation,
                  //               curve: Curves.slowMiddle,
                  //             ),
                  //           );

                  //       // Fade ค่อยๆ ชัดขึ้น
                  //       final fade = Tween<double>(begin: 0.0, end: 1.0)
                  //           .animate(
                  //             CurvedAnimation(
                  //               parent: animation,
                  //               curve: Curves.easeIn,
                  //             ),
                  //           );

                  //       return SlideTransition(
                  //         position: slide,
                  //         child: FadeTransition(opacity: fade, child: child),
                  //       );
                  //     },
                  //   ),
                  // );
                },
                child: Text(
                  'Login',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
            SizedBox(height: 20),
            Stack(
              children: [
                Divider(height: 30, color: Color.fromARGB(255, 255, 255, 255)),
                SizedBox(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      color: Color.fromARGB(255, 33, 165, 0),
                      width: 40,
                      child: Center(
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              child: OutlinedButton.icon(
                onPressed: () {},
                // icon: Image.asset(
                //   // 'assets/Google_Rounded_Solid_icon.png',
                //   width: 30,
                //   height: 30,
                // ),
                label: Text(
                  'Login With Google',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 20,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color.fromRGBO(255, 255, 255, 255)),
                ),
              ),
            ),
            SizedBox(
              child: OutlinedButton.icon(
                onPressed: () {},
                // icon: Image.asset(
                //   // // 'assets/Line_Rounded_Solid_icon.png',
                //   // width: 30,
                //   // height: 30,
                // ),
                label: Text(
                  '  Login With Line   ',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 20,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color.fromRGBO(255, 255, 255, 255)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
