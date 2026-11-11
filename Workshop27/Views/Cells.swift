//
//  Cells.swift
//  Workshop27
//

import UIKit

// MARK: - Compact playlist tile (Explore → "Your favorites" grid)

final class PlaylistTileCell: UICollectionViewCell {
    static let reuseID = "PlaylistTileCell"

    private let artwork = ArtworkView()
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = Metrics.artworkCornerRadius
        contentView.clipsToBounds = true

        artwork.cornerRadius = 0
        artwork.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = Metrics.titleFont
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

    func configure(with playlist: Playlist) {
        artwork.configure(palette: playlist.palette, symbol: playlist.symbol)
        nameLabel.text = playlist.name
    }
}

// MARK: - Artwork card (Explore rails)

final class ArtworkCardCell: UICollectionViewCell {
    static let reuseID = "ArtworkCardCell"

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Metrics.titleFont
        subtitleLabel.font = Metrics.subtitleFont
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = Metrics.titleFont
        artistLabel.font = Metrics.subtitleFont
        artistLabel.textColor = .secondaryLabel
        albumLabel.font = Metrics.subtitleFont
        albumLabel.textColor = .secondaryLabel
        durationLabel.font = .monospacedDigitSystemFont(ofSize: Metrics.subtitleFont.pointSize, weight: .regular)
        durationLabel.textColor = .secondaryLabel
        likeButton.tintColor = .systemPink
        likeButton.addTarget(self, action: #selector(likeTapped), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let row = UIStackView(arrangedSubviews: [artwork, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12

        // ⚠️ BAD PRACTICE: the idiom decides which columns exist. A wide iPhone window
        // (iPhone Mirroring, iPhone app on iPad) never gets the album/duration columns,
        // and a narrow iPad window (Split View, Slide Over) gets them squeezed.
        if Device.isPad {
            albumLabel.widthAnchor.constraint(equalToConstant: 220).isActive = true
            durationLabel.widthAnchor.constraint(equalToConstant: 60).isActive = true
            durationLabel.textAlignment = .right
            row.addArrangedSubview(albumLabel)
            row.addArrangedSubview(durationLabel)
        }
        row.addArrangedSubview(likeButton)

        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            artwork.widthAnchor.constraint(equalToConstant: Metrics.songArtworkSize),
            artwork.heightAnchor.constraint(equalToConstant: Metrics.songArtworkSize),
            likeButton.widthAnchor.constraint(equalToConstant: 44),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Metrics.horizontalPadding),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.horizontalPadding + 8),
            row.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        artwork.cornerRadius = 6
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
