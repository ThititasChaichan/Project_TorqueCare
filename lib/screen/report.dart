import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 217, 255, 0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Report Screen',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
