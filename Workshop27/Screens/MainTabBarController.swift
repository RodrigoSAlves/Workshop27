//
//  MainTabBarController.swift
//  Workshop27
//

import UIKit

final class MainTabBarController: UITabBarController {

    enum Tab: Int {
        case explore, liked, settings

        init?(host: String?) {
            switch host {
            case "explore": self = .explore
            case "liked": self = .liked
            case "settings": self = .settings
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
            makeTab(SettingsViewController(), title: "Settings", image: "gearshape", selected: "gearshape.fill"),
        ]

        view.addSubview(miniPlayer)
        let tap = UITapGestureRecognizer(target: self, action: #selector(miniPlayerTapped))
        miniPlayer.addGestureRecognizer(tap)
    }

    private func makeTab(_ root: UIViewController, title: String, image: String, selected: String) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: image),
                                      selectedImage: UIImage(systemName: selected))
        // Leave room for the floating mini player.
        nav.additionalSafeAreaInsets.bottom = Metrics.miniPlayerHeight + 8
        return nav
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        miniPlayer.frame = miniPlayerFrame()
    }

    /// ⚠️ BAD PRACTICE: the mini player frame is computed from the *screen* size, the key
    /// window's safe area and a hard-coded tab bar height. When the window is not the
    /// size of the screen (iPad windowing, iPhone Mirroring, iPhone Duo) or the tab bar
    /// changes shape (Liquid Glass), the player ends up in the wrong place.
    private func miniPlayerFrame() -> CGRect {
        let height = Metrics.miniPlayerHeight
        let width = Device.isPad ? min(Device.screenWidth * 0.6, 640) : Device.screenWidth - 16
        let x = (Device.screenWidth - width) / 2
        let y = Device.screenHeight - Device.safeAreaBottom - Metrics.tabBarHeight - height - 8
        return CGRect(x: x, y: y, width: width, height: height)
    }

    // ⚠️ BAD PRACTICE: reacts to the device orientation instead of the new size.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape || UIDevice.current.orientation.isPortrait {
            coordinator.animate(alongsideTransition: { _ in
                self.miniPlayer.frame = self.miniPlayerFrame()
            })
        }
    }

    @objc private func miniPlayerTapped() {
        guard let song = PlayerState.shared.current else { return }
        SongActions.present(for: song, from: self)
    }
}
