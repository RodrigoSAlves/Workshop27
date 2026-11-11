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
            case .diagnostics: return "What the legacy helpers believe about the space the app has. Resize the window and compare."
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

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tintColor = .systemPink
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        // ⚠️ BAD PRACTICE: on iPad the table is clamped to a fixed width; on iPhone it is
        // full width. The idiom, not the available width, decides. Use
        // `cellLayoutMarginsFollowReadableWidth` / `readableContentGuide` instead.
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        if Device.isPad {
            tableView.widthAnchor.constraint(equalToConstant: Metrics.settingsMaxWidth).isActive = true
        } else {
            tableView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadSections(IndexSet(integer: Section.diagnostics.rawValue), with: .none)
    }

    // ⚠️ BAD PRACTICE: traitCollectionDidChange(_:) is deprecated since iOS 17.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle
            || traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            tableView.reloadSections(IndexSet(integer: Section.diagnostics.rawValue), with: .none)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.tableView.reloadSections(IndexSet(integer: Section.diagnostics.rawValue), with: .none)
        }
    }

    // MARK: - Connected apps (canOpenURL)

    private var querySchemes: [String] {
        Bundle.main.object(forInfoDictionaryKey: "LSApplicationQueriesSchemes") as? [String] ?? []
    }

    /// ⚠️ BAD PRACTICE: probes every declared scheme with canOpenURL(_:).
    /// The iOS 27 SDK limits LSApplicationQueriesSchemes to 25 entries; Apple recommends
    /// calling open(_:options:completionHandler:) and handling failure instead.
    private var installedShareTargets: [String] {
        querySchemes.filter { scheme in
            guard let url = URL(string: "\(scheme)://") else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    private func openMusicApp() {
        let url = URL(string: "music://")!
        // ⚠️ BAD PRACTICE: canOpenURL gate before open.
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            let alert = UIAlertController(title: "Music not installed",
                                          message: "We couldn't find the Music app on this device.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
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
        case .connectedApps: return 2
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
            if indexPath.row == 0 {
                content.text = "Open in Music"
                content.image = UIImage(systemName: "arrow.up.forward.app")
                cell.accessoryType = .disclosureIndicator
            } else {
                content.text = "Share Destinations"
                content.secondaryText = "\(installedShareTargets.count) of \(querySchemes.count) apps detected"
                content.image = UIImage(systemName: "square.and.arrow.up")
                cell.selectionStyle = .none
            }
            content.imageProperties.tintColor = .systemPink

        case .diagnostics:
            cell.selectionStyle = .none
            content = UIListContentConfiguration.valueCell()
            let rows: [(String, String)] = [
                ("Idiom", Device.isPad ? "pad" : "phone"),
                ("UIScreen.main", "\(Int(Device.screenWidth)) × \(Int(Device.screenHeight)) @\(Int(Device.scale))x"),
                ("View bounds", "\(Int(view.bounds.width)) × \(Int(view.bounds.height))"),
                ("Orientation", Device.isLandscape ? "landscape" : "portrait"),
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
        case .connectedApps where indexPath.row == 0:
            openMusicApp()
        default:
            break
        }
    }
}
