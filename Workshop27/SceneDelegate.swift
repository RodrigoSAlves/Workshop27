//
//  SceneDelegate.swift
//  Workshop27
//
//  Scene-based life cycle, required for apps built with the iOS 27 SDK.
//  Owns the window and receives URLs, quick actions and foreground/background
//  transitions that used to arrive on the app delegate.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var rootTabBarController: MainTabBarController? {
        window?.rootViewController as? MainTabBarController
    }

    // MARK: - Connection (cold launch)

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        self.window = window
        window.makeKeyAndVisible()

        ThemeManager.apply(SettingsStore.shared.theme)

        // Cold launches from a URL or a quick action arrive here, not in
        // application(_:didFinishLaunchingWithOptions:).
        if let url = connectionOptions.urlContexts.first?.url {
            handle(url: url)
        }
        if let shortcut = connectionOptions.shortcutItem {
            handle(shortcut: shortcut)
        }
    }

    // MARK: - While running

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handle(url: url)
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handle(shortcut: shortcutItem))
    }

    // MARK: - Orientation

    // iOS 27+: per-scene orientation preference (ignored in resizable environments).
    // On iOS 26 the app delegate's application(_:supportedInterfaceOrientationsFor:) still applies.
    @available(iOS 27.0, *)
    func supportedInterfaceOrientations(for windowScene: UIWindowScene) -> UIInterfaceOrientationMask {
        Device.isPad ? .all : .portrait
    }

    // MARK: - Scene state

    func sceneWillResignActive(_ scene: UIScene) {
        PlayerState.shared.isPlaying = false
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        NotificationCenter.default.post(name: .appDidRefreshLayout, object: nil)
    }

    // MARK: - Routing (musiclib://explore, musiclib://liked, musiclib://settings)

    private func handle(url: URL) {
        guard url.scheme == "musiclib" else { return }
        if url.host == "settings" {
            rootTabBarController?.showSettings()
        } else if let tab = MainTabBarController.Tab(host: url.host) {
            rootTabBarController?.selectedIndex = tab.rawValue
        }
    }

    @discardableResult
    private func handle(shortcut: UIApplicationShortcutItem) -> Bool {
        guard shortcut.type.hasSuffix(".liked") else { return false }
        rootTabBarController?.selectedIndex = MainTabBarController.Tab.liked.rawValue
        return true
    }
}
