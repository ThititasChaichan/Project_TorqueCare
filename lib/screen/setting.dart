import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/manageAccounts.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBarforthispage(context: context, title: 'Setting'),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //User information
          Container(child: ProfileSection()),
          Stack(
            children: [
              SizedBox(
                width: 380,
                child: const Divider(
                  height: 20,
                  color: Color.fromARGB(255, 129, 129, 129),
                ),
              ),
              // Container(
              //   color: const Color.fromARGB(255, 255, 255, 255),
              //   padding: const EdgeInsets.all(8),
              //   child: const Text(
              //     ' ตั้งค่า',
              //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //   ),
              // ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text('ยานพหนะ', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text(
                'บันทึกเหตุการณ์',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text('สถิติ', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text(
                'ประวัติการทำรายการ',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text(
                'การดูแลจักรยานยนต์เบื่องต้น',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text(
                'จัดการการแจ้งเตือน',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: 380,
            child: const Divider(
              height: 20,
              color: Color.fromARGB(255, 129, 129, 129),
            ),
          ),
          SizedBox(height: 8),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text('ตั้งค่า', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 380,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.settings, size: 25),
              label: const Text('เกี่ยวกับ', style: TextStyle(fontSize: 20)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                alignment: Alignment.centerLeft,
                backgroundColor: const Color.fromARGB(255, 241, 241, 241),
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

PreferredSizeWidget buildCustomAppBarforthispage({
  required BuildContext context,
  required String title,
}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(80.0),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 182, 182, 182),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              size: 30,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryanimation) =>
                      BaseLayout(body: HomeScreen(), activeIndex: 0),
                  transitionsBuilder:
                      (context, animation, secondaryanimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                ),
              );
            },
          ),
          SvgPicture.asset('assets/SVG_logo.svg', height: 100),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color.fromARGB(255, 0, 0, 0),
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  Future<Map<String, dynamic>?> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return doc.data();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('ไม่พบข้อมูลผู้ใช้'),
          );
        }

        final userData = snapshot.data!;
        final name = userData['username'] ?? 'ไม่ระบุชื่อ';
        final email = userData['email'] ?? 'ไม่มีอีเมล';
        final photoUrl = userData['photoUrl'] ?? '';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageAccountsScreen(),
                        ),
                      );
                    },
                    label: const Text(
                      'จัดการบัญชีผู้ใช้',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 4,
                      shadowColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
