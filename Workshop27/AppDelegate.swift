//
//  AppDelegate.swift
//  Workshop27
//
//  App-wide setup only. Windows, deep links, quick actions and per-scene state live in
//  SceneDelegate.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()
        return true
    }

    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.font: Style.font(17, weight: .semibold, style: .headline)]
        navAppearance.largeTitleTextAttributes = [.font: Style.font(34, weight: .heavy, style: .largeTitle)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemPink

        UITabBar.appearance().tintColor = .systemPink
    }
}
