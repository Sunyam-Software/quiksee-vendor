import 'package:geolocator/geolocator.dart';

class GpsLocationHelper {
  static const Duration maxUploadAge = Duration(seconds: 30);
  static const Duration maxLastKnownAge = Duration(seconds: 45);
  static const double maxUploadAccuracyMeters = 100.0;
  static const double maxLastKnownAccuracyMeters = 150.0;

  static bool hasValidCoordinates(double latitude, double longitude) {
    return latitude.abs() > 0.01 && longitude.abs() > 0.01;
  }

  static bool isFreshEnough(
    Position position, {
    Duration maxAge = maxUploadAge,
  }) {
    return DateTime.now().difference(position.timestamp) <= maxAge;
  }

  static bool isAccurateEnough(
    Position position, {
    double maxAccuracyMeters = maxUploadAccuracyMeters,
  }) {
    if (position.accuracy <= 0) {
      return false;
    }
    return position.accuracy <= maxAccuracyMeters;
  }

  static bool isUsableLastKnown(Position? position) {
    if (position == null) {
      return false;
    }
    return hasValidCoordinates(position.latitude, position.longitude) &&
        isFreshEnough(position, maxAge: maxLastKnownAge) &&
        isAccurateEnough(
          position,
          maxAccuracyMeters: maxLastKnownAccuracyMeters,
        );
  }

  static bool isUsableForUpload(Position position) {
    return hasValidCoordinates(position.latitude, position.longitude) &&
        isFreshEnough(position) &&
        isAccurateEnough(position);
  }

  static Future<Position?> resolveForStatusUpdate({
    Position? cachedPosition,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (cachedPosition != null &&
        hasValidCoordinates(cachedPosition.latitude, cachedPosition.longitude)) {
      return cachedPosition;
    }

    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null && hasValidCoordinates(last.latitude, last.longitude)) {
        if (DateTime.now().difference(last.timestamp) <=
            const Duration(minutes: 3)) {
          return last;
        }
      }
    } catch (_) {}

    try {
      final Position current = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      ).timeout(timeout + const Duration(seconds: 1));
      if (hasValidCoordinates(current.latitude, current.longitude)) {
        return current;
      }
    } catch (_) {}

    try {
      final Position? last = await Geolocator.getLastKnownPosition();
      if (last != null && hasValidCoordinates(last.latitude, last.longitude)) {
        return last;
      }
    } catch (_) {}

    return null;
  }

  static Future<Position?> resolveFreshPosition({
    Duration timeout = const Duration(seconds: 12),
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
    bool allowLastKnownFallback = true,
  }) async {
    if (allowLastKnownFallback) {
      try {
        final Position? last = await Geolocator.getLastKnownPosition();
        if (isUsableLastKnown(last)) {
          return last;
        }
      } catch (_) {}
    }

    try {
      final Position current = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      ).timeout(timeout + const Duration(seconds: 2));

      if (isUsableForUpload(current)) {
        return current;
      }

      if (hasValidCoordinates(current.latitude, current.longitude) &&
          isFreshEnough(current)) {
        return current;
      }
    } catch (_) {}

    return null;
  }
}
