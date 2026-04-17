import 'package:kosher_dart/kosher_dart.dart';

/// Service for calculating halachic zmanim (times),
/// primarily tzet hakochavim (nightfall) for daily widget refresh.
class ZmanimService {
  /// Default location: Jerusalem (Kotel)
  static const double defaultLatitude = 31.7767;
  static const double defaultLongitude = 35.2345;

  /// Returns a [ComplexZmanimCalendar] for the given date and location.
  ///
  /// The date is passed via the [DateTime] parameter in [GeoLocation.setLocation].
  static ComplexZmanimCalendar _getCalendar({
    DateTime? date,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
  }) {
    final useDate = date ?? DateTime.now();

    final geoLocation = GeoLocation.setLocation(
      'User Location',
      latitude,
      longitude,
      useDate,
    );

    return ComplexZmanimCalendar.intGeoLocation(geoLocation);
  }

  /// Returns tzet hakochavim (nightfall) for today.
  ///
  /// Uses the standard 8.5° below the horizon, which is a widely
  /// accepted shiur for tzet hakochavim (3 medium stars visible).
  static DateTime? getTzetHakochavim({
    DateTime? date,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
  }) {
    final calendar = _getCalendar(
      date: date,
      latitude: latitude,
      longitude: longitude,
    );

    // 8.5 degrees - standard tzet hakochavim
    return calendar.getTzaisGeonim8Point5Degrees();
  }

  /// Returns tzet hakochavim using Rabbeinu Tam (72 minutes after shkiah).
  static DateTime? getTzetRabbeinuTam({
    DateTime? date,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
  }) {
    final calendar = _getCalendar(
      date: date,
      latitude: latitude,
      longitude: longitude,
    );

    return calendar.getTzais72();
  }

  /// Returns the *next* tzet hakochavim from now.
  ///
  /// If today's tzet has already passed, returns tomorrow's tzet.
  static DateTime? getNextTzetHakochavim({
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
  }) {
    final now = DateTime.now();

    // Try today's tzet
    final todayTzet = getTzetHakochavim(
      date: now,
      latitude: latitude,
      longitude: longitude,
    );

    if (todayTzet != null && todayTzet.isAfter(now)) {
      return todayTzet;
    }

    // Today's tzet has passed — get tomorrow's
    final tomorrow = now.add(const Duration(days: 1));
    return getTzetHakochavim(
      date: tomorrow,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Returns shkiah (sunset) for today.
  static DateTime? getShkiah({
    DateTime? date,
    double latitude = defaultLatitude,
    double longitude = defaultLongitude,
  }) {
    final calendar = _getCalendar(
      date: date,
      latitude: latitude,
      longitude: longitude,
    );

    return calendar.getSunset();
  }

  /// Returns a human-readable time string (HH:mm) for a DateTime.
  static String formatTime(DateTime? dateTime) {
    if (dateTime == null) return '--:--';
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
