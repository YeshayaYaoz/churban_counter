# זכר לחורבן - Zecher LaChurban

מונה ימים מאז חורבן בית המקדש השני (ט׳ באב ג׳תתכ״ח / 70 לספירה).

A Flutter app with **home screen widget** that counts the number of days since the destruction of the Second Beit HaMikdash.

---

## Features

- **Total day count** from 9 Av 3828 to today using the Hebrew calendar (`kosher_dart`)
- **Home screen widget** for Android (AppWidgetProvider) and iOS (WidgetKit)
- **Bilingual** Hebrew / English toggle
- **Mourning period awareness**: special UI during the Three Weeks, Nine Days, and Tisha B'Av
- **Background updates** via WorkManager (daily refresh)
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
    </intent-filter>
    <meta-data
        android:name="android.appwidget.provider"
        android:resource="@xml/churban_widget_info" />
</receiver>
```

#### b. Add WorkManager initialization

In `android/app/build.gradle`, ensure minSdk is at least 21:

```gradle
android {
    defaultConfig {
        minSdk = 21
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

1. Create a `JewishDate` for 9 Av 3828 (the date of the Churban)
2. Create a `JewishDate` for today
3. Calculate the difference using `getAbsDate()` (Julian Day Number)

The result is the precise number of days between the two Hebrew calendar dates.

---

## Customization

- **Colors**: Edit `primaryColor` and `accentColor` in `home_screen.dart`
- **Widget size**: Adjust `minWidth`/`minHeight` in `churban_widget_info.xml`
- **Update frequency**: Change `Duration(hours: 12)` in `widget_service.dart`
- **Pasuk**: Change the verse displayed at the bottom of `home_screen.dart`

---

## Dependencies

| Package | Purpose |
|---------|---------|
| `kosher_dart` | Hebrew calendar calculations |
| `home_widget` | Cross-platform home screen widget |
| `workmanager` | Background task scheduling |
| `shared_preferences` | Persist locale choice |
| `google_fonts` | Typography (Frank Ruhl Libre, Assistant) |

---

בע״ה שנזכה לבניין בית המקדש במהרה בימינו
