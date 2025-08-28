import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class NearbyMosquesMap extends StatefulWidget {
  const NearbyMosquesMap({Key? key}) : super(key: key);

  @override
  State<NearbyMosquesMap> createState() => _NearbyMosquesMapState();
}

class _NearbyMosquesMapState extends State<NearbyMosquesMap> {
  @override
  void initState() {
    super.initState();
    // Wait for first frame to ensure context is ready for navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goToGoogleMaps();
    });
  }

  Future<void> _goToGoogleMaps() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar("Location services are disabled.");
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar("Location permission denied.");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar("Location permissions are permanently denied.");
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final lat = position.latitude;
      final lng = position.longitude;

      // Google Maps search nearby mosques URL
      final query = Uri.encodeComponent('mosque');
      final url = 'https://www.google.com/maps/search/$query/@$lat,$lng,15z';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open Google Maps.');
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }
    // Optionally, pop this page from the stack so user doesn't see a blank screen
    if (mounted) Navigator.pop(context);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner very briefly, the user will be navigated away almost instantly
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}