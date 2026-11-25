//
//  SettingsStore.swift
//  Workshop27
//

import UIKit

enum PlaybackQuality: Int, CaseIterable {
    case low, normal, high, lossless

    var title: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .lossless: return "Lossless"
        }
    }

    var detail: String {
        switch self {
        case .low: return "24 kbit/s · saves data"
        case .normal: return "96 kbit/s"
        case .high: return "320 kbit/s"
        case .lossless: return "ALAC up to 24-bit/48 kHz"
        }
    }
}

enum AppTheme: Int, CaseIterable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var style: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class SettingsStore {
    static let shared = SettingsStore()
    private let defaults = UserDefaults.standard

    var quality: PlaybackQuality {
        get { (defaults.object(forKey: "quality") as? Int).flatMap(PlaybackQuality.init(rawValue:)) ?? .normal }
        set { defaults.set(newValue.rawValue, forKey: "quality") }
    }

    var theme: AppTheme {
        get { AppTheme(rawValue: defaults.integer(forKey: "theme")) ?? .system }
        set {
            defaults.set(newValue.rawValue, forKey: "theme")
            NotificationCenter.default.post(name: .themeDidChange, object: nil)
        }
    }

    var normalizeVolume: Bool {
        get { defaults.object(forKey: "normalizeVolume") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "normalizeVolume") }
    }

    var streamOverCellular: Bool {
        get { defaults.object(forKey: "streamOverCellular") as? Bool ?? false }
        set { defaults.set(newValue, forKey: "streamOverCellular") }
    }
}

extension Notification.Name {
    /// Posted when the theme changes. Each scene applies it to its own window.
    static let themeDidChange = Notification.Name("themeDidChange")
}
