//
//  Cells.swift
//  Workshop27
//

import UIKit

// MARK: - Compact playlist tile (Explore → "Your favorites" grid)

final class PlaylistTileCell: UICollectionViewCell {

    private let artwork = ArtworkView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.clipsToBounds = true

        artwork.cornerRadius = 0
        artwork.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = Metrics.titleFont
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 2
        contentView.addSubview(artwork)
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artwork.topAnchor.constraint(equalTo: contentView.topAnchor),
            artwork.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            artwork.widthAnchor.constraint(equalTo: artwork.heightAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: artwork.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Read at layout time so it follows size class changes automatically.
        contentView.layer.cornerRadius = Metrics.artworkCornerRadius(for: traitCollection)
    }

    func configure(with playlist: Playlist) {
        artwork.configure(palette: playlist.palette, symbol: playlist.symbol)
        nameLabel.text = playlist.name
    }
}

// MARK: - Artwork card (Explore rails)

final class ArtworkCardCell: UICollectionViewCell {

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Metrics.titleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = Metrics.subtitleFont
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2

        [artwork, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            artwork.topAnchor.constraint(equalTo: contentView.topAnchor),
            artwork.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            artwork.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            artwork.heightAnchor.constraint(equalTo: artwork.widthAnchor),
            titleLabel.topAnchor.constraint(equalTo: artwork.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, palette: Int, symbol: String) {
        artwork.configure(palette: palette, symbol: symbol)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    /// Height of the text block below the square artwork, for the given traits.
    static func textHeight(for traits: UITraitCollection) -> CGFloat {
        let title = Metrics.font(.subheadline, weight: .semibold, compatibleWith: traits)
        let subtitle = Metrics.font(.footnote, compatibleWith: traits)
        return ceil(8 + title.lineHeight + 2 + subtitle.lineHeight * 2)
    }
}

// MARK: - Section header (Explore)

final class SectionHeaderView: UICollectionReusableView {

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Metrics.sectionTitleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Song row (Liked Songs, playlist detail)

final class SongCell: UITableViewCell {
    static let reuseID = "SongCell"

    var onLikeTapped: (() -> Void)?

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let albumLabel = UILabel()
    private let durationLabel = UILabel()
    private let likeButton = UIButton(type: .system)

    private var artworkWidth: NSLayoutConstraint!
    private var artworkHeight: NSLayoutConstraint!
    private var rowLeading: NSLayoutConstraint!
    private var rowTrailing: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = Metrics.titleFont
        artistLabel.font = Metrics.subtitleFont
        artistLabel.textColor = .secondaryLabel
        albumLabel.font = Metrics.subtitleFont
        albumLabel.textColor = .secondaryLabel
        durationLabel.font = UIFontMetrics(forTextStyle: .footnote)
            .scaledFont(for: .monospacedDigitSystemFont(ofSize: 13, weight: .regular))
        durationLabel.textColor = .secondaryLabel
        durationLabel.textAlignment = .right
        [titleLabel, artistLabel, albumLabel, durationLabel].forEach { $0.adjustsFontForContentSizeCategory = true }
        likeButton.tintColor = .systemPink
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        // The album and duration columns always exist; the size class decides whether
        // they are shown (see `updateLayoutForSizeClass()`).
        let row = UIStackView(arrangedSubviews: [artwork, textStack, albumLabel, durationLabel, likeButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        artworkWidth = artwork.widthAnchor.constraint(equalToConstant: 0)
        artworkHeight = artwork.heightAnchor.constraint(equalToConstant: 0)
        rowLeading = row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
        rowTrailing = row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        // Below required so a hidden column (collapsed by the stack view) doesn't conflict.
        let albumWidth = albumLabel.widthAnchor.constraint(equalToConstant: 220)
        albumWidth.priority = .required - 1
        let durationWidth = durationLabel.widthAnchor.constraint(equalToConstant: 60)
        durationWidth.priority = .required - 1

        NSLayoutConstraint.activate([
            artworkWidth, artworkHeight, rowLeading, rowTrailing, albumWidth, durationWidth,
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            row.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            row.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            row.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        artwork.cornerRadius = 6

        updateLayoutForSizeClass()
        registerForTraitChanges([UITraitHorizontalSizeClass.self]) { (self: SongCell, _) in
            self.updateLayoutForSizeClass()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Wide rows (regular width) show the album and duration columns and larger artwork.
    /// This follows the space the table has, not the device: a wide iPhone window gets
    /// the columns and a narrow iPad window doesn't.
    private func updateLayoutForSizeClass() {
        let traits = traitCollection
        let isRegular = Metrics.isRegularWidth(traits)
        albumLabel.isHidden = !isRegular
        durationLabel.isHidden = !isRegular

        let artworkSize = Metrics.songArtworkSize(for: traits)
        artworkWidth.constant = artworkSize
        artworkHeight.constant = artworkSize

        let padding = Metrics.horizontalPadding(for: traits)
        rowLeading.constant = padding
        rowTrailing.constant = -padding + 8
        // The separator starts where the text starts.
        separatorInset.left = padding + artworkSize + 12
    }

    func configure(with song: Song, liked: Bool, playing: Bool) {
        artwork.configure(palette: song.palette, symbol: song.symbol)
        titleLabel.text = song.title
        titleLabel.textColor = playing ? .systemPink : .label
        artistLabel.text = song.artist
        albumLabel.text = song.album
        durationLabel.text = song.formattedDuration
        likeButton.setImage(UIImage(systemName: liked ? "heart.fill" : "heart"), for: .normal)
    }

    @objc private func likeTapped() { onLikeTapped?() }
}
