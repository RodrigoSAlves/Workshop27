//
//  ArtworkView.swift
//  Workshop27
//
//  Placeholder album artwork: a gradient with an SF Symbol.
//

import UIKit

final class ArtworkView: UIView {

    private let gradient = CAGradientLayer()
    private let symbolView = UIImageView()
    private var palette = 0

    var cornerRadius: CGFloat = Style.artworkCornerRadius {
        didSet { layer.cornerRadius = cornerRadius }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = cornerRadius

        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradient, at: 0)

        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.contentMode = .scaleAspectFit
        symbolView.tintColor = UIColor.white.withAlphaComponent(0.9)
        addSubview(symbolView)
        NSLayoutConstraint.activate([
            symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.42),
            symbolView.heightAnchor.constraint(equalTo: symbolView.widthAnchor),
        ])
        setNeedsUpdateProperties()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(palette: Int, symbol: String) {
        self.palette = palette
        symbolView.image = UIImage(systemName: symbol)
        setNeedsUpdateProperties()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        CATransaction.commit()
    }

    /// Reads `traitCollection`, so UIKit re-runs it automatically when the appearance or
    /// the display scale changes (iOS 26+). No manual trait observation needed.
    override func updateProperties() {
        super.updateProperties()
        layer.borderWidth = 1 / traitCollection.displayScale
        applyColors()
    }

    private func applyColors() {
        let (start, end) = ArtworkPalette.colors(palette)
        gradient.colors = [start.resolvedColor(with: traitCollection).cgColor,
                           end.resolvedColor(with: traitCollection).cgColor]
        layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }
}
