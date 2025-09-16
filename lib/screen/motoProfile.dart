import 'package:flutter/material.dart';
import 'addMoto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        child: motoData == null
            ? const Text(
                'ยังไม่มีข้อมูลจักรยานยนต์',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
            : Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: motoData!.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ไปหน้า addMoto แล้วรอข้อมูลกลับมา
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const AddMotoPage()),
          );
          if (result != null) {
            setState(() {
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
