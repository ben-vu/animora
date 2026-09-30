//
//  WatchHistoryRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation

/// Anything that remembers what the viewer has already seen.
///
/// This is a second repository alongside `AnimeRepository`, following the same shape.
/// Keeping it behind a protocol means the Use Cases do not care whether the history
/// is held in memory for the tests or saved with Core Data in the real app.
protocol WatchHistoryRepository {

    /// Every anime the viewer has marked as watched, newest first.
    var watchedRecords: [WatchedAnimeRecord] { get }

    /// Saves one new record.
    ///
    /// The whole anime is passed in as well as the record, because the Core Data
    /// version keeps a copy of the anime's details. That way the history screen can
    /// still show it even with no internet.
    func add(_ record: WatchedAnimeRecord, anime: Anime)

    /// Whether this anime has already been marked.
    func hasWatched(animeID: Int) -> Bool
}
