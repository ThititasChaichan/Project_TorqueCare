import 'package:flutter/material.dart';
import 'addPaperNoti.dart'; // ตัวอย่างหน้าจอเปล่า
import 'addServiceNoti.dart'; // ตัวอย่างหน้าจอเปล่า
import 'widget.dart'; // ไฟล์ที่เราแยก ExpandableFab ไว้

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  final List<Map<String, dynamic>> _menuItems = const [
    {"icon": Icons.edit_document, "text": "Paper"},
    {"icon": Icons.construction_rounded, "text": "Service"},
    {"icon": Icons.settings, "text": "Settings"},
    {"icon": Icons.info, "text": "About"},
    {"icon": Icons.logout, "text": "Logout"},
  ];

  void _handleMenuSelected(BuildContext context, int index) {
    Widget page;
    switch (index) {
      case 0:
        page = const AddPaperNotificationScreen();
        break;
      case 1:
        page = const AddServiceNotificationScreen();
        break;
      case 2:
        page = const DummyPage(title: "Unknown");
        break;
      case 3:
        page = const AddServiceNotificationScreen();
        break;
      case 4:
        page = const AddServiceNotificationScreen();
        break;
      default:
        page = const DummyPage(title: "Unknown");
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                width: screenWidth * 0.95,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 0, 0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                margin: const EdgeInsets.all(3),
                // padding: const EdgeInsets.all(3),
                child: const Text(
                  'Notification Screen',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),

          /// 🔥 ส่ง callback ไป
          ExpandableFab(
            menuItems: _menuItems,
            onItemSelected: (index) => _handleMenuSelected(context, index),
          ),
        ],
      ),
    );
  }
}
