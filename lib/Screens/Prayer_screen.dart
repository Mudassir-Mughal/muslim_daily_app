import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../Services/prayerprovider.dart';
import 'NamazTrackerScreen.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool _loading = true;
  Map<String, String> _prayerTimes = {};
  Map<String, DateTime> _prayerTimesDateTime = {};
  List<Map<String, dynamic>> _cities = [];
  TextEditingController _cityController = TextEditingController();
  String _selectedZone = "";
  Map<String, dynamic>? _selectedCity;
  bool _notificationSwitch = false;

  final String _apiKey = "A93ZJTWRZK52";
  static const int daysToSchedule = 30;

  double? _reminderLat;
  double? _reminderLng;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    _initAwesomeNotifications();
    _initDataAsync();
  }

  void _initAwesomeNotifications() {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Namaz Reminder',
          channelDescription: 'Reminders for prayer times',
          defaultColor: Colors.teal,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          soundSource: 'resource://raw/adhan',
        ),
      ],
      debug: true,
    );
  }

  void _initDataAsync() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _requestNotificationPermission(),
        _loadNotificationPreference(),
        _loadSelectedCity(),
        _loadReminderLocation(),
      ]);
      await _loadCities();

      // --- CHANGED: Use Provider location as default (current location)
      final provider = Provider.of<PrayerProvider>(context, listen: false);
      if (_selectedCity != null) {
        provider.setLocation(_selectedCity!['lat'], _selectedCity!['lng']);
        await provider.fetchPrayers();
      } else {
        // No need to fetch here: current location prayers already initialized by provider
      }
      setState(() {
        _loading = false;
      });
    });
  }

  Future<void> _refreshPrayerTimes() async {
    final provider = Provider.of<PrayerProvider>(context, listen: false);
    if (_selectedCity != null) {
      provider.setLocation(_selectedCity!['lat'], _selectedCity!['lng']);
      await provider.fetchPrayers();
    } else if (_reminderLat != null && _reminderLng != null) {
      provider.setLocation(_reminderLat!, _reminderLng!);
      await provider.fetchPrayers();
    } else {
      await _getPrayerTimesFromLocation();
    }
    setState(() {});
  }

  Future<void> _requestNotificationPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Notification permission requested. Please enable!")),
        );
      }
    }
  }

  Future<void> _loadCities() async {
    final jsonData = await rootBundle.loadString('assets/worldcities.json');
    final List<Map<String, dynamic>> parsedCities =
    await compute(_parseCities, jsonData);
    setState(() {
      _cities = parsedCities;
    });
  }

  static List<Map<String, dynamic>> _parseCities(String jsonStr) {
    final List<dynamic> data = json.decode(jsonStr);
    return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<Map<String, dynamic>?> _getTimeZoneDB(double lat, double lng) async {
    try {
      final tzResponse = await http.get(Uri.parse(
          "http://api.timezonedb.com/v2.1/get-time-zone?key=$_apiKey&format=json&by=position&lat=$lat&lng=$lng"
      ));
      if (tzResponse.statusCode == 200) {
        final data = jsonDecode(tzResponse.body);
        if (data["status"] == "OK") {
          return {
            "zoneName": data["zoneName"],
            "localTime": data["formatted"],
          };
        }
      }
    } catch (e) {
      debugPrint("Timezone fetch error: $e");
    }
    return null;
  }

  Future<void> _getPrayerTimesFromLocation() async {
    setState(() => _loading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Location permission denied")),
          );
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final provider = Provider.of<PrayerProvider>(context, listen: false);
      provider.setLocation(position.latitude, position.longitude);
      await provider.fetchPrayers();
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _schedulePrayerNotificationsForMultipleDays(double lat, double lng) async {
    await AwesomeNotifications().cancelAll();
    int id = 2000;
    String? localTimeZone;
    try {
      localTimeZone = await AwesomeNotifications().getLocalTimeZoneIdentifier();
    } catch (_) {
      localTimeZone = null;
    }

    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final myCoordinates = Coordinates(lat, lng);

    DateTime now = DateTime.now();
    for (int dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final prayerTimes = PrayerTimes(
        myCoordinates,
        DateComponents(date.year, date.month, date.day),
        params,
      );
      final times = {
        "Fajr": prayerTimes.fajr,
        "Dhuhr": prayerTimes.dhuhr,
        "Asr": prayerTimes.asr,
        "Maghrib": prayerTimes.maghrib,
        "Isha": prayerTimes.isha,
      };

      for (var prayer in times.keys) {
        final time = times[prayer]!;
        if (time.isAfter(DateTime.now())) {
          await AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: id++,
              channelKey: 'basic_channel',
              title: '$prayer Time',
              body: "Namaz time. It's time for $prayer.",
              notificationLayout: NotificationLayout.Default,
            ),
            schedule: NotificationCalendar(
              year: time.year,
              month: time.month,
              day: time.day,
              hour: time.hour,
              minute: time.minute,
              second: time.second,
              preciseAlarm: true,
              timeZone: localTimeZone,
              repeats: false,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveReminderLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reminderLat', lat);
    await prefs.setDouble('reminderLng', lng);
    setState(() {
      _reminderLat = lat;
      _reminderLng = lng;
    });
  }

  Future<void> _loadReminderLocation() async {
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('reminderLat');
    double? lng = prefs.getDouble('reminderLng');
    if (lat != null && lng != null) {
      setState(() {
        _reminderLat = lat;
        _reminderLng = lng;
      });
    }
  }

  Future<void> _onEnableReminders() async {
    double lat, lng;
    if (_selectedCity != null) {
      lat = _selectedCity!['lat'];
      lng = _selectedCity!['lng'];
    } else {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      lat = pos.latitude;
      lng = pos.longitude;
    }
    await _saveReminderLocation(lat, lng);
    await _schedulePrayerNotificationsForMultipleDays(lat, lng);
  }

  Future<void> _cancelPrayerNotifications() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> _calculatePrayerTimes(double lat, double lng) async {
    setState(() {
      _loading = true;
      _selectedZone = "";
    });

    Map<String, dynamic>? tzResult = await _getTimeZoneDB(lat, lng);

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

    final formatter = DateFormat.jm();

    final fajrCity = tz.TZDateTime.from(prayerTimes.fajr.toUtc(), cityLocation);
    final sunriseCity = tz.TZDateTime.from(prayerTimes.sunrise.toUtc(), cityLocation);
    final dhuhrCity = tz.TZDateTime.from(prayerTimes.dhuhr.toUtc(), cityLocation);
    final asrCity = tz.TZDateTime.from(prayerTimes.asr.toUtc(), cityLocation);
    final maghribCity = tz.TZDateTime.from(prayerTimes.maghrib.toUtc(), cityLocation);
    final ishaCity = tz.TZDateTime.from(prayerTimes.isha.toUtc(), cityLocation);

    setState(() {
      _prayerTimes = {
        "Fajr": formatter.format(fajrCity),
        "Sunrise": formatter.format(sunriseCity),
        "Dhuhr": formatter.format(dhuhrCity),
        "Asr": formatter.format(asrCity),
        "Maghrib": formatter.format(maghribCity),
        "Isha": formatter.format(ishaCity),
      };
      _prayerTimesDateTime = {
        "Fajr": fajrCity,
        "Dhuhr": dhuhrCity,
        "Asr": asrCity,
        "Maghrib": maghribCity,
        "Isha": ishaCity,
      };
      _loading = false;
      _selectedZone = zoneName;
    });

    if (_notificationSwitch) {
      await _onEnableReminders();
    } else {
      await _cancelPrayerNotifications();
    }
  }

  Future<void> _saveSelectedCity(Map<String, dynamic>? city) async {
    final prefs = await SharedPreferences.getInstance();
    if (city == null) {
      await prefs.remove('selectedCity');
    } else {
      await prefs.setString('selectedCity', jsonEncode(city));
    }
  }

  Future<void> _loadSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    final cityString = prefs.getString('selectedCity');
    if (cityString != null) {
      setState(() {
        _selectedCity = jsonDecode(cityString);
      });
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationSwitch', value);
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('notificationSwitch');
    setState(() {
      _notificationSwitch = value ?? false;
    });
  }

  Widget _buildPrayerRow(
      String prayer,
      String time,
      String iconPath,
      Color color,
      double fontSize,
      double iconSize,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                color: color,
              ),
            ),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Text(
              prayer,
              style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: Colors.black),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _zoneRow(double width) {
    final provider = Provider.of<PrayerProvider>(context);
    final showZone = _selectedCity != null
        ? '${_selectedCity!['city']}, ${_selectedCity!['country']}'
        : provider.currentCity ?? 'Zone: $_selectedZone';
    return Padding(
      padding: EdgeInsets.only(left: width * 0.065, top: 2, right: width * 0.055),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.teal, size: 18),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              showZone,
              style: GoogleFonts.poppins(
                fontSize: width * 0.036,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.my_location, color: Colors.teal, size: 20),
            tooltip: "Use Current Location",
            onPressed: () async {
              setState(() {
                _selectedCity = null;
              });
              await _saveSelectedCity(null);
              // No need to fetch again, provider already has current location prayers
              setState(() {});
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final fontSize = width * 0.045;
    final iconSize = width * 0.06;

    final prayerInfo = [
      {
        "name": "Fajr",
        "icon": "assets/fajr.png",
        "color": Color(0xFF6EC6F1),
      },
      {
        "name": "Sunrise",
        "icon": "assets/sunrise.png",
        "color": Color(0xFFFFC162),
      },
      {
        "name": "Dhuhr",
        "icon": "assets/dhuhr.png",
        "color": Color(0xFFF29E38),
      },
      {
        "name": "Asr",
        "icon": "assets/asr.png",
        "color": Color(0xFF8C80F8),
      },
      {
        "name": "Maghrib",
        "icon": "assets/maghrib.png",
        "color": Color(0xFFFF8C81),
      },
      {
        "name": "Isha",
        "icon": "assets/isha.png",
        "color": Color(0xFF3E65F9),
      },
    ];

    // --- CHANGED: Use provider for display
    final provider = Provider.of<PrayerProvider>(context);
    final showLoading = _loading || provider.loading;
    final providerPrayers = _selectedCity != null
        ? provider.prayerTimes
        : provider.locationPrayerTimes;

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FC),
      body: Stack(
        children: [
          // Background image (like Qibla screen)
          SizedBox(
            width: width,
            height: height * 0.30,
            child: Image.asset(
              "assets/background.png",
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: height * 0.006),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Row(
                    children: [
                      Text(
                        "Prayer Times",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: width * 0.055,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: height * 0.23), // More space below header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: TypeAheadField<Map<String, dynamic>>(
                    suggestionsCallback: (pattern) async {
                      return _cities.where((city) => city['city']
                          .toLowerCase()
                          .contains(pattern.toLowerCase())).toList();
                    },
                    builder: (context, controller, focusNode) {
                      _cityController = controller;
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: GoogleFonts.poppins(fontSize: fontSize, color: Colors.black),
                        decoration: InputDecoration(
                          labelText: '',
                          hintText: 'Search City',
                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFFB9C2D9),
                            fontSize: fontSize,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Color(0xFFE9EAF1), width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(13),
                            borderSide: BorderSide(color: Color(0xFFE9EAF1), width: 1),
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.teal),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        ),
                      );
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        title: Text('${suggestion['city']}', style: GoogleFonts.poppins(fontSize: fontSize)),
                        subtitle: Text('${suggestion['country']}', style: GoogleFonts.poppins(fontSize: fontSize * 0.85)),
                      );
                    },
                    onSelected: (suggestion) async {
                      _cityController.text = suggestion['city'];
                      setState(() {
                        _selectedCity = suggestion;
                      });
                      await _saveSelectedCity(suggestion);
                      final provider = Provider.of<PrayerProvider>(context, listen: false);
                      provider.setLocation(suggestion['lat'], suggestion['lng']);
                      await provider.fetchPrayers();
                      if (_notificationSwitch) {
                        await _onEnableReminders();
                      }
                    },
                  ),
                ),
                SizedBox(height: height * 0.01),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.032),
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 12.0),
                          child: Icon(Icons.notifications_active, color: Colors.teal, size: width * 0.05),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Namaz Reminders",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: fontSize,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        Switch(
                          value: _notificationSwitch,
                          activeColor: Colors.teal,
                          onChanged: (value) async {
                            setState(() {
                              _notificationSwitch = value;
                            });
                            await _saveNotificationPreference(value);
                            if (value) {
                              await _onEnableReminders();
                            } else {
                              await _cancelPrayerNotifications();
                            }
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      value
                                          ? "Namaz reminders enabled"
                                          : "Namaz reminders disabled"
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: height * 0.001),
                _zoneRow(width),
                SizedBox(height: height * 0.001),
                Expanded(
                  child: showLoading
                      ? Center(child: CircularProgressIndicator())
                      : providerPrayers == null
                      ? Center(
                    child: Text(
                      "Please set your location to view prayer times.",
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  )
                      : ListView(
                    padding: EdgeInsets.only(top: 0, bottom: height * 0.012),
                    children: prayerInfo
                        .where((info) => providerPrayers.any((p) => p.name == info['name']))
                        .map((info) {
                      final p = providerPrayers.firstWhere((p) => p.name == info['name']);
                      return _buildPrayerRow(
                        info['name'] as String,
                        DateFormat('h:mm a').format(p.time),
                        info['icon'] as String,
                        info['color'] as Color,
                        fontSize,
                        width * 0.058,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}