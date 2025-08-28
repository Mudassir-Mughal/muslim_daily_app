import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_daily/Screens/calender.dart';
import 'package:muslim_daily/Screens/features.dart';
import 'package:muslim_daily/Screens/qibla.dart';
import 'Prayer_screen.dart';
import 'home.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop()

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({this.initialIndex = 0, Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomePage(),
    HijriCalendarPage(),
    PrayerTimesScreen(),
    QiblahCompassScreen(),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      // Show exit dialog
      bool? shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => _ExitConfirmationDialog(),
      );
      if (shouldExit == true) {
        // Exit the app
        SystemNavigator.pop();
        return true;
      } else {
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final double selectedIconSize = w * 0.125;
    final double unselectedIconSize = w * 0.099;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 12,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              selectedItemColor: const Color(0xFF158443),
              unselectedItemColor: Colors.black54,
              selectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: w * 0.032,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: w * 0.031,
              ),
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  icon: Image.asset(
                    'assets/home.png',
                    width: _currentIndex == 0 ? selectedIconSize : unselectedIconSize,
                    height: _currentIndex == 0 ? selectedIconSize : unselectedIconSize,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    'assets/calender.png',
                    width: _currentIndex == 1 ? selectedIconSize : unselectedIconSize,
                    height: _currentIndex == 1 ? selectedIconSize : unselectedIconSize,
                  ),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    'assets/prayer.png',
                    width: _currentIndex == 2 ? selectedIconSize : unselectedIconSize,
                    height: _currentIndex == 2 ? selectedIconSize : unselectedIconSize,
                  ),
                  label: 'Prayer',
                ),
                BottomNavigationBarItem(
                  icon: Image.asset(
                    'assets/qibla.png',
                    width: _currentIndex == 3 ? selectedIconSize : unselectedIconSize,
                    height: _currentIndex == 3 ? selectedIconSize : unselectedIconSize,
                  ),
                  label: 'Qibla',
                ),
              ],
              backgroundColor: Colors.white,
              elevation: 9,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExitConfirmationDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.07),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.exit_to_app, color: const Color(0xFF158443), size: w * 0.13),
            SizedBox(height: w * 0.04),
            Text(
              'Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF158443),
                fontWeight: FontWeight.w700,
                fontSize: w * 0.05,
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              "You will close the MuslimLink app.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w400,
                fontSize: w * 0.035,
              ),
            ),
            SizedBox(height: w * 0.06),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF158443),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: w * 0.018),
                      child: Text(
                        "Exit",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: w * 0.042,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.04),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      elevation: 0,
                      foregroundColor: const Color(0xFF158443),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF158443), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: w * 0.018),
                      child: Text(
                        "No",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: w * 0.042,
                          color: const Color(0xFF158443),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}