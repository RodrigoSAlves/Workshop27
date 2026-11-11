//
//  ExploreViewController.swift
//  Workshop27
//
//  Music lobby: featured banner, favourite playlists, new songs, mixes, recently played.
//

import UIKit

final class ExploreViewController: UIViewController {

    private let library = MusicLibrary.shared

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let banner = FeaturedBannerView()
    private var bannerHeight: NSLayoutConstraint!

    private let favoritesLayout = UICollectionViewFlowLayout()
    private lazy var favoritesGrid = UICollectionView(frame: .zero, collectionViewLayout: favoritesLayout)
    private var favoritesHeight: NSLayoutConstraint!

    private lazy var newSongsRail = HorizontalRailView(title: "New Songs") { Metrics.songCardWidth }
    private lazy var mixesRail = HorizontalRailView(title: "Made For You") { Metrics.mixCardWidth }
    private lazy var recentRail = HorizontalRailView(title: "Recently Played") { Metrics.songCardWidth }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = greeting()
        view.backgroundColor = .systemBackground

        setUpScrollView()
        setUpBanner()
        setUpFavorites()
        setUpRails()
        applyLayoutForCurrentDevice()

        NotificationCenter.default.addObserver(self, selector: #selector(applyLayoutForCurrentDevice),
                                               name: .appDidRefreshLayout, object: nil)
    }

    // MARK: - Setup

    private func setUpScrollView() {
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = Metrics.sectionSpacing

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            // ⚠️ BAD PRACTICE: content width pinned to the screen width, not the scroll view.
            contentStack.widthAnchor.constraint(equalToConstant: Device.screenWidth),
        ])
    }

    private func setUpBanner() {
        let mix = library.madeForYou[2]
        banner.configure(title: mix.name, subtitle: "Fresh picks updated every Monday",
                         palette: mix.palette, symbol: mix.symbol)
        banner.onListen = { [weak self] in self?.open(mix) }

        let container = UIView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(banner)
        bannerHeight = banner.heightAnchor.constraint(equalToConstant: Metrics.heroHeight)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: container.topAnchor),
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Metrics.horizontalPadding),
            banner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -Metrics.horizontalPadding),
            bannerHeight,
        ])
        contentStack.addArrangedSubview(container)
    }

    private func setUpFavorites() {
        let title = UILabel()
        title.text = "Your Favorite Playlists"
        title.font = Metrics.sectionTitleFont

        favoritesLayout.minimumInteritemSpacing = Metrics.interItemSpacing / 1.5
        favoritesLayout.minimumLineSpacing = Metrics.interItemSpacing / 1.5
        favoritesGrid.isScrollEnabled = false
        favoritesGrid.backgroundColor = .clear
        favoritesGrid.dataSource = self
        favoritesGrid.delegate = self
        favoritesGrid.register(PlaylistTileCell.self, forCellWithReuseIdentifier: PlaylistTileCell.reuseID)
        favoritesHeight = favoritesGrid.heightAnchor.constraint(equalToConstant: 0)
        favoritesHeight.isActive = true

        let section = UIStackView(arrangedSubviews: [title, favoritesGrid])
        section.axis = .vertical
        section.spacing = 12
        section.isLayoutMarginsRelativeArrangement = true
        section.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: Metrics.horizontalPadding,
                                                                   bottom: 0, trailing: Metrics.horizontalPadding)
        contentStack.addArrangedSubview(section)
    }

    private func setUpRails() {
        newSongsRail.setItems(library.newReleases.map(railItem))
        newSongsRail.onSelect = { [weak self] index in
            guard let self else { return }
            SongActions.present(for: self.library.newReleases[index], from: self)
        }

        mixesRail.setItems(library.madeForYou.map {
            RailItem(title: $0.name, subtitle: $0.subtitle, palette: $0.palette, symbol: $0.symbol)
        })
        mixesRail.onSelect = { [weak self] index in
            guard let self else { return }
            self.open(self.library.madeForYou[index])
        }

        recentRail.setItems(library.recentlyPlayed.map(railItem))
        recentRail.onSelect = { [weak self] index in
            guard let self else { return }
            SongActions.present(for: self.library.recentlyPlayed[index], from: self)
        }

        [newSongsRail, mixesRail, recentRail].forEach(contentStack.addArrangedSubview)
    }

    private func railItem(_ song: Song) -> RailItem {
        RailItem(title: song.title, subtitle: song.artist, palette: song.palette, symbol: song.symbol)
    }

    // MARK: - Layout

    /// ⚠️ BAD PRACTICE: every size on this screen comes from the idiom, the main screen
    /// and the orientation. It is only re-run on rotation, never when the window resizes.
    @objc private func applyLayoutForCurrentDevice() {
        bannerHeight.constant = Metrics.heroHeight

        let columns = CGFloat(Metrics.favoriteColumns)
        let available = Device.screenWidth - Metrics.horizontalPadding * 2
            - favoritesLayout.minimumInteritemSpacing * (columns - 1)
        let itemWidth = floor(available / columns)
        favoritesLayout.itemSize = CGSize(width: itemWidth, height: Metrics.favoriteTileHeight)
        let rows = ceil(CGFloat(library.favoritePlaylists.count) / columns)
        favoritesHeight.constant = rows * Metrics.favoriteTileHeight + (rows - 1) * favoritesLayout.minimumLineSpacing
        favoritesLayout.invalidateLayout()

        [newSongsRail, mixesRail, recentRail].forEach { $0.relayout() }
    }

    // ⚠️ BAD PRACTICE: deciding on orientation and ignoring `size`.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.applyLayoutForCurrentDevice()
            self.view.layoutIfNeeded()
        })
    }

    // MARK: - Navigation

    private func open(_ playlist: Playlist) {
        navigationController?.pushViewController(SongListViewController(source: .playlist(playlist)), animated: true)
    }

    private func greeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        library.favoritePlaylists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlaylistTileCell.reuseID,
                                                      for: indexPath) as! PlaylistTileCell
        cell.configure(with: library.favoritePlaylists[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        open(library.favoritePlaylists[indexPath.item])
    }
}

// MARK: - Featured banner

final class FeaturedBannerView: UIView {
    var onListen: (() -> Void)?

    private let artwork = ArtworkView()
    private let symbolView = UIImageView()
    private let eyebrow = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        artwork.cornerRadius = 16
        eyebrow.text = "FEATURED"
        eyebrow.font = .systemFont(ofSize: 12, weight: .bold)
        eyebrow.textColor = UIColor.white.withAlphaComponent(0.8)
        // ⚠️ BAD PRACTICE: font sizes by idiom and by device model.
        titleLabel.font = .systemFont(ofSize: Device.isPad ? 40 : (Device.isSmallPhone ? 24 : 30), weight: .heavy)
        titleLabel.textColor = .white
        subtitleLabel.font = Metrics.subtitleFont
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)

        var config = UIButton.Configuration.filled()
        config.title = "Listen now"
        config.image = UIImage(systemName: "play.fill")
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        button.configuration = config
        button.addTarget(self, action: #selector(listenTapped), for: .touchUpInside)

        let text = UIStackView(arrangedSubviews: [eyebrow, titleLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 4
        let stack = UIStackView(arrangedSubviews: [text, button])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 12

        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = UIColor.white.withAlphaComponent(0.35)

        [artwork, symbolView, stack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            symbolView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6),
            symbolView.widthAnchor.constraint(equalTo: symbolView.heightAnchor),
            artwork.topAnchor.constraint(equalTo: topAnchor),
            artwork.bottomAnchor.constraint(equalTo: bottomAnchor),
            artwork.leadingAnchor.constraint(equalTo: leadingAnchor),
            artwork.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, palette: Int, symbol: String) {
        artwork.configure(palette: palette, symbol: "")
        symbolView.image = UIImage(systemName: symbol)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    @objc private func listenTapped() { onListen?() }
}
