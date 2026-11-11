//
//  SettingsButton.swift
//  Workshop27
//

import UIKit

extension UIViewController {

    /// Adds the gear button that opens Settings to this screen's navigation bar.
    func installSettingsButton() {
        let button = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
                                     primaryAction: UIAction { [weak self] _ in self?.openSettings() })
        button.accessibilityLabel = "Settings"
        navigationItem.rightBarButtonItem = button
    }

    private func openSettings() {
        // The window belongs to this view's scene, not to the app delegate.
        (view.window?.rootViewController as? MainTabBarController)?.showSettings()
    }
}
