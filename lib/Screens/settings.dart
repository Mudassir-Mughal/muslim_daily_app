import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/topbar.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color green = const Color(0xFF158443);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(85),
        child: IslamicTopBar(
          title: "Settings",
        ),
      ),
      backgroundColor: Colors.lightBlue[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Themes Card (White)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.color_lens, color: green),
                title: Text("Themes", style: TextStyle(color: green)),
                trailing: Icon(Icons.arrow_forward_ios, color: green, size: 16),
                onTap: () {
                  // TODO: Theme settings
                },
              ),
            ),
            const SizedBox(height: 16),

            // Rate Us Card (Green)
            Card(
              color: green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.star_rate, color: Colors.white),
                title: Text("Rate Us", style: TextStyle(color: Colors.white)),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                onTap: () {
                  // TODO: Rate us functionality
                },
              ),
            ),
            const SizedBox(height: 16),

            // Share Card (White)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.share, color: green),
                title: Text("Share", style: TextStyle(color: green)),
                trailing: Icon(Icons.arrow_forward_ios, color: green, size: 16),
                onTap: () {
                  // TODO: Share functionality
                },
              ),
            ),
            const SizedBox(height: 16),

            // Follow Card (Green)
          ],
        ),
      ),
    );
  }
}