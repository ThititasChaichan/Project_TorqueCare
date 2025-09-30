import 'dart:ui';
import 'package:flutter/material.dart';

/// ✅ Widget ใหม่: ExpandableFab (ไม่มี Navigator ภายใน)
class ExpandableFab extends StatefulWidget {
  final List<Map<String, dynamic>> menuItems;
  final void Function(int index) onItemSelected;

  const ExpandableFab({
    super.key,
    required this.menuItems,
    required this.onItemSelected,
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _animations;
  late Animation<double> _fabAnimation;
  bool _isMenuOpen = false;

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

    _animations = List.generate(widget.menuItems.length, (index) {
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
    } else {
      _controller.forward();
    }
    setState(() => _isMenuOpen = !_isMenuOpen);
  }

  Widget _buildMenuItem(IconData icon, String text, int index) {
    return SlideTransition(
      position: _animations[index],
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () {
            _toggleMenu();
            widget.onItemSelected(index); // ✅ ส่ง index กลับไป
          },
          child: Container(
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
          ),
        ),
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
    return Stack(
      children: [
        if (_isMenuOpen)
          GestureDetector(
            onTap: _toggleMenu,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),

        if (_isMenuOpen)
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.menuItems.length, (index) {
                final item = widget.menuItems[index];
                return _buildMenuItem(item["icon"], item["text"], index);
              }),
            ),
          ),

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
    );
  }
}

/// Dummy page
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
