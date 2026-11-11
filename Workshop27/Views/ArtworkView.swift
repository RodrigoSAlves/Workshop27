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

    var cornerRadius: CGFloat = Metrics.artworkCornerRadius {
        didSet { layer.cornerRadius = cornerRadius }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = cornerRadius
        // ⚠️ BAD PRACTICE: hairline from UIScreen.main.scale.
        layer.borderWidth = Device.hairline

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
        applyColors()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(palette: Int, symbol: String) {
        self.palette = palette
        symbolView.image = UIImage(systemName: symbol)
        applyColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        CATransaction.commit()
    }

    // ⚠️ BAD PRACTICE: traitCollectionDidChange(_:) is deprecated since iOS 17.
    // Use registerForTraitChanges(_:handler:) or automatic trait tracking (iOS 18+).
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            applyColors()
        }
    }

    private func applyColors() {
        let (start, end) = ArtworkPalette.colors(palette)
        gradient.colors = [start.resolvedColor(with: traitCollection).cgColor,
                           end.resolvedColor(with: traitCollection).cgColor]
        layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }
}
