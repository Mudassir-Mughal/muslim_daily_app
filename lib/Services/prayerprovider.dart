import 'package:flutter/material.dart';
import 'package:muslim_daily/Services/prayerservice.dart';

class PrayerProvider extends ChangeNotifier {
  // For manual selection (Prayer screen)
  List<PrayerTime>? _prayerTimes;
  double? _lat;
  double? _lng;

  // For current location (HomePage)
  List<PrayerTime>? _locationPrayerTimes;
  double? _currentLat;
  double? _currentLng;

  bool _loading = false;
  String? _error;

  List<PrayerTime>? get prayerTimes => _prayerTimes;
  List<PrayerTime>? get locationPrayerTimes => _locationPrayerTimes;
  bool get loading => _loading;
  String? get error => _error;

  /// Set manual location (for Prayer screen)
  void setLocation(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    fetchPrayers();
  }

  /// Set device location (for HomePage, called by LocationProvider)
  void setCurrentLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
    fetchLocationPrayers();
  }

  Future<void> initialize() async {
    // Optionally auto-fetch with default or saved location here.
    return;
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

  /// Returns the next prayer for either current location or manual selection
  Map<String, dynamic>? getNextPrayer({bool forCurrentLocation = false}) {
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
    return null;
  }
}