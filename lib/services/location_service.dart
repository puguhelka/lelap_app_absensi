import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        return '${p.street ?? ''}, ${p.subLocality ?? ''}, ${p.locality ?? ''}, ${p.subAdministrativeArea ?? ''}'
            .replaceAll(RegExp(r'^,\s*|,\s*$'), '')
            .replaceAll(RegExp(r',\s*,'), ',');
      }
    } catch (_) {}
    return '$lat, $lng';
  }

  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static bool isMockLocation(Position position) {
    // Deteksi mock location di Android
    try {
      return position.isMocked;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getLocationData({
    double? officeLat,
    double? officeLng,
  }) async {
    final pos = await getCurrentPosition();
    if (pos == null) return {'error': 'Gagal mendapatkan lokasi.'};

    final address = await getAddressFromLatLng(pos.latitude, pos.longitude);
    double? distance;
    bool? inRadius;

    if (officeLat != null && officeLng != null) {
      distance = calculateDistance(pos.latitude, pos.longitude, officeLat, officeLng);
      inRadius = distance <= 20; // radius 20 meter
    }

    return {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'address': address,
      'distance': distance,
      'inRadius': inRadius,
      'isMock': isMockLocation(pos),
      'accuracy': pos.accuracy,
    };
  }
}
