//
//  SceneDelegate.swift
//  Workshop27
//
//  Owns the window for one scene and handles everything that arrives per scene:
//  deep links, Home Screen quick actions, activation changes and orientations.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var rootTabBarController: MainTabBarController? {
        window?.rootViewController as? MainTabBarController
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        self.window = window
        ThemeManager.apply(SettingsStore.shared.theme, to: windowScene)
        window.makeKeyAndVisible()

        // Cold launch from a quick action or a deep link.
        if let shortcut = connectionOptions.shortcutItem {
            _ = handle(shortcut: shortcut)
        }
        if let url = connectionOptions.urlContexts.first?.url {
            _ = handle(url: url)
        }
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

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcut: shortcutItem))
    }

    private func handle(shortcut: UIApplicationShortcutItem) -> Bool {
        guard shortcut.type.hasSuffix(".liked") else { return false }
        rootTabBarController?.selectedIndex = MainTabBarController.Tab.liked.rawValue
        return true
    }

    // MARK: - Activation

    func sceneWillResignActive(_ scene: UIScene) {
        PlayerState.shared.isPlaying = false
    }

    // MARK: - Orientation

    // TODO: Modernization - Every screen now sizes itself from its container, so the iPhone
    // portrait lock is no longer needed for layout. Delete this method to fall back to the
    // Info.plist orientations, or adopt `prefersInterfaceOrientationLocked` (iOS 26+) if the
    // lock is a product decision. Kept for now so iPhone behavior does not change.
    func supportedInterfaceOrientations(for windowScene: UIWindowScene) -> UIInterfaceOrientationMask {
        windowScene.traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }
}
