import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'polygon_utils.dart';

import 'district_model.dart';

class MapView extends StatelessWidget {
  final MapController mapController;
  final LatLng? currentPosition;
  final List<dynamic> districts;
  final List<LatLng> currentDistrictPoints;
  final bool isCreatingDistrict;
  final bool isEditingDistrict;
  final int? selectedDistrictIndex;
  final int? editingPointIndex;
  final void Function(LatLng) onMapTapEditDistrict;
  final void Function(LatLng) addDistrictPoint;
  final void Function(int) onEditPointTap;
  final VoidCallback confirmRemovePoint;
  final void Function(int) onSelectDistrict;
  final VoidCallback onStartEditDistrict;
  final VoidCallback onDeleteSelectedDistrict;
  final VoidCallback onStopEditDistrict;
  final VoidCallback onConfirmEditDistrict;
  final bool hasDistrictEditChanged;
  final VoidCallback onStartDistrictCreation;
  final VoidCallback onSaveDistrict;
  final VoidCallback onCancelDistrictCreation;
  final bool followLocation;
  final VoidCallback onCenterLocation;
  final VoidCallback onUserMapMove;
  final bool satelliteView;

  // POI support
  final List<PointOfInterest> pois;
  final void Function(LatLng)? onMapTapAddPOI;
  final void Function(int, PointOfInterest)? onTapPOI;

  const MapView({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.districts,
    required this.currentDistrictPoints,
    required this.isCreatingDistrict,
    required this.isEditingDistrict,
    required this.selectedDistrictIndex,
    required this.editingPointIndex,
    required this.onMapTapEditDistrict,
    required this.addDistrictPoint,
    required this.onEditPointTap,
    required this.confirmRemovePoint,
    required this.onSelectDistrict,
    required this.onStartEditDistrict,
    required this.onDeleteSelectedDistrict,
    required this.onStopEditDistrict,
    required this.onConfirmEditDistrict,
    required this.hasDistrictEditChanged,
    required this.onStartDistrictCreation,
    required this.onSaveDistrict,
    required this.onCancelDistrictCreation,
    required this.followLocation,
    required this.onCenterLocation,
    required this.onUserMapMove,
    required this.satelliteView,
    required this.pois,
    this.onMapTapAddPOI,
    this.onTapPOI,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            center: currentPosition,
            zoom: 15.0,
            onTap: (tapPosition, latlng) {
              if (isCreatingDistrict) {
                addDistrictPoint(latlng);
                return;
              }
              if (isEditingDistrict && selectedDistrictIndex != null) {
                onMapTapEditDistrict(latlng);
                return;
              }
              if (onMapTapAddPOI != null) {
                onMapTapAddPOI!(latlng);
                return;
              }
              // Polygon selection by tap
              for (int i = 0; i < districts.length; i++) {
                final d = districts[i];
                if (d.latLngPoints.length > 2 &&
                    PolygonUtils.pointInPolygon(latlng, d.latLngPoints)) {
                  onSelectDistrict(i);
                  break;
                }
              }
            },
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                onUserMapMove();
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: satelliteView
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: satelliteView ? const [] : const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                if (currentPosition != null)
                  Marker(
                    width: 80.0,
                    height: 80.0,
                    point: currentPosition!,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ...currentDistrictPoints.map(
                  (point) => Marker(
                    width: 30.0,
                    height: 30.0,
                    point: point,
                    child: const Icon(
                      Icons.circle,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                ),
                if (isEditingDistrict && selectedDistrictIndex != null)
                  ...districts[selectedDistrictIndex!].points
                      .asMap()
                      .entries
                      .map((entry) {
                        final idx = entry.key;
                        final pt = entry.value;
                        return Marker(
                          width: 60.0,
                          height: 36.0,
                          point: pt.toLatLng(),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  onEditPointTap(idx);
                                },
                                child: Icon(
                                  Icons.circle,
                                  color: editingPointIndex == idx
                                      ? Colors.orange
                                      : Colors.deepPurple,
                                  size: 22,
                                ),
                              ),
                              if (editingPointIndex == idx)
                                Positioned(
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: confirmRemovePoint,
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 18),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                // POI markers
                ...pois.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final poi = entry.value;
                  IconData icon;
                  Color color = Colors.green;
                  switch (poi.type) {
                    case 'Kirrung':
                      icon = Icons.grass;
                      color = Colors.brown;
                      break;
                    case 'Hochsitz':
                      icon = Icons.chair_alt;
                      color = Colors.blueGrey;
                      break;
                    case 'Drückjagd Sitz':
                      icon = Icons.chair;
                      color = Colors.deepOrange;
                      break;
                    case 'Fütterung':
                      icon = Icons.restaurant;
                      color = Colors.amber;
                      break;
                    case 'Wildäsungsfläche':
                      icon = Icons.eco;
                      color = Colors.green;
                      break;
                    case 'Fasanenfütterung':
                      icon = Icons.egg;
                      color = Colors.purple;
                      break;
                    case 'Salzlecke':
                      icon = Icons.spa;
                      color = Colors.lightBlue;
                      break;
                    case 'Wasserstelle':
                      icon = Icons.water;
                      color = Colors.blue;
                      break;
                    case 'Wechsel':
                      icon = Icons.alt_route;
                      color = Colors.teal;
                      break;
                    case 'Sonstiges':
                      icon = Icons.location_on;
                      color = Colors.grey;
                      break;
                    default:
                      icon = Icons.place;
                      color = Colors.green;
                  }
                  return Marker(
                    width: 40.0,
                    height: 40.0,
                    point: poi.latLng,
                    child: GestureDetector(
                      onTap: onTapPOI != null
                          ? () => onTapPOI!(idx, poi)
                          : null,
                      child: Icon(icon, color: color, size: 32),
                    ),
                  );
                }),
              ],
            ),
            PolygonLayer(
              polygons: [
                ...districts.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  final isSelected = i == selectedDistrictIndex;
                  return Polygon(
                    points: d.latLngPoints,
                    color: d.color.withOpacity(isSelected ? 0.5 : 0.3),
                    borderStrokeWidth: isSelected ? 5 : 3,
                    borderColor: isSelected ? Colors.black : d.color,
                  );
                }),
                if (isCreatingDistrict && currentDistrictPoints.length > 2)
                  Polygon(
                    points: currentDistrictPoints,
                    color: Colors.blue.withOpacity(0.2),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blue,
                  ),
              ],
            ),
          ],
        ),
        // Save and Cancel buttons for district (bottom center, above FABs)
        if (isCreatingDistrict && !isEditingDistrict)
          Positioned(
            bottom: 90,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentDistrictPoints.length > 2)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save District'),
                    onPressed: onSaveDistrict,
                  ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: onCancelDistrictCreation,
                ),
              ],
            ),
          ),
        // ...removed background center map button...
        // Legend (top right) with edit controls
        if (districts.isNotEmpty)
          Positioned(
            top: 24,
            right: 24,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Districts',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ...districts.asMap().entries.map((entry) {
                      final i = entry.key;
                      final d = entry.value;
                      final isSelected = i == selectedDistrictIndex;
                      return InkWell(
                        onTap: () => onSelectDistrict(i),
                        child: Container(
                          color: isSelected ? Colors.black12 : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: d.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(d.name),
                              if (isSelected && !isEditingDistrict) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: onStartEditDistrict,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: onDeleteSelectedDistrict,
                                ),
                              ],
                              if (isSelected && isEditingDistrict) ...[
                                if (hasDistrictEditChanged)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Confirm Edit',
                                    onPressed: onConfirmEditDistrict,
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: 'Exit Edit',
                                  onPressed: onStopEditDistrict,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
