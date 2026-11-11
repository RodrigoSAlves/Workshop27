//
//  HorizontalRailView.swift
//  Workshop27
//
//  A titled, horizontally scrolling row of artwork cards.
//

import UIKit

struct RailItem {
    let title: String
    let subtitle: String
    let palette: Int
    let symbol: String
}

final class HorizontalRailView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {

    var onSelect: ((Int) -> Void)?

    private let titleLabel = UILabel()
    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private var heightConstraint: NSLayoutConstraint!
    private var items: [RailItem] = []
    private let cardWidth: () -> CGFloat

    /// - Parameter cardWidth: evaluated on every relayout. Callers pass values derived
    ///   from `UIScreen.main` / idiom (see `Metrics`).
    init(title: String, cardWidth: @escaping () -> CGFloat) {
        self.cardWidth = cardWidth
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.font = Metrics.sectionTitleFont

        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metrics.interItemSpacing
        layout.sectionInset = UIEdgeInsets(top: 0, left: Metrics.horizontalPadding,
                                           bottom: 0, right: Metrics.horizontalPadding)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ArtworkCardCell.self, forCellWithReuseIdentifier: ArtworkCardCell.reuseID)

        [titleLabel, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.horizontalPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.horizontalPadding),
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightConstraint,
        ])
        relayout()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setItems(_ items: [RailItem]) {
        self.items = items
        collectionView.reloadData()
    }

    /// Recomputes the card size. Called manually by the owner on rotation.
    func relayout() {
        let width = cardWidth()
        // title + 2 subtitle lines below a square artwork
        let textHeight: CGFloat = Device.isPad ? 64 : 58
        layout.itemSize = CGSize(width: width, height: width + textHeight)
        heightConstraint.constant = width + textHeight
        layout.invalidateLayout()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArtworkCardCell.reuseID,
                                                      for: indexPath) as! ArtworkCardCell
        let item = items[indexPath.item]
        cell.configure(title: item.title, subtitle: item.subtitle, palette: item.palette, symbol: item.symbol)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelect?(indexPath.item)
    }
}
