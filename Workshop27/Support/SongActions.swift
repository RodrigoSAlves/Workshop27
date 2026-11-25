//
//  SongActions.swift
//  Workshop27
//

import UIKit

enum SongActions {

    /// Presents Play / Like actions for a song.
    /// - Parameter sourceItem: the view or bar item the user tapped. When the sheet is
    ///   shown as a popover (regular width), it points at this item.
    static func present(for song: Song, from viewController: UIViewController,
                        sourceItem: UIPopoverPresentationControllerSourceItem? = nil) {
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

        // UIKit decides whether the sheet becomes a popover from the size class of the
        // presenting context. Always give it an anchor; it is ignored when not needed.
        if let popover = sheet.popoverPresentationController {
            if let sourceItem {
                popover.sourceItem = sourceItem
            } else {
                let view: UIView = viewController.view
                popover.sourceView = view
                popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
        }
        viewController.present(sheet, animated: true)
    }
}
