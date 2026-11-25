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

        // The system positions the accessory above the tab bar (or inline with it when
        // the tab bar minimizes), adapts it to the window size, and adds it to the safe
        // area of every tab, so no manual frame or inset bookkeeping is needed.
        bottomAccessory = UITabAccessory(contentView: miniPlayer)
        let tap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayer.addGestureRecognizer(tap)
    }

    private func makeTab(_ root: UIViewController, title: String, image: String, selected: String) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image),
                                      selectedImage: UIImage(systemName: selected))
        return nav
    }

    // MARK: - Settings

    /// Opens Settings from the selected tab (nav bar button or `musiclib://settings`).
    func showSettings() {
        guard let nav = selectedViewController as? UINavigationController else { return }
        if nav.topViewController is SettingsViewController { return }
        let settings = SettingsViewController()

        // The space this window has decides the presentation, not the device: a wide
        // window gets a form sheet, a narrow one gets a push.
        if traitCollection.horizontalSizeClass == .regular {
            let modal = UINavigationController(rootViewController: settings)
            modal.modalPresentationStyle = .formSheet
            modal.preferredContentSize = CGSize(width: Metrics.settingsMaxWidth, height: view.bounds.height * 0.7)
            present(modal, animated: true)
        } else {
            nav.pushViewController(settings, animated: true)
        }
    }

    @objc private func miniPlayerTapped() {
        guard let song = PlayerState.shared.current else { return }
        SongActions.present(for: song, from: self, sourceItem: miniPlayer)
    }
}
