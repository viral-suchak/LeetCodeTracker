// LeetCodeWidget.swift
// LeetCodeWidget

import WidgetKit
import SwiftUI

// MARK: - Timeline entry & provider

struct LeetCodeEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
    let hasData: Bool
}

struct LeetCodeProvider: TimelineProvider {
    func placeholder(in context: Context) -> LeetCodeEntry {
        LeetCodeEntry(date: Date(), data: emptyWidgetData(), hasData: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (LeetCodeEntry) -> Void) {
        let stored = loadWidgetData()
        completion(LeetCodeEntry(date: Date(), data: stored ?? emptyWidgetData(), hasData: stored != nil))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LeetCodeEntry>) -> Void) {
        let stored = loadWidgetData()
        let entry = LeetCodeEntry(date: Date(), data: stored ?? emptyWidgetData(), hasData: stored != nil)
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Small widget view

struct SmallWidgetView: View {
    let data: WidgetData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(data.username)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(data.totalSolved)")
                .font(.system(size: 38, weight: .bold).monospacedDigit())

            Text("Solved")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 0) {
                DifficultyDot(count: data.easySolved,   color: .green)
                DifficultyDot(count: data.mediumSolved, color: .orange)
                DifficultyDot(count: data.hardSolved,   color: .red)
            }

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text("\(data.streak) day streak")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium widget view

struct MediumWidgetView: View {
    let data: WidgetData

    var body: some View {
        HStack(spacing: 0) {
            // Left column
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.orange)
                    Text("LeetCode")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                Text(data.username)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                Text("\(data.totalSolved)")
                    .font(.system(size: 42, weight: .bold).monospacedDigit())
                Text("Problems Solved")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if data.ranking > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "trophy.fill").font(.caption2).foregroundStyle(.yellow)
                        Text("#\(data.ranking.formatted())")
                            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .frame(maxHeight: .infinity, alignment: .leading)

            Divider().padding(.vertical, 12)

            // Right column
            VStack(alignment: .leading, spacing: 8) {
                DifficultyRow(label: "Easy",   count: data.easySolved,   total: data.totalSolved, color: .green)
                DifficultyRow(label: "Medium", count: data.mediumSolved, total: data.totalSolved, color: .orange)
                DifficultyRow(label: "Hard",   count: data.hardSolved,   total: data.totalSolved, color: .red)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").font(.caption2).foregroundStyle(.orange)
                    Text("\(data.streak) day streak")
                        .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Entry view

struct LeetCodeWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: LeetCodeProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall: SmallWidgetView(data: entry.data)
        default:           MediumWidgetView(data: entry.data)
        }
    }
}

// MARK: - Widget definition

struct LeetCodeWidget: Widget {
    let kind = "LeetCodeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LeetCodeProvider()) { entry in
            if #available(iOS 17.0, *) {
                LeetCodeWidgetEntryView(entry: entry)
                    .containerBackground(.background, for: .widget)
            } else {
                LeetCodeWidgetEntryView(entry: entry).padding().background()
            }
        }
        .configurationDisplayName("LeetCode Stats")
        .description("Solved count, streak, and difficulty breakdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Helper subviews

struct DifficultyDot: View {
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundStyle(color)
        }
        .padding(.trailing, 6)
    }
}

struct DifficultyRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color

    private var ratio: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label).font(.caption2).foregroundStyle(color)
                Spacer()
                Text("\(count)").font(.caption2.bold().monospacedDigit())
            }
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.2)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(color)
                        .frame(width: g.size.width * ratio, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    LeetCodeWidget()
} timeline: {
    LeetCodeEntry(date: .now, data: WidgetData(
        username: "neal_wu", totalSolved: 842,
        easySolved: 312, mediumSolved: 420, hardSolved: 110,
        totalQuestions: 3350, streak: 47, ranking: 12345, lastUpdated: .now
    ), hasData: true)
}

#Preview(as: .systemMedium) {
    LeetCodeWidget()
} timeline: {
    LeetCodeEntry(date: .now, data: WidgetData(
        username: "neal_wu", totalSolved: 842,
        easySolved: 312, mediumSolved: 420, hardSolved: 110,
        totalQuestions: 3350, streak: 47, ranking: 12345, lastUpdated: .now
    ), hasData: true)
}
