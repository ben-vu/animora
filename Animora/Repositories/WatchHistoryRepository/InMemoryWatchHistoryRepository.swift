//
//  InMemoryWatchHistoryRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 3/9/2026.
//

import Foundation

/// Keeps the watch history in memory while the app is open.
///
/// Everywhere else in Animora I used structs, because a struct gets copied whenever it
/// is passed around and that is exactly what I want for records the app only reads.
///
/// This is the one place where copying would be wrong. The detail screen adds to the
/// history, and the request screen has to see that change. If this were a struct, each
/// screen would quietly get its own copy and marking something as watched would appear
/// to do nothing.
///
class InMemoryWatchHistoryRepository: WatchHistoryRepository {

    /// The records so far.
    ///
    /// `private(set)` means any screen can read the list, but only this class can
    /// change it, so nothing can add a record without going through `add`.
    private(set) var watchedRecords: [WatchedAnimeRecord] = []

    init() {
        // A brand new viewer has not watched anything yet.
    }

    func add(_ record: WatchedAnimeRecord) {
        watchedRecords.append(record)
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
