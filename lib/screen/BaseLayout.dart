import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moto/screen/setting.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/notification.dart';
import 'package:moto/screen/history.dart';
import 'package:moto/screen/event.dart';
import 'package:moto/screen/report.dart';

class BaseLayout extends StatelessWidget {
  final Widget body;
  final int activeIndex;

  const BaseLayout({super.key, required this.body, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context: context, title: 'หน้าแรก'),
      body: body,
      bottomNavigationBar: bottomNavigationBar(context, activeIndex),
    );
  }
}

PreferredSizeWidget buildCustomAppBar({
  required BuildContext context,
  required String title,
}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(80.0),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 131, 0, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.menu, size: 30, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryanimation) =>
                      SettingScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryanimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
          ),
          SvgPicture.asset('assets/SVG_light_logo.svg', height: 100),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.white, // เปลี่ยนสีตัวหนังสือ
              fontSize: 30, // (เพิ่มเติม) ขนาดตัวหนังสือ
              fontWeight: FontWeight.bold, // (เพิ่มเติม) ตัวหนา
            ),
          ),
        ],
      ),
    ),
  );
}

// Widget _roundedBox() {
//   return Positioned(
//     top: 12,
//     left: 3,
//     child: Container(
//       width: 60,
//       height: 40,
//       decoration: BoxDecoration(
//         color: Colors.orange,
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//   );
// }

BottomAppBar bottomNavigationBar(BuildContext context, int activeIndex) {
  return BottomAppBar(
    color: const Color.fromARGB(255, 0, 26, 255),
    child: SizedBox(
      height: 60,
      child: Stack(
        children: [
          AnimatedBar(activeIndex: activeIndex),
          Align(
            alignment: Alignment.bottomCenter,
            child: MyAnimatedIconButton(activeIndex: activeIndex),
          ),
        ],
      ),
    ),
  );
}

class AnimatedBar extends StatefulWidget {
  final int activeIndex;
  const AnimatedBar({super.key, required this.activeIndex});

  @override
  State<AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<AnimatedBar>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _position;

  double _currentLeft = 22;

  double getLeftPosition(int index) {
    switch (index) {
      case 0:
        return 12;
      case 1:
        return 88;
      case 2:
        return 164;
      case 3:
        return 240;
      case 4:
        return 316;
      default:
        return 12;
    }
  }

  @override
  void initState() {
    super.initState();

    _currentLeft = getLeftPosition(widget.activeIndex); // <-- เพิ่มบรรทัดนี้

    _controller = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );

    _position = Tween<double>(
      begin: _currentLeft,
      end: _currentLeft,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      double newLeft = getLeftPosition(widget.activeIndex);

      _position = Tween<double>(begin: _currentLeft, end: newLeft).animate(
        CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn),
      );

      _controller.reset();
      _controller.forward();
      _currentLeft = newLeft;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_position.value, 30),
          child: Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 31, 2, 158),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class MyAnimatedIconButton extends StatefulWidget {
  final int activeIndex;
  const MyAnimatedIconButton({super.key, required this.activeIndex});
  @override
  _MyAnimatedIconButtonState createState() => _MyAnimatedIconButtonState();
}

class _MyAnimatedIconButtonState extends State<MyAnimatedIconButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAnimatedIcon(
          context,
          index: 0,
          iconActive: Icons.house_rounded,
          iconInactive: Icons.home_rounded,
          color: Colors.white,
          sizeActive: 30,
          sizeInactive: 35,
        ),
        _buildAnimatedIcon(
          context,
          index: 1,
          iconActive: Icons.notifications_active_rounded,
          iconInactive: Icons.notifications_rounded,
          color: const Color.fromARGB(255, 255, 255, 255),
          sizeActive: 30,
          sizeInactive: 35,
        ),
        _buildAnimatedIcon(
          context,
          index: 2,
          iconActive: Icons.menu_book_rounded,
          iconInactive: Icons.book_rounded,
          color: const Color.fromARGB(255, 255, 255, 255),
          sizeActive: 30,
          sizeInactive: 30,
        ),
        _buildAnimatedIcon(
          context,
          index: 3,
          iconActive: Icons.stacked_line_chart_rounded,
          iconInactive: Icons.show_chart_rounded,
          color: const Color.fromARGB(255, 255, 255, 255),
          sizeActive: 30,
          sizeInactive: 35,
        ),
        _buildAnimatedIcon(
          context,
          index: 4,
          iconActive: Icons.bookmarks_rounded,
          iconInactive: Icons.bookmark_rounded,
          color: const Color.fromARGB(255, 255, 255, 255),
          sizeActive: 25,
          sizeInactive: 30,
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(
    BuildContext context, {
    required int index,
    required IconData iconActive,
    required IconData iconInactive,
    required Color color,
    required double sizeActive,
    required double sizeInactive,
  }) {
    bool isActive = index == widget.activeIndex;

    return IconButton(
      onPressed: () {
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    BaseLayout(body: HomeScreen(), activeIndex: 0),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
            break;
          case 1:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    BaseLayout(body: NotificationScreen(), activeIndex: 1),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
            break;
          case 2:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    BaseLayout(body: HistoryScreen(), activeIndex: 2),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
            break;
          case 3:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    BaseLayout(body: ReportScreen(), activeIndex: 3),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
            break;
          case 4:
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, animation, __) =>
                    BaseLayout(body: EventScreen(), activeIndex: 4),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
              ),
            );
            break;
        }
      },
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isActive ? iconActive : iconInactive,
          size: isActive ? sizeActive : sizeInactive,
          key: ValueKey<bool>(isActive),
          color: color,
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:moto/screen/setting.dart';
// import 'package:moto/screen/home.dart';
// import 'package:moto/screen/hume.dart';
// import 'package:moto/screen/heme.dart';
// import 'package:moto/screen/hame.dart';

// class BaseLayout extends StatelessWidget {
//   final Widget body;
//   final int activeIndex;

//   const BaseLayout({super.key, required this.body, required this.activeIndex});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: buildCustomAppBar(context: context, title: 'หน้าแรก'),
//       body: body,
//       bottomNavigationBar: bottomNavigationBar(context, activeIndex),
//     );
//   }
// }

// PreferredSizeWidget buildCustomAppBar({
//   required BuildContext context,
//   required String title,
// }) {
//   return PreferredSize(
//     preferredSize: Size.fromHeight(80.0),
//     child: AppBar(
//       automaticallyImplyLeading: false,
//       backgroundColor: const Color.fromARGB(255, 131, 0, 0),
//       title: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           IconButton(
//             icon: Icon(Icons.menu, size: 30, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 PageRouteBuilder(
//                   pageBuilder: (context, animation, secondaryanimation) =>
//                       SettingScreen(),
//                   transitionsBuilder:
//                       (context, animation, secondaryanimation, child) {
//                         return FadeTransition(opacity: animation, child: child);
//                       },
//                 ),
//               );
//             },
//           ),
//           SvgPicture.asset('assets/SVG_light_logo.svg', height: 100),
//           SizedBox(width: 8),
//           Text(
//             title,
//             style: TextStyle(
//               color: Colors.white, // เปลี่ยนสีตัวหนังสือ
//               fontSize: 30, // (เพิ่มเติม) ขนาดตัวหนังสือ
//               fontWeight: FontWeight.bold, // (เพิ่มเติม) ตัวหนา
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // Widget _roundedBox() {
// //   return Positioned(
// //     top: 12,
// //     left: 3,
// //     child: Container(
// //       width: 60,
// //       height: 40,
// //       decoration: BoxDecoration(
// //         color: Colors.orange,
// //         borderRadius: BorderRadius.circular(12),
// //       ),
// //     ),
// //   );
// // }

// BottomAppBar bottomNavigationBar(BuildContext context, int activeIndex) {
//   return BottomAppBar(
//     color: const Color.fromARGB(255, 0, 26, 255),
//     child: SizedBox(
//       height: 60,
//       child: Stack(
//         children: [
//           AnimatedBar(activeIndex: activeIndex),
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: MyAnimatedIconButton(activeIndex: activeIndex),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// class AnimatedBar extends StatefulWidget {
//   final int activeIndex;
//   const AnimatedBar({super.key, required this.activeIndex});

//   @override
//   State<AnimatedBar> createState() => _AnimatedBarState();
// }

// class _AnimatedBarState extends State<AnimatedBar> {
//   double getLeftPosition(int index) {
//     switch (index) {
//       case 0:
//         return 22;
//       case 1:
//         return 117;
//       case 2:
//         return 212;
//       case 3:
//         return 307;
//       default:
//         return 22;
//     }
//   }

//   late double _left;

//   @override
//   void initState() {
//     super.initState();
//     _left = getLeftPosition(widget.activeIndex);
//   }

//   @override
//   void didUpdateWidget(covariant AnimatedBar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.activeIndex != widget.activeIndex) {
//       setState(() {
//         _left = getLeftPosition(widget.activeIndex);
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedPositioned(
//       duration: Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       top: 10,
//       left: _left,
//       child: Container(
//         width: 50,
//         height: 40,
//         decoration: BoxDecoration(
//           color: Colors.orange,
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     );
//   }
// }

// class MyAnimatedIconButton extends StatefulWidget {
//   final int activeIndex;
//   const MyAnimatedIconButton({super.key, required this.activeIndex});
//   @override
//   _MyAnimatedIconButtonState createState() => _MyAnimatedIconButtonState();
// }

// class _MyAnimatedIconButtonState extends State<MyAnimatedIconButton> {
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         _buildAnimatedIcon(
//           context,
//           index: 0,
//           iconActive: Icons.house_rounded,
//           iconInactive: Icons.home_rounded,
//           color: Colors.white,
//           sizeActive: 30,
//           sizeInactive: 25,
//         ),
//         _buildAnimatedIcon(
//           context,
//           index: 1,
//           iconActive: Icons.notifications_active_rounded,
//           iconInactive: Icons.notifications_rounded,
//           color: const Color.fromARGB(255, 255, 255, 255),
//           sizeActive: 30,
//           sizeInactive: 25,
//         ),
//         _buildAnimatedIcon(
//           context,
//           index: 2,
//           iconActive: Icons.menu_book_rounded,
//           iconInactive: Icons.book_rounded,
//           color: const Color.fromARGB(255, 255, 255, 255),
//           sizeActive: 30,
//           sizeInactive: 25,
//         ),
//         _buildAnimatedIcon(
//           context,
//           index: 3,
//           iconActive: Icons.bookmarks_rounded,
//           iconInactive: Icons.bookmark_rounded,
//           color: const Color.fromARGB(255, 255, 255, 255),
//           sizeActive: 25,
//           sizeInactive: 20,
//         ),
//       ],
//     );
//   }

//   Widget _buildAnimatedIcon(
//     BuildContext context, {
//     required int index,
//     required IconData iconActive,
//     required IconData iconInactive,
//     required Color color,
//     required double sizeActive,
//     required double sizeInactive,
//   }) {
//     bool isActive = index == widget.activeIndex;

//     return IconButton(
//       onPressed: () {
//         switch (index) {
//           case 0:
//             Navigator.pushReplacement(
//               context,
//               PageRouteBuilder(
//                 pageBuilder: (_, animation, __) =>
//                     BaseLayout(body: HomeScreen(), activeIndex: 0),
//                 transitionsBuilder: (_, animation, __, child) =>
//                     FadeTransition(opacity: animation, child: child),
//               ),
//             );
//             break;
//           case 1:
//             Navigator.push(
//               context,
//               PageRouteBuilder(
//                 pageBuilder: (_, animation, __) =>
//                     BaseLayout(body: HumeScreen(), activeIndex: 1),
//                 transitionsBuilder: (_, animation, __, child) =>
//                     FadeTransition(opacity: animation, child: child),
//               ),
//             );
//             break;
//           case 2:
//             Navigator.push(
//               context,
//               PageRouteBuilder(
//                 pageBuilder: (_, animation, __) =>
//                     BaseLayout(body: HemeScreen(), activeIndex: 2),
//                 transitionsBuilder: (_, animation, __, child) =>
//                     FadeTransition(opacity: animation, child: child),
//               ),
//             );
//             break;
//           case 3:
//             Navigator.push(
//               context,
//               PageRouteBuilder(
//                 pageBuilder: (_, animation, __) =>
//                     BaseLayout(body: HameScreen(), activeIndex: 3),
//                 transitionsBuilder: (_, animation, __, child) =>
//                     FadeTransition(opacity: animation, child: child),
//               ),
//             );
//             break;
//         }
//       },
//       icon: AnimatedSwitcher(
//         duration: Duration(milliseconds: 300),
//         transitionBuilder: (child, animation) {
//           return ScaleTransition(scale: animation, child: child);
//         },
//         child: Icon(
//           isActive ? iconActive : iconInactive,
//           size: isActive ? sizeActive : sizeInactive,
//           key: ValueKey<bool>(isActive),
//           color: color,
//         ),
//       ),
//     );
//   }
// }

















// BottomAppBar bottomNavigationBar(BuildContext context) {
//   return BottomAppBar(
//     color: const Color.fromARGB(255, 0, 26, 255),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: [
//         IconButton(
//           icon: Icon(Icons.home filled, color: Colors.white),
//           onPressed: () {
//             Navigator.push(
//               context,
//               PageRouteBuil der(
//                 pageBuilder: (context, animation, secondaryanimation) =>
//                     HomeScreen(),
//                 transitionsBuilder:
//                     (context, animation, secondaryanimation, child) {
//                       return FadeTransition(opacity: animation, child: child);
//                     },
//               ),
//             );
//           },
//         ),
//         IconButton(
//           icon: Icon(Icons.search, color: Colors.white),
//           onPressed: () {},
//         ),
//         IconButton(
//           icon: Icon(Icons.settings, color: Colors.white),
//           onPressed: () {},
//         ),
//       ],
//     ),
//   );
// }
