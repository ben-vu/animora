//
//  InMemoryWatchlistRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation

/// Keeps the Now watching list in memory. Used by the unit tests and the previews.
class InMemoryWatchlistRepository: WatchlistRepository {

    /// Kept in the order they were added. `entries` sorts them when asked.
    private var storedEntries: [WatchlistEntry] = []

    init() {
        // Nothing on the go yet.
    }

    var entries: [WatchlistEntry] {
        // Most recently touched first, the same as the Core Data version.
        storedEntries.sorted { first, second in
            first.updatedAt > second.updatedAt
        }
    }

    func entry(forAnimeID animeID: Int) -> WatchlistEntry? {
        for entry in storedEntries {
            if entry.anime.id == animeID {
                return entry
            }
        }
        return nil
    }

    func add(_ entry: WatchlistEntry) {
        storedEntries.append(entry)
    }

    func update(_ entry: WatchlistEntry) {
        for index in 0..<storedEntries.count {
            if storedEntries[index].anime.id == entry.anime.id {
                storedEntries[index] = entry
            }
        }
    }

    func remove(animeID: Int) {
        var kept: [WatchlistEntry] = []
        for entry in storedEntries {
            if entry.anime.id != animeID {
                kept.append(entry)
            }
        }
        storedEntries = kept
    }
}
