//
//  MiniPlayerView.swift
//  Workshop27
//
//  "Now playing" content shown in the tab bar controller's bottom accessory.
//  The system places and styles the accessory, so this view only lays out its content.
//

import UIKit

final class MiniPlayerView: UIView {

    private let artwork = ArtworkView()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playButton = UIButton(type: .system)
    private let progress = UIView()
    private var progressHeight: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = Metrics.titleFont
        artistLabel.font = Metrics.subtitleFont
        artistLabel.textColor = .secondaryLabel
        [titleLabel, artistLabel].forEach { $0.adjustsFontForContentSizeCategory = true }
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
        progressHeight = progress.heightAnchor.constraint(equalToConstant: 2 / traitCollection.displayScale)
        NSLayoutConstraint.activate([
            // Artwork follows the height the accessory gives us.
            artwork.heightAnchor.constraint(equalTo: heightAnchor, constant: -12),
            artwork.widthAnchor.constraint(equalTo: artwork.heightAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
            progress.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            progress.bottomAnchor.constraint(equalTo: bottomAnchor),
            progress.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.35),
            progressHeight,
        ])

        // Two physical pixels: recompute when the display scale changes (another display).
        registerForTraitChanges([UITraitDisplayScale.self]) { (self: MiniPlayerView, _) in
            self.progressHeight.constant = 2 / self.traitCollection.displayScale
        }

        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .nowPlayingDidChange, object: nil)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func refresh() {
        let state = PlayerState.shared
        guard let song = state.current else { isHidden = true; return }
        isHidden = false
        artwork.configure(palette: song.palette, symbol: song.symbol)
        titleLabel.text = song.title
        artistLabel.text = song.artist
        let symbol = state.isPlaying ? "pause.fill" : "play.fill"
        playButton.setImage(UIImage(systemName: symbol,
                                    withConfiguration: UIImage.SymbolConfiguration(textStyle: .title3)), for: .normal)
    }

    @objc private func togglePlay() {
        PlayerState.shared.isPlaying.toggle()
    }
}
