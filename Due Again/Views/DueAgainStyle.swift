import SwiftUI
import UIKit

extension Color {
    static let dueAgainBackground = Color(.systemGroupedBackground)
    static let dueAgainSurface = Color(.secondarySystemGroupedBackground)
    static let dueAgainElevatedSurface = Color(.tertiarySystemGroupedBackground)
    static let dueAgainSeparator = Color(.separator)
    static let dueAgainInk = Color(.label)
    static let dueAgainSecondaryText = Color(.secondaryLabel)
    static let dueAgainGreen = Color(
        light: UIColor(red: 0.06, green: 0.42, blue: 0.27, alpha: 1),
        dark: UIColor(red: 0.28, green: 0.78, blue: 0.55, alpha: 1)
    )
    static let dueAgainBlue = Color(
        light: UIColor(red: 0.10, green: 0.32, blue: 0.58, alpha: 1),
        dark: UIColor(red: 0.45, green: 0.70, blue: 1.0, alpha: 1)
    )
    static let dueAgainClay = Color(
        light: UIColor(red: 0.66, green: 0.20, blue: 0.12, alpha: 1),
        dark: UIColor(red: 1.0, green: 0.48, blue: 0.36, alpha: 1)
    )
    static let dueAgainGreenFill = Color(
        light: UIColor(red: 0.88, green: 0.96, blue: 0.91, alpha: 1),
        dark: UIColor(red: 0.05, green: 0.20, blue: 0.14, alpha: 1)
    )
    static let dueAgainBlueFill = Color(
        light: UIColor(red: 0.88, green: 0.94, blue: 1.0, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.14, blue: 0.24, alpha: 1)
    )
    static let dueAgainClayFill = Color(
        light: UIColor(red: 1.0, green: 0.92, blue: 0.89, alpha: 1),
        dark: UIColor(red: 0.28, green: 0.10, blue: 0.07, alpha: 1)
    )

    private init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}
