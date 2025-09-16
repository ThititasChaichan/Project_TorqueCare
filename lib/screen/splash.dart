import 'package:flutter/material.dart';
import 'package:moto/screen/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _controller2;
  late AnimationController _controller3;

  late Animation<double> _position;
  late Animation<double> _size;
  late Animation<double> _fsize;
  late Animation<double> _fsize2;
  late Animation<double> _fadeItem;
  late Animation<double> _fadelogin;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _controller3 = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _size = Tween<double>(
      begin: 200,
      end: 120,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
    _fsize = Tween<double>(
      begin: 50,
      end: 30,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
    _fsize2 = Tween<double>(
      begin: 20,
      end: 12,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
    _position = Tween<double>(
      begin: 0,
      end: -200,
    ).animate(CurvedAnimation(parent: _controller2, curve: Curves.easeInOut));
    _fadeItem = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadelogin = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller3, curve: Curves.easeInOut));

    _controller.forward();
    // ฟังว่าอันแรกจบไหม
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // ถ้าเสร็จแล้ว ค่อยเริ่มตัวที่สอง
        _controller2.forward();
      }
      _controller2.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller3.forward(); // เริ่ม fade-in ของ LoginField
        }
      });

      // รอ 2 วินาที แล้วไปหน้า Home
      // Timer(const Duration(seconds: 5), () {
      //   Navigator.of(context).pushReplacementNamed('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 33, 165, 0),
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _controller2]),
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _position.value),
                  child: Opacity(
                    opacity: _fadeItem.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/SVG_light_logo.png',
                          width: _size.value,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'TorqueCare',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _fsize.value,
                          ),
                        ),
                        Text(
                          'Care Your Bike Saved your Life',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _fsize2.value,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadelogin,
              child: Center(
                child: SizedBox(width: 320, height: 500, child: LoginField()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class SplashScreen extends StatefulWidget {
//   @override
//   _SplashScreen createState() => _SplashScreen();
// }

// class _SplashScreen extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _sizeAnimation;
//   late Animation<Color?> _colorAnimation;
//   late Animation<double> _positionAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: Duration(seconds: 6),
//       vsync: this,
//     )..repeat(reverse: true); // ให้วนกลับไปมา

//     _sizeAnimation = Tween<double>(begin: 100, end: 200).animate(_controller);
//     _colorAnimation = ColorTween(
//       begin: Colors.red,
//       end: Colors.blue,
//     ).animate(_controller);
//     _positionAnimation = Tween<double>(begin: 0, end: 200).animate(_controller);
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: AnimatedBuilder(
//         animation: _controller,
//         builder: (context, child) {
//           return Center(
//             child: Transform.translate(
//               offset: Offset(0, _positionAnimation.value),
//               child: Container(
//                 width: _sizeAnimation.value,
//                 height: _sizeAnimation.value,
//                 color: _colorAnimation.value,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();

//     // รอ 2 วินาที แล้วไปหน้า Home
//     // Timer(const Duration(seconds: 5), () {
//     //   Navigator.of(context).pushReplacementNamed('/home');
//     // });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color.fromARGB(255, 255, 0, 0), // สีพื้นหลัง
//       body: Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset('assets/SVG_light_logo.png', width: 200), // โลโก้
//             Padding(
//               padding: EdgeInsets.only(top: 16.0),
//               child: Text(
//                 'TorqueCare',
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 255, 255, 255),
//                   fontSize: 30,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(0.0),
//               child: Text(
//                 'Care Your Bike Seved your Life',
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 255, 255, 255),
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }



// late AnimationController _controller1;
// late AnimationController _controller2;

// @override
// void initState() {
//   super.initState();

//   _controller1 = AnimationController(
//     duration: Duration(seconds: 1),
//     vsync: this,
//   );

//   _controller2 = AnimationController(
//     duration: Duration(seconds: 1),
//     vsync: this,
//   );

//   // เริ่มอันแรก
//   _controller1.forward();

//   // ฟังว่าอันแรกจบไหม
//   _controller1.addStatusListener((status) {
//     if (status == AnimationStatus.completed) {
//       // ถ้าเสร็จแล้ว ค่อยเริ่มตัวที่สอง
//       _controller2.forward();
//     }
//   });
// }