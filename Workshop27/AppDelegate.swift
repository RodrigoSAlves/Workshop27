//
//  AppDelegate.swift
//  Workshop27
//
//  App-level setup only. The window, URLs, quick actions and scene state live in
//  SceneDelegate (scene-based life cycle, required by the iOS 27 SDK).
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()
        return true
    }

    // MARK: - Scene sessions

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Orientation

    // Fallback for iOS 26 and earlier. On iOS 27 SceneDelegate.supportedInterfaceOrientations(for:)
    // takes over (this method is deprecated in the iOS 27 SDK).
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Device.isPad ? .all : .portrait
    }

    // MARK: - Appearance

    private func configureAppearance() {
        // ⚠️ BAD PRACTICE: font sizes picked by device idiom through appearance proxies.
        let titleSize: CGFloat = Device.isPad ? 20 : 17
        let largeTitleSize: CGFloat = Device.isPad ? 40 : (Device.isSmallPhone ? 28 : 34)

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: titleSize, weight: .semibold)]
        navAppearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: largeTitleSize, weight: .heavy)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemPink

        UITabBar.appearance().tintColor = .systemPink
    }
}

extension Notification.Name {
    static let appDidRefreshLayout = Notification.Name("appDidRefreshLayout")
}
