import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class District {
  final String name;
  final List<LatLng> points;
  final Color color;
  District({required this.name, required this.points, required this.color});
}
