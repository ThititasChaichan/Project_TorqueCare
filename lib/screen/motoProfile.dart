import 'package:flutter/material.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:moto/screen/home.dart';
import 'addMoto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:moto/moto_provider.dart';

void main() {
  runApp(const Motoprofile());
}

class Motoprofile extends StatelessWidget {
  const Motoprofile({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moto Profile',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MotoProfilePage(),
    );
  }
}

class MotoProfilePage extends StatefulWidget {
  const MotoProfilePage({super.key});

  @override
  State<MotoProfilePage> createState() => _MotoProfilePageState();
}

class _MotoProfilePageState extends State<MotoProfilePage> {
  Map<String, dynamic>? motoData;
  Future<List<Map<String, dynamic>>> fetchMotoData() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('motos')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ข้อมูลจักรยานยนต์ของฉัน',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Center(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchMotoData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final motos = snapshot.data ?? [];

            if (motos.isEmpty) {
              return const Text(
                'ยังไม่มีข้อมูลจักรยานยนต์',
                style: TextStyle(fontSize: 18, color: Colors.grey),
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
                    leading: const Icon(
                      Icons.motorcycle,
                      size: 32,
                      color: Colors.teal,
                    ),
                    title: Text(
                      moto['brand'] ?? 'ไม่ทราบยี่ห้อ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'รุ่น: ${moto['model'] ?? '-'}\nทะเบียน: ${moto['plate'] ?? '-'}',
                    ),
                    onTap: () {
                      context.read<MotoProvider>().setMoto(moto);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BaseLayout(body: HomeScreen(), activeIndex: 0),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddMotoPage()),
          );
          if (result != null) {
            setState(() {
              // อัปเดตทั้ง motoData และให้ FutureBuilder โหลดใหม่
              motoData = result;
            });
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
