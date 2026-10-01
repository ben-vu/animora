//
//  PreviewData.swift
//  Animora
//
//  Created by Benjamin Vu on 19/9/2026.
//

import Foundation

#if DEBUG

/// Made-up data for the SwiftUI previews only.
///
/// The previews used to read the hard-coded list. Now that the real anime come from
/// the internet, the previews use these instead so they load instantly and look the
/// same every time. `#if DEBUG` keeps all of this out of the real app.
enum PreviewData {

    static let frieren = Anime(
        id: 52991,
        title: "Frieren: Beyond Journey's End",
        synopsis: "After the party of heroes defeats the Demon King, the elf mage Frieren sets out to understand the humans she travelled with.",
        episodes: 28,
        episodeMinutes: 24,
        score: 9.3,
        status: .finished,
        genres: [.adventure, .drama, .fantasy]
    )

    static let mobPsycho = Anime(
        id: 32182,
        title: "Mob Psycho 100",
        synopsis: "An immensely powerful young psychic just wants to be normal.",
        episodes: 12,
        episodeMinutes: 24,
        score: 8.5,
        status: .finished,
        genres: [.action, .comedy]
    )

    static let frierenMatch = AnimeMatch(
        anime: frieren,
        matchPercentage: 97,
        reasons: [
            "Sam told you to watch this one",
            "Matches the Fantasy you picked",
            "Rated 9.3 out of 10, which is high for this kind of show"
        ],
        friendName: "Sam"
    )

    /// A watchlist with one show on it, three episodes in.
    static func makeWatchlist() -> InMemoryWatchlistRepository {
        let watchlist = InMemoryWatchlistRepository()
        watchlist.add(WatchlistEntry(anime: frieren, episodesWatched: 3, startedAt: Date(), updatedAt: Date()))
        watchlist.add(WatchlistEntry(anime: mobPsycho, episodesWatched: 10, startedAt: Date(), updatedAt: Date().addingTimeInterval(-86_400)))
        return watchlist
    }

    /// A history with one show on it.
    static func makeHistory() -> InMemoryWatchHistoryRepository {
        let history = InMemoryWatchHistoryRepository()
        let record = WatchedAnimeRecord(animeID: mobPsycho.id, animeTitle: mobPsycho.title, markedAt: Date(), reason: .finishedWithAnimora)
        history.add(record, anime: mobPsycho)
        return history
    }

    /// Two friends' picks: one looked up, one still waiting.
    static func makeFriendPicks() -> InMemoryFriendPickRepository {
        let picks = InMemoryFriendPickRepository()
        picks.add(FriendPick(id: UUID(), sharedTitle: "Frieren", sharedLink: nil, friendName: "Sam", receivedAt: Date(), anime: frieren))
        picks.add(FriendPick(id: UUID(), sharedTitle: "Cowboy Bebop", sharedLink: nil, friendName: "Priya", receivedAt: Date()))
        return picks
    }

    static func makeRecommendationViewModel() -> RecommendationViewModel {
        RecommendationViewModel(
            repository: TenraiAnimeRepository(),
            watchlist: makeWatchlist(),
            friendPicks: makeFriendPicks()
        )
    }

    static func makeWatchlistViewModel() -> WatchlistViewModel {
        let viewModel = WatchlistViewModel(watchlist: makeWatchlist(), watchHistory: makeHistory())
        viewModel.refresh()
        return viewModel
    }

    static func makeFriendPicksViewModel() -> FriendPicksViewModel {
        let viewModel = FriendPicksViewModel(friendPicks: makeFriendPicks(), catalogue: TenraiAnimeRepository())
        viewModel.refresh()
        return viewModel
    }
}

#endif
