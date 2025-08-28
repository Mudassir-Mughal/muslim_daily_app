import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:muslim_daily/Screens/NamazTrackerScreen.dart';
import 'package:muslim_daily/Screens/dailyhadith.dart';
import 'package:muslim_daily/Screens/dua_collection.dart';
import 'package:muslim_daily/Screens/islamicnames.dart';
import 'package:muslim_daily/Screens/mosques.dart';
import 'package:muslim_daily/Screens/qibla.dart';
import 'package:muslim_daily/Screens/settings.dart';
import 'package:muslim_daily/Screens/tasbeeh.dart';
import 'package:muslim_daily/Screens/zakatcalculator.dart';
import 'package:provider/provider.dart';

import '../Services/prayerprovider.dart';


// Helper to convert TimeOfDay to DateTime for mock/demo
extension TimeOfDayExtension on TimeOfDay {
  DateTime toDateTime(DateTime ref) =>
      DateTime(ref.year, ref.month, ref.day, hour, minute);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String city = "Rawalpindi";
  final String prayerName = "Asr";
  late DateTime prayerTime;
  late DateTime nextPrayerTime;
  late Duration countdown;
  Timer? _timer;

  // Provider fields
  String? providerPrayerName;
  DateTime? providerPrayerTime;
  Duration? providerCountdown;

  @override
  void initState() {
    super.initState();
    prayerTime = TimeOfDay(hour: 16, minute: 54).toDateTime(DateTime.now());
    nextPrayerTime = TimeOfDay(hour: 21, minute: 26).toDateTime(DateTime.now());
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  void _updateCountdown() {
    setState(() {
      countdown = nextPrayerTime.difference(DateTime.now());
      if (countdown.isNegative) countdown = Duration.zero;

      // Provider logic (do not change any widget, just get the data)
      final provider = Provider.of<PrayerProvider>(context, listen: false);
      if (provider.prayerTimes != null && provider.prayerTimes!.isNotEmpty) {
        final next = provider.getNextPrayer();
        if (next != null && next['name'] != null && next['time'] != null) {
          providerPrayerName = next['name'];
          providerPrayerTime = next['time'];
          providerCountdown = next['time'].difference(DateTime.now());
          if (providerCountdown!.isNegative) providerCountdown = Duration.zero;
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}";
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM').format(now);

    // Provider logic for real-time card (do not change design, just use provider)
    final provider = Provider.of<PrayerProvider>(context);
    String showPrayerName = prayerName;
    DateTime showPrayerTime = prayerTime;
    String showTimeText = DateFormat('h:mm').format(prayerTime);
    String showAmpm = DateFormat('a').format(prayerTime);
    Duration showCountdown = countdown;

    if (provider.prayerTimes != null && provider.prayerTimes!.isNotEmpty) {
      final next = provider.getNextPrayer();
      if (next != null && next['name'] != null && next['time'] != null) {
        showPrayerName = next['name'];
        showPrayerTime = next['time'];
        showTimeText = DateFormat('h:mm').format(showPrayerTime);
        showAmpm = DateFormat('a').format(showPrayerTime);
        showCountdown = next['time'].difference(DateTime.now());
        if (showCountdown.isNegative) showCountdown = Duration.zero;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.025),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: App Name and City Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "MuslimLink",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: w * 0.06,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.045, vertical: w * 0.012),
                        decoration: BoxDecoration(
                          color: const Color(0xFF158431),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Text(
                              city,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: w * 0.03,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.person_pin_circle, color: Colors.white, size: w * 0.035),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6), // Space between city container and settings icon
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => Settings()), // Replace with your settings page widget
                          );
                        },
                        child: Image.asset(
                          'assets/settings.png',
                          width: w * 0.07,
                          height: w * 0.07,
                          // Or remove if your icon is colored
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: w * 0.04),
              // Prayer Card
              Container(
                width: double.infinity,
                height: w * 0.63,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.09),
                      blurRadius: 13,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: Image.asset(
                        "assets/prayercard.png",
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Date (top left)
                    Positioned(
                      top: 14, left: 18,
                      child: Text(
                        dateStr,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: w * 0.036,
                        ),
                      ),
                    ),
                    // Centered prayer info
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            showPrayerName,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: w * 0.056,
                            ),
                          ),
                          SizedBox(height: 0), // LESS gap
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                showTimeText,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: w * 0.1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: w * 0.008, left: 4),
                                child: Text(
                                  showAmpm,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: w * 0.056,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2), // LESS gap
                          Text(
                            "Next Prayer ${_formatDuration(showCountdown)}",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                              fontSize: w * 0.044,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: w * 0.07),
              // Daily Hadith Title
              Text(
                "Daily Hadith",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: w * 0.059,
                  color: Colors.black,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(height: w * 0.03),
              // Sunan Abu Dawud Card (with tap to open a page)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HadithPage()), // Yahan apna page name likh do
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5F6E3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/book.png',
                        width: w * 0.09,
                        height: w * 0.09,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Sunan Abu Dawad",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF158443),
                            fontWeight: FontWeight.w600,
                            fontSize: w * 0.042,
                          ),
                        ),
                      ),
                      Text(
                        "سنن ابو داود",
                        style: GoogleFonts.notoNaskhArabic(
                          color: const Color(0xFF158443),
                          fontWeight: FontWeight.w600,
                          fontSize: w * 0.042,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: w * 0.05),
              // Feature grid
              GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/names.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Islamic Names",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IslamicNamesScreen())),
                  ),
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/zakat.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Zakat",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZakatCalculator())),
                  ),
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/Tracker.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Namaz Tracker",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NamazTrackerScreen())),
                  ),
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/Tasbeeh.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Tasbeeh",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TasbeehScreen())),
                  ),
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/Dua.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Dua Collection",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DuaCollectionScreen())),
                  ),
                  _featureCard(
                    iconWidget: Image.asset(
                      'assets/Mosques.png',
                      width: 36,
                      height: 36,
                    ),
                    title: "Mosques",
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyMosquesMap())),
                  ),
                ],
              ),
            ],),),),);
  }

  Widget _featureCard({
    required Widget iconWidget,
    required String title,
    required VoidCallback onTap,
    Color? outlineColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD5F6E3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: outlineColor ?? Colors.transparent,
            width: outlineColor != null ? 2 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 7,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // White circle for icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}