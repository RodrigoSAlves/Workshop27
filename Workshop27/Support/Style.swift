//
//  Style.swift
//  Workshop27
//
//  Shared typography and spacing. Nothing here asks the device how much space it has:
//  sizes come from Dynamic Type, and layout decisions come from the container.
//

import UIKit

enum Style {

    static let horizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let interItemSpacing: CGFloat = 12
    static let artworkCornerRadius: CGFloat = 8
    static let songArtworkSize: CGFloat = 46

    /// Container width at which a row has room for the album and duration columns.
    static let wideRowWidth: CGFloat = 600

    static func font(_ size: CGFloat, weight: UIFont.Weight, style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }

    static var sectionTitleFont: UIFont { font(22, weight: .bold, style: .title2) }
    static var titleFont: UIFont { font(15, weight: .semibold, style: .subheadline) }
    static var subtitleFont: UIFont { font(13, weight: .regular, style: .footnote) }
    static var heroTitleFont: UIFont { font(30, weight: .heavy, style: .largeTitle) }
    static var headerTitleFont: UIFont { font(28, weight: .heavy, style: .title1) }
}
