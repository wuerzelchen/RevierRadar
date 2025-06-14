import 'package:latlong2/latlong.dart';
import 'dart:math';

class PolygonUtils {
  // Ray-casting algorithm for point in polygon
  static bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length; j++) {
      LatLng a = polygon[j];
      LatLng b = polygon[(j + 1) % polygon.length];
      if (((a.latitude > point.latitude) != (b.latitude > point.latitude)) &&
          (point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude)) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  // Shoelace formula for polygon area (absolute value)
  static double polygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }
    return area.abs() / 2.0;
  }

  // Check if point is near any edge of the polygon (within threshold in degrees)
  static bool pointNearPolygonEdge(
    LatLng point,
    List<LatLng> polygon,
    double threshold,
  ) {
    for (int j = 0; j < polygon.length; j++) {
      LatLng a = polygon[j];
      LatLng b = polygon[(j + 1) % polygon.length];
      if (distanceToSegment(point, a, b) < threshold) {
        return true;
      }
    }
    return false;
  }

  static double distanceToSegment(LatLng p, LatLng a, LatLng b) {
    double px = p.longitude, py = p.latitude;
    double ax = a.longitude, ay = a.latitude;
    double bx = b.longitude, by = b.latitude;
    double dx = bx - ax, dy = by - ay;
    if (dx == 0 && dy == 0) {
      dx = px - ax;
      dy = py - ay;
      return sqrt(dx * dx + dy * dy);
    }
    double t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    double projx = ax + t * dx;
    double projy = ay + t * dy;
    double distx = px - projx, disty = py - projy;
    return sqrt(distx * distx + disty * disty);
  }
}
