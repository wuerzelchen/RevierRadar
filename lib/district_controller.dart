import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'district_model.dart';
import 'polygon_utils.dart';

class DistrictController extends ChangeNotifier {
  bool isEditingDistrict = false;
  int? editingPointIndex;
  List<LatLng>? originalDistrictPoints;
  int? removePointCandidateIdx;
  int? selectedDistrictIndex;
  bool isCreatingDistrict = false;
  List<LatLng> currentDistrictPoints = [];
  List<District> districts = [];
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
    final current = districts[selectedDistrictIndex!].points;
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
    notifyListeners();
  }

  void startEditDistrict() {
    if (selectedDistrictIndex == null) return;
    isEditingDistrict = true;
    editingPointIndex = null;
    originalDistrictPoints = List<LatLng>.from(
      districts[selectedDistrictIndex!].points,
    );
    notifyListeners();
  }

  void stopEditDistrict() {
    if (selectedDistrictIndex != null && originalDistrictPoints != null) {
      districts[selectedDistrictIndex!].points
        ..clear()
        ..addAll(originalDistrictPoints!);
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
      district.points[editingPointIndex!] = latlng;
      notifyListeners();
      return;
    }
    final points = district.points;
    const double threshold = 0.00001;
    bool exists = points.any(
      (p) =>
          (p.latitude - latlng.latitude).abs() < threshold &&
          (p.longitude - latlng.longitude).abs() < threshold,
    );
    if (exists) return;
    if (points.length < 2) {
      points.add(latlng);
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
    points.insert(insertIdx, latlng);
    notifyListeners();
  }

  void confirmRemovePoint() {
    if (selectedDistrictIndex != null && removePointCandidateIdx != null) {
      districts[selectedDistrictIndex!].points.removeAt(
        removePointCandidateIdx!,
      );
      removePointCandidateIdx = null;
      editingPointIndex = null;
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
    notifyListeners();
  }
}
