#!/usr/bin/env ruby
require 'xcodeproj'
require 'fileutils'

# === CONFIG ===
PROJECT_PATH = 'ios/Runner.xcodeproj'
WIDGET_NAME = 'ChurbanWidget'
WIDGET_BUNDLE_ID = 'com.arielapps.churbanCounter.ChurbanWidget'
MAIN_BUNDLE_ID = 'com.arielapps.churbanCounter'
APP_GROUP = 'group.com.arielapps.churbanCounter.ChurbanWidge'
DEPLOYMENT_TARGET = '17.0'
TEAM_ID = '95PWP7NY36'

# === Create widget extension directory and files ===
widget_dir = "ios/#{WIDGET_NAME}"
FileUtils.mkdir_p(widget_dir)

swift_code = <<~SWIFT
import WidgetKit
import SwiftUI

struct ChurbanProvider: TimelineProvider {
    let sharedDefaults = UserDefaults(suiteName: "#{APP_GROUP}")

    func placeholder(in context: Context) -> ChurbanEntry {
        ChurbanEntry(date: Date(), totalDays: "714,340", hebrewDate: "", nextTzet: "", isTishaBAv: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChurbanEntry) -> ()) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChurbanEntry>) -> ()) {
        let entry = createEntry()
        let refreshDate = nextTzetDate() ?? fallbackRefreshDate()
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func createEntry() -> ChurbanEntry {
        let totalDays = sharedDefaults?.string(forKey: "total_days") ?? "---"
        let hebrewDate = sharedDefaults?.string(forKey: "hebrew_date") ?? ""
        let nextTzet = sharedDefaults?.string(forKey: "next_tzet_display") ?? ""
        let isTishaBAv = sharedDefaults?.string(forKey: "is_tisha_bav") == "true"
        return ChurbanEntry(date: Date(), totalDays: totalDays, hebrewDate: hebrewDate, nextTzet: nextTzet, isTishaBAv: isTishaBAv)
    }

    private func nextTzetDate() -> Date? {
        guard let tsString = sharedDefaults?.string(forKey: "next_tzet_timestamp"),
              let tsMillis = Double(tsString) else { return nil }
        let date = Date(timeIntervalSince1970: tsMillis / 1000.0)
        let now = Date()
        guard date > now, date < now.addingTimeInterval(48 * 3600) else { return nil }
        return date
    }

    private func fallbackRefreshDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 19; components.minute = 30
        if let tonight = calendar.date(from: components), tonight > Date() { return tonight }
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        var tc = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        tc.hour = 19; tc.minute = 30
        return calendar.date(from: tc) ?? Date().addingTimeInterval(86400)
    }
}

struct ChurbanEntry: TimelineEntry {
    let date: Date
    let totalDays: String
    let hebrewDate: String
    let nextTzet: String
    let isTishaBAv: Bool
}

struct ChurbanWidgetEntryView: View {
    var entry: ChurbanProvider.Entry
    @Environment(\\.widgetFamily) var widgetFamily

    private var accentColor: Color {
        entry.isTishaBAv ? .red : Color(red: 0.83, green: 0.66, blue: 0.29)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.11, green: 0.23, blue: 0.29), Color(red: 0.04, green: 0.04, blue: 0.04)], startPoint: .top, endPoint: .bottom)
            VStack(spacing: 4) {
                Text(entry.isTishaBAv ? "ט׳ באב" : "זכר לחורבן")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(accentColor)
                Text(entry.totalDays)
                    .font(.system(size: widgetFamily == .systemSmall ? 28 : 36, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                Text("ימים")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(accentColor.opacity(0.8))
                    .tracking(2)
                if widgetFamily != .systemSmall {
                    Spacer()
                    HStack(spacing: 12) {
                        Text(entry.hebrewDate)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                        if !entry.nextTzet.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "moon.stars.fill").font(.system(size: 9))
                                Text(entry.nextTzet).font(.system(size: 10))
                            }.foregroundColor(accentColor.opacity(0.5))
                        }
                    }
                }
            }.padding()
        }
    }
}

@main
struct ChurbanWidgetBundle: Widget {
    let kind: String = "ChurbanWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChurbanProvider()) { entry in
            ChurbanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("זכר לחורבן")
        .description("מונה ימים מאז חורבן בית המקדש")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
SWIFT

File.write("#{widget_dir}/ChurbanWidget.swift", swift_code)
puts "✅ Created #{widget_dir}/ChurbanWidget.swift"

info_plist = <<~PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>ChurbanWidget</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
PLIST

File.write("#{widget_dir}/Info.plist", info_plist)
puts "✅ Created #{widget_dir}/Info.plist"

# === Modify the Xcode project ===
project = Xcodeproj::Project.open(PROJECT_PATH)
puts "✅ Opened #{PROJECT_PATH}"

if project.targets.any? { |t| t.name == WIDGET_NAME }
  puts "⚠️ Target '#{WIDGET_NAME}' already exists, skipping"
  exit 0
end

widget_target = project.new_target(:app_extension, WIDGET_NAME, :ios, DEPLOYMENT_TARGET)
widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['INFOPLIST_FILE'] = "#{WIDGET_NAME}/Info.plist"
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET_NAME}/#{WIDGET_NAME}.entitlements"
  config.build_settings['DEVELOPMENT_TEAM'] = TEAM_ID
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
    '$(inherited)',
    '@executable_path/Frameworks',
    '@executable_path/../../Frameworks'
  ]
end
puts "✅ Created target '#{WIDGET_NAME}'"

widget_group = project.main_group.new_group(WIDGET_NAME, widget_dir)
swift_ref = widget_group.new_file("#{widget_dir}/ChurbanWidget.swift")
widget_target.add_file_references([swift_ref])
puts "✅ Added Swift file to target"

widget_group.new_file("#{widget_dir}/Info.plist")

entitlements_content = <<~ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>#{APP_GROUP}</string>
    </array>
</dict>
</plist>
ENTITLEMENTS

File.write("#{widget_dir}/#{WIDGET_NAME}.entitlements", entitlements_content)
widget_group.new_file("#{widget_dir}/#{WIDGET_NAME}.entitlements")
puts "✅ Created widget entitlements"

runner_entitlements_path = 'ios/Runner/Runner.entitlements'
unless File.exist?(runner_entitlements_path)
  runner_ent = <<~RENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>#{APP_GROUP}</string>
    </array>
</dict>
</plist>
RENT
  File.write(runner_entitlements_path, runner_ent)
  puts "✅ Created Runner entitlements"
end

runner_target = project.targets.find { |t| t.name == 'Runner' }
if runner_target
  runner_target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
    config.build_settings['DEVELOPMENT_TEAM'] = TEAM_ID
  end
  puts "✅ Updated Runner signing"
end
# Embed widget in app bundle
embed_phase = runner_target.new_copy_files_build_phase('Embed Foundation Extensions')
embed_phase.dst_subfolder_spec = '13'
embed_phase.add_file_reference(widget_target.product_reference)
puts "✅ Added embed phase for widget"

project.save
puts "✅ Saved project"
puts "\n🎉 Widget Extension '#{WIDGET_NAME}' added successfully!"