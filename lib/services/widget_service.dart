import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hebrew_date_service.dart';
import 'zmanim_service.dart';

/// Manages home screen widget updates for both Android and iOS.
///
/// Uses home_widget's built-in mechanisms:
/// - Android: updatePeriodMillis in XML (periodic OS refresh)
///            + registerBackgroundCallback for interactive updates
/// - iOS: WidgetKit Timeline refreshes at tzet hakochavim
/// - Both: widget data updated every time the app is opened
class WidgetService {
  static const String appGroupId = 'group.com.example.churbanCounter';
  static const String androidWidgetName = 'ChurbanWidgetProvider';
  static const String iOSWidgetName = 'ChurbanWidget';

  /// Initialize home widget.
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);

    // Register background callback for interactive widget taps
    await HomeWidget.registerInteractivityCallback(backgroundCallback);

    // Perform initial data update
    await updateWidget();
  }

  /// Update the home screen widget with current data.
  static Future<void> updateWidget() async {
    final data = HebrewDateService.getWidgetData();

    // Load saved user location for zmanim
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_latitude') ?? ZmanimService.defaultLatitude;
    final lng = prefs.getDouble('user_longitude') ?? ZmanimService.defaultLongitude;

    // Add tzet info for iOS Timeline refresh
    final nextTzet = ZmanimService.getNextTzetHakochavim(
      latitude: lat,
      longitude: lng,
    );
    data['next_tzet'] = ZmanimService.formatTime(nextTzet);

    if (nextTzet != null) {
      data['next_tzet_timestamp'] = nextTzet.millisecondsSinceEpoch.toString();
    }

    // Save all data to shared storage
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }

    // Trigger native widget UI refresh
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }

  /// Saves the user's location for accurate zmanim calculations.
  static Future<void> saveUserLocation(double lat, double lng) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_latitude', lat);
    await prefs.setDouble('user_longitude', lng);

    // Re-update with new location
    await updateWidget();
  }
}

/// Background callback triggered when user taps the widget.
/// This refreshes the data.
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await WidgetService.updateWidget();
}
