//
//  MiniPlayerView.swift
//  Workshop27
//
//  "Now playing" bar shown as the tab bar controller's bottom accessory.
//

import UIKit

final class MiniPlayerView: UIView {

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let progress = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = Style.titleFont
        titleLabel.adjustsFontForContentSizeCategory = true
        artistLabel.font = Style.subtitleFont
        artistLabel.adjustsFontForContentSizeCategory = true
        artistLabel.textColor = .secondaryLabel
        playButton.tintColor = .label
        playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
        progress.backgroundColor = .systemPink
        artwork.cornerRadius = 6

        let text = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        text.axis = .vertical
        let row = UIStackView(arrangedSubviews: [artwork, text, playButton])
        row.spacing = 12
        row.alignment = .center

        [row, progress].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        let artworkSize: CGFloat = 36
        NSLayoutConstraint.activate([
            artwork.widthAnchor.constraint(equalToConstant: artworkSize),
            artwork.heightAnchor.constraint(equalToConstant: artworkSize),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor),
            progress.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.35),
            progress.heightAnchor.constraint(equalToConstant: 2),
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .nowPlayingDidChange, object: nil)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func refresh() {
        let state = PlayerState.shared
        guard let song = state.current else { return }
        artwork.configure(palette: song.palette, symbol: song.symbol)
        titleLabel.text = song.title
        artistLabel.text = song.artist
        let symbol = state.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: symbol,
                                    withConfiguration: UIImage.SymbolConfiguration(pointSize: 20)), for: .normal)
    }

    @objc private func togglePlay() {
        PlayerState.shared.isPlaying.toggle()
    }
}
