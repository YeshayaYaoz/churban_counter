import WidgetKit
import SwiftUI

struct ChurbanProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "group.com.arielapps.churbanCounter.ChurbanWidge")

    // Days in one timeline. WidgetKit asks for the next ones once they run out.
    let timelineDays = 30

    let dayFormatter: DateFormatter = {
        // Fixed calendar and locale, as the device may use a different calendar
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func placeholder(in context: Context) -> ChurbanEntry {
        ChurbanEntry(date: Date(), totalDays: "714,502", yearsMonths: "1,956 שנים ו-3 חודשים", hebrewDate: "", isTishaBAv: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChurbanEntry) -> ()) {
        completion(createEntry(for: Date(), upcomingDays: loadUpcomingDays()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChurbanEntry>) -> ()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let upcomingDays = loadUpcomingDays()

        var entries: [ChurbanEntry] = []
        for offset in 0..<timelineDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { break }
            entries.append(createEntry(for: date, upcomingDays: upcomingDays))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func loadUpcomingDays() -> [String: [String: String]] {
        guard let json = sharedDefaults?.string(forKey: "upcoming_days"),
              let data = json.data(using: .utf8),
              let days = try? JSONDecoder().decode([String: [String: String]].self, from: data) else { return [:] }
        return days
    }

    private func createEntry(for date: Date, upcomingDays: [String: [String: String]]) -> ChurbanEntry {
        let day = upcomingDays[dayFormatter.string(from: date)]

        // Past the end of the upcoming days, stay on what the app last saved
        func value(_ key: String) -> String? {
            day?[key] ?? sharedDefaults?.string(forKey: key)
        }

        return ChurbanEntry(
            date: date,
            totalDays: value("total_days") ?? "---",
            yearsMonths: value("years_months") ?? "",
            hebrewDate: value("hebrew_date") ?? "",
            isTishaBAv: value("is_tisha_bav") == "true"
        )
    }
}

struct ChurbanEntry: TimelineEntry {
    let date: Date
    let totalDays: String
    let yearsMonths: String
    let hebrewDate: String
    let isTishaBAv: Bool
}

struct ChurbanWidgetEntryView: View {
    var entry: ChurbanProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    private let caption = "לחורבן בית המקדש"

    private var accentColor: Color {
        entry.isTishaBAv ? .red : Color(red: 0.83, green: 0.66, blue: 0.29)
    }

    var body: some View {
        content
            .environment(\.layoutDirection, .rightToLeft)
            .containerBackground(for: .widget) {
                widgetBackground
            }
    }

    @ViewBuilder
    private var widgetBackground: some View {
        switch widgetFamily {
        case .accessoryCircular:
            AccessoryWidgetBackground()
        case .accessoryRectangular, .accessoryInline:
            Color.clear
        default:
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.23, blue: 0.29), Color(red: 0.04, green: 0.04, blue: 0.04)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        switch widgetFamily {
        case .accessoryCircular:
            // עיצוב עגול
            VStack(spacing: 0) {
                Text(entry.totalDays)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .widgetAccentable()
                Text("ימים")
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 4)

        case .accessoryRectangular:
            // עיצוב מלבני
            VStack(alignment: .leading, spacing: 0) {
                Text("\u{200F}\(entry.totalDays) ימים")
                    .font(.system(size: 16, weight: .bold))
                    .widgetAccentable()
                if !entry.yearsMonths.isEmpty {
                    Text(entry.yearsMonths)
                        .font(.system(size: 13))
                }
                Text(caption)
                    .font(.system(size: 13, weight: .medium))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity, alignment: .leading)

        case .accessoryInline:
            // שורה אחת
            ViewThatFits {
                Text("\u{200F}\(entry.totalDays) ימים לחורבן בית המקדש")
                Text("\u{200F}\(entry.totalDays) ימים לחורבן")
            }

        case .systemMedium:
            // Home Screen - medium
            HStack(spacing: 14) {
                dayCounter(size: 40)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 1)
                    .padding(.vertical, 14)

                VStack(spacing: 5) {
                    durationLines(size: 15)
                    Text(entry.hebrewDate)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .padding(.top, 3)
                }
                .frame(maxWidth: .infinity)
            }

        default:
            // Home Screen - small
            VStack(spacing: 8) {
                dayCounter(size: 34)
                Rectangle()
                    .fill(accentColor.opacity(0.3))
                    .frame(width: 40, height: 1)
                VStack(spacing: 3) {
                    durationLines(size: 13)
                }
            }
        }
    }

    private func dayCounter(size: CGFloat) -> some View {
        VStack(spacing: 1) {
            if entry.isTishaBAv {
                Text("ט׳ באב")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            Text(entry.totalDays)
                .font(.system(size: size, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("ימים")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(accentColor)
                .tracking(2)
        }
    }

    @ViewBuilder
    private func durationLines(size: CGFloat) -> some View {
        if !entry.yearsMonths.isEmpty {
            Text(entry.yearsMonths)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        Text(caption)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
@main
struct ChurbanWidget: Widget {
    let kind: String = "ChurbanWidget"


    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChurbanProvider()) { entry in
            ChurbanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("זכר לחורבן")
        .description("מונה ימים מאז חורבן בית המקדש")
        .supportedFamilies([
        .systemSmall,
        .systemMedium,
        .accessoryCircular,      // Lock Screen עגול
        .accessoryRectangular,   // Lock Screen מלבני
        .accessoryInline ]) // Lock Screen שורה
    }
}