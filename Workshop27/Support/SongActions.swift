//
//  SongActions.swift
//  Workshop27
//

import UIKit

enum SongActions {

    /// Presents Play / Like actions for a song.
    static func present(for song: Song, from viewController: UIViewController) {
        let library = MusicLibrary.shared
        let sheet = UIAlertController(title: song.title, message: song.artist, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Play", style: .default) { _ in
            PlayerState.shared.play(song)
        })
        let likeTitle = library.isLiked(song) ? "Remove from Liked Songs" : "Add to Liked Songs"
        sheet.addAction(UIAlertAction(title: likeTitle, style: .default) { _ in
            library.toggleLike(song)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // Anchored to the middle of the presenting view, wherever that view is. Compact
        // widths present the action sheet at the bottom and ignore the anchor.
        if let popover = sheet.popoverPresentationController {
            let bounds = viewController.view.bounds
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        viewController.present(sheet, animated: true)
    }
}
