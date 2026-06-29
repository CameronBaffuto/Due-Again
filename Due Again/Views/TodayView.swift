import SwiftUI

struct TodayView: View {
    let tasks: [CadenceTask]
    let onAdd: () -> Void
    let onEdit: (CadenceTask) -> Void
    let onComplete: (CadenceTask) -> Void

    private var dueTasks: [CadenceTask] {
        CadenceTaskFilter.dueToday(tasks)
    }

    private var activeTasks: [CadenceTask] {
        CadenceTaskFilter.active(tasks)
    }

    private var nextTasks: [CadenceTask] {
        Array(CadenceTaskFilter.upcoming(tasks, dayLimit: 14).prefix(3))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                HeaderSummaryView(
                    title: "Due Today",
                    count: dueTasks.count,
                    subtitle: dueTasks.isEmpty ? "Nothing needs attention today." : "Ready again now."
                )

                if dueTasks.isEmpty {
                    if activeTasks.isEmpty {
                        EmptyCadenceView(onAdd: onAdd)
                    } else {
                        AllCaughtUpView(nextTasks: nextTasks, onAdd: onAdd)
                    }
                } else {
                    ForEach(dueTasks) { task in
                        CadenceTaskCard(
                            task: task,
                            prominence: .ready,
                            onDone: { onComplete(task) },
                            onEdit: { onEdit(task) }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .background(Color.dueAgainBackground)
        .navigationTitle("Due Again")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onAdd) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add cadence")
            }
        }
    }
}

struct HeaderSummaryView: View {
    let title: String
    let count: Int
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color.dueAgainInk)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(count)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.dueAgainGreen)

                Text(count == 1 ? "thing due" : "things due")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.dueAgainSecondaryText)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.dueAgainSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

struct EmptyCadenceView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(Color.dueAgainGreen)
                .accessibilityHidden(true)

            Text("Never wonder when you last did it.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.dueAgainInk)

            Text("Add upkeep routines that become due again after a set number of days.")
                .font(.body)
                .foregroundStyle(Color.dueAgainSecondaryText)

            VStack(alignment: .leading, spacing: 8) {
                Text("Common cadences")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.dueAgainSecondaryText)

                ExampleRow(title: "Water cactus", cadence: "every 12 days")
                ExampleRow(title: "Clean toilets", cadence: "every 7 days")
                ExampleRow(title: "Replace air filter", cadence: "every 90 days")
            }
            .padding(14)
            .background(Color.dueAgainElevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button(action: onAdd) {
                Label("Add first cadence", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(Color.dueAgainGreen)
        }
        .padding(20)
        .background(Color.dueAgainSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.dueAgainSeparator.opacity(0.22))
        }
    }
}

private struct AllCaughtUpView: View {
    let nextTasks: [CadenceTask]
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("All caught up", systemImage: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.dueAgainGreen)

            Text("No cadences are due right now. The next items below will move here when they are ready again.")
                .font(.body)
                .foregroundStyle(Color.dueAgainSecondaryText)

            if !nextTasks.isEmpty {
                VStack(spacing: 0) {
                    ForEach(nextTasks) { task in
                        NextDueRow(task: task)

                        if task.id != nextTasks.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color.dueAgainElevatedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            Button(action: onAdd) {
                Label("Add cadence", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(Color.dueAgainGreen)
        }
        .padding(20)
        .background(Color.dueAgainSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.dueAgainSeparator.opacity(0.22))
        }
    }
}

private struct NextDueRow: View {
    let task: CadenceTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: CadenceCategory(rawValue: task.categoryName)?.symbolName ?? CadenceCategory.other.symbolName)
                .foregroundStyle(Color.dueAgainBlue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.dueAgainInk)

                Text(DisplayText.cadence(task.cadenceDays))
                    .font(.caption)
                    .foregroundStyle(Color.dueAgainSecondaryText)
            }

            Spacer()

            Text(DisplayText.countdown(for: task))
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dueAgainBlue)
        }
        .padding(12)
    }
}

private struct ExampleRow: View {
    let title: String
    let cadence: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.triangle.2.circlepath.circle")
                .foregroundStyle(Color.dueAgainBlue)

            Text(title)
                .foregroundStyle(Color.dueAgainInk)

            Spacer()

            Text(cadence)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.dueAgainSecondaryText)
        }
        .font(.subheadline)
    }
}
