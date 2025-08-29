import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/topbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // <-- Add this import

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Color green = const Color(0xFF158443);
    final Color lightGreen = const Color(0xFFB9E4C9);

    void _showRateDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          int _selectedStars = 0;

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              content: SizedBox(
                width: 310,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Graphic/Header
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFFE060),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rate, color: green, size: 30),
                              SizedBox(width: 6),
                              Text("RATE US!", style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Hi, take a minute to rate this app and help support to improve",
                          style: TextStyle(color: Colors.grey[700], fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                                (index) => IconButton(
                              icon: Icon(
                                Icons.star,
                                color: index < _selectedStars ? Color(0xFFFFB800) : Color(0xFFE5E5E5),
                                size: 32,
                              ),
                              onPressed: () => setState(() => _selectedStars = index + 1),
                              splashRadius: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: green,
                              side: BorderSide(color: lightGreen, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Thank you for rating us!")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: green,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text("Submit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    void _showExitDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          content: SizedBox(
            width: 310,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Graphic/Header
                Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Icon(Icons.exit_to_app, color: green, size: 56),
                      SizedBox(height: 10),
                      Text("Exit", style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 22)),
                    ],
                  ),
                ),
                Text(
                  "Do you want to exit app?",
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: green,
                          side: BorderSide(color: lightGreen, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("No", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Exit the app when user presses Yes
                          SystemNavigator.pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text("Yes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

    void _shareApp() {
      Share.share('Check out the Muslim Daily app!');
    }

    Widget buildCard(IconData icon, String label, VoidCallback onTap) {
      return Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Icon(icon, color: green, size: 32),
          title: Text(label, style: TextStyle(color: green, fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.arrow_forward_ios, color: green, size: 18),
          onTap: onTap,
        ),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(85),
        child: IslamicTopBar(
          title: "Settings",
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            buildCard(Icons.star_rate, "Rate Us", _showRateDialog),
            SizedBox(height: 10),
            buildCard(Icons.share, "Share", _shareApp),
            SizedBox(height: 10),
            buildCard(Icons.feedback_outlined, "Feedback", () {
              // TODO: Implement feedback
            }),
            SizedBox(height: 10),
            buildCard(Icons.exit_to_app, "Exit", _showExitDialog),
          ],
        ),
      ),
    );
  }
}