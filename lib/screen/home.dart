import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../moto_provider.dart';
import 'uiverse_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // รีเฟรชเมื่อเปลี่ยนรถ
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    final moto = context.read<MotoProvider>().selectedMoto;
    final String? motoId = moto?['id'];

    final Map<String, List<String>> structure = {
      'เอกสาร': [
        'พ.ร.บ.',
        'ภาษีประจำปี',
        'ใบขับขี่',
        'ตรวจสภาพรถ',
        'ประกันภัย',
      ],
      'บริการ': [
        'ถ่ายน้ำมันเครื่อง',
        'เปลี่ยนยาง',
        'เปลี่ยนผ้าเบรก',
        'เช็คระยะ',
      ],
    };

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    List<Future<QuerySnapshot>> tasks = [];
    List<Map<String, String>> metas = [];

    for (var entry in structure.entries) {
      final category = entry.key;
      for (var type in entry.value) {
        // user-level (ใบขับขี่)
        tasks.add(
          userRef
              .collection('notifications')
              .doc(category)
              .collection(type)
              .get(),
        );
        metas.add({'category': category, 'type': type, 'motoId': ''});

        // moto-level
        if (motoId != null) {
          tasks.add(
            userRef
                .collection('motos')
                .doc(motoId)
                .collection('notifications')
                .doc(category)
                .collection(type)
                .get(),
          );
          metas.add({'category': category, 'type': type, 'motoId': motoId});
        }
      }
    }

    final results = await Future.wait(tasks);
    List<Map<String, dynamic>> tempList = [];

    for (int i = 0; i < results.length; i++) {
      for (var doc in results[i].docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['docId'] = doc.id;
        data['type'] = metas[i]['type'];
        data['category'] = metas[i]['category'];
        data['motoId'] = metas[i]['motoId'];
        if (metas[i]['motoId']!.isNotEmpty) {
          data['docPath'] =
              'users/$uid/motos/${metas[i]['motoId']}/notifications/${metas[i]['category']}/${metas[i]['type']}/${doc.id}';
          data['historyPath'] =
              'users/$uid/motos/${metas[i]['motoId']}/history';
        } else {
          data['docPath'] =
              'users/$uid/notifications/${metas[i]['category']}/${metas[i]['type']}/${doc.id}';
          data['historyPath'] = 'users/$uid/history';
        }
        tempList.add(data);
      }
    }

    // เรียงตาม expiry_date
    tempList.sort((a, b) {
      final tA = a['expiry_date'] as Timestamp?;
      final tB = b['expiry_date'] as Timestamp?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tA.compareTo(tB);
    });

    if (mounted) {
      setState(() {
        _notifications = tempList;
        _isLoading = false;
      });
    }
  }

  void _showTickBottomSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TickBottomSheet(
        data: data,
        currentMileage:
            context.read<MotoProvider>().selectedMoto?['distance'] ?? 0,
        onSaved: () {
          _fetchNotifications();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moto = context.watch<MotoProvider>().selectedMoto;
    final screenWidth = MediaQuery.of(context).size.width;

    // แบ่งหมวด
    final docs = _notifications
        .where((n) => n['category'] == 'เอกสาร')
        .toList();
    final services = _notifications
        .where((n) => n['category'] == 'บริการ')
        .toList();

    return Scaffold(
      body: _isLoading
          ? Center(child: UiverseLoader())
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีรายการแจ้งเตือน',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 24,
                left: 16,
                right: 16,
              ),
              children: [
                // ชื่อรถที่เลือก
                if (moto != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.motorcycle,
                          size: 20,
                          color: Color(0xFF830000),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${moto['brand'] ?? ''} ${moto['model'] ?? ''} | ${moto['plate'] ?? ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF830000),
                          ),
                        ),
                      ],
                    ),
                  ),

                // หมวดเอกสาร
                if (docs.isNotEmpty) ...[
                  _buildSectionHeader(
                    'เอกสาร',
                    Icons.description,
                    const Color(0xFF007A35),
                  ),
                  ...docs.map((d) => _buildCheckItem(d)),
                  const SizedBox(height: 16),
                ],

                // หมวดบริการ
                if (services.isNotEmpty) ...[
                  _buildSectionHeader(
                    'บริการ',
                    Icons.construction_rounded,
                    const Color(0xFF0057A8),
                  ),
                  ...services.map((d) => _buildCheckItem(d)),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildCheckItem(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final category = data['category'] ?? '';
    final Timestamp? ts = data['expiry_date'] as Timestamp?;
    final DateTime? expiry = ts?.toDate();
    final int daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays
        : 9999;

    Color statusColor;
    String statusText;
    if (expiry == null) {
      statusColor = Colors.grey;
      statusText = 'ไม่มีวันหมดอายุ';
    } else if (daysLeft < 0) {
      statusColor = Colors.red;
      statusText = 'หมดอายุแล้ว';
    } else if (daysLeft <= 7) {
      statusColor = Colors.red;
      statusText = 'อีก $daysLeft วัน';
    } else if (daysLeft <= 30) {
      statusColor = Colors.orange;
      statusText = 'อีก $daysLeft วัน';
    } else {
      statusColor = Colors.green;
      statusText = expiry != null ? DateFormat('dd/MM/yy').format(expiry) : '';
    }

    final isDoc = category == 'เอกสาร';
    final color = isDoc ? const Color(0xFF007A35) : const Color(0xFF0057A8);

    final categoryList = _notifications
        .where((n) => n['category'] == category)
        .toList();
    final isLast = categoryList.last == data;

    // ความสูงคงที่ต่อ item
    const double itemHeight = 64.0;

    return SizedBox(
      height: itemHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ====== Timeline column (fixed height) ======
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // เส้นแนวตั้งลงมาจาก dot ถึงก้นของ item
                if (!isLast)
                  Positioned(
                    top: 24, // ใต้ dot
                    bottom: 0,
                    child: Container(width: 2, color: Colors.grey[200]),
                  ),
                // dot
                Positioned(
                  top: 14,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.35),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ====== Content + Divider ======
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ปุ่ม tick
                      GestureDetector(
                        onTap: () => _showTickBottomSheet(data),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[50],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider ขั้นระหว่าง item (ไม่แสดงถ้าเป็น item สุดท้าย)
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey[150],
                    indent: 0,
                    endIndent: 8,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Bottom Sheet =====
class _TickBottomSheet extends StatefulWidget {
  final Map<String, dynamic> data;
  final dynamic currentMileage;
  final VoidCallback onSaved;

  const _TickBottomSheet({
    required this.data,
    required this.currentMileage,
    required this.onSaved,
  });

  @override
  State<_TickBottomSheet> createState() => _TickBottomSheetState();
}

class _TickBottomSheetState extends State<_TickBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  bool _isDone = false;

  // fields
  final _mileageCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // service
  bool _setNextRound = false;
  final _nextKmCtrl = TextEditingController();
  DateTime? _nextServiceDate;

  // document
  DateTime? _nextExpiryDate;

  late AnimationController _doneController;
  late Animation<double> _doneScale;
  late Animation<double> _doneOpacity;

  bool get _isDoc => widget.data['category'] == 'เอกสาร';
  int get _currentMileage {
    final v = widget.currentMileage;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _mileageCtrl.text = _currentMileage.toString();

    _doneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _doneScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _doneController, curve: Curves.elasticOut),
    );
    _doneOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _doneController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _mileageCtrl.dispose();
    _costCtrl.dispose();
    _noteCtrl.dispose();
    _nextKmCtrl.dispose();
    _doneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // validate mileage > current
    final newMileage = int.tryParse(_mileageCtrl.text.trim()) ?? 0;
    if (newMileage < _currentMileage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เลขไมล์ต้องไม่น้อยกว่าเดิม ($_currentMileage กม.)'),
        ),
      );
      return;
    }

    // validate document next expiry
    if (_isDoc && _nextExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกวันหมดอายุรอบถัดไป')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docPath = widget.data['docPath'] as String;
      final historyPath = widget.data['historyPath'] as String;
      final type = widget.data['type'] ?? '';
      final category = widget.data['category'] ?? '';

      // 1. บันทึก history
      final historyData = {
        'type': type,
        'category': category,
        'mileage': newMileage,
        'cost': double.tryParse(_costCtrl.text.trim()) ?? 0.0,
        'note': _noteCtrl.text.trim(),
        'doneAt': Timestamp.now(),
        'motoId': widget.data['motoId'] ?? '',
      };
      await FirebaseFirestore.instance.collection(historyPath).add(historyData);

      // 2. อัปเดต mileage ของรถ
      if (newMileage > _currentMileage) {
        final motoId = widget.data['motoId'];
        if (motoId != null && motoId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('motos')
              .doc(motoId)
              .update({'distance': newMileage});
        }
      }

      // 3. อัปเดต notification (expiry_date รอบถัดไป)
      if (_isDoc && _nextExpiryDate != null) {
        await FirebaseFirestore.instance.doc(docPath).update({
          'expiry_date': Timestamp.fromDate(_nextExpiryDate!),
          'updatedAt': Timestamp.now(),
        });
      } else if (!_isDoc && _setNextRound) {
        final updates = <String, dynamic>{'updatedAt': Timestamp.now()};
        if (_nextServiceDate != null) {
          updates['expiry_date'] = Timestamp.fromDate(_nextServiceDate!);
        }
        if (_nextKmCtrl.text.isNotEmpty) {
          updates['next_km'] = int.tryParse(_nextKmCtrl.text.trim());
        }
        await FirebaseFirestore.instance.doc(docPath).update(updates);
      }

      // 4. แสดง animation done
      setState(() {
        _isSaving = false;
        _isDone = true;
      });
      await _doneController.forward();

      // 5. รอแล้วปิด
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  Future<void> _pickDate({required bool isNextExpiry}) async {
    final initial = isNextExpiry
        ? (widget.data['expiry_date'] as Timestamp?)?.toDate() ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(DateTime.now()) ? initial : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isNextExpiry) {
          _nextExpiryDate = picked;
        } else {
          _nextServiceDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['type'] ?? '';
    final screenHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _isDone
              ? _buildDoneView()
              : Column(
                  children: [
                    // handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isDoc
                                ? Icons.description
                                : Icons.construction_rounded,
                            color: _isDoc
                                ? const Color(0xFF007A35)
                                : const Color(0xFF0057A8),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'บันทึกการดำเนินการ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (_isDoc
                                    ? const Color(0xFF007A35)
                                    : const Color(0xFF0057A8))
                                .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            type,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isDoc
                                  ? const Color(0xFF007A35)
                                  : const Color(0xFF0057A8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // form
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // เลขไมล์
                              _buildLabel('เลขไมล์ปัจจุบัน (กม.)'),
                              TextFormField(
                                controller: _mileageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco(
                                  'เลขไมล์ (ปัจจุบัน: $_currentMileage)',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'กรุณากรอกเลขไมล์';
                                  }
                                  final n = int.tryParse(v);
                                  if (n == null) return 'ตัวเลขเท่านั้น';
                                  if (n < _currentMileage) {
                                    return 'ต้องไม่น้อยกว่า $_currentMileage';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ค่าใช้จ่าย
                              _buildLabel('ค่าใช้จ่าย (บาท)'),
                              TextFormField(
                                controller: _costCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: _inputDeco('0.00'),
                              ),
                              const SizedBox(height: 16),

                              // รายละเอียด
                              _buildLabel('รายละเอียด'),
                              TextFormField(
                                controller: _noteCtrl,
                                maxLines: 3,
                                decoration: _inputDeco('บันทึกเพิ่มเติม...'),
                              ),
                              const SizedBox(height: 20),

                              // ===== เอกสาร: วันหมดอายุถัดไป (บังคับ) =====
                              if (_isDoc) ...[
                                Row(
                                  children: [
                                    _buildLabel('วันหมดอายุรอบถัดไป'),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'บังคับ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _pickDate(isNextExpiry: true),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _nextExpiryDate == null
                                            ? Colors.grey[300]!
                                            : const Color(0xFF007A35),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: _nextExpiryDate == null
                                              ? Colors.grey
                                              : const Color(0xFF007A35),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _nextExpiryDate == null
                                              ? 'เลือกวันหมดอายุรอบถัดไป'
                                              : DateFormat(
                                                  'dd/MM/yyyy',
                                                ).format(_nextExpiryDate!),
                                          style: TextStyle(
                                            color: _nextExpiryDate == null
                                                ? Colors.grey
                                                : Colors.black87,
                                            fontWeight: _nextExpiryDate != null
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // ===== บริการ: ตั้งรอบถัดไป (optional) =====
                              if (!_isDoc) ...[
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _setNextRound,
                                      activeColor: const Color(0xFF0057A8),
                                      onChanged: (v) => setState(
                                        () => _setNextRound = v ?? false,
                                      ),
                                    ),
                                    const Text(
                                      'ตั้งรอบตรวจถัดไป',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_setNextRound) ...[
                                  const SizedBox(height: 8),
                                  // km ถัดไป
                                  _buildLabel('กิโลเมตรถัดไป'),
                                  TextFormField(
                                    controller: _nextKmCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDeco('เช่น 5000'),
                                  ),
                                  const SizedBox(height: 16),
                                  // วันที่ถัดไป
                                  _buildLabel('วันที่ถัดไป (ไม่บังคับ)'),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _pickDate(isNextExpiry: false),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            _nextServiceDate == null
                                                ? 'เลือกวันที่ถัดไป'
                                                : DateFormat(
                                                    'dd/MM/yyyy',
                                                  ).format(_nextServiceDate!),
                                            style: TextStyle(
                                              color: _nextServiceDate == null
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],

                              const SizedBox(height: 28),

                              // ปุ่มบันทึก
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF830000),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'บันทึก',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: AnimatedBuilder(
        animation: _doneController,
        builder: (_, __) {
          return Opacity(
            opacity: _doneOpacity.value,
            child: Transform.scale(
              scale: _doneScale.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ทำรายการเสร็จสิ้น',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'รายการนี้จะถูกบันทึกลงประวัติทำรายการของคุณ',
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
