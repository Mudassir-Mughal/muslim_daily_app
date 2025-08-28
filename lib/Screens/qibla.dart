import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class QiblahCompassScreen extends StatefulWidget {
  const QiblahCompassScreen({Key? key}) : super(key: key);

  @override
  State<QiblahCompassScreen> createState() => _QiblahCompassScreenState();
}

class _QiblahCompassScreenState extends State<QiblahCompassScreen> {
  bool _loading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      final result = await Permission.locationWhenInUse.request();
      if (!result.isGranted) {
        setState(() {
          _loading = false;
          _hasPermission = false;
        });
        return;
      }
    }

    setState(() {
      _hasPermission = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    final double h = MediaQuery.of(context).size.height;

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "Location permission is required to show Qiblah direction.",
            style: GoogleFonts.poppins(
              fontSize: w * 0.045,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image
          SizedBox(
            width: w,
            height: h * 0.30,
            child: Image.asset(
              "assets/background.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: h * 0.006),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        "Find Qibla",
                        style: GoogleFonts.poppins(
                          fontSize: w * 0.055,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.2),
                Expanded(
                  child: Center(
                    child: StreamBuilder<QiblahDirection>(
                      stream: FlutterQiblah.qiblahStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (snapshot.hasError) {
                          return Text(
                            "Error: ${snapshot.error}",
                            style: GoogleFonts.poppins(fontSize: w * 0.045, color: Colors.red),
                          );
                        }

                        if (!snapshot.hasData) {
                          return Text(
                            "Unable to get Qiblah direction.",
                            style: GoogleFonts.poppins(fontSize: w * 0.045, color: Colors.black54),
                          );
                        }

                        final direction = snapshot.data!;
                        final angle = direction.qiblah;

                        // Responsive compass diameter
                        final double compassSize = w * 0.68;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Compass and Kaaba overlay
                            SizedBox(
                              width: compassSize,
                              height: compassSize,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Transform.rotate(
                                    angle: -angle * (math.pi / 180),
                                    child: Image.asset(
                                      "assets/compass.png",
                                      width: compassSize,
                                      height: compassSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // Kaaba icon at the Qibla direction (top-center of compass)
                                ],
                              ),
                            ),
                            SizedBox(height: h * 0.032),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: h * 0.01,
                                horizontal: w * 0.12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF18895B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Qibla ${angle.toStringAsFixed(2)}",
                                style: GoogleFonts.poppins(
                                  fontSize: w * 0.055,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(height: h * 0.01),
                            Text("if the compass seems inaccurate, please move your device",
                                style: GoogleFonts.poppins(
                                  fontSize: w * 0.028,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: h * 0.06),
              ],
            ),
          ),
        ],
      ),
    );
  }
}