//
//  AppRepositories.swift
//  Animora
//
//  Created by Benjamin Vu on 21/9/2026.
//

import Foundation

/// The one place the app decides which real repositories it runs on.
///
/// Everything below this talks to protocols. This is the only file that names
/// `TenraiAnimeRepository` or any of the Core Data classes, so the tests and previews
/// can run the same ViewModels and Use Cases on in-memory versions instead.
///
/// They are `static let` so the whole app shares one of each. That matters for the
/// catalogue in particular, because it remembers what it has loaded.
struct AppRepositories {
    static let catalogue = TenraiAnimeRepository()
    static let watchHistory = CoreDataWatchHistoryRepository()
    static let watchlist = CoreDataWatchlistRepository()
    static let friendPicks = CoreDataFriendPickRepository()
}
