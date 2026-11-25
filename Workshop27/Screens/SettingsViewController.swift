//
//  SettingsViewController.swift
//  Workshop27
//
//  Playback quality, theme appearance, connected apps and a layout diagnostics panel.
//

import UIKit

final class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int, CaseIterable {
        case quality, playback, appearance, connectedApps, diagnostics

        var title: String {
            switch self {
            case .quality: return "Streaming Quality"
            case .playback: return "Playback"
            case .appearance: return "Appearance"
            case .connectedApps: return "Connected Apps"
            case .diagnostics: return "Layout Diagnostics"
            }
        }

        var footer: String? {
            switch self {
            case .quality: return "Higher quality uses more data."
            case .diagnostics: return "The space this screen actually has. Resize the window and watch it follow."
            default: return nil
            }
        }
    }

    private let store = SettingsStore.shared
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let cellID = "SettingsCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = .systemGroupedBackground

        if navigationController?.viewControllers.first === self {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                systemItem: .done,
                primaryAction: UIAction { [weak self] _ in self?.dismiss(animated: true) })
        } else {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tintColor = .systemPink
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // Rows follow the readable width, so the table reads well in any window size.
        tableView.cellLayoutMarginsFollowReadableWidth = true
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        registerForTraitChanges([UITraitUserInterfaceStyle.self, UITraitHorizontalSizeClass.self]) { (self: Self, _) in
            self.reloadDiagnostics()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadDiagnostics()
    }

    private func reloadDiagnostics() {
        tableView.reloadSections(IndexSet(integer: Section.diagnostics.rawValue), with: .none)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.reloadDiagnostics()
        }
    }

    // MARK: - Connected apps

    /// Opens the URL through this window's scene and handles failure, instead of probing with
    /// `canOpenURL` first (which needs `LSApplicationQueriesSchemes`).
    private func openMusicApp() {
        guard let scene = view.window?.windowScene else { return }
        scene.open(URL(string: "music://")!, options: nil) { [weak self] success in
            guard !success else { return }
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Music not installed",
                                              message: "We couldn't find the Music app on this device.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
    }

    // MARK: - Data source

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        Section(rawValue: section)?.footer
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .quality: return PlaybackQuality.allCases.count
        case .playback: return 2
        case .appearance: return AppTheme.allCases.count
        case .connectedApps: return 1
        case .diagnostics: return 4
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        cell.accessoryType = .none
        cell.accessoryView = nil
        cell.selectionStyle = .default
        var content = UIListContentConfiguration.subtitleCell()
        content.secondaryTextProperties.color = .secondaryLabel

        switch Section(rawValue: indexPath.section)! {
        case .quality:
            let quality = PlaybackQuality.allCases[indexPath.row]
            content.text = quality.title
            content.secondaryText = quality.detail
            cell.accessoryType = quality == store.quality ? .checkmark : .none

        case .playback:
            let toggle = UISwitch()
            toggle.onTintColor = .systemPink
            if indexPath.row == 0 {
                content.text = "Normalize Volume"
                content.secondaryText = "Play all songs at the same loudness"
                toggle.isOn = store.normalizeVolume
                toggle.addAction(UIAction { [weak self] action in
                    self?.store.normalizeVolume = (action.sender as? UISwitch)?.isOn ?? false
                }, for: .valueChanged)
            } else {
                content.text = "Stream over Cellular"
                content.secondaryText = "May incur additional charges"
                toggle.isOn = store.streamOverCellular
                toggle.addAction(UIAction { [weak self] action in
                    self?.store.streamOverCellular = (action.sender as? UISwitch)?.isOn ?? false
                }, for: .valueChanged)
            }
            cell.accessoryView = toggle
            cell.selectionStyle = .none

        case .appearance:
            let theme = AppTheme.allCases[indexPath.row]
            content.text = theme.title
            content.image = UIImage(systemName: ["circle.lefthalf.filled", "sun.max", "moon"][indexPath.row])
            content.imageProperties.tintColor = .systemPink
            cell.accessoryType = theme == store.theme ? .checkmark : .none

        case .connectedApps:
            content.text = "Open in Music"
            content.image = UIImage(systemName: "arrow.up.forward.app")
            cell.accessoryType = .disclosureIndicator
            content.imageProperties.tintColor = .systemPink

        case .diagnostics:
            cell.selectionStyle = .none
            content = UIListContentConfiguration.valueCell()
            func sizeClass(_ value: UIUserInterfaceSizeClass) -> String {
                switch value {
                case .compact: return "compact"
                case .regular: return "regular"
                default: return "unspecified"
                }
            }
            let sceneBounds = view.window?.windowScene?.effectiveGeometry.coordinateSpace.bounds ?? .zero
            let rows: [(String, String)] = [
                ("Horizontal size class", sizeClass(traitCollection.horizontalSizeClass)),
                ("Vertical size class", sizeClass(traitCollection.verticalSizeClass)),
                ("View bounds", "\(Int(view.bounds.width)) × \(Int(view.bounds.height))"),
                ("Scene bounds", "\(Int(sceneBounds.width)) × \(Int(sceneBounds.height))"),
            ]
            content.text = rows[indexPath.row].0
            content.secondaryText = rows[indexPath.row].1
        }
        cell.contentConfiguration = content
        return cell
    }

    // MARK: - Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch Section(rawValue: indexPath.section)! {
        case .quality:
            store.quality = PlaybackQuality.allCases[indexPath.row]
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        case .appearance:
            store.theme = AppTheme.allCases[indexPath.row]
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        case .connectedApps:
            openMusicApp()
        default:
            break
        }
    }
}
