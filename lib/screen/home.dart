import 'dart:ui';
import 'package:flutter/material.dart';
import 'notification.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _animations;
  late Animation<double> _fabAnimation;

  bool _isMenuOpen = false;

  final List<Map<String, dynamic>> _menuItems = [
    {"icon": Icons.settings, "text": "Settings"},
    {"icon": Icons.favorite, "text": "Favorites"},
    {"icon": Icons.person, "text": "Profile"},
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _animations = List.generate(_menuItems.length, (index) {
      final start = 0.1 * index;
      final end = start + 0.6;
      return Tween<Offset>(
        begin: const Offset(0, 1.5),
        end: const Offset(0, 0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutBack),
        ),
      );
    });
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _controller.reverse();
      setState(() => _isMenuOpen = false);
    } else {
      _controller.forward();
      setState(() => _isMenuOpen = true);
    }
  }

  Widget _buildMenuItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // เนื้อหาหลัก
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: 400,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Home Screen bababoi',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),

          // Overlay + Blur
          if (_isMenuOpen)
            GestureDetector(
              onTap: _toggleMenu,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),

          // เมนูปุ่ม (อยู่เหนือ FAB)
          if (_isMenuOpen)
            Positioned(
              right: 16,
              bottom: 100, // วางเมนูเหนือ FAB
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_menuItems.length, (index) {
                  final item = _menuItems[index];
                  return SlideTransition(
                    position: _animations[index],
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ), // เว้นแต่ละปุ่ม
                      child: GestureDetector(
                        onTap: () {
                          _toggleMenu();

                          // 👉 เลือกหน้าใหม่ตาม index
                          Widget page;
                          switch (index) {
                            case 0:
                              page = const NotificationScreen();
                              break;
                            case 1:
                              page = const NotificationScreen();
                              break;
                            case 2:
                              page = const NotificationScreen();
                              break;
                            default:
                              page = const DummyPage(title: "Unknown");
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => page),
                          );
                        },
                        child: _buildMenuItem(item["icon"], item["text"]),
                      ),
                    ),
                  );
                }),
              ),
            ),
          // FAB fixed
          Positioned(
            right: 16,
            bottom: 40,
            child: AnimatedBuilder(
              animation: _fabAnimation,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _fabAnimation.value * (15.708 / 4),
                  child: child,
                );
              },
              child: FloatingActionButton(
                onPressed: _toggleMenu,
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DummyPage extends StatelessWidget {
  final String title;
  const DummyPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          "ขออภัย เกิดข้อผิดพลาด ($title)",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
