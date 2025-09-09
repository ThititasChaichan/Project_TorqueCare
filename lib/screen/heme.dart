import 'package:flutter/material.dart';
// import 'package:moto/screen/BaseLayout.dart';

class HemeScreen extends StatelessWidget {
  const HemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 320,
          height: 800,
          padding: EdgeInsets.all(16),
          color: const Color.fromARGB(255, 0, 255, 34),
          child: Text('sdgsdgsdg', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
