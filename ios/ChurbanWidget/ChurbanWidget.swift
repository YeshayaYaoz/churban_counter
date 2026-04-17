import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ChurbanProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.example.churbanCounter")

    func placeholder(in context: Context) -> ChurbanEntry {
        ChurbanEntry(
            date: Date(),
            totalDays: "714,340",
            hebrewDate: "",
            nextTzet: "",
            isTishaBAv: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChurbanEntry) -> ()) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChurbanEntry>) -> ()) {
        let entry = createEntry()

        // Read next tzet hakochavim timestamp saved by Flutter
        let refreshDate = nextTzetDate() ?? fallbackRefreshDate()

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Helpers

    private func createEntry() -> ChurbanEntry {
        let totalDays = sharedDefaults?.string(forKey: "total_days") ?? "---"
        let hebrewDate = sharedDefaults?.string(forKey: "hebrew_date") ?? ""
        let nextTzet = sharedDefaults?.string(forKey: "next_tzet_display") ?? ""
        let isTishaBAv = sharedDefaults?.string(forKey: "is_tisha_bav") == "true"

        return ChurbanEntry(
            date: Date(),
            totalDays: totalDays,
            hebrewDate: hebrewDate,
            nextTzet: nextTzet,
            isTishaBAv: isTishaBAv
        )
    }

    /// Reads the next tzet hakochavim timestamp that Flutter
    /// calculated via kosher_dart and saved to shared preferences.
    private func nextTzetDate() -> Date? {
        guard let tsString = sharedDefaults?.string(forKey: "next_tzet_timestamp"),
              let tsMillis = Double(tsString) else {
            return nil
        }
        let date = Date(timeIntervalSince1970: tsMillis / 1000.0)

        // Sanity check: must be in the future and within 48 hours
        let now = Date()
        guard date > now, date < now.addingTimeInterval(48 * 3600) else {
            return nil
        }
        return date
    }

    /// Fallback: if Flutter hasn't saved a tzet time yet,
    /// approximate nightfall as today 19:30 local (or tomorrow
    /// 19:30 if that's already passed). The Flutter side will
    /// overwrite this with the precise time on next app open.
    private func fallbackRefreshDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19
        components.minute = 30

        if let tonight = calendar.date(from: components), tonight > Date() {
            return tonight
        }

        // Tonight already passed — use tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        tomorrowComponents.hour = 19
        tomorrowComponents.minute = 30
        return calendar.date(from: tomorrowComponents) ?? Date().addingTimeInterval(24 * 3600)
    }
}

// MARK: - Entry

struct ChurbanEntry: TimelineEntry {
    let date: Date
    let totalDays: String
    let hebrewDate: String
    let nextTzet: String
    let isTishaBAv: Bool
}

// MARK: - Widget View

struct ChurbanWidgetEntryView: View {
    var entry: ChurbanProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    private var accentColor: Color {
        entry.isTishaBAv ? .red : Color(red: 0.83, green: 0.66, blue: 0.29)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.23, blue: 0.29),
                    Color(red: 0.04, green: 0.04, blue: 0.04)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 4) {
                // Title
                Text(entry.isTishaBAv ? "ט׳ באב" : "זכר לחורבן")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(accentColor)

                // Day count
                Text(entry.totalDays)
                    .font(.system(size: widgetFamily == .systemSmall ? 28 : 36, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)

                // Label
                Text("ימים")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.8))
                    .tracking(2)

                if widgetFamily != .systemSmall {
                    Spacer()

                    HStack(spacing: 12) {
                        // Hebrew date
                        Text(entry.hebrewDate)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))

                        // Next tzet indicator
                        if !entry.nextTzet.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 9))
                                Text(entry.nextTzet)
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(accentColor.opacity(0.5))
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Widget Configuration

@main
struct ChurbanWidget: Widget {
    let kind: String = "ChurbanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChurbanProvider()) { entry in
            ChurbanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("זכר לחורבן")
        .description("מונה ימים מאז חורבן בית המקדש · מתעדכן בצאת הכוכבים")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
