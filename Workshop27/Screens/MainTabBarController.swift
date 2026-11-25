//
//  MainTabBarController.swift
//  Workshop27
//

import UIKit

final class MainTabBarController: UITabBarController {

    enum Tab: Int {
        case explore, liked

        init?(host: String?) {
            switch host {
            case "explore": self = .explore
            case "liked": self = .liked
            default: return nil
            }
        }
    }

    private let miniPlayer = MiniPlayerView()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewControllers = [
            makeTab(ExploreViewController(), title: "Explore", image: "square.grid.2x2", selected: "square.grid.2x2.fill"),
            makeTab(SongListViewController(source: .liked), title: "Liked Songs", image: "heart", selected: "heart.fill"),
        ]

        // The system positions the accessory relative to the tab bar and keeps the content of
        // every tab clear of it, wherever the tab bar is and however big the window is.
        let tap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayer.addGestureRecognizer(tap)
        updateMiniPlayer()
        NotificationCenter.default.addObserver(self, selector: #selector(updateMiniPlayer),
                                               name: .nowPlayingDidChange, object: nil)
    }

    private func makeTab(_ root: UIViewController, title: String, image: String, selected: String) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image),
                                      selectedImage: UIImage(systemName: selected))
        return nav
    }

    @objc private func updateMiniPlayer() {
        let hasSong = PlayerState.shared.current != nil
        if hasSong, bottomAccessory == nil {
            bottomAccessory = UITabAccessory(contentView: miniPlayer)
        } else if !hasSong, bottomAccessory != nil {
            bottomAccessory = nil
        }
    }

    // MARK: - Settings

    /// Opens Settings from the selected tab (nav bar button or `musiclib://settings`).
    func showSettings() {
        guard let nav = selectedViewController as? UINavigationController else { return }
        if nav.topViewController is SettingsViewController { return }
        let settings = SettingsViewController()

        // Regular width has room for a form sheet; compact width pushes. The size class
        // describes the space this window has, which the device idiom does not.
        if traitCollection.horizontalSizeClass == .regular {
            let modal = UINavigationController(rootViewController: settings)
            modal.modalPresentationStyle = .formSheet
            present(modal, animated: true)
        } else {
            nav.pushViewController(settings, animated: true)
        }
    }

    @objc private func miniPlayerTapped() {
        guard let song = PlayerState.shared.current else { return }
        SongActions.present(for: song, from: self)
    }
}
