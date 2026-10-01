//
//  WatchlistViewModel.swift
//  Animora
//
//  Created by Benjamin Vu on 20/9/2026.
//

import Foundation
import Combine

/// Holds the Now watching list and the watch history for the screens that show them.
class WatchlistViewModel: ObservableObject {

    /// Everything in progress, most recently touched first.
    @Published private(set) var entries: [WatchlistEntry] = []

    /// Everything already seen, newest first.
    @Published private(set) var history: [WatchedAnimeRecord] = []

    /// The message to show if ticking off an episode went wrong.
    @Published var errorMessage: String? = nil

    /// A short well done message, shown once when the viewer ticks off the final
    /// episode of something.
    @Published var finishedMessage: String? = nil

    private let watchlist: WatchlistRepository
    private let watchHistory: WatchHistoryRepository
    private let logEpisodeWatched: LogEpisodeWatchedUseCase

    init(watchlist: WatchlistRepository, watchHistory: WatchHistoryRepository) {
        self.watchlist = watchlist
        self.watchHistory = watchHistory
        self.logEpisodeWatched = LogEpisodeWatchedUseCase(
            watchlist: watchlist,
            watchHistory: watchHistory
        )
    }

    /// The one the viewer is most likely on right now. This is the same one the Up next
    /// widget shows, so the home screen and the widget always agree.
    var upNext: WatchlistEntry? {
        entries.first
    }

    /// Loads the latest lists.
    ///
    /// Called whenever a screen appears and whenever the app comes back to the front,
    /// because the widget can tick off episodes while the app is closed.
    func refresh() {
        entries = watchlist.entries
        history = watchHistory.watchedRecords
    }

    /// Ticks off the next episode of one show.
    func logEpisode(for entry: WatchlistEntry) {
        errorMessage = nil
        finishedMessage = nil

        do {
            let updated = try logEpisodeWatched.execute(animeID: entry.anime.id)
            if updated.isFinished {
                finishedMessage = "You finished \(updated.anime.title)! It's moved to Already seen, so it won't be suggested again."
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        refresh()
    }
}
