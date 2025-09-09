import 'package:flutter/material.dart';
// import 'package:moto/screen/BaseLayout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: 20),
          child: Container(
            width: 320,
            height: 500,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(12), // ปรับมุมโค้งตรงนี้
              border: Border.all(color: Colors.black, width: 3),
            ),
            padding: EdgeInsets.all(16),
            child: Text('Home Screen bababoi', style: TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: buildCustomAppBar(context: context, title: 'Home'),
//       backgroundColor: Colors.green,
//       body: Center(
//         child: Container(
//           width: 320,
//           height: 800,
//           padding: EdgeInsets.all(16),
//           color: Colors.white,
//           child: Text('Home Screen bababoi', style: TextStyle(fontSize: 24)),
//         ),
//       ),
//       bottomNavigationBar: bottomNavigationBar(context),
//     );
//   }
// }
