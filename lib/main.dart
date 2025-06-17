import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_controller.dart';
import 'location_service.dart';
import 'map_view.dart';
import 'dialogs.dart';
import 'poi_dialog.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'dart:math';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final districtController = DistrictController();
  Future.wait([districtController.init(), districtController.initPOIs()]).then((
    _,
  ) {
    runApp(MyApp(districtController: districtController));
  });
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
  // POI creation state
  bool _isCreatingPOI = false;
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
                );
              },
            ),
      // Only use a single custom stack, no default FABs
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Center button on top
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0, right: 16.0),
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
          // Add POI button below
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
            child: FloatingActionButton(
              heroTag: 'add-poi',
              onPressed: _isCreatingPOI ? null : _startPOICreation,
              backgroundColor: _isCreatingPOI ? Colors.orange : null,
              child: const Icon(Icons.add_location_alt),
              tooltip: 'Add Point of Interest',
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: null,
    );
  }
}
