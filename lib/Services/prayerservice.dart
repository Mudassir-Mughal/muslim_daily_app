import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class PrayerTime {
  final String name;
  final DateTime time;
  const PrayerTime({required this.name, required this.time});
}

class PrayerService {
  static final String _apiKey = "A93ZJTWRZK52";

  static Future<void> initializeTimeZones() async {
    tzdata.initializeTimeZones();
  }

  static Future<Map<String, dynamic>?> getTimeZoneDB(double lat, double lng) async {
    try {
      final resp = await http.get(Uri.parse(
        "http://api.timezonedb.com/v2.1/get-time-zone?key=$_apiKey&format=json&by=position&lat=$lat&lng=$lng",
      ));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data["status"] == "OK") {
          return {
            "zoneName": data["zoneName"],
            "localTime": data["formatted"],
          };
        }
      }
    } catch (e) {
      // Just return null on error
    }
    return null;
  }

  static Future<List<PrayerTime>?> fetchPrayerTimes({
    required double lat,
    required double lng,
    DateTime? date,
  }) async {
    await initializeTimeZones();
    date ??= DateTime.now();
    final tzResult = await getTimeZoneDB(lat, lng);
    String zoneName = "UTC";
    tz.Location cityLocation = tz.getLocation('UTC');
    tz.TZDateTime nowInZone = tz.TZDateTime.now(cityLocation);

    if (tzResult != null && tzResult["zoneName"] != null) {
      zoneName = tzResult["zoneName"];
      try {
        cityLocation = tz.getLocation(zoneName);
        nowInZone = tz.TZDateTime.now(cityLocation);
      } catch (e) {
        cityLocation = tz.getLocation('UTC');
        nowInZone = tz.TZDateTime.now(cityLocation);
      }
    }

    final myCoordinates = Coordinates(lat, lng);

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;

    final prayerTimes = PrayerTimes(
      myCoordinates,
      DateComponents(nowInZone.year, nowInZone.month, nowInZone.day),
      params,
    );

    final List<PrayerTime> result = [
      PrayerTime(name: "Fajr", time: tz.TZDateTime.from(prayerTimes.fajr.toUtc(), cityLocation)),
      PrayerTime(name: "Dhuhr", time: tz.TZDateTime.from(prayerTimes.dhuhr.toUtc(), cityLocation)),
      PrayerTime(name: "Asr", time: tz.TZDateTime.from(prayerTimes.asr.toUtc(), cityLocation)),
      PrayerTime(name: "Maghrib", time: tz.TZDateTime.from(prayerTimes.maghrib.toUtc(), cityLocation)),
      PrayerTime(name: "Isha", time: tz.TZDateTime.from(prayerTimes.isha.toUtc(), cityLocation)),
    ];
    return result;
  }
}