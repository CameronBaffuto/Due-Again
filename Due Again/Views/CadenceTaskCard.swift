import SwiftUI

struct CadenceTaskCard: View {
    enum Prominence {
        case ready
        case quiet
        case muted
    }

    let task: CadenceTask
    var prominence: Prominence = .quiet
    let onDone: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                CountdownRing(daysRemaining: task.daysRemaining(), prominence: prominence)

                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(prominence == .muted ? Color.dueAgainSecondaryText : Color.dueAgainInk)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(task.categoryName, systemImage: categorySymbol)
                        Text(DisplayText.cadence(task.cadenceDays))
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.dueAgainSecondaryText)
                    .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(DisplayText.countdown(for: task))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(countdownColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(countdownFill, in: Capsule())
            }

            HStack(spacing: 10) {
                Text(DisplayText.lastDone(task.lastCompletedAt))
                    .font(.caption)
                    .foregroundStyle(Color.dueAgainSecondaryText)

                Spacer()

                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(task.title)")

                Button(action: onDone) {
                    Label("Done", systemImage: "checkmark")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.dueAgainGreen)
                .disabled(task.isArchived)
                .accessibilityIdentifier("done-\(task.id.uuidString)")
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.dueAgainSeparator.opacity(0.22))
        }
        .opacity(task.isArchived ? 0.65 : 1)
    }

    private var cardBackground: Color {
        switch prominence {
        case .ready:
            Color.dueAgainSurface
        case .quiet, .muted:
            Color.dueAgainSurface
        }
    }

    private var countdownColor: Color {
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

    private var categorySymbol: String {
        CadenceCategory(rawValue: task.categoryName)?.symbolName ?? CadenceCategory.other.symbolName
    }
}

private struct CountdownRing: View {
    let daysRemaining: Int
    let prominence: CadenceTaskCard.Prominence

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.dueAgainSeparator.opacity(0.18), lineWidth: 5)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text(centerText)
                .font(.caption2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(ringColor)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 46, height: 46)
        .accessibilityHidden(true)
    }

    private var progress: Double {
        if daysRemaining <= 0 {
            return 1
        }

        return max(0.18, min(1, Double(14 - min(daysRemaining, 14)) / 14))
    }

    private var centerText: String {
        if daysRemaining < 0 {
            return "+\(abs(daysRemaining))"
        }

        return "\(daysRemaining)"
    }

    private var ringColor: Color {
        if prominence == .muted {
            return Color.dueAgainSecondaryText
        }

        if daysRemaining < 0 {
            return Color.dueAgainClay
        }

        if daysRemaining == 0 {
            return Color.dueAgainGreen
        }

        return Color.dueAgainBlue
    }
}

private extension CadenceTaskCard {
    var countdownFill: Color {
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
}
