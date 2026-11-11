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
        // ⚠️ BAD PRACTICE: reaches the root through the app delegate's window instead of
        // `view.window?.rootViewController` / the scene.
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        appDelegate?.rootTabBarController?.showSettings()
    }
}
