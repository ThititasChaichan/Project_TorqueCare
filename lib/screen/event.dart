import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'addEvent.dart';
import 'notification.dart';
import 'package:moto/moto_provider.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();
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
                  color: const Color.fromARGB(255, 98, 0, 255),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Event Screen',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 40,
            child: FloatingActionButton(
              onPressed: () {
                final moto = context.read<MotoProvider>().selectedMoto;
                if (moto == null || moto['id'] == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('กรุณาเลือกรถก่อนเพิ่มเหตุการณ์'),
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) =>
                        Addevent(existingData: moto),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
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
