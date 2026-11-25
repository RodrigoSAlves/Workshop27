//
//  AppDelegate.swift
//  Workshop27
//
//  One-time, process-wide setup only. Windows, deep links, quick actions and
//  activation changes are handled per scene in SceneDelegate.
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
        // Text-style fonts scale with Dynamic Type instead of being picked by device idiom.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        navAppearance.titleTextAttributes = [.font: Metrics.font(.headline, weight: .semibold)]
        navAppearance.largeTitleTextAttributes = [.font: Metrics.font(.largeTitle, weight: .heavy)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = .systemPink

        UITabBar.appearance().tintColor = .systemPink
    }
}
