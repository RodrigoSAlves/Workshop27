//
//  Device.swift
//  Workshop27
//
//  ⚠️ BAD PRACTICE HUB (intentional, for the iOS 27 workshop).
//  Global helpers that answer "how much space do I have?" by asking the device:
//  its idiom, its main screen and its orientation. In iOS 27 an iPhone app can run
//  at any size (iPhone Mirroring on Mac, iPhone apps on iPad, iPhone Duo), so none
//  of these answers describe the space a view actually has.
//

import UIKit

enum Device {

    // ⚠️ Idiom used as a proxy for "wide" vs "narrow".
    static var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    static var isPhone: Bool { UIDevice.current.userInterfaceIdiom == .phone }

    // ⚠️ UIScreen.main is deprecated since iOS 26 and is not the scene's size.
    static var screenWidth: CGFloat { UIScreen.main.bounds.width }
    static var screenHeight: CGFloat { UIScreen.main.bounds.height }
    static var scale: CGFloat { UIScreen.main.scale }

    // ⚠️ Device-model detection through the physical pixel size.
    // 1334 px tall = iPhone SE / 8 class devices.
    static var isSmallPhone: Bool { isPhone && UIScreen.main.nativeBounds.height <= 1334 }

    // ⚠️ Orientation used as a proxy for "wide". iPhone Mirroring always reports portrait.
    static var isLandscape: Bool {
        UIApplication.shared.statusBarOrientation.isLandscape
    }

    // ⚠️ UIApplication.shared.windows is deprecated since iOS 15 and breaks with scenes.
    static var keyWindow: UIWindow? {
        UIApplication.shared.windows.first { $0.isKeyWindow }
    }

    static var safeAreaBottom: CGFloat { keyWindow?.safeAreaInsets.bottom ?? 0 }

    // ⚠️ Hairline from the main screen scale instead of traitCollection.displayScale.
    static var hairline: CGFloat { 1 / scale }

    static var debugDescription: String {
        let idiom = isPad ? "pad" : "phone"
        let orientation = isLandscape ? "landscape" : "portrait"
        return "idiom=\(idiom) · screen=\(Int(screenWidth))×\(Int(screenHeight)) @\(Int(scale))x · \(orientation)"
    }
}

/// Layout constants derived from the device instead of the container.
enum Metrics {
    static var horizontalPadding: CGFloat { Device.isPad ? 32 : 16 }
    static var interItemSpacing: CGFloat { Device.isPad ? 20 : 12 }
    static var sectionSpacing: CGFloat { Device.isPad ? 36 : 24 }

    static var sectionTitleFont: UIFont {
        .systemFont(ofSize: Device.isPad ? 26 : (Device.isSmallPhone ? 19 : 22), weight: .bold)
    }
    static var titleFont: UIFont { .systemFont(ofSize: Device.isPad ? 17 : 15, weight: .semibold) }
    static var subtitleFont: UIFont { .systemFont(ofSize: Device.isPad ? 15 : 13, weight: .regular) }

    static var artworkCornerRadius: CGFloat { Device.isPad ? 12 : 8 }

    // Explore
    static var heroHeight: CGFloat {
        if Device.isPad { return Device.isLandscape ? Device.screenHeight * 0.28 : Device.screenHeight * 0.22 }
        return Device.isSmallPhone ? 150 : Device.screenHeight * 0.22
    }
    static var favoriteColumns: Int { Device.isPad ? (Device.isLandscape ? 4 : 3) : 2 }
    static var favoriteTileHeight: CGFloat { Device.isPad ? 80 : 56 }
    static var songCardWidth: CGFloat { Device.isPad ? 180 : Device.screenWidth * 0.36 }
    static var mixCardWidth: CGFloat { Device.isPad ? 260 : Device.screenWidth * 0.62 }

    // Lists
    static var songRowHeight: CGFloat { Device.isPad ? 76 : 62 }
    static var songArtworkSize: CGFloat { Device.isPad ? 56 : 46 }
    static var listHeaderHeight: CGFloat { Device.isPad ? 280 : Device.screenWidth * 0.5 + 170 }
    static var listHeaderArtworkSize: CGFloat { Device.isPad ? 220 : Device.screenWidth * 0.5 }

    // Mini player
    static var miniPlayerHeight: CGFloat { Device.isPad ? 72 : 60 }
    static var tabBarHeight: CGFloat { Device.isPad ? 50 : 49 } // magic number

    // Settings
    static var settingsMaxWidth: CGFloat { 640 }
}
