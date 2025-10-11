import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MotoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _motoList = [];
  Map<String, dynamic>? selectedMoto;
  String? userId; // เพิ่ม field userId

  List<Map<String, dynamic>> get motoList => _motoList;

  // เซ็ต userId หลัง login หรือสร้าง provider
  void setUserId(String id) {
    userId = id;
    notifyListeners();
  }

  Future<void> selectMoto(Map<String, dynamic> moto) async {
    selectedMoto = moto;
    notifyListeners();
  }

  // โหลดข้อมูลรถจาก Firestore
  Future<void> loadMotosFromFirestore() async {
    if (userId == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('motos')
        .get();
    _motoList = snapshot.docs
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();
    notifyListeners();
  }

  void setMoto(Map<String, dynamic> moto) {
    selectedMoto = moto;
    notifyListeners();
  }
}
