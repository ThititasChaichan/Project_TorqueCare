import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moto/screen/setting.dart';
import 'package:moto/screen/home.dart';
import 'package:moto/screen/notification.dart';
import 'package:moto/screen/history.dart';
import 'package:moto/screen/event.dart';
import 'package:moto/screen/report.dart';
import 'package:provider/provider.dart';
import '../moto_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BaseLayout extends StatelessWidget {
  final Widget body;
  final int activeIndex;
  const BaseLayout({super.key, required this.body, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildCustomAppBar(context: context, title: 'หน้าแรก'),
      body: body,
      bottomNavigationBar: bottomNavigationBar(context, activeIndex),
    );
  }
}

PreferredSizeWidget buildCustomAppBar({
  required BuildContext context,
  required String title,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final moto = context.watch<MotoProvider>().selectedMoto;
  Map<String, dynamic>? motoData;
  Future<List<Map<String, dynamic>>> fetchMotoData() async {
    final user = FirebaseAuth.instance.currentUser;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('motos')
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  return PreferredSize(
    preferredSize: Size.fromHeight(screenHeight * 0.188),
    child: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color.fromARGB(255, 131, 0, 0),
      flexibleSpace: SafeArea(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(width: screenWidth * 0.02),
                  IconButton(
                    icon: Icon(
                      Icons.menu,
                      size: screenWidth * 0.08,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) => SettingScreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                  ),
                  SvgPicture.asset(
                    'assets/SVG_light_logo.svg',
                    height: screenHeight * 0.08,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              Container(
                transformAlignment: Alignment.center,
                width: screenWidth * 0.95,
                height: screenHeight * 0.05,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: screenWidth * 0.02),
                        if (moto?['brand'] == 'Honda')
                          SvgPicture.asset(
                            'assets/moto_logo/honda.svg',
                            width: screenWidth * 0.1,
                          )
                        else if (moto?['brand'] == 'Yamaha')
                          SvgPicture.asset(
                            'assets/moto_logo/yamaha.svg',
                            width: screenWidth * 0.1,
                          )
                        else if (moto?['brand'] == 'Suzuki')
                          SvgPicture.asset(
                            'assets/moto_logo/suzuki.svg',
                            width: screenWidth * 0.1,
                          )
                        else
                          Icon(
                            Icons.motorcycle,
                            size: screenWidth * 0.07,
                            color: Colors.teal,
                          ),
                        Text(
                          '  ${moto?['brand'] ?? '-'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.050,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ' ${moto?['model'] ?? '-'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' | ${moto?['plate'] ?? '-'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.040,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: -screenHeight * 0.005,
                      child: IconButton(
                        padding: EdgeInsets.only(
                          left: screenWidth * 0.0455,
                          top: screenHeight * 0.001,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: const Color.fromARGB(255, 255, 0, 0),
                          size: screenWidth * 0.1,
                        ),
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          final snapshot = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('motos')
                              .get();

                          final motos = snapshot.docs
                              .map((doc) => {...doc.data(), 'id': doc.id})
                              .toList();

                          if (motos.isEmpty || !context.mounted) return;

                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) {
                              return DraggableScrollableSheet(
                                initialChildSize: 0.5,
                                minChildSize: 0.3,
                                maxChildSize: 0.9,
                                builder: (_, scrollCtrl) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                            bottom: 8,
                                          ),
                                          width: 40,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Text(
                                                'เลือกรถ',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${motos.length} คัน',
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Divider(height: 1),
                                        Expanded(
                                          child: ListView.separated(
                                            controller: scrollCtrl,
                                            itemCount: motos.length,
                                            separatorBuilder: (_, __) =>
                                                const Divider(
                                                  height: 1,
                                                  indent: 72,
                                                ),
                                            itemBuilder: (_, i) {
                                              final m = motos[i];
                                              final brand = m['brand'] ?? '-';
                                              final model = m['model'] ?? '-';
                                              final plate = m['plate'] ?? '-';
                                              final distance =
                                                  m['distance']?.toString() ??
                                                  '-';
                                              final isSelected =
                                                  context
                                                      .read<MotoProvider>()
                                                      .selectedMoto?['id'] ==
                                                  m['id'];

                                              return ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 4,
                                                    ),
                                                leading: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF830000,
                                                          ).withOpacity(0.08)
                                                        : Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  child: brand == 'Honda'
                                                      ? SvgPicture.asset(
                                                          'assets/moto_logo/honda.svg',
                                                        )
                                                      : brand == 'Yamaha'
                                                      ? SvgPicture.asset(
                                                          'assets/moto_logo/yamaha.svg',
                                                        )
                                                      : brand == 'Suzuki'
                                                      ? SvgPicture.asset(
                                                          'assets/moto_logo/suzuki.svg',
                                                        )
                                                      : const Icon(
                                                          Icons.motorcycle,
                                                          color: Colors.teal,
                                                        ),
                                                ),
                                                title: Text(
                                                  '$brand $model',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? const Color(
                                                            0xFF830000,
                                                          )
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'ทะเบียน: $plate  |  ไมล์: $distance กม.',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                trailing: isSelected
                                                    ? const Icon(
                                                        Icons.check_circle,
                                                        color: Color(
                                                          0xFF830000,
                                                        ),
                                                      )
                                                    : null,
                                                onTap: () {
                                                  context
                                                      .read<MotoProvider>()
                                                      .setMoto(m);
                                                  Navigator.pop(ctx);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.010),
              Container(
                width: screenWidth * 1.0,
                margin: EdgeInsets.only(top: screenHeight * 0.005),
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 233, 233, 233),
                  // borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '   เลขไมล์: ${moto?['distance'] ?? '-'} กม.',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

BottomAppBar bottomNavigationBar(BuildContext context, int activeIndex) {
  final screenHeight = MediaQuery.of(context).size.height;

  return BottomAppBar(
    color: const Color.fromARGB(255, 0, 26, 255),
    child: SizedBox(
      height: screenHeight * 0.09, // responsive height
      child: Stack(
        children: [
          AnimatedBar(activeIndex: activeIndex),
          Align(
            alignment: Alignment.bottomCenter,
            child: MyAnimatedIconButton(activeIndex: activeIndex),
          ),
        ],
      ),
    ),
  );
}

class AnimatedBar extends StatefulWidget {
  final int activeIndex;
  const AnimatedBar({super.key, required this.activeIndex});

  @override
  State<AnimatedBar> createState() => _AnimatedBarState();
}

class _AnimatedBarState extends State<AnimatedBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _alignX;
  late double _currentX;

  double getAlignX(int index, int itemCount) {
    // กลับมาใช้เลขที่คุณปรับไว้เป๊ะๆ เพื่อให้ตำแหน่งอยู่ที่เดิม
    double x = (index / (itemCount - 0.7)) * 2 - 1;
    return x + 0.08; // ปรับเล็กน้อยเพื่อให้ตรงกับตำแหน่งไอคอน
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // 1. ดึงตำแหน่งหน้าเก่าจาก Provider มาเป็นจุดเริ่มต้น (Begin)
    final lastIdx = context.read<MotoProvider>().lastIndex;
    final beginX = getAlignX(lastIdx, 5);

    // 2. ตำแหน่งหน้าปัจจุบันที่ต้องการไป (End)
    _currentX = getAlignX(widget.activeIndex, 5);

    _alignX =
        Tween<double>(
          begin: beginX, // เริ่มจากตำแหน่งหน้าที่แล้ว
          end: _currentX, // ไปยังตำแหน่งหน้าปัจจุบัน
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
        );

    // 3. สั่งให้เลื่อนทันทีที่หน้าจอถูกสร้าง
    if (lastIdx != widget.activeIndex) {
      _controller.forward();
      // อัปเดตค่า Index ปัจจุบันลง Provider เพื่อรอไว้สำหรับหน้าถัดไป
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<MotoProvider>().setIndex(widget.activeIndex);
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      final newX = getAlignX(widget.activeIndex, 5);

      _alignX =
          Tween<double>(
            begin: _currentX,
            end: newX, // หรือ _currentX ใน initState
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeOutBack, // ใช้ตัวนี้แทน backOut ครับ
            ),
          );

      _controller.reset();
      _controller.forward();
      _currentX = newX;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ใช้ Tween ตรงๆ แทน ไม่ต้องเก็บเป็น field
    final widthAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
    ]).animate(_controller); // ← _controller init แล้วใน initState ✅

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Align(
          alignment: Alignment(_alignX.value, 1.0),
          child: Container(
            width: screenWidth * 0.12 * widthAnim.value,
            height: screenHeight * 0.008,
            margin: EdgeInsets.only(bottom: screenHeight * 0.005),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 31, 2, 158),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MyAnimatedIconButton extends StatefulWidget {
  final int activeIndex;
  const MyAnimatedIconButton({super.key, required this.activeIndex});
  @override
  _MyAnimatedIconButtonState createState() => _MyAnimatedIconButtonState();
}

class _MyAnimatedIconButtonState extends State<MyAnimatedIconButton> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildAnimatedIcon(
          context,
          0,
          Icons.house_rounded,
          Icons.home_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          1,
          Icons.notifications_active_rounded,
          Icons.notifications_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          2,
          Icons.menu_book_rounded,
          Icons.book_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          3,
          Icons.stacked_line_chart_rounded,
          Icons.show_chart_rounded,
          Colors.white,
          screenWidth,
        ),
        _buildAnimatedIcon(
          context,
          4,
          Icons.bookmarks_rounded,
          Icons.bookmark_rounded,
          Colors.white,
          screenWidth,
        ),
      ],
    );
  }

  Widget _buildAnimatedIcon(
    BuildContext context,
    int index,
    IconData iconActive,
    IconData iconInactive,
    Color color,
    double screenWidth,
  ) {
    bool isActive = index == widget.activeIndex;
    final double sizeActive = screenWidth * 0.07;
    final double sizeInactive = screenWidth * 0.065;

    return IconButton(
      onPressed: () {
        Widget nextScreen;
        switch (index) {
          case 0:
            nextScreen = BaseLayout(body: HomeScreen(), activeIndex: 0);
            break;
          case 1:
            nextScreen = BaseLayout(body: NotificationScreen(), activeIndex: 1);
            break;
          case 2:
            nextScreen = BaseLayout(body: HistoryScreen(), activeIndex: 2);
            break;
          case 3:
            nextScreen = BaseLayout(body: ReportScreen(), activeIndex: 3);
            break;
          case 4:
            nextScreen = BaseLayout(body: EventScreen(), activeIndex: 4);
            break;
          default:
            nextScreen = BaseLayout(body: HomeScreen(), activeIndex: 0);
        }

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => nextScreen,
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      icon: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: Icon(
          isActive ? iconActive : iconInactive,
          size: isActive ? sizeActive : sizeInactive,
          key: ValueKey<bool>(isActive),
          color: color,
        ),
      ),
    );
  }
}
