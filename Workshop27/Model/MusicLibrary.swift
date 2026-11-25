//
//  MusicLibrary.swift
//  Workshop27
//
//  Synthetic, in-memory music catalogue. No playback, no network.
//

import UIKit

nonisolated struct Song: Hashable, Sendable {
    let id: Int
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let palette: Int
    let symbol: String

    var formattedDuration: String {
        String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}

nonisolated struct Playlist: Hashable, Sendable {
    let id: Int
    let name: String
    let subtitle: String
    let songIDs: [Int]
    let palette: Int
    let symbol: String
}

enum ArtworkPalette {
    static let all: [(UIColor, UIColor)] = [
        (.systemPink, .systemPurple),
        (.systemOrange, .systemRed),
        (.systemTeal, .systemBlue),
        (.systemGreen, .systemTeal),
        (.systemIndigo, .systemPurple),
        (.systemYellow, .systemOrange),
        (.systemMint, .systemCyan),
        (.systemRed, .systemPink),
        (.systemBlue, .systemIndigo),
        (.systemBrown, .systemOrange),
    ]

    static func colors(_ index: Int) -> (UIColor, UIColor) { all[abs(index) % all.count] }
}

extension Notification.Name {
    static let likedSongsDidChange = Notification.Name("likedSongsDidChange")
    static let nowPlayingDidChange = Notification.Name("nowPlayingDidChange")
}

final class MusicLibrary {
    static let shared = MusicLibrary()

    let songs: [Song]
    let favoritePlaylists: [Playlist]
    let madeForYou: [Playlist]

    private let likedKey = "likedSongIDs"
    private(set) var likedIDs: [Int] {
        didSet {
            UserDefaults.standard.set(likedIDs, forKey: likedKey)
            NotificationCenter.default.post(name: .likedSongsDidChange, object: nil)
        }
    }

    private init() {
        let symbols = ["music.note", "waveform", "guitars.fill", "pianokeys", "headphones",
                       "music.mic", "hifispeaker.fill", "metronome.fill", "music.quarternote.3", "radio.fill"]
        let titles = ["Midnight Drive", "Neon Bloom", "Paper Satellites", "Golden Hour", "Low Tide",
                      "Glass Garden", "Static Hearts", "Northern Lines", "Velvet Echo", "Slow Motion City",
                      "Lighthouse", "Polaroid Summer", "Afterglow", "Cloud Atlas Road", "Ember & Ash",
                      "Wild Orchid", "Monochrome", "Signal Fire", "Daydream Avenue", "Silver Lining",
                      "Open Water", "Satellite Hearts", "First Light", "Echo Chamber"]
        let artists = ["The Lanterns", "Nova Reyes", "Kite Theory", "Mira Sol", "Atlas Club",
                       "Juniper Lane", "Copper Coast", "Vela"]
        let albums = ["Night Shift", "Bloom", "Orbit", "Coastlines", "Prism", "Analog Dreams"]

        songs = titles.enumerated().map { index, title in
            Song(id: index,
                 title: title,
                 artist: artists[index % artists.count],
                 album: albums[index % albums.count],
                 duration: TimeInterval(150 + (index * 37) % 140),
                 palette: index,
                 symbol: symbols[index % symbols.count])
        }

        let favoriteNames = ["Liked Songs Mix", "Focus Flow", "Road Trip", "Late Night Jazz",
                             "Workout Hits", "Sunday Morning", "Indie Essentials", "Throwbacks"]
        favoritePlaylists = favoriteNames.enumerated().map { index, name in
            Playlist(id: 100 + index, name: name, subtitle: "Playlist",
                     songIDs: Array(0..<24).filter { ($0 + index) % 3 != 0 },
                     palette: index + 3, symbol: symbols[(index + 2) % symbols.count])
        }

        let mixNames = ["Daily Mix 1", "Daily Mix 2", "Discover Weekly", "Release Radar", "Chill Mix", "Throwback Mix"]
        madeForYou = mixNames.enumerated().map { index, name in
            Playlist(id: 200 + index, name: name,
                     subtitle: "\(artists[index % artists.count]), \(artists[(index + 3) % artists.count]) and more",
                     songIDs: Array(0..<24).filter { ($0 * (index + 1)) % 4 != 1 },
                     palette: index + 6, symbol: symbols[(index + 5) % symbols.count])
        }

        likedIDs = UserDefaults.standard.array(forKey: likedKey) as? [Int] ?? [1, 4, 7, 10, 13, 18]
    }

    var newReleases: [Song] { Array(songs.suffix(10).reversed()) }
    var recentlyPlayed: [Song] { [2, 5, 8, 11, 14, 17, 20].map { songs[$0] } }
    var likedSongs: [Song] { likedIDs.compactMap { id in songs.first { $0.id == id } } }

    func songs(in playlist: Playlist) -> [Song] { playlist.songIDs.map { songs[$0] } }

    func isLiked(_ song: Song) -> Bool { likedIDs.contains(song.id) }

    func toggleLike(_ song: Song) {
        if let index = likedIDs.firstIndex(of: song.id) {
            likedIDs.remove(at: index)
        } else {
            likedIDs.insert(song.id, at: 0)
        }
    }
}

/// Fake "now playing" state. Nothing actually plays.
final class PlayerState {
    static let shared = PlayerState()

    var current: Song? = MusicLibrary.shared.recentlyPlayed.first { didSet { notify() } }
    var isPlaying = false { didSet { notify() } }

    func play(_ song: Song) {
        current = song
        isPlaying = true
    }

    private func notify() {
        NotificationCenter.default.post(name: .nowPlayingDidChange, object: nil)
    }
}
