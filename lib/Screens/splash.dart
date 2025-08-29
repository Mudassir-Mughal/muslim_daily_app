import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:muslim_daily/Screens/bottomnavigator.dart';

// Replace with your actual HomePage widget import.
import 'home.dart'; // Ensure you have a HomePage widget in home_page.dart

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
        body: Container(
        decoration: const BoxDecoration(
        image: DecorationImage(
        image: AssetImage("assets/splash2.png"), // 👈 put your image in assets
    fit: BoxFit.cover, // covers whole screen
    ),
    ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: h * 0.30),
            Container(
              width: w * 0.38,
              height: w * 0.38,
              child: Padding(
                padding: EdgeInsets.all(w * 0.01),
                child: Image.asset(
                  'assets/appicon.png', // Use your Figma-exported icon here
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(height: h * 0.00),
            Text(
              "MuslimLink",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: w * 0.07,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 6),
            Text(
              "All-in-One Muslim Guide",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w400,
                fontSize: w * 0.037,
                color: Colors.black.withOpacity(0.65),
                letterSpacing: 0.1,
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.08, vertical: h * 0.04),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF158443),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    minimumSize: const Size(0, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    shadowColor: const Color(0xFFA2C96F),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) =>  MainScreen(),),
                    );
                  },
                  child: Text(
                    "Get Started",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: w * 0.052,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),),
    );
  }
}