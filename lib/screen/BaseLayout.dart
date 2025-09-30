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
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return PreferredSize(
    preferredSize: Size.fromHeight(screenHeight * 0.12),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 131, 0, 0),
      titleSpacing: 0,
      title: Row(
        children: [
          SizedBox(width: screenWidth * 0.02),
          IconButton(
            icon: Icon(
              Icons.menu,
              size: screenWidth * 0.08,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, animation, __) => SettingScreen(),
                  transitionsBuilder: (_, animation, __, child) =>
                      FadeTransition(opacity: animation, child: child),
                ),
              );
            },
          ),
          SvgPicture.asset(
            'assets/SVG_light_logo.svg',
            height: screenHeight * 0.08, // responsive
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.06, // responsive font
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

BottomAppBar bottomNavigationBar(BuildContext context, int activeIndex) {
  final screenHeight = MediaQuery.of(context).size.height;

  return BottomAppBar(
    color: const Color.fromARGB(255, 0, 26, 255),
    child: SizedBox(
      height: screenHeight * 0.09, // responsive height
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _alignX;
  double _currentX = -1;

  double getAlignX(int index, int itemCount) {
    double x = (index / (itemCount - 0.8)) * 2 - 1;
    return x + 0.05;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _currentX = getAlignX(widget.activeIndex, 5);

    _alignX = Tween<double>(
      begin: _currentX,
      end: _currentX,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      final newX = getAlignX(widget.activeIndex, 5);

      _alignX = Tween<double>(
        begin: _currentX,
        end: newX,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

      _controller.reset();
      _controller.forward();
      _currentX = newX;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _alignX,
      builder: (context, child) {
        return Align(
          alignment: Alignment(_alignX.value, 1.0),
          child: Container(
            width: screenWidth * 0.12,
            height: screenHeight * 0.02,
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.015,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 31, 2, 158),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAnimatedIcon(
          context,
          0,
          Icons.house_rounded,
          Icons.home_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          1,
          Icons.notifications_active_rounded,
          Icons.notifications_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          2,
          Icons.menu_book_rounded,
          Icons.book_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          3,
          Icons.stacked_line_chart_rounded,
          Icons.show_chart_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          4,
          Icons.bookmarks_rounded,
          Icons.bookmark_rounded,
          Colors.white,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(
    BuildContext context,
    int index,
    IconData iconActive,
    IconData iconInactive,
    Color color,
    double screenWidth,
  ) {
    bool isActive = index == widget.activeIndex;
    final double sizeActive = screenWidth * 0.07;
    final double sizeInactive = screenWidth * 0.065;

    return IconButton(
      onPressed: () {
        Widget nextScreen;
        switch (index) {
          case 0:
            nextScreen = BaseLayout(body: HomeScreen(), activeIndex: 0);
            break;
          case 1:
            nextScreen = BaseLayout(body: NotificationScreen(), activeIndex: 1);
            break;
          case 2:
            nextScreen = BaseLayout(body: HistoryScreen(), activeIndex: 2);
            break;
          case 3:
            nextScreen = BaseLayout(body: ReportScreen(), activeIndex: 3);
            break;
          case 4:
            nextScreen = BaseLayout(body: EventScreen(), activeIndex: 4);
            break;
          default:
            nextScreen = BaseLayout(body: HomeScreen(), activeIndex: 0);
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => nextScreen,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
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
