//
//  ChooseAnimeUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 4/9/2026.
//

import Foundation

/// The ways choosing an anime can go wrong.
enum ChooseAnimeError: LocalizedError, Equatable {

    /// The viewer tapped 'I'll watch this' on a suggestion that is no longer the one
    /// on screen, e.g after the screen has moved on.
    case notTheCurrentSuggestion

    /// It is already on their Now watching list.
    case alreadyOnWatchlist(animeTitle: String)

    var errorDescription: String? {
        switch self {
        case .notTheCurrentSuggestion:
            return "That suggestion has already moved on. Have a look at the one on screen instead."

        case .alreadyOnWatchlist(let animeTitle):
            return "\(animeTitle) is already on your Now watching list. Open Now watching from the home screen to pick up where you left off."
        }
    }
}

/// Records which anime the viewer has decided to watch, and puts it on their Now
/// watching list.
///
/// In Assessment 2 this only returned the choice. Now it also starts the watchlist
/// entry, because choosing a show is only the start of the problem: the viewer
/// still has to remember to come back to it, which is what the list and the Up next
/// widget are for.
///
/// Business rules:
/// 1. You can only choose the anime currently being suggested. Without this rule a
///    stale tap could commit the viewer to something the app has already moved past.
/// 2. The same anime can't be on the Now watching list twice.
/// 3. A newly chosen anime starts at episode 1, with nothing watched yet.
///
/// This is its own Use Case rather than the ViewModel just setting a property, so the
/// rules live in one obvious, testable place.
struct ChooseAnimeUseCase {

    let watchlist: WatchlistRepository

    init(watchlist: WatchlistRepository = InMemoryWatchlistRepository()) {
        self.watchlist = watchlist
    }

    @discardableResult
    func execute(chosenMatch: AnimeMatch, currentSuggestion: AnimeMatch?, on date: Date = Date()) throws -> AnimeMatch {

        // Rule 1: it has to be the one on screen.
        guard let current = currentSuggestion, current.id == chosenMatch.id else {
            throw ChooseAnimeError.notTheCurrentSuggestion
        }

        // Rule 2: not already on the list.
        if watchlist.entry(forAnimeID: chosenMatch.anime.id) != nil {
            throw ChooseAnimeError.alreadyOnWatchlist(animeTitle: chosenMatch.anime.title)
        }

        // Rule 3: start from nothing watched.
        let entry = WatchlistEntry(
            anime: chosenMatch.anime,
            episodesWatched: 0,
            startedAt: date,
            updatedAt: date
        )
        watchlist.add(entry)

        return chosenMatch
    }
}
