//
//  AnimoraTests.swift
//  AnimoraTests
//
//  Created by Benjamin Vu on 8/9/2026.
//

import Foundation
import Testing
@testable import Animora

// MARK: - A repository I control completely

/// A small fake repository used by the tests.
///
/// This is the payoff from making `AnimeRepository` a protocol. The tests hand the Use
/// Cases a tiny list written by hand, so I can work out the right answer myself and
/// check against it. A test should only fail when a rule breaks, not when I add a new
/// anime to the app.
class TestAnimeRepository: AnimeRepository {

    private(set) var anime: [Anime] = []

    init() { anime = load() }

    static let shortAction = Anime(
        id: 101, title: "Short Action Show", synopsis: "For testing.",
        episodes: 12, score: 8.0, status: .finished, genres: [.action]
    )

    static let longAction = Anime(
        id: 102, title: "Long Action Epic", synopsis: "For testing.",
        episodes: 60, score: 9.0, status: .finished, genres: [.action]
    )

    static let lowRatedAction = Anime(
        id: 103, title: "Low Rated Action Show", synopsis: "For testing.",
        episodes: 12, score: 6.4, status: .finished, genres: [.action]
    )

    static let romanceOnly = Anime(
        id: 104, title: "Romance Only Show", synopsis: "For testing.",
        episodes: 24, score: 8.5, status: .finished, genres: [.romance]
    )

    func load() -> [Anime] {
        [
            TestAnimeRepository.shortAction,
            TestAnimeRepository.longAction,
            TestAnimeRepository.lowRatedAction,
            TestAnimeRepository.romanceOnly
        ]
    }
}

/// Builds a request without repeating the same lines in every test.
func makePreferences(genres: Set<AnimeGenre> = [],
                     episodeLimit: EpisodeLimit = .any,
                     status: AnimeStatusPreference = .any) -> AnimePreferences {
    var preferences = AnimePreferences()
    preferences.genres = genres
    preferences.episodeLimit = episodeLimit
    preferences.status = status
    return preferences
}

// MARK: - Suggesting an anime

struct FindAnimeRecommendationsUseCaseTests {

    private func makeUseCase(_ history: WatchHistoryRepository = InMemoryWatchHistoryRepository())
    -> FindAnimeRecommendationsUseCase {
        FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), watchHistory: history)
    }

    @Test func bestMatchFirst() throws {
        let matches = try makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        // Three action anime qualify, and the strongest is offered first.
        #expect(matches.count == 3)
        #expect(matches[0].matchPercentage >= matches[1].matchPercentage)
        #expect(matches[1].matchPercentage >= matches[2].matchPercentage)
    }

    @Test func wrongGenreExcluded() throws {
        // A viewer who asked for Action should never be shown the romance series,
        // however well rated it is.
        let matches = try makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        #expect(!matches.contains { $0.anime.id == TestAnimeRepository.romanceOnly.id })
    }

    @Test func episodeLimitIsInclusive() throws {
        // The short action show has exactly 12 episodes and the limit is 12.
        // "Under 12" has to include 12 itself, or the boundary is off by one.
        let matches = try makeUseCase().execute(
            preferences: makePreferences(genres: [.action], episodeLimit: .under12)
        )

        #expect(matches.contains { $0.anime.id == TestAnimeRepository.shortAction.id })
    }

    @Test func errorNamesEmptyGenre() {
        // There are no sports anime in the test repository at all.
        #expect(throws: FindAnimeRecommendationsError.noAnimeInChosenGenres(genreNames: "Sports")) {
            try makeUseCase().execute(preferences: makePreferences(genres: [.sports]))
        }
    }

    @Test func errorQuotesShortestSeries() {
        // The only romance anime is 24 episodes, so a viewer asking for under 12 needs
        // to be told that number — otherwise they don't know how far to move the control.
        #expect(throws: FindAnimeRecommendationsError.episodeLimitTooShort(shortestAvailable: 24)) {
            try makeUseCase().execute(
                preferences: makePreferences(genres: [.romance], episodeLimit: .under12)
            )
        }
    }

    @Test func errorsGiveNextStep() {
        // Section 3 of the brief asks what the person can do next, so every message
        // has to contain an actual instruction rather than just naming the problem.
        let allErrors: [FindAnimeRecommendationsError] = [
            .noAnimeInChosenGenres(genreNames: "Sports"),
            .everythingAlreadyWatched(genreNames: "Action"),
            .noFinishedSeriesAvailable,
            .noAiringSeriesAvailable,
            .episodeLimitTooShort(shortestAvailable: 24)
        ]

        for error in allErrors {
            let message = error.localizedDescription
            let givesAdvice = message.contains("Try") || message.contains("try") || message.contains("Set")
            #expect(givesAdvice, "This message doesn't say what to do next: \(message)")
        }
    }

    @Test func reasonsUseRealNumbers() throws {
        let matches = try makeUseCase().execute(preferences: makePreferences(genres: [.action]))
        let lowRated = try #require(matches.first { $0.anime.id == TestAnimeRepository.lowRatedAction.id })

        #expect(lowRated.reasons.contains("Matches the Action you picked"))
        #expect(lowRated.reasons.contains("Rated 6.4 out of 10"))
        // A 6.4 is not a selling point, so nothing should imply it is. A reason that
        // appears on every result whatever its score is not a reason.
        for reason in lowRated.reasons {
            #expect(!reason.contains("high"), "A 6.4 anime shouldn't be called high: \(reason)")
        }
    }
}

// MARK: - Remembering what the viewer has already seen

struct AlreadyWatchedTests {

    /// Builds the two Use Cases over one shared history, which is how the app wires
    /// them up too.
    private func makeUseCases() -> (FindAnimeRecommendationsUseCase, MarkAsAlreadyWatchedUseCase) {
        let repository = TestAnimeRepository()
        let history = InMemoryWatchHistoryRepository()
        return (
            FindAnimeRecommendationsUseCase(repository: repository, watchHistory: history),
            MarkAsAlreadyWatchedUseCase(animeRepository: repository, watchHistory: history)
        )
    }

    @Test func seenStopsSuggestions() throws {
        let (search, markSeen) = makeUseCases()

        let before = try search.execute(preferences: makePreferences(genres: [.action]))
        #expect(before.contains { $0.anime.id == TestAnimeRepository.shortAction.id })

        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)

        // This is the whole point of the feature: the app remembers, so a rejected
        // suggestion never comes back — not in this search, and not in a later one.
        let after = try search.execute(preferences: makePreferences(genres: [.action]))
        #expect(!after.contains { $0.anime.id == TestAnimeRepository.shortAction.id })
        #expect(after.count == before.count - 1)
    }

    @Test func allSeenNamesGenre() throws {
        let (search, markSeen) = makeUseCases()

        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.longAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.lowRatedAction.id)

        // The message names the genre rather than just saying "no results".
        #expect(throws: FindAnimeRecommendationsError.everythingAlreadyWatched(genreNames: "Action")) {
            try search.execute(preferences: makePreferences(genres: [.action]))
        }
    }

    @Test func doubleMarkRejected() throws {
        let (_, markSeen) = makeUseCases()
        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)

        // Usually a double tap. The app says so rather than saving a duplicate.
        #expect(throws: MarkAsAlreadyWatchedError.alreadyMarkedAsWatched(animeTitle: "Short Action Show")) {
            try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)
        }
    }

    @Test func unknownAnimeRejected() {
        // An id that is not in the catalogue would put a broken row on the watch
        // history, so it is refused rather than saved.
        let (_, markSeen) = makeUseCases()

        #expect(throws: MarkAsAlreadyWatchedError.animeNotInCatalogue) {
            try markSeen.execute(animeID: 9999)
        }
    }
}

// MARK: - Choosing the suggestion

struct ChooseAnimeUseCaseTests {

    private let useCase = ChooseAnimeUseCase()

    private func makeMatch(_ anime: Anime) -> AnimeMatch {
        AnimeMatch(anime: anime, matchPercentage: 90, reasons: ["A reason"])
    }

    @Test func choosingOnScreenWorks() throws {
        // The normal case: the viewer taps "I'll watch this" on the anime in front
        // of them.
        let match = makeMatch(TestAnimeRepository.shortAction)

        let chosen = try useCase.execute(chosenMatch: match, currentSuggestion: match)

        #expect(chosen.id == match.id)
    }

    @Test func staleChoiceRejected() {
        // A tap arriving for an anime the app has already moved past. Letting it
        // through would commit the viewer to something they are no longer looking at.
        let onScreen = makeMatch(TestAnimeRepository.shortAction)
        let stale = makeMatch(TestAnimeRepository.romanceOnly)

        #expect(throws: ChooseAnimeError.notTheCurrentSuggestion) {
            try useCase.execute(chosenMatch: stale, currentSuggestion: onScreen)
        }
    }
}
