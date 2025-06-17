import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();
  LocationData? _currentPosition;
  late final Stream<LocationData> _locationStream;

  LocationService() {
    _locationStream = _location.onLocationChanged;
  }

  Future<LocationData?> getCurrentLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }
    _currentPosition = await _location.getLocation();
    return _currentPosition;
  }

  Stream<LocationData> get locationStream => _locationStream;
}
