import 'package:flutter/material.dart';

class LocationProvider extends ChangeNotifier {
  String? _cityName;
  double? _lat;
  double? _lng;

  String? get cityName => _cityName;
  double? get lat => _lat;
  double? get lng => _lng;

  /// Call this whenever the device's location or city changes.
  void updateLocation({required String city, required double lat, required double lng}) {
    _cityName = city;
    _lat = lat;
    _lng = lng;
    notifyListeners();
  }

// Optionally, add any location fetching or permission logic here.
}