//
//  AppDelegate.swift
//  Workshop27
//
//  ⚠️ LEGACY LIFE CYCLE (intentional, for the iOS 27 workshop).
//  The app delegate owns the window, handles deep links, quick actions and the
//  orientation lock. iOS 27 requires all of this to move to a UIWindowSceneDelegate.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // ⚠️ BAD PRACTICE: the app delegate owns the one and only window.
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()

        // ⚠️ BAD PRACTICE: UIWindow(frame:) is deprecated, and UIScreen.main.bounds
        // assumes the window always covers the whole device screen.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MainTabBarController()
        window?.makeKeyAndVisible()

        ThemeManager.apply(SettingsStore.shared.theme)

        // ⚠️ BAD PRACTICE: cold-launch quick actions handled from launch options.
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            _ = handle(shortcut: shortcut)
            return false
        }
        return true
    }

    // MARK: - Orientation

    // ⚠️ BAD PRACTICE: app-wide orientation lock in the app delegate (deprecated in iOS 27).
    // iPhone is locked to portrait and the layout code assumes this never changes.
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        Device.isPad ? .all : .portrait
    }

    // MARK: - Deep links (musiclib://liked, musiclib://settings, musiclib://explore)

    // ⚠️ BAD PRACTICE: URL handling in the app delegate instead of
    // scene(_:willConnectTo:options:) / scene(_:openURLContexts:).
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.scheme == "musiclib", let tab = MainTabBarController.Tab(host: url.host) else { return false }
        rootTabBarController?.selectedIndex = tab.rawValue
        return true
    }

    // ⚠️ BAD PRACTICE: quick actions in the app delegate instead of
    // windowScene(_:performActionFor:completionHandler:).
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcut: shortcutItem))
    }

    private func handle(shortcut: UIApplicationShortcutItem) -> Bool {
        guard shortcut.type.hasSuffix(".liked") else { return false }
        rootTabBarController?.selectedIndex = MainTabBarController.Tab.liked.rawValue
        return true
    }

    // MARK: - App state

    // ⚠️ BAD PRACTICE: foreground/background transitions observed on the app,
    // not per scene.
    func applicationWillResignActive(_ application: UIApplication) {
        PlayerState.shared.isPlaying = false
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: .appDidRefreshLayout, object: nil)
    }

    // MARK: - Helpers

    var rootTabBarController: MainTabBarController? {
        window?.rootViewController as? MainTabBarController
    }

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
