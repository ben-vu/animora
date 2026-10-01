//
//  LogEpisodeWatchedUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 24/9/2026.
//

import Foundation

/// The ways ticking off an episode can go wrong.
///
/// The viewer can meet these in the app or on the widget. The widget has no room to
/// show a message, so in practice these are shown in the app, and the widget just
/// redraws with whatever is true now.
enum LogEpisodeWatchedError: LocalizedError, Equatable {

    /// The anime isn't on the Now watching list, usually because it was just finished
    /// or removed on another screen.
    case notOnWatchlist

    /// Every episode has already been ticked off.
    case alreadyFinished(animeTitle: String)

    var errorDescription: String? {
        switch self {

        case .notOnWatchlist:
            return "That anime isn't on your Now watching list any more. Pull down to refresh the list, or pick something new from the home screen."

        case .alreadyFinished(let animeTitle):
            return "You've already ticked off every episode of \(animeTitle). Tap Find your next anime to pick something new."
        }
    }
}

/// Ticks off one episode of something the viewer is watching.
///
/// This is what both the "Watched episode 4" button in the app and the button on the
/// Up next widget do. It lives in the Shared folder so that the widget runs exactly
/// the same rules as the app, instead of a second copy that could drift.
///
/// Business rules:
/// 1. You can only tick off an episode of something on your Now watching list.
/// 2. You can't tick off more episodes than the series has.
/// 3. Ticking off the final episode finishes the series. It comes off the Now
///    watching list and goes into the watch history, so it is never suggested again
///    and the widget moves on to the next thing.
struct LogEpisodeWatchedUseCase {

    let watchlist: WatchlistRepository
    let watchHistory: WatchHistoryRepository

    /// Ticks off the next episode.
    ///
    /// - Parameters:
    ///   - animeID: which anime the viewer watched an episode of.
    ///   - date: when. Passed in so the tests can use a fixed date.
    /// - Returns: the entry after the change. Check `isFinished` to see whether that
    ///   was the last episode.
    /// - Throws: a `LogEpisodeWatchedError` explaining what went wrong.
    @discardableResult
    func execute(animeID: Int, on date: Date = Date()) throws -> WatchlistEntry {

        // Rule 1: it has to be on the list.
        guard var entry = watchlist.entry(forAnimeID: animeID) else {
            throw LogEpisodeWatchedError.notOnWatchlist
        }

        // Rule 2: no ticking past the last episode. This mostly guards against a
        // double tap on the widget arriving after the show was already finished.
        if entry.isFinished {
            throw LogEpisodeWatchedError.alreadyFinished(animeTitle: entry.anime.title)
        }

        entry.episodesWatched += 1
        entry.updatedAt = date

        // Rule 3: the last episode finishes the series.
        if entry.isFinished {
            let record = WatchedAnimeRecord(
                animeID: entry.anime.id,
                animeTitle: entry.anime.title,
                markedAt: date,
                reason: .finishedWithAnimora
            )

            if watchHistory.hasWatched(animeID: entry.anime.id) == false {
                watchHistory.add(record, anime: entry.anime)
            }
            watchlist.remove(animeID: entry.anime.id)
        } else {
            watchlist.update(entry)
        }

        return entry
    }
}
