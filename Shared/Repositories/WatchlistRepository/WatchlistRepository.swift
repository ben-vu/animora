//
//  WatchlistRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation

/// Anything that remembers what the viewer is partway through.
///
/// Both the main app and the Up next widget use this, which is why it lives in the
/// Shared folder. The widget's "Watched it" button goes through exactly the same
/// protocol and Use Case as the button inside the app.
protocol WatchlistRepository {

    /// Everything the viewer is currently watching, most recently touched first.
    var entries: [WatchlistEntry] { get }

    /// The entry for one anime, or `nil` if it is not on the list.
    func entry(forAnimeID animeID: Int) -> WatchlistEntry?

    /// Puts a new anime on the list.
    func add(_ entry: WatchlistEntry)

    /// Saves a change to an entry that is already on the list, like a new episode
    /// count.
    func update(_ entry: WatchlistEntry)

    /// Takes an anime off the list, for example once it is finished.
    func remove(animeID: Int)
}
