import 'package:flutter/material.dart';

class AddMotoPage extends StatefulWidget {
  const AddMotoPage({super.key});

  @override
  State<AddMotoPage> createState() => _AddMotoPageState();
}

class _AddMotoPageState extends State<AddMotoPage> {
  final _formKey = GlobalKey<FormState>();

  String? brand;
  String? model;
  String? year;
  String? fuelType;
  String? distance;

  final List<String> brands = [
    'Honda',
    'Yamaha',
    'Suzuki',
    'Kawasaki',
    'อื่นๆ',
  ];
  final List<String> years = [
    for (int y = DateTime.now().year; y >= 2000; y--) y.toString(),
  ];
  final List<String> fuelTypes = [
    'เบนซิน',
    'แก๊สโซฮอล์',
    'ดีเซล',
    'ไฟฟ้า',
    'อื่นๆ',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลจักรยานยนต์'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ยี่ห้อ กับ รุ่น อยู่บรรทัดเดียวกัน
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'ยี่ห้อรถ'),
                      items: brands
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      value: brand,
                      onChanged: (v) => setState(() => brand = v),
                      validator: (v) => v == null ? 'กรุณาเลือกยี่ห้อรถ' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'รุ่น'),
                      onChanged: (v) => model = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกรุ่น' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ปี กับ ระยะทาง อยู่บรรทัดเดียวกัน
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'ปี'),
                      items: years
                          .map(
                            (y) => DropdownMenuItem(value: y, child: Text(y)),
                          )
                          .toList(),
                      value: year,
                      onChanged: (v) => setState(() => year = v),
                      validator: (v) => v == null ? 'กรุณาเลือกปี' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'ระยะทาง (กม.)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => distance = v,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'กรุณากรอกระยะทาง' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'ชนิดเชื้อเพลิง'),
                items: fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                value: fuelType,
                onChanged: (v) => setState(() => fuelType = v),
                validator: (v) => v == null ? 'กรุณาเลือกชนิดเชื้อเพลิง' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      'brand': brand,
                      'model': model,
                      'year': year,
                      'distance': distance,
                      'fuelType': fuelType,
                    });
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
