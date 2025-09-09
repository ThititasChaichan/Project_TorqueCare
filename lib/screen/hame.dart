import 'package:flutter/material.dart';
import 'package:moto/screen/BaseLayout.dart';

class HameScreen extends StatelessWidget {
  const HameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      activeIndex: 3,
      body: Center(
        child: Container(
          width: 320,
          height: 800,
          padding: EdgeInsets.all(16),
          color: const Color.fromARGB(255, 76, 0, 255),
          child: Text('zdfsghzdfhzdf', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
