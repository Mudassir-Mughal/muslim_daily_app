import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:muslim_daily/Screens/features.dart'; // Adjust the path as per your folder
import 'package:muslim_daily/Screens/splash.dart';

import 'Services/location_permission.dart';
import 'Services/prayerprovider.dart';
import 'Services/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;// Required by service

import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();// Important!
  await TimeZoneService.initializeTimeZone();
  runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PrayerProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
        ],
        child: MyApp(),
      ),);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Muslim Daily',
      home: SplashScreen(),
    );
  }
}