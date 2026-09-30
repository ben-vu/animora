//
//  WatchHistoryRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 3/9/2026.
//

import Foundation

/// Anything that remembers what the viewer has already seen.
///
/// This is a second repository alongside `AnimeRepository`, following the same shape.
/// Keeping it behind a protocol means the Use Cases do not care whether the history
/// is held in memory, written to a file, or stored with SwiftData later on.
protocol WatchHistoryRepository {

    /// Every anime the viewer has marked as already watched.
    var watchedRecords: [WatchedAnimeRecord] { get }

    /// Saves one new record.
    func add(_ record: WatchedAnimeRecord)

    /// Whether this anime has already been marked.
    func hasWatched(animeID: Int) -> Bool
}
