import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IslamicTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final double height;
  const IslamicTopBar({
    Key? key,
    required this.title,
    this.onBack,
    this.height = 110,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = height;

    return Container(
      width: double.infinity,
      height: h,
      decoration: const BoxDecoration(
        color: Color(0xFF18895B),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Stack(
        children: [
          // Mosque image (top right)
          Positioned(
            right: 15,
            top: 40,
            bottom: 0,
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                'assets/islamicmosque.png',
                height: h * 0.7,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white, size: 36),
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: w * 0.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}