//
//  SongListViewController.swift
//  Workshop27
//
//  Used by the "Liked Songs" tab and by playlist detail screens.
//

import UIKit

final class SongListViewController: UITableViewController {

    enum Source {
        case liked
        case playlist(Playlist)
    }

    private let source: Source
    private let library = MusicLibrary.shared
    private var songs: [Song] = []

    init(source: Source) {
        self.source = source
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        switch source {
        case .liked:
            title = "Liked Songs"
            installSettingsButton()
        case .playlist(let playlist):
            title = playlist.name
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.register(SongCell.self, forCellReuseIdentifier: SongCell.reuseID)
        // ⚠️ BAD PRACTICE: row height by idiom.
        tableView.rowHeight = Metrics.songRowHeight
        tableView.separatorInset.left = Metrics.horizontalPadding + Metrics.songArtworkSize + 12

        reloadSongs()
        installHeader()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadSongs),
                                               name: .likedSongsDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadVisibleRows),
                                               name: .nowPlayingDidChange, object: nil)
    }

    @objc private func reloadSongs() {
        switch source {
        case .liked: songs = library.likedSongs
        case .playlist(let playlist): songs = library.songs(in: playlist)
        }
        tableView.reloadData()
        (tableView.tableHeaderView as? SongListHeaderView)?.updateCount(songs.count)
        updateEmptyState()
    }

    @objc private func reloadVisibleRows() {
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: .none)
    }

    // MARK: - Header

    /// ⚠️ BAD PRACTICE: frame-based table header sized from the screen, and hidden
    /// entirely when the device is in landscape.
    private func installHeader() {
        if Device.isLandscape && Device.isPhone {
            tableView.tableHeaderView = nil
            return
        }
        let header = SongListHeaderView(frame: CGRect(x: 0, y: 0,
                                                      width: Device.screenWidth,
                                                      height: Metrics.listHeaderHeight))
        switch source {
        case .liked:
            header.configure(title: "Liked Songs", subtitle: "Songs you love, all in one place",
                             palette: 7, symbol: "heart.fill", count: songs.count)
        case .playlist(let playlist):
            header.configure(title: playlist.name, subtitle: playlist.subtitle,
                             palette: playlist.palette, symbol: playlist.symbol, count: songs.count)
        }
        header.onPlay = { [weak self] in
            guard let first = self?.songs.first else { return }
            PlayerState.shared.play(first)
        }
        header.onShuffle = { [weak self] in
            guard let song = self?.songs.randomElement() else { return }
            PlayerState.shared.play(song)
        }
        tableView.tableHeaderView = header
    }

    // ⚠️ BAD PRACTICE: header rebuilt from the orientation, `size` ignored.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.installHeader()
        }
    }

    private func updateEmptyState() {
        guard songs.isEmpty else { tableView.backgroundView = nil; return }
        let label = UILabel()
        label.text = "Songs you like will appear here.\nTap ♡ on any song."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = Metrics.titleFont
        tableView.backgroundView = label
    }

    // MARK: - Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongCell.reuseID, for: indexPath) as! SongCell
        let song = songs[indexPath.row]
        cell.configure(with: song, liked: library.isLiked(song), playing: PlayerState.shared.current == song)
        cell.onLikeTapped = { [weak self] in
            self?.library.toggleLike(song)
            if case .playlist = self?.source { self?.reloadVisibleRows() }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        PlayerState.shared.play(songs[indexPath.row])
    }

    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let song = songs[indexPath.row]
        guard library.isLiked(song) else { return nil }
        let unlike = UIContextualAction(style: .destructive, title: "Unlike") { [weak self] _, _, done in
            self?.library.toggleLike(song)
            done(true)
        }
        unlike.image = UIImage(systemName: "heart.slash")
        return UISwipeActionsConfiguration(actions: [unlike])
    }
}

// MARK: - Header view

final class SongListHeaderView: UIView {
    var onPlay: (() -> Void)?
    var onShuffle: (() -> Void)?

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let countLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        artwork.cornerRadius = 16
        titleLabel.font = .systemFont(ofSize: Device.isPad ? 34 : 24, weight: .heavy)
        titleLabel.numberOfLines = 2
        subtitleLabel.font = Metrics.subtitleFont
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        countLabel.font = Metrics.subtitleFont
        countLabel.textColor = .secondaryLabel

        let play = makeButton(title: "Play", symbol: "play.fill", filled: true, action: #selector(playTapped))
        let shuffle = makeButton(title: "Shuffle", symbol: "shuffle", filled: false, action: #selector(shuffleTapped))
        let buttons = UIStackView(arrangedSubviews: [play, shuffle])
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, countLabel, buttons])
        text.axis = .vertical
        text.spacing = 6
        text.setCustomSpacing(16, after: countLabel)

        // ⚠️ BAD PRACTICE: the idiom decides between side-by-side and stacked layout.
        let main = UIStackView(arrangedSubviews: [artwork, text])
        main.axis = Device.isPad ? .horizontal : .vertical
        main.alignment = Device.isPad ? .center : .center
        main.spacing = Device.isPad ? 28 : 16
        if Device.isPhone {
            titleLabel.textAlignment = .center
            subtitleLabel.textAlignment = .center
            countLabel.textAlignment = .center
            buttons.widthAnchor.constraint(equalToConstant: Device.screenWidth - Metrics.horizontalPadding * 2).isActive = true
        }

        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)
        let size = Metrics.listHeaderArtworkSize
        NSLayoutConstraint.activate([
            artwork.widthAnchor.constraint(equalToConstant: size),
            artwork.heightAnchor.constraint(equalToConstant: size),
            main.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            main.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            main.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        if Device.isPhone {
            main.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, palette: Int, symbol: String, count: Int) {
        artwork.configure(palette: palette, symbol: symbol)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        updateCount(count)
    }

    func updateCount(_ count: Int) {
        countLabel.text = count == 1 ? "1 song" : "\(count) songs"
    }

    private func makeButton(title: String, symbol: String, filled: Bool, action: Selector) -> UIButton {
        var config: UIButton.Configuration = filled ? .filled() : .tinted()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemPink
        config.baseForegroundColor = filled ? .white : .systemPink
        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func playTapped() { onPlay?() }
    @objc private func shuffleTapped() { onShuffle?() }
}
