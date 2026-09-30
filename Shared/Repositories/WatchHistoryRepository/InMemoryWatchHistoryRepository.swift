//
//  InMemoryWatchHistoryRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation

/// Keeps the watch history in memory while the app is open.
///
/// In Assessment 2 this was what the real app used. Now the real app saves the
/// history with Core Data, and this one is kept for the unit tests and the SwiftUI
/// previews, where I want a clean history every time and nothing written to disk.
///
/// This is a class rather than a struct. The detail screen adds to the history, and
/// the request screen has to see that change. If this were a struct, each Use Case
/// would quietly get its own copy and marking something as watched would appear to
/// do nothing.
class InMemoryWatchHistoryRepository: WatchHistoryRepository {

    /// The records so far.
    ///
    /// `private(set)` means anything can read the list, but only this class can
    /// change it, so nothing can add a record without going through `add`.
    private(set) var watchedRecords: [WatchedAnimeRecord] = []

    init() {
        // A brand new viewer has not watched anything yet.
    }

    func add(_ record: WatchedAnimeRecord, anime: Anime) {
        // Newest first, to match the Core Data version.
        watchedRecords.insert(record, at: 0)
    }

    func hasWatched(animeID: Int) -> Bool {
        for record in watchedRecords {
            if record.animeID == animeID {
                return true
            }
        }
        return false
    }
}
