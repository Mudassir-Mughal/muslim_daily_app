import 'package:flutter/material.dart';
import 'package:muslim_daily/Services/prayerservice.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerProvider extends ChangeNotifier {
  List<PrayerTime>? _prayerTimes;
  double? _lat;
  double? _lng;
  String? _city;

  // For current location (default)
  List<PrayerTime>? _locationPrayerTimes;
  double? _currentLat;
  double? _currentLng;
  String? _currentCity;

  bool _loading = false;
  String? _error;
  bool _initialized = false;

  List<PrayerTime>? get prayerTimes => _prayerTimes;
  List<PrayerTime>? get locationPrayerTimes => _locationPrayerTimes;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentCity => _currentCity;

  /// Call this ONCE at app start (e.g. HomePage initState) to set up location & city & prayers.
  Future<void> initializeWithCurrentLocation() async {
    if (_initialized) return;
    _initialized = true;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _currentCity = "Permission required";
      notifyListeners();
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    _currentCity = placemarks.isNotEmpty
        ? (placemarks.first.locality ?? placemarks.first.administrativeArea ?? "Unknown City")
        : "Unknown City";
    _currentLat = position.latitude;
    _currentLng = position.longitude;
    await fetchLocationPrayers();
  }

  /// For manual city selection (Prayer screen)
  void setLocation(double lat, double lng, {String? city}) {
    _lat = lat;
    _lng = lng;
    _city = city;
    fetchPrayers();
  }

  /// For updating current location (from HomePage, but should use provider.initializeWithCurrentLocation ideally)
  void updateLocation(double lat, double lng, String city) {
    _currentLat = lat;
    _currentLng = lng;
    _currentCity = city;
    fetchLocationPrayers();
  }

  Future<void> fetchPrayers() async {
    if (_lat == null || _lng == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await PrayerService.fetchPrayerTimes(lat: _lat!, lng: _lng!);
      _prayerTimes = data;
    } catch (e) {
      _error = "Unable to fetch prayer times.";
      _prayerTimes = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> fetchLocationPrayers() async {
    if (_currentLat == null || _currentLng == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await PrayerService.fetchPrayerTimes(lat: _currentLat!, lng: _currentLng!);
      _locationPrayerTimes = data;
    } catch (e) {
      _error = "Unable to fetch prayer times.";
      _locationPrayerTimes = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// Gets the next prayer for either current location (default) or manual city
  Map<String, dynamic>? getNextPrayer({bool forCurrentLocation = true}) {
    final now = DateTime.now();
    final list = forCurrentLocation ? _locationPrayerTimes : _prayerTimes;
    if (list == null) return null;
    for (final p in list) {
      if (p.time.isAfter(now)) {
        return {
          "name": p.name,
          "time": p.time,
          "countdown": p.time.difference(now),
        };
      }
    }
    // If none left today, return tomorrow's first prayer
    if (list.isNotEmpty) {
      final firstPrayerTomorrow = list[0].time.add(Duration(days: 1));
      return {
        "name": list[0].name,
        "time": firstPrayerTomorrow,
        "countdown": firstPrayerTomorrow.difference(now),
      };
    }
    return null;
  }
}