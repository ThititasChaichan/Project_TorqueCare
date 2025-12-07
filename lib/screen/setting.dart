import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/manageAccounts.dart';
import 'package:moto/screen/BaseLayout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moto/screen/motoProfile.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // ✅ ดึงขนาดหน้าจอ
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: buildCustomAppBarforthispage(context: context, title: 'Setting'),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ ป้องกัน Overflow
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile
                const ProfileSection(),
                SizedBox(height: screenHeight * 0.02),

                Divider(color: Colors.grey[600], thickness: 1),

                SizedBox(height: screenHeight * 0.02),

                // ✅ สร้างเมธอดให้ปุ่ม ใช้ซ้ำได้
                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.motorcycle,
                  label: 'ยานพาหนะ',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MotoProfilePage(),
                      ),
                    );
                  },
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.event_note,
                  label: 'บันทึกเหตุการณ์',
                  onPressed: () {},
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.bar_chart,
                  label: 'สถิติ',
                  onPressed: () {},
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.history,
                  label: 'ประวัติการทำรายการ',
                  onPressed: () {},
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.build,
                  label: 'การดูแลจักรยานยนต์เบื้องต้น',
                  onPressed: () {},
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.notifications_active,
                  label: 'จัดการการแจ้งเตือน',
                  onPressed: () {},
                ),

                SizedBox(height: screenHeight * 0.015),

                Divider(color: Colors.grey[600], thickness: 1),

                SizedBox(height: screenHeight * 0.02),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.settings,
                  label: 'ตั้งค่า',
                  onPressed: () {},
                ),

                buildMenuButton(
                  context,
                  screenWidth,
                  icon: Icons.info_outline,
                  label: 'เกี่ยวกับ',
                  onPressed: () {},
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✅ เมธอดสำหรับปุ่มเมนู
  Widget buildMenuButton(
    BuildContext context,
    double screenWidth, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.03),
      child: SizedBox(
        width: double.infinity, // ✅ ให้เต็มความกว้างที่เหลือ
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: screenWidth * 0.06, color: Colors.black87),
          label: Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: Colors.black,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.03,
              horizontal: screenWidth * 0.04,
            ),
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
    );
  }
}

/// ✅ AppBar Responsive
PreferredSizeWidget buildCustomAppBarforthispage({
  required BuildContext context,
  required String title,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return PreferredSize(
    preferredSize: Size.fromHeight(screenHeight * 0.10),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 182, 182, 182),
      titleSpacing: 0,
      flexibleSpace: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: screenWidth * 0.02),
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    size: screenWidth * 0.08,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryanimation) =>
                            BaseLayout(body: HomeScreen(), activeIndex: 0),
                        transitionsBuilder:
                            (context, animation, secondaryanimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                ),
                SvgPicture.asset(
                  'assets/SVG_logo.svg',
                  height: screenHeight * 0.08,
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// ✅ Profile Section
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
    final screenWidth = MediaQuery.of(context).size.width;

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
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.10,
                backgroundImage: photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : const AssetImage('assets/default_avatar.png')
                          as ImageProvider,
              ),
              SizedBox(width: screenWidth * 0.05),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageAccountsScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.manage_accounts,
                        size: screenWidth * 0.059,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'จัดการบัญชีผู้ใช้',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        elevation: 4,
                        shadowColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenWidth * 0.02,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
