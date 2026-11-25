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

    /// An explicit corner radius. When `nil`, the radius follows the size class of the
    /// space the artwork is in (see `Metrics.artworkCornerRadius(for:)`).
    var cornerRadius: CGFloat? {
        didSet { setNeedsLayout() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true

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

        // Resolved CGColors do not update by themselves; refresh them when any trait
        // that affects color appearance changes (Dark Mode, contrast, ...).
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (self: ArtworkView, _) in
            self.applyColors()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(palette: Int, symbol: String) {
        self.palette = palette
        symbolView.image = UIImage(systemName: symbol)
        applyColors()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Traits read here are tracked automatically, so a size class or display scale
        // change (for example, moving the window to another display) relays this out.
        layer.cornerRadius = cornerRadius ?? Metrics.artworkCornerRadius(for: traitCollection)
        layer.borderWidth = 1 / traitCollection.displayScale

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradient.frame = bounds
        CATransaction.commit()
    }

    private func applyColors() {
        let (start, end) = ArtworkPalette.colors(palette)
        gradient.colors = [start.resolvedColor(with: traitCollection).cgColor,
                           end.resolvedColor(with: traitCollection).cgColor]
        layer.borderColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }
}
