import SwiftUI
import WidgetKit

struct DueAgainWidgetSnapshot: Codable, Equatable {
    var dueCount: Int
    var nextTaskTitle: String?
    var nextTaskDueText: String?
    var updatedAt: Date

    static let empty = DueAgainWidgetSnapshot(
        dueCount: 0,
        nextTaskTitle: nil,
        nextTaskDueText: nil,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}

enum WidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.cambaffuto.DueAgain"
    static let key = "dueAgain.widget.snapshot"

    static func read() -> DueAgainWidgetSnapshot {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        guard
            let data = defaults.data(forKey: key),
            let snapshot = try? JSONDecoder().decode(DueAgainWidgetSnapshot.self, from: data)
        else {
            return .empty
        }

        return snapshot
    }
}

struct DueAgainTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: DueAgainWidgetSnapshot
}

struct DueAgainTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DueAgainTimelineEntry {
        DueAgainTimelineEntry(
            date: Date(),
            snapshot: DueAgainWidgetSnapshot(
                dueCount: 2,
                nextTaskTitle: "Water cactus",
                nextTaskDueText: "Due today",
                updatedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DueAgainTimelineEntry) -> Void) {
        completion(DueAgainTimelineEntry(date: Date(), snapshot: WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DueAgainTimelineEntry>) -> Void) {
        let entry = DueAgainTimelineEntry(date: Date(), snapshot: WidgetSnapshotStore.read())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct DueAgainWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DueAgainTimelineEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        case .accessoryCircular:
            AccessoryCircularView(snapshot: entry.snapshot)
        case .accessoryInline:
            Text("\(entry.snapshot.dueCount) due again")
        default:
            SmallWidgetView(snapshot: entry.snapshot)
        }
    }
}

private struct MediumWidgetView: View {
    let snapshot: DueAgainWidgetSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Due Again")
                    .font(.headline.weight(.semibold))

                Text(snapshot.dueCount == 1 ? "1 thing due today" : "\(snapshot.dueCount) things due today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Text("\(snapshot.dueCount)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.green)

                if let title = snapshot.nextTaskTitle {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Text(snapshot.nextTaskDueText ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Nothing due")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

private struct SmallWidgetView: View {
    let snapshot: DueAgainWidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Due Again")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.green)
            }

            Text("\(snapshot.dueCount)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .monospacedDigit()

            Text(snapshot.dueCount == 1 ? "thing due" : "things due")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            if let title = snapshot.nextTaskTitle {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Text(snapshot.nextTaskDueText ?? "")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } else {
                Text("Nothing due today")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.background, for: .widget)
    }
}

private struct AccessoryCircularView: View {
    let snapshot: DueAgainWidgetSnapshot

    var body: some View {
        Gauge(value: Double(snapshot.dueCount), in: 0...max(1, Double(snapshot.dueCount))) {
            Image(systemName: "checkmark.circle")
        } currentValueLabel: {
            Text("\(snapshot.dueCount)")
        }
        .gaugeStyle(.accessoryCircular)
    }
}

struct DueAgainWidget: Widget {
    let kind = "DueAgainWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DueAgainTimelineProvider()) { entry in
            DueAgainWidgetView(entry: entry)
        }
        .configurationDisplayName("Due Again")
        .description("See how many cadences are due today and what is next.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}

@main
struct DueAgainWidgetBundle: WidgetBundle {
    var body: some Widget {
        DueAgainWidget()
    }
}

#Preview(as: .systemSmall) {
    DueAgainWidget()
} timeline: {
    DueAgainTimelineEntry(
        date: Date(),
        snapshot: DueAgainWidgetSnapshot(
            dueCount: 1,
            nextTaskTitle: "Clean toilets",
            nextTaskDueText: "Due today",
            updatedAt: Date()
        )
    )
}
