//
//  Metrics.swift
//  Workshop27
//
//  Layout constants derived from the container the view lives in, never from the
//  device. Sizes are chosen from the trait collection of the view that lays out
//  (its size class), so they follow window resizes, iPhone Mirroring, iPhone apps on
//  iPad and the iPhone Duo. Fonts use text styles so they follow Dynamic Type.
//

import UIKit

enum Metrics {

    /// "There is room for the wide layout." Reads the horizontal size class of the
    /// caller's own trait collection.
    static func isRegularWidth(_ traits: UITraitCollection) -> Bool {
        traits.horizontalSizeClass == .regular
    }

    static func horizontalPadding(for traits: UITraitCollection) -> CGFloat { isRegularWidth(traits) ? 32 : 16 }
    static func interItemSpacing(for traits: UITraitCollection) -> CGFloat { isRegularWidth(traits) ? 20 : 12 }
    static func sectionSpacing(for traits: UITraitCollection) -> CGFloat { isRegularWidth(traits) ? 36 : 24 }
    static func artworkCornerRadius(for traits: UITraitCollection) -> CGFloat { isRegularWidth(traits) ? 12 : 8 }

    // Lists
    static func songArtworkSize(for traits: UITraitCollection) -> CGFloat { isRegularWidth(traits) ? 56 : 46 }

    // Settings
    static let settingsMaxWidth: CGFloat = 640

    // MARK: - Fonts

    static var sectionTitleFont: UIFont { font(.title2, weight: .bold) }
    static var titleFont: UIFont { font(.subheadline, weight: .semibold) }
    static var subtitleFont: UIFont { font(.footnote) }

    /// A system font with a custom weight that scales with Dynamic Type like `style`.
    /// Pass `traits` to resolve the size for a specific content size category (for
    /// example, inside a compositional layout section provider); omit it for labels
    /// that set `adjustsFontForContentSizeCategory`.
    static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular,
                     compatibleWith traits: UITraitCollection? = nil) -> UIFont {
        // Base point size at the default content size category; UIFontMetrics scales it.
        let defaultCategory = UITraitCollection(preferredContentSizeCategory: .large)
        let baseSize = UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultCategory).pointSize
        let base = UIFont.systemFont(ofSize: baseSize, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: base, compatibleWith: traits)
    }
}
