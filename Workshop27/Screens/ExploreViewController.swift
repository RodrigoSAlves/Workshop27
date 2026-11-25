//
//  ExploreViewController.swift
//  Workshop27
//
//  Music lobby: featured banner, favourite playlists, new songs, mixes, recently played.
//  One collection view with a compositional layout. Every size is derived from the
//  container the layout is given, so it follows the window as it is resized.
//

import UIKit

final class ExploreViewController: UIViewController {

    private enum Section: Int, CaseIterable {
        case banner, favorites, newSongs, mixes, recent

        var title: String? {
            switch self {
            case .banner: return nil
            case .favorites: return "Your Favorite Playlists"
            case .newSongs: return "New Songs"
            case .mixes: return "Made For You"
            case .recent: return "Recently Played"
            }
        }
    }

    private let library = MusicLibrary.shared

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())

    // Registrations are created once, up front. Creating them while dequeuing is an error.
    private var bannerRegistration: UICollectionView.CellRegistration<BannerCell, Playlist>!
    private let tileRegistration = UICollectionView.CellRegistration<PlaylistTileCell, Playlist> { cell, _, playlist in
        cell.configure(with: playlist)
    }
    private let cardRegistration = UICollectionView.CellRegistration<ArtworkCardCell, RailItem> { cell, _, item in
        cell.configure(title: item.title, subtitle: item.subtitle, palette: item.palette, symbol: item.symbol)
    }
    private let headerRegistration = UICollectionView.SupplementaryRegistration<SectionTitleView>(
        elementKind: UICollectionView.elementKindSectionHeader) { _, _, _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = greeting()
        installSettingsButton()
        view.backgroundColor = .systemBackground

        bannerRegistration = UICollectionView.CellRegistration<BannerCell, Playlist> { [weak self] cell, _, mix in
            cell.banner.configure(title: mix.name, subtitle: "Fresh picks updated every Monday",
                                  palette: mix.palette, symbol: mix.symbol)
            cell.banner.onListen = { self?.open(mix) }
        }

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Layout

    private func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] index, environment in
            guard let section = Section(rawValue: index) else { return nil }
            return self?.layoutSection(section, width: environment.container.effectiveContentSize.width)
        }
    }

    /// Sections are sized from the width of the container they are laid out in.
    private func layoutSection(_ section: Section, width: CGFloat) -> NSCollectionLayoutSection {
        let layoutSection: NSCollectionLayoutSection
        let pad = Style.horizontalPadding

        switch section {
        case .banner:
            let height = min(max(width * 0.4, 150), 300)
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                             heightDimension: .absolute(height)),
                                                           subitems: [item])
            layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.contentInsets = .init(top: 8, leading: pad, bottom: Style.sectionSpacing, trailing: pad)

        case .favorites:
            let columns = width < 500 ? 2 : (width < 800 ? 3 : 4)
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1 / CGFloat(columns)),
                                                                heightDimension: .fractionalHeight(1)))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                             heightDimension: .absolute(60)),
                                                           repeatingSubitem: item, count: columns)
            let spacing = Style.interItemSpacing / 1.5
            group.interItemSpacing = .fixed(spacing)
            layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.interGroupSpacing = spacing
            layoutSection.contentInsets = .init(top: 12, leading: pad, bottom: Style.sectionSpacing, trailing: pad)

        case .newSongs, .recent:
            layoutSection = railSection(cardWidth: min(max(width * 0.36, 140), 200))

        case .mixes:
            layoutSection = railSection(cardWidth: min(max(width * 0.62, 220), 300))
        }

        if section.title != nil {
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(32)),
                elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            header.contentInsets = .init(top: 0, leading: -pad, bottom: 0, trailing: -pad)
            layoutSection.boundarySupplementaryItems = [header]
        }
        return layoutSection
    }

    private func railSection(cardWidth: CGFloat) -> NSCollectionLayoutSection {
        // Square artwork plus the title and two subtitle lines, which grow with Dynamic Type.
        let height = NSCollectionLayoutDimension.estimated(cardWidth + 64)
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .absolute(cardWidth),
                                                                         heightDimension: height),
                                                       subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.interGroupSpacing = Style.interItemSpacing
        section.contentInsets = .init(top: 12, leading: Style.horizontalPadding, bottom: Style.sectionSpacing,
                                      trailing: Style.horizontalPadding)
        return section
    }

    // MARK: - Content

    private func railItem(_ song: Song) -> RailItem {
        RailItem(title: song.title, subtitle: song.artist, palette: song.palette, symbol: song.symbol)
    }

    private func railItem(_ mix: Playlist) -> RailItem {
        RailItem(title: mix.name, subtitle: mix.subtitle, palette: mix.palette, symbol: mix.symbol)
    }

    private var featuredMix: Playlist { library.madeForYou[2] }

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

// MARK: - Data source and selection

extension ExploreViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { Section.allCases.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .banner: return 1
        case .favorites: return library.favoritePlaylists.count
        case .newSongs: return library.newReleases.count
        case .mixes: return library.madeForYou.count
        case .recent: return library.recentlyPlayed.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .banner:
            return collectionView.dequeueConfiguredReusableCell(using: bannerRegistration, for: indexPath, item: featuredMix)
        case .favorites:
            return collectionView.dequeueConfiguredReusableCell(using: tileRegistration, for: indexPath,
                                                                item: library.favoritePlaylists[indexPath.item])
        case .newSongs:
            return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath,
                                                                item: railItem(library.newReleases[indexPath.item]))
        case .mixes:
            return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath,
                                                                item: railItem(library.madeForYou[indexPath.item]))
        case .recent:
            return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath,
                                                                item: railItem(library.recentlyPlayed[indexPath.item]))
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        header.titleLabel.text = Section(rawValue: indexPath.section)?.title
        return header
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch Section(rawValue: indexPath.section)! {
        case .banner: break
        case .favorites: open(library.favoritePlaylists[indexPath.item])
        case .newSongs: SongActions.present(for: library.newReleases[indexPath.item], from: self)
        case .mixes: open(library.madeForYou[indexPath.item])
        case .recent: SongActions.present(for: library.recentlyPlayed[indexPath.item], from: self)
        }
    }
}

// MARK: - Supporting views

struct RailItem {
    let title: String
    let subtitle: String
    let palette: Int
    let symbol: String
}

final class BannerCell: UICollectionViewCell {
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

final class SectionTitleView: UICollectionReusableView {
    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Style.sectionTitleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Style.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Style.horizontalPadding),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
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
        titleLabel.font = Style.heroTitleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.textColor = .white
        subtitleLabel.font = Style.subtitleFont
        subtitleLabel.adjustsFontForContentSizeCategory = true
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
