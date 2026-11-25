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
    private let header = SongListHeaderView()

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
        // Rows size themselves from their content (artwork size, Dynamic Type).
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 62

        configureHeader()
        reloadSongs()
        updateHeaderVisibility()

        // A short window (for example, iPhone landscape) has no room for the big header.
        registerForTraitChanges([UITraitVerticalSizeClass.self]) { (self: SongListViewController, _) in
            self.updateHeaderVisibility()
        }

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
        header.updateCount(songs.count)
        updateEmptyState()
    }

    @objc private func reloadVisibleRows() {
        tableView.reloadRows(at: tableView.indexPathsForVisibleRows ?? [], with: .none)
    }

    // MARK: - Header

    private func configureHeader() {
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
    }

    private func updateHeaderVisibility() {
        tableView.tableHeaderView = traitCollection.verticalSizeClass == .compact ? nil : header
        view.setNeedsLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Table header views are frame-based: size the header to the table's current
        // width every layout pass, so it follows window resizes.
        guard let header = tableView.tableHeaderView else { return }
        let fitting = header.systemLayoutSizeFitting(
            CGSize(width: tableView.bounds.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        let size = CGSize(width: tableView.bounds.width, height: ceil(fitting.height))
        if header.frame.size != size {
            header.frame.size = size
            tableView.tableHeaderView = header // Reassign so the table picks up the new height.
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
    private let buttons = UIStackView()
    private let main = UIStackView()

    private var leading: NSLayoutConstraint!
    private var trailing: NSLayoutConstraint!
    private var compactTrailing: NSLayoutConstraint!
    /// Side-by-side layout: fixed artwork size and natural-width buttons.
    private var regularConstraints: [NSLayoutConstraint] = []
    /// Stacked layout: artwork at half the width, centered, full-width buttons.
    private var compactConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        artwork.cornerRadius = 16
        titleLabel.font = Metrics.font(.title1, weight: .heavy)
        titleLabel.numberOfLines = 2
        subtitleLabel.font = Metrics.subtitleFont
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        countLabel.font = Metrics.subtitleFont
        countLabel.textColor = .secondaryLabel
        [titleLabel, subtitleLabel, countLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

        let play = makeButton(title: "Play", symbol: "play.fill", filled: true, action: #selector(playTapped))
        let shuffle = makeButton(title: "Shuffle", symbol: "shuffle", filled: false, action: #selector(shuffleTapped))
        [play, shuffle].forEach(buttons.addArrangedSubview)
        buttons.spacing = 12
        buttons.distribution = .fillEqually

        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, countLabel, buttons])
        text.axis = .vertical
        text.spacing = 6
        text.setCustomSpacing(16, after: countLabel)

        [artwork, text].forEach(main.addArrangedSubview)
        main.alignment = .center
        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)

        // Pin to the safe area: a vertical bar (for example on iPhone Duo) arrives as a
        // leading or trailing inset, and the header must not slide under it.
        let safeArea = safeAreaLayoutGuide
        leading = main.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor)
        trailing = main.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor)
        NSLayoutConstraint.activate([
            leading, trailing,
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor),
            main.topAnchor.constraint(equalTo: topAnchor, constant: 24),
            main.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -24),
        ])
        regularConstraints = [
            artwork.widthAnchor.constraint(equalToConstant: 220),
        ]
        // The stacked layout spans the padded width so the buttons can fill it.
        compactTrailing = main.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor)
        compactConstraints = [
            artwork.widthAnchor.constraint(equalTo: safeArea.widthAnchor, multiplier: 0.5),
            buttons.widthAnchor.constraint(equalTo: main.widthAnchor),
            compactTrailing,
        ]

        updateLayoutForSizeClass()
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: SongListHeaderView, _) in
            self.updateLayoutForSizeClass()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// The width this header has decides between side-by-side and stacked layout.
    private func updateLayoutForSizeClass() {
        let traits = traitCollection
        let isRegular = Metrics.isRegularWidth(traits)
        main.axis = isRegular ? .horizontal : .vertical
        main.spacing = isRegular ? 28 : 16
        let alignment: NSTextAlignment = isRegular ? .natural : .center
        [titleLabel, subtitleLabel, countLabel].forEach { $0.textAlignment = alignment }

        let padding = Metrics.horizontalPadding(for: traits)
        leading.constant = padding
        trailing.constant = -padding

        compactTrailing.constant = -padding

        NSLayoutConstraint.deactivate(isRegular ? compactConstraints : regularConstraints)
        NSLayoutConstraint.activate(isRegular ? regularConstraints : compactConstraints)
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
