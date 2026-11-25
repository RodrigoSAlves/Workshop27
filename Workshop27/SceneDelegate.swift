//
//  SceneDelegate.swift
//  Workshop27
//
//  Owns the window, deep links, quick actions and per-scene life cycle.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var rootTabBarController: MainTabBarController? {
        window?.rootViewController as? MainTabBarController
    }

    // MARK: - Connection

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        window.overrideUserInterfaceStyle = SettingsStore.shared.theme.style
        window.makeKeyAndVisible()
        self.window = window

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange),
                                               name: .themeDidChange, object: nil)

        // Cold-launch quick action and deep links.
        if let shortcut = connectionOptions.shortcutItem {
            _ = handle(shortcut: shortcut)
        }
        if let context = connectionOptions.urlContexts.first {
            _ = handle(url: context.url)
        }
    }

    @objc private func themeDidChange() {
        window?.overrideUserInterfaceStyle = SettingsStore.shared.theme.style
    }

    // MARK: - Deep links (musiclib://liked, musiclib://settings, musiclib://explore)

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = handle(url: url)
    }

    private func handle(url: URL) -> Bool {
        guard url.scheme == "musiclib" else { return false }
        if url.host == "settings" {
            rootTabBarController?.showSettings()
            return true
        }
        guard let tab = MainTabBarController.Tab(host: url.host) else { return false }
        rootTabBarController?.selectedIndex = tab.rawValue
        return true
    }

    // MARK: - Quick actions

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcut: shortcutItem))
    }

    private func handle(shortcut: UIApplicationShortcutItem) -> Bool {
        guard shortcut.type.hasSuffix(".liked") else { return false }
        rootTabBarController?.selectedIndex = MainTabBarController.Tab.liked.rawValue
        return true
    }

    // MARK: - Scene state

    func sceneWillResignActive(_ scene: UIScene) {
        PlayerState.shared.isPlaying = false
    }
}
