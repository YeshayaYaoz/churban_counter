import 'package:home_widget/home_widget.dart';
import 'hebrew_date_service.dart';

/// Manages home screen widget updates for both Android and iOS.
///
/// Dart can't run while the app is closed, so the saved data includes the
/// upcoming days and each widget looks up the current date in them:
/// - Android: an alarm at midnight redraws the widget, with updatePeriodMillis
///            in XML as a backup and registerBackgroundCallback for
///            interactive updates
/// - iOS: WidgetKit Timeline has an entry for each coming midnight
/// - Both: widget data updated every time the app is opened
class WidgetService {
  static const String appGroupId = 'group.com.arielapps.churbanCounter.ChurbanWidge';
  // Qualified because the provider's package differs from the applicationId.
  static const String androidWidgetName =
      'com.example.churban_counter.ChurbanWidgetProvider';
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

    // Save all data to shared storage
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }

    // Trigger native widget UI refresh
    await HomeWidget.updateWidget(
      qualifiedAndroidName: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}

/// Background callback triggered when user taps the widget.
/// This refreshes the data.
@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  await WidgetService.updateWidget();
}
