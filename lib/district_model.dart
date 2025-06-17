import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'district_model.g.dart';

@HiveType(typeId: 2)
class PointOfInterest {
  @HiveField(0)
  String name;
  @HiveField(1)
  String type; // e.g., 'Kirrung', 'Hochsitz', etc.
  @HiveField(2)
  LatLngSerializable location;
  @HiveField(3)
  String? imagePath; // Optional: file path to the image

  static const List<String> types = [
    'Kirrung',
    'Hochsitz',
    'Drückjagd Sitz',
    'Fütterung',
    'Wildäsungsfläche',
    'Fasanenfütterung',
    'Salzlecke',
    'Wasserstelle',
    'Wechsel',
    'Sonstiges',
  ];

  PointOfInterest({
    required this.name,
    required this.type,
    required this.location,
    this.imagePath,
  });

  LatLng get latLng => location.toLatLng();
}

@HiveType(typeId: 0)
class District extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<LatLngSerializable> points;

  @HiveField(2)
  int colorValue;

  // Main constructor for app logic (takes LatLng list)
  District({
    required this.name,
    required List<LatLng> points,
    required Color color,
  }) : points = points.map((p) => LatLngSerializable.fromLatLng(p)).toList(),
       colorValue = color.value;

  // Factory for restoring from Hive (takes LatLngSerializable list)
  factory District.hive({
    required String name,
    required List<dynamic> points,
    required int colorValue,
  }) {
    // Defensive: convert List<LatLng> to List<LatLngSerializable> if needed
    final safePoints = points.isNotEmpty && points.first is LatLng
        ? (points as List<LatLng>)
              .map((p) => LatLngSerializable.fromLatLng(p))
              .toList()
        : points.cast<LatLngSerializable>();
    return District._internal(
      name: name,
      points: safePoints,
      colorValue: colorValue,
    );
  }

  // Private constructor for Hive
  District._internal({
    required this.name,
    required this.points,
    required this.colorValue,
  });

  Color get color => Color(colorValue);
  List<LatLng> get latLngPoints => points.map((p) => p.toLatLng()).toList();
}

@HiveType(typeId: 1)
class LatLngSerializable {
  @HiveField(0)
  double latitude;
  @HiveField(1)
  double longitude;

  LatLngSerializable({required this.latitude, required this.longitude});

  factory LatLngSerializable.fromLatLng(LatLng latLng) => LatLngSerializable(
    latitude: latLng.latitude,
    longitude: latLng.longitude,
  );

  LatLng toLatLng() => LatLng(latitude, longitude);
}
