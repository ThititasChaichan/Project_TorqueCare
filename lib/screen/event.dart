import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'addEvent.dart';
import 'package:moto/moto_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});
  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  Map<String, dynamic>? eventData;
  Future<List<Map<String, dynamic>>> fetchMotoEvent(String motoId) async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('motos')
        .doc(motoId)
        .collection('events')
        .get();
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(
        doc.data() as Map<String, dynamic>,
      );
      data['id'] = doc.id; // เพิ่ม document id เข้าไป
      return data;
    }).toList();
  }

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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchMotoEvent(
              context.read<MotoProvider>().selectedMoto?['id'] ?? '',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final motos = snapshot.data ?? [];

              if (motos.isEmpty) {
                return Center(
                  child: const Text(
                    'ยังไม่มีข้อมูลประวัติเหตุการณ์',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: motos.length,
                itemBuilder: (context, index) {
                  final moto = motos[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        moto['title'] ?? 'ไม่ทราบยี่ห้อ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(moto['detail'] ?? 'ไม่ทราบรายละเอียด'),
                      onTap: () {
                        context.read<MotoProvider>().setMoto(moto);
                      },
                      trailing: Container(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Text(
                          moto['date'] ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
                  MaterialPageRoute(
                    builder: (_) => Addevent(existingData: moto),
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
