import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class TimeZoneService {
  static late String timeZoneName;

  static Future<void> initializeTimeZone() async {
    tzdata.initializeTimeZones();
    timeZoneName = await FlutterTimezone.getLocalTimezone();
    print("Timezone: $timeZoneName");
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  static bool shouldAdjustHijriDate() {
    // Adjust Hijri date if timezone is in Asia
    return timeZoneName.toLowerCase().contains("asia");
  }

  static DateTime getLocalDateTime() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    return now;
  }
}
