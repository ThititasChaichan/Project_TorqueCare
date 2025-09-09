import 'package:flutter/material.dart';
// import 'package:moto/screen/BaseLayout.dart';

class HumeScreen extends StatelessWidget {
  const HumeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 320,
          height: 800,
          padding: EdgeInsets.all(16),
          color: const Color.fromARGB(255, 255, 0, 0),
          child: Text('somes day', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
