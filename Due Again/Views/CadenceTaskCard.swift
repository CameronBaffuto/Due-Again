import SwiftUI

struct CadenceTaskCard: View {
    enum Prominence {
        case ready
        case quiet
        case muted
    }

    let task: CadenceTask
    var categorySymbol = "circle.grid.2x2"
    var prominence: Prominence = .quiet
    let onDone: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: categorySymbol)
                            .font(.title3)
                            .foregroundStyle(statusColor)
                            .frame(width: 42, height: 42)
                            .background(statusFill, in: RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 5) {
                            Text(task.title)
                                .font(.headline)
                                .foregroundStyle(titleColor)
                                .multilineTextAlignment(.leading)

                            Text(task.categoryName)
                                .font(.subheadline)
                                .foregroundStyle(Color.dueAgainSecondaryText)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: "chevron.right")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.dueAgainSecondaryText)
                            .accessibilityHidden(true)
                    }

                    Label(DisplayText.countdown(for: task), systemImage: statusSymbol)
                        .font(.subheadline.bold())
                        .foregroundStyle(statusColor)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens cadence details")

            Divider()

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(DisplayText.cadence(task.cadenceDays), systemImage: "arrow.triangle.2.circlepath")
                    Label(DisplayText.lastDone(task.lastCompletedAt), systemImage: "clock.arrow.circlepath")
                }
                .font(.subheadline)
                .foregroundStyle(Color.dueAgainSecondaryText)

                Spacer(minLength: 8)

                Button(action: onDone) {
                    Label("Done", systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon)
                }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.dueAgainGreen)
                    .disabled(task.isArchived)
                    .accessibilityIdentifier("done-\(task.id.uuidString)")
            }
        }
        .padding(16)
        .background(Color.dueAgainSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(borderColor)
        }
        .opacity(task.isArchived ? 0.65 : 1)
        .accessibilityElement(children: .contain)
    }

    private var titleColor: Color {
        prominence == .muted ? Color.dueAgainSecondaryText : Color.dueAgainInk
    }

    private var borderColor: Color {
        prominence == .ready ? statusColor.opacity(0.4) : Color.dueAgainSeparator.opacity(0.22)
    }

    private var statusColor: Color {
        switch task.status() {
        case .overdue:
            Color.dueAgainClay
        case .dueToday:
            Color.dueAgainGreen
        case .upcoming:
            Color.dueAgainBlue
        case .archived:
            Color.dueAgainSecondaryText
        }
    }

    private var statusFill: Color {
        switch task.status() {
        case .overdue:
            Color.dueAgainClayFill
        case .dueToday:
            Color.dueAgainGreenFill
        case .upcoming:
            Color.dueAgainBlueFill
        case .archived:
            Color.dueAgainElevatedSurface
        }
    }

    private var statusSymbol: String {
        switch task.status() {
        case .overdue:
            "exclamationmark.circle.fill"
        case .dueToday:
            "checkmark.circle.fill"
        case .upcoming:
            "calendar"
        case .archived:
            "archivebox"
        }
    }
}
