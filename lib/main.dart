import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_controller.dart';
import 'district_model.dart';
import 'location_service.dart';
import 'map_view.dart';
import 'dialogs.dart';
import 'poi_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final districtController = DistrictController();
  await Future.wait([districtController.init(), districtController.initPOIs()]);

  runApp(MyApp(districtController: districtController));
}

class MyApp extends StatelessWidget {
  final DistrictController districtController;
  const MyApp({super.key, required this.districtController});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revier Radar',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 12, 37, 0),
          contrastLevel: 0.5,
          brightness: Brightness.dark,
        ),
      ),
      home: MyHomePage(districtController: districtController),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final DistrictController districtController;
  const MyHomePage({Key? key, required this.districtController})
    : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _onTapPOI(int index, PointOfInterest poi) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                child: Text(
                  poi.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (poi.imagePath != null && poi.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: SizedBox(
                    height: 120,
                    child: Image.file(
                      File(poi.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Bild nicht gefunden'),
                    ),
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit POI'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _editPOI(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete POI'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete POI'),
                      content: Text('Delete POI "${poi.name}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _deletePOI(index);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  // POI creation state
  bool _isCreatingPOI = false;

  // Show POI list (Read)
  void _showPOIList() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final pois = _districtController.pois;
        if (pois.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: Text('No POIs available.')),
          );
        }
        return ListView.separated(
          itemCount: pois.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final poi = pois[index];
            return ListTile(
              title: Text(poi.name),
              subtitle: Text(
                'Lat: ${poi.latLng.latitude.toStringAsFixed(5)}, Lng: ${poi.latLng.longitude.toStringAsFixed(5)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _editPOI(index);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete POI'),
                          content: Text('Delete POI "${poi.name}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _deletePOI(index);
                        Navigator.of(
                          context,
                        ).pop(); // Close the sheet after delete
                      }
                    },
                  ),
                ],
              ),
              onTap: () {
                // Center map on POI
                Navigator.of(context).pop();
                _mapController.move(poi.latLng, _mapController.camera.zoom);
              },
            );
          },
        );
      },
    );
  }

  // Edit POI (Update)
  Future<void> _editPOI(int index) async {
    final poi = _districtController.pois[index];
    final result = await showDialog(
      context: context,
      builder: (context) => POIDialog(location: poi.latLng, initialPOI: poi),
    );
    if (result != null) {
      await _districtController.updatePOI(index, result);
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('POI "${result.name}" updated')));
    }
  }

  // Delete POI (Delete)
  Future<void> _deletePOI(int index) async {
    await _districtController.deletePOI(index);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('POI deleted')));
  }
  // LatLng? _pendingPOILocation; // No longer needed

  Future<void> _startPOICreation() async {
    setState(() {
      _isCreatingPOI = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tap on the map to set POI location')),
    );
  }

  Future<void> _onMapTapAddPOI(LatLng latlng) async {
    if (!_isCreatingPOI) return;
    final result = await showDialog(
      context: context,
      builder: (context) => POIDialog(location: latlng),
    );
    if (result != null) {
      await _districtController.addPOI(result);
      // Center the map on the new POI
      _mapController.move(result.latLng, _mapController.camera.zoom);
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('POI "${result.name}" hinzugefügt')),
      );
    }
    setState(() {
      _isCreatingPOI = false;
    });
  }

  late final DistrictController _districtController;
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  LocationData? _currentPosition;
  late final Stream<LocationData> _locationStream;
  bool _followLocation = true;
  bool _satelliteView = false;

  @override
  void initState() {
    super.initState();
    _districtController = widget.districtController;
    _initLocation();
  }

  Future<void> _initLocation() async {
    _currentPosition = await _locationService.getCurrentLocation();
    setState(() {});
    _locationStream = _locationService.locationStream;
    _locationStream.listen((LocationData newPosition) {
      setState(() {
        _currentPosition = newPosition;
      });
      if (_followLocation && _currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
          _mapController.camera.zoom,
        );
      }
    });
  }

  Future<void> _onSaveDistrict(BuildContext context) async {
    if (_districtController.currentDistrictPoints.length < 3) return;
    String name = await showDistrictNameDialog(context);
    if (name.isEmpty) return;
    _districtController.saveDistrict(name);
  }

  void _onSelectDistrictAndCenter(int index) {
    _districtController.selectDistrict(index);
    final district = _districtController.districts[index];
    if (district.latLngPoints.isEmpty) return;
    double minLat = district.latLngPoints.first.latitude;
    double maxLat = district.latLngPoints.first.latitude;
    double minLng = district.latLngPoints.first.longitude;
    double maxLng = district.latLngPoints.first.longitude;
    for (final pt in district.latLngPoints) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }
    // Add margin (5%)
    final latMargin = (maxLat - minLat) * 0.1;
    final lngMargin = (maxLng - minLng) * 0.1;
    minLat -= latMargin;
    maxLat += latMargin;
    minLng -= lngMargin;
    maxLng += lngMargin;
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    // Estimate zoom so that the bounding box fits
    final worldDim = 256.0;
    final mapSize = MediaQuery.of(context).size;
    double latRad(double lat) {
      final siny = sin(lat * pi / 180.0);
      return log((1 + siny) / (1 - siny)) / 2;
    }

    double zoom(double mapPx, double worldPx, double fraction) {
      return (log(mapPx / worldPx / fraction) / ln2).clamp(0.0, 18.0);
    }

    final latFraction = (latRad(maxLat) - latRad(minLat)) / pi;
    final lngFraction = ((maxLng - minLng) / 360.0).abs();
    final latZoom = zoom(mapSize.height, worldDim, latFraction);
    final lngZoom = zoom(mapSize.width, worldDim, lngFraction);
    final targetZoom = min(latZoom, lngZoom);
    _mapController.move(center, targetZoom);
  }

  // For Speed Dial FAB
  bool _isFabExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Revier Radar'),
        actions: [
          IconButton(
            icon: Icon(_satelliteView ? Icons.satellite : Icons.map),
            tooltip: _satelliteView ? 'Switch to Map' : 'Switch to Satellite',
            onPressed: () {
              setState(() {
                _satelliteView = !_satelliteView;
              });
            },
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _districtController as Listenable,
              builder: (context, _) {
                return MapView(
                  mapController: _mapController,
                  currentPosition: _currentPosition == null
                      ? null
                      : LatLng(
                          _currentPosition!.latitude!,
                          _currentPosition!.longitude!,
                        ),
                  districts: _districtController.districts,
                  currentDistrictPoints:
                      _districtController.currentDistrictPoints,
                  isCreatingDistrict: _districtController.isCreatingDistrict,
                  isEditingDistrict: _districtController.isEditingDistrict,
                  selectedDistrictIndex:
                      _districtController.selectedDistrictIndex,
                  editingPointIndex: _districtController.editingPointIndex,
                  onMapTapEditDistrict:
                      _districtController.onMapTapEditDistrict,
                  addDistrictPoint: _districtController.addDistrictPoint,
                  onEditPointTap: _districtController.onEditPointTap,
                  confirmRemovePoint: _districtController.confirmRemovePoint,
                  onSelectDistrict: _onSelectDistrictAndCenter,
                  onStartEditDistrict: _districtController.startEditDistrict,
                  onDeleteSelectedDistrict:
                      _districtController.deleteSelectedDistrict,
                  onStopEditDistrict: _districtController.stopEditDistrict,
                  onConfirmEditDistrict:
                      _districtController.confirmEditDistrict,
                  hasDistrictEditChanged:
                      _districtController.hasDistrictEditChanged,
                  onStartDistrictCreation:
                      _districtController.startDistrictCreation,
                  onSaveDistrict: () => _onSaveDistrict(context),
                  onCancelDistrictCreation:
                      _districtController.cancelDistrictCreation,
                  followLocation: _followLocation,
                  onCenterLocation: () {
                    setState(() {
                      _followLocation = true;
                    });
                    if (_currentPosition != null) {
                      _mapController.move(
                        LatLng(
                          _currentPosition!.latitude!,
                          _currentPosition!.longitude!,
                        ),
                        _mapController.camera.zoom,
                      );
                    }
                  },
                  onUserMapMove: () {
                    if (_followLocation) {
                      setState(() {
                        _followLocation = false;
                      });
                    }
                  },
                  satelliteView: _satelliteView,
                  pois: _districtController.pois,
                  onMapTapAddPOI: _isCreatingPOI ? _onMapTapAddPOI : null,
                  onTapPOI: _onTapPOI,
                );
              },
            ),
      floatingActionButton: Stack(
        children: [
          // Center button (bottom right)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 16.0,
                right: MediaQuery.of(context).size.width * 0.05,
              ),
              child: FloatingActionButton(
                heroTag: 'center-map',
                onPressed: () {
                  setState(() {
                    _followLocation = true;
                  });
                  if (_currentPosition != null) {
                    _mapController.move(
                      LatLng(
                        _currentPosition!.latitude!,
                        _currentPosition!.longitude!,
                      ),
                      _mapController.camera.zoom,
                    );
                  }
                },
                child: const Icon(Icons.my_location),
                tooltip: 'Karte zentrieren',
              ),
            ),
          ),
          // Speed Dial FAB (bottom left)
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 16.0,
                left: MediaQuery.of(context).size.width * 0.10,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isFabExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'show-pois',
                        onPressed: () {
                          setState(() {
                            _isFabExpanded = false;
                          });
                          _showPOIList();
                        },
                        icon: const Icon(Icons.list),
                        label: const Text('Show POIs'),
                        tooltip: 'Show all POIs',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'add-district',
                        onPressed: _districtController.isCreatingDistrict
                            ? null
                            : () {
                                setState(() {
                                  _isFabExpanded = false;
                                });
                                _districtController.startDistrictCreation();
                              },
                        backgroundColor: _districtController.isCreatingDistrict
                            ? Colors.orange
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add District'),
                        tooltip: 'Add District',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'add-poi',
                        onPressed: _isCreatingPOI
                            ? null
                            : () {
                                setState(() {
                                  _isFabExpanded = false;
                                });
                                _startPOICreation();
                              },
                        backgroundColor: _isCreatingPOI ? Colors.orange : null,
                        icon: const Icon(Icons.add_location_alt),
                        label: const Text('Add POI'),
                        tooltip: 'Add Point of Interest',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: FloatingActionButton.extended(
                        heroTag: 'add-activity',
                        onPressed: () {
                          setState(() {
                            _isFabExpanded = false;
                          });
                          // TODO: Implement activity creation dialog
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Add Activity (not implemented yet)',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.event_note),
                        label: const Text('Add Activity'),
                        tooltip: 'Add Activity',
                      ),
                    ),
                  ],
                  FloatingActionButton(
                    heroTag: 'expand-add',
                    onPressed: () {
                      setState(() {
                        _isFabExpanded = !_isFabExpanded;
                      });
                    },
                    child: AnimatedRotation(
                      turns: _isFabExpanded ? 0.125 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.add),
                    ),
                    tooltip: _isFabExpanded ? 'Close' : 'Add',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: null,
    );
  }
}
