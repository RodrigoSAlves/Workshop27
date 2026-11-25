//
//  ExploreViewController.swift
//  Workshop27
//
//  Music lobby: featured banner, favourite playlists, new songs, mixes, recently played.
//
//  One collection view with a compositional layout. Every size comes from the layout
//  environment (the collection view's own size and traits), and UIKit re-runs the
//  section provider whenever that size or those traits change, so the screen follows
//  window resizes with no manual relayout code.
//

import UIKit

final class ExploreViewController: UIViewController {

    // Diffable identifiers must be Sendable, so they opt out of the default MainActor isolation.
    nonisolated private enum Section: Int, CaseIterable {
        case featured, favorites, newSongs, mixes, recent

        var title: String? {
            switch self {
            case .featured: return nil
            case .favorites: return "Your Favorite Playlists"
            case .newSongs: return "New Songs"
            case .mixes: return "Made For You"
            case .recent: return "Recently Played"
            }
        }
    }

    /// Each case is a distinct identifier, so a song can appear in two rails at once.
    nonisolated private enum Item: Hashable {
        case featured(Playlist)
        case favorite(Playlist)
        case newSong(Song)
        case mix(Playlist)
        case recent(Song)
    }

    private let library = MusicLibrary.shared
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = greeting()
        installSettingsButton()
        view.backgroundColor = .systemBackground

        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        configureDataSource()
        applySnapshot()
    }

    // MARK: - Layout

    private static func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, environment in
            guard let section = Section(rawValue: sectionIndex) else { return nil }
            return makeSection(section, environment: environment)
        }
    }

    private static func makeSection(_ section: Section,
                                    environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let traits = environment.traitCollection
        let container = environment.container.effectiveContentSize
        let isRegular = Metrics.isRegularWidth(traits)
        let padding = Metrics.horizontalPadding(for: traits)
        let spacing = Metrics.interItemSpacing(for: traits)
        let fullItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                                                 heightDimension: .fractionalHeight(1)))
        let layoutSection: NSCollectionLayoutSection

        switch section {
        case .featured:
            // Taller when the space is wide and regular, from the collection view's own size.
            let isWide = container.width > container.height
            let height = max(180, container.height * (isRegular && isWide ? 0.28 : 0.22))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)),
                subitems: [fullItem])
            layoutSection = NSCollectionLayoutSection(group: group)

        case .favorites:
            // As many ~230 pt columns as fit (2...4), instead of a column count per device.
            let available = container.width - padding * 2
            let columns = max(2, min(4, Int(available / 230)))
            let tileSpacing = spacing / 1.5
            let titleFont = Metrics.font(.subheadline, weight: .semibold, compatibleWith: traits)
            let height = max(isRegular ? 80 : 56, ceil(titleFont.lineHeight * 2 + 16))
            let tileWidth = floor((available - tileSpacing * CGFloat(columns - 1)) / CGFloat(columns))
            let tile = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(tileWidth),
                                                                                 heightDimension: .fractionalHeight(1)))
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)),
                subitems: [tile])
            group.interItemSpacing = .fixed(tileSpacing)
            layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.interGroupSpacing = tileSpacing

        case .newSongs, .mixes, .recent:
            let width: CGFloat
            if section == .mixes {
                width = isRegular ? 260 : container.width * 0.62
            } else {
                width = isRegular ? 180 : container.width * 0.36
            }
            let height = width + ArtworkCardCell.textHeight(for: traits)
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(width), heightDimension: .absolute(height)),
                subitems: [fullItem])
            layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.orthogonalScrollingBehavior = .continuous
            layoutSection.interGroupSpacing = spacing
        }

        layoutSection.contentInsets = NSDirectionalEdgeInsets(top: section == .featured ? 8 : 0,
                                                              leading: padding,
                                                              bottom: Metrics.sectionSpacing(for: traits),
                                                              trailing: padding)
        if section.title != nil {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(40)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            layoutSection.boundarySupplementaryItems = [header]
        }
        return layoutSection
    }

    // MARK: - Data

    private func configureDataSource() {
        let bannerRegistration = UICollectionView.CellRegistration<FeaturedBannerCell, Playlist> { [weak self] cell, _, mix in
            cell.banner.configure(title: mix.name, subtitle: "Fresh picks updated every Monday",
                                  palette: mix.palette, symbol: mix.symbol)
            cell.banner.onListen = { self?.open(mix) }
        }
        let tileRegistration = UICollectionView.CellRegistration<PlaylistTileCell, Playlist> { cell, _, playlist in
            cell.configure(with: playlist)
        }
        let cardRegistration = UICollectionView.CellRegistration<ArtworkCardCell, Item> { cell, _, item in
            switch item {
            case .newSong(let song), .recent(let song):
                cell.configure(title: song.title, subtitle: song.artist, palette: song.palette, symbol: song.symbol)
            case .mix(let mix):
                cell.configure(title: mix.name, subtitle: mix.subtitle, palette: mix.palette, symbol: mix.symbol)
            case .featured, .favorite:
                break
            }
        }

        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .featured(let mix):
                return collectionView.dequeueConfiguredReusableCell(using: bannerRegistration, for: indexPath, item: mix)
            case .favorite(let playlist):
                return collectionView.dequeueConfiguredReusableCell(using: tileRegistration, for: indexPath, item: playlist)
            case .newSong, .mix, .recent:
                return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath, item: item)
            }
        }

        let headerRegistration = UICollectionView.SupplementaryRegistration<SectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader) { [weak self] header, _, indexPath in
            header.titleLabel.text = self?.dataSource.sectionIdentifier(for: indexPath.section)?.title
        }
        dataSource.supplementaryViewProvider = { collectionView, _, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)
        snapshot.appendItems([.featured(library.madeForYou[2])], toSection: .featured)
        snapshot.appendItems(library.favoritePlaylists.map(Item.favorite), toSection: .favorites)
        snapshot.appendItems(library.newReleases.map(Item.newSong), toSection: .newSongs)
        snapshot.appendItems(library.madeForYou.map(Item.mix), toSection: .mixes)
        snapshot.appendItems(library.recentlyPlayed.map(Item.recent), toSection: .recent)
        dataSource.apply(snapshot, animatingDifferences: false)
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

extension ExploreViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        // The banner is not a tappable cell; it has its own "Listen now" button.
        if case .featured = dataSource.itemIdentifier(for: indexPath) { return false }
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case .favorite(let playlist), .mix(let playlist):
            open(playlist)
        case .newSong(let song), .recent(let song):
            SongActions.present(for: song, from: self, sourceItem: collectionView.cellForItem(at: indexPath))
        case .featured:
            break
        }
    }
}

// MARK: - Featured banner

final class FeaturedBannerCell: UICollectionViewCell {
    let banner = FeaturedBannerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        banner.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: contentView.topAnchor),
            banner.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            banner.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

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
        eyebrow.font = Metrics.font(.caption1, weight: .bold)
        eyebrow.textColor = UIColor.white.withAlphaComponent(0.8)
        // Text styles scale with Dynamic Type instead of a size per device model.
        titleLabel.font = Metrics.font(.title1, weight: .heavy)
        titleLabel.textColor = .white
        subtitleLabel.font = Metrics.subtitleFont
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        [eyebrow, titleLabel, subtitleLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

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
