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

        // ⚠️ BAD PRACTICE: the popover is anchored to the centre of the *screen* only when
        // the idiom is pad. An iPhone app in a wide window, or an iPad window that is not
        // full screen, anchors to the wrong place (or crashes if the idiom check is wrong).
        if Device.isPad, let popover = sheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: Device.screenWidth / 2, y: Device.screenHeight / 2, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        viewController.present(sheet, animated: true)
    }
}
