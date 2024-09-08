//
//  Widget_storage.swift
//  Widget storage
//
//  Created by 1Kamekame on 2024/01/23.
//

import WidgetKit
import SwiftUI

struct StorageProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let placeholderConfiguration = ConfigurationAppIntent()
        return SimpleEntry(date: Date(), configuration: placeholderConfiguration, freeStorage: "1.5 GB", maxStorage: "100.0 GB") // ダミーの空き容量を追加
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let snapshotConfiguration = ConfigurationAppIntent()
        return SimpleEntry(date: Date(), configuration: snapshotConfiguration, freeStorage: "1.5 GB", maxStorage: "100.0 GB") // ダミーの空き容量を追加
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Get available storage capacity (in bytes)
        let fileManager = FileManager.default
        do {
            let systemAttributes = try fileManager.attributesOfFileSystem(forPath: "/")
            //空き容量
            if let freeSize = systemAttributes[.systemFreeSize] as? NSNumber {
                if let maxCapacity = systemAttributes[.systemSize] as? NSNumber {
                    let formattedFreeSize = ByteCountFormatter.string(fromByteCount: freeSize.int64Value, countStyle: .file)
                    let formattedMaxCapacity = ByteCountFormatter.string(fromByteCount: maxCapacity.int64Value, countStyle: .file)
                    let entry = SimpleEntry(date: Date(), configuration: configuration, freeStorage: formattedFreeSize, maxStorage: formattedMaxCapacity)
                    entries.append(entry)
                }
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let freeStorage: String
    let maxStorage: String
}

struct Widget_storageEntryView: View {
    var entry: StorageProvider.Entry

    @Environment(\.widgetFamily) var family: WidgetFamily

    var body: some View {
        VStack {
            Spacer()
            Text("Free Storage:")
                .font(.headline)

            if family == .systemSmall {
                // 1x1サイズの場合は文字だけ表示
                Text(entry.freeStorage)
                    .font(.title)
            } else if family == .systemMedium {
                // 1x2サイズの場合は文字と横向きのバーで容量の割合を表すグラフを表示
                HStack {
                    Spacer()
                    Text(entry.freeStorage)
                        .font(.title)
                    Spacer()
                    if let unwrappedNumerator = extractDoubleFromString(entry.freeStorage), let unwrappedDenominator = extractDoubleFromString(entry.maxStorage), unwrappedDenominator != 0 {
                        let result = unwrappedNumerator / unwrappedDenominator
                        BarGraphView(storagePercentage: result)
                            .frame(width: 150, height: 20) // バーグラフのサイズを調整
                    }
                    Spacer()
                }
            }
            Spacer()
        }
        .padding()
        .cornerRadius(10)
    }
}


func extractDoubleFromString(_ inputString: String) -> Double? {
    let components = inputString.components(separatedBy: " ")

    if let doubleValueString = components.first,
       let doubleValue = Double(doubleValueString) {
        return doubleValue
    }

    return nil
}

struct BarGraphView: View {
    var storagePercentage: Double
    let colorWithAlpha = Color(red: 43.0/255.0, green: 215.0/255.0, blue: 87.0/255.0, opacity: 1.0)

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Rectangle()
                    .fill(colorWithAlpha) // 空いていない側は白
                    .frame(width: CGFloat(1 - storagePercentage) * geometry.size.width, height: geometry.size.height)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: CGFloat(storagePercentage) * geometry.size.width, height: geometry.size.height)
                    .border(Color.blue, width: 1) // 境界を青で表示
            }
        }
        .border(Color.white, width: 1) // バー全体に対するボーダー
    }
}

struct Widget_storage: Widget {
    let kind: String = "Widget_storage"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: StorageProvider()) { entry in
            Widget_storageEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Storage Widget")
        .description("Display Mac storage information.")
        .supportedFamilies([.systemSmall, .systemMedium])  // .systemSmallのみをサポートするように変更
    }
}
