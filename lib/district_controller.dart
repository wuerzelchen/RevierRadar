import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_model.dart';
import 'polygon_utils.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DistrictController extends ChangeNotifier {
  static const String _poiBoxName = 'poiBox';
  List<PointOfInterest> pois = [];

  Future<void> initPOIs() async {
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(PointOfInterestAdapter());
    var box = await Hive.openBox<PointOfInterest>(_poiBoxName);
    pois = box.values.toList();
    notifyListeners();
  }

  Future<void> addPOI(PointOfInterest poi) async {
    var box = await Hive.openBox<PointOfInterest>(_poiBoxName);
    await box.add(poi);
    // Reload the POIs from Hive to ensure the list is always up-to-date and triggers UI update
    pois = box.values.toList();
    notifyListeners();
  }

  static const String _districtsBoxName = 'districtsBox';
  bool isEditingDistrict = false;
  int? editingPointIndex;
  List<LatLng>? originalDistrictPoints;
  int? removePointCandidateIdx;
  int? selectedDistrictIndex;
  bool isCreatingDistrict = false;
  List<LatLng> currentDistrictPoints = [];
  List<District> districts = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(DistrictAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(LatLngSerializableAdapter());
    var box = await Hive.openBox<District>(_districtsBoxName);
    districts = box.values.toList();
    await initPOIs(); // Ensure POIs are loaded at startup
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveDistricts() async {
    var box = await Hive.openBox<District>(_districtsBoxName);
    await box.clear();
    await box.addAll(districts);
  }

  final List<Color> districtColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
    Colors.indigo,
  ];
  int districtColorIndex = 0;

  bool get hasDistrictEditChanged {
    if (!isEditingDistrict ||
        selectedDistrictIndex == null ||
        originalDistrictPoints == null)
      return false;
    final current = districts[selectedDistrictIndex!].latLngPoints;
    final original = originalDistrictPoints!;
    if (current.length != original.length) return true;
    for (int i = 0; i < current.length; i++) {
      if (current[i] != original[i]) return true;
    }
    return false;
  }

  void confirmEditDistrict() {
    isEditingDistrict = false;
    editingPointIndex = null;
    originalDistrictPoints = null;
    _saveDistricts();
    notifyListeners();
  }

  void startEditDistrict() {
    if (selectedDistrictIndex == null) return;
    isEditingDistrict = true;
    editingPointIndex = null;
    originalDistrictPoints = List<LatLng>.from(
      districts[selectedDistrictIndex!].latLngPoints,
    );
    notifyListeners();
  }

  void stopEditDistrict() {
    if (selectedDistrictIndex != null && originalDistrictPoints != null) {
      districts[selectedDistrictIndex!].points
        ..clear()
        ..addAll(
          originalDistrictPoints!.map((p) => LatLngSerializable.fromLatLng(p)),
        );
    }
    isEditingDistrict = false;
    editingPointIndex = null;
    originalDistrictPoints = null;
    notifyListeners();
  }

  void onMapTapEditDistrict(LatLng latlng) {
    if (selectedDistrictIndex == null || !isEditingDistrict) return;
    final district = districts[selectedDistrictIndex!];
    if (editingPointIndex != null) {
      district.points[editingPointIndex!] = LatLngSerializable.fromLatLng(
        latlng,
      );
      _saveDistricts();
      notifyListeners();
      return;
    }
    final points = district.latLngPoints;
    const double threshold = 0.00001;
    bool exists = points.any(
      (p) =>
          (p.latitude - latlng.latitude).abs() < threshold &&
          (p.longitude - latlng.longitude).abs() < threshold,
    );
    if (exists) return;
    if (points.length < 2) {
      districts[selectedDistrictIndex!].points.add(
        LatLngSerializable.fromLatLng(latlng),
      );
      _saveDistricts();
      notifyListeners();
      return;
    }
    int insertIdx = 0;
    double minDist = double.infinity;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      double d = PolygonUtils.distanceToSegment(latlng, points[i], points[j]);
      if (d < minDist) {
        minDist = d;
        insertIdx = j;
      }
    }
    districts[selectedDistrictIndex!].points.insert(
      insertIdx,
      LatLngSerializable.fromLatLng(latlng),
    );
    _saveDistricts();
    notifyListeners();
  }

  void confirmRemovePoint() {
    if (selectedDistrictIndex != null && removePointCandidateIdx != null) {
      districts[selectedDistrictIndex!].points.removeAt(
        removePointCandidateIdx!,
      );
      removePointCandidateIdx = null;
      editingPointIndex = null;
      _saveDistricts();
      notifyListeners();
    }
  }

  void onEditPointTap(int idx) {
    editingPointIndex = idx;
    removePointCandidateIdx = idx;
    notifyListeners();
  }

  void selectDistrict(int index) {
    selectedDistrictIndex = index;
    notifyListeners();
  }

  void deleteSelectedDistrict() {
    if (selectedDistrictIndex != null &&
        selectedDistrictIndex! < districts.length) {
      districts.removeAt(selectedDistrictIndex!);
      selectedDistrictIndex = null;
      _saveDistricts();
      notifyListeners();
    }
  }

  void cancelDistrictCreation() {
    isCreatingDistrict = false;
    currentDistrictPoints = [];
    notifyListeners();
  }

  void startDistrictCreation() {
    isCreatingDistrict = true;
    currentDistrictPoints = [];
    notifyListeners();
  }

  void addDistrictPoint(LatLng point) {
    currentDistrictPoints.add(point);
    notifyListeners();
  }

  void saveDistrict(String name) {
    if (currentDistrictPoints.length < 3) return;
    districts.add(
      District(
        name: name,
        points: List.from(currentDistrictPoints),
        color: districtColors[districtColorIndex % districtColors.length],
      ),
    );
    districtColorIndex++;
    isCreatingDistrict = false;
    currentDistrictPoints = [];
    _saveDistricts();
    notifyListeners();
  }
}
