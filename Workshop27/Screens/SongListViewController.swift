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
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 62
        tableView.separatorInset.left = Style.horizontalPadding + Style.songArtworkSize + 12

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

    /// Self-sizing Auto Layout header. Its height follows the table's width, see
    /// `viewDidLayoutSubviews`, so it adapts to any window size.
    private func installHeader() {
        let header = SongListHeaderView()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        let size = header.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                  withHorizontalFittingPriority: .required,
                                                  verticalFittingPriority: .fittingSizeLevel)
        if header.frame.size != CGSize(width: width, height: size.height) {
            header.frame.size = CGSize(width: width, height: size.height)
            tableView.tableHeaderView = header
        }
    }

    private func updateEmptyState() {
        guard songs.isEmpty else { tableView.backgroundView = nil; return }
        let label = UILabel()
        label.text = "Songs you like will appear here.\nTap ♡ on any song."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = Style.titleFont
        label.adjustsFontForContentSizeCategory = true
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
    private let main = UIStackView()
    private let text = UIStackView()
    private let artworkSize: NSLayoutConstraint

    /// Applied at compact width: centered column, text as wide as the header.
    private var compactConstraints: [NSLayoutConstraint] = []
    /// Applied at regular width: artwork and text side by side, leading aligned.
    private var regularConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        artworkSize = artwork.widthAnchor.constraint(equalToConstant: 200)
        super.init(frame: frame)
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 16, leading: Style.horizontalPadding,
                                                           bottom: 16, trailing: Style.horizontalPadding)
        artwork.cornerRadius = 16
        titleLabel.font = Style.headerTitleFont
        titleLabel.numberOfLines = 2
        subtitleLabel.font = Style.subtitleFont
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        countLabel.font = Style.subtitleFont
        countLabel.textColor = .secondaryLabel
        [titleLabel, subtitleLabel, countLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

        let play = makeButton(title: "Play", symbol: "play.fill", filled: true, action: #selector(playTapped))
        let shuffle = makeButton(title: "Shuffle", symbol: "shuffle", filled: false, action: #selector(shuffleTapped))
        let buttons = UIStackView(arrangedSubviews: [play, shuffle])
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        text.addArrangedSubview(titleLabel)
        text.addArrangedSubview(subtitleLabel)
        text.addArrangedSubview(countLabel)
        text.addArrangedSubview(buttons)
        text.axis = .vertical
        text.spacing = 6
        text.setCustomSpacing(16, after: countLabel)

        main.addArrangedSubview(artwork)
        main.addArrangedSubview(text)
        main.alignment = .center

        main.translatesAutoresizingMaskIntoConstraints = false
        artwork.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)

        let widthCap = artwork.widthAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.widthAnchor)
        artworkSize.priority = .defaultHigh
        NSLayoutConstraint.activate([
            artworkSize,
            widthCap,
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor),
            main.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            main.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
        ])
        compactConstraints = [
            main.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            main.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            text.widthAnchor.constraint(equalTo: main.widthAnchor),
        ]
        regularConstraints = [
            main.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            main.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
        ]
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Reads the size class from this view's own trait collection. UIKit re-runs this when it
    /// changes (iOS 26+), so the header re-arranges itself when the window is resized.
    override func updateProperties() {
        super.updateProperties()
        let regular = traitCollection.horizontalSizeClass == .regular
        main.axis = regular ? .horizontal : .vertical
        main.spacing = regular ? 28 : 16
        artworkSize.constant = regular ? 220 : 200
        let alignment: NSTextAlignment = regular ? .natural : .center
        [titleLabel, subtitleLabel, countLabel].forEach { $0.textAlignment = alignment }
        NSLayoutConstraint.deactivate(regular ? compactConstraints : regularConstraints)
        NSLayoutConstraint.activate(regular ? regularConstraints : compactConstraints)
    }

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
