# זכר לחורבן - Zecher LaChurban

מונה ימים מאז חורבן בית המקדש השני (ט׳ באב ג׳תת״ל / 70 לספירה).

A Flutter app with **home screen widget** that counts the number of days since the destruction of the Second Beit HaMikdash.

---

## Features

- **Total day count** from 9 Av 3830 to today using the Hebrew calendar (`kosher_dart`)
- **Home screen widget** for Android (AppWidgetProvider) and iOS (WidgetKit)
- **Bilingual** Hebrew / English toggle
- **Mourning period awareness**: special UI during the Three Weeks, Nine Days, and Tisha B'Av
- **Daily updates** of the widgets at midnight, even while the app is closed
- **Animated counter** on app launch

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, locale management
├── screens/
│   └── home_screen.dart               # Main UI screen
├── services/
│   ├── hebrew_date_service.dart        # Hebrew calendar calculations
│   └── widget_service.dart             # Home widget update logic
└── widgets/
    ├── day_counter_display.dart        # Animated number display
    └── info_card.dart                  # Notification cards

android/.../
├── ChurbanWidgetProvider.kt           # Native Android widget provider
├── res/layout/churban_widget.xml      # Widget layout
├── res/drawable/widget_background.xml # Widget background
├── res/xml/churban_widget_info.xml    # Widget config
└── res/values/strings.xml             # String resources

ios/ChurbanWidget/
└── ChurbanWidget.swift                # iOS WidgetKit implementation
```

---

## Setup Instructions

### 1. Create the Flutter project

```bash
flutter create churban_counter
cd churban_counter
```

Then replace the generated files with the files from this project.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Android Setup

#### a. Register the widget in `AndroidManifest.xml`

Add inside the `<application>` tag:

```xml
<receiver
    android:name=".ChurbanWidgetProvider"
    android:exported="true">
    <intent-filter>
        <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
        <action android:name="android.intent.action.TIME_SET" />
        <action android:name="android.intent.action.TIMEZONE_CHANGED" />
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/churban_widget_info" />
</receiver>
```

#### b. Check the minimum SDK

In `android/app/build.gradle.kts`, keep minSdk at Flutter's minimum:

```gradle
android {
    defaultConfig {
        minSdk = flutter.minSdkVersion
    }
}
```

### 4. iOS Setup

#### a. Add a Widget Extension

1. Open `ios/Runner.xcworkspace` in Xcode
2. File → New → Target → Widget Extension
3. Name it `ChurbanWidget`
4. Replace the generated Swift file content with `ChurbanWidget.swift`

#### b. Configure App Groups

1. In Xcode, select the **Runner** target → Signing & Capabilities → + App Groups
2. Add group: `group.com.arielapps.churbanCounter.ChurbanWidge`
3. Do the same for the **ChurbanWidget** target

### 5. Run

```bash
flutter run
```

---

## How the Calculation Works

The app uses `kosher_dart` (Dart port of KosherJava) to:

1. Create a `JewishDate` for 9 Av 3830 (the date of the Churban)
2. Create a `JewishDate` for today
3. Calculate the difference using `getAbsDate()` (Julian Day Number)

The total is that difference less 3 days (`totalDaysAdjustment`), so that 21 Cheshvan 5787 shows 714,502. Years and months are counted from 9 Av and are not adjusted.

## How the Widgets Update

Dart can't run while the app is closed, so each time the app opens it saves what the widgets show on each of the next two years of days, keyed by Gregorian date (`upcoming_days`). The widgets look up the current date there:

- **Android**: an alarm at midnight redraws the widget, and so does a change to the clock or time zone
- **iOS**: the WidgetKit timeline has an entry for each coming midnight

Like the app, the widgets turn over at midnight, not at nightfall. If the app stays closed for longer than the saved days cover, the widgets go back to the values from the last time it ran.

---

## Customization

- **Colors**: Edit `primaryColor` and `accentColor` in `home_screen.dart`
- **Widget size**: Adjust `minWidth`/`minHeight` in `churban_widget_info.xml`
- **Days saved ahead**: Change `upcomingDaysCount` in `hebrew_date_service.dart`
- **Pasuk**: Change the verse displayed at the bottom of `home_screen.dart`

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `kosher_dart` | Hebrew calendar calculations |
| `home_widget` | Cross-platform home screen widget |
| `shared_preferences` | Persist locale choice |
| `google_fonts` | Typography (Frank Ruhl Libre, Assistant) |

---

בע״ה שנזכה לבניין בית המקדש במהרה בימינו
