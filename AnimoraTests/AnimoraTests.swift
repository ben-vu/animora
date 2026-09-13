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
/// The tests hand the Use Cases a tiny list written by hand, so I can work out the
/// right answer myself and check against it. A test should only fail when a rule breaks,
/// not when I add a new anime to the app.
///
/// Every fixture runs approximately 24 minutes an episode, which is what almost all TV anime do.
/// That keeps the hours easy to work out by hand: 15 episodes is exactly 6 hours, 12 episodes
/// is 4.8, 24 episodes is 9.6, and 60 episodes is 24.
class TestAnimeRepository: AnimeRepository {

    private(set) var anime: [Anime] = []

    init() { anime = load() }

    /// Exactly 6.0 hours, which is the boundary of "A few evenings".
    static let shortAction = Anime(
        id: 101, title: "Short Action Show", synopsis: "For testing.",
        episodes: 15, episodeMinutes: 24, score: 8.0, status: .finished, genres: [.action]
    )

    /// 24 hours, past every budget the viewer can choose.
    static let longAction = Anime(
        id: 102, title: "Long Action Epic", synopsis: "For testing.",
        episodes: 60, episodeMinutes: 24, score: 9.0, status: .finished, genres: [.action]
    )

    /// 4.8 hours, and deliberately the only poorly rated one.
    static let lowRatedAction = Anime(
        id: 103, title: "Low Rated Action Show", synopsis: "For testing.",
        episodes: 12, episodeMinutes: 24, score: 6.4, status: .finished, genres: [.action]
    )

    /// 9.6 hours, so a romance request on a short budget has nothing to offer.
    static let romanceOnly = Anime(
        id: 104, title: "Romance Only Show", synopsis: "For testing.",
        episodes: 24, episodeMinutes: 24, score: 8.5, status: .finished, genres: [.romance]
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
                     time: TimeCommitment = .any,
                     status: AnimeStatusPreference = .any) -> AnimePreferences {
    var preferences = AnimePreferences()
    preferences.genres = genres
    preferences.timeCommitment = time
    preferences.status = status
    return preferences
}

// MARK: - Suggesting an anime

struct FindAnimeRecommendationsUseCaseTests {

    private func makeUseCase(_ history: WatchHistoryRepository = InMemoryWatchHistoryRepository())
    -> FindAnimeRecommendationsUseCase {
        FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), watchHistory: history)
    }

    @Test func suggestions_rankedBestFirst() throws {
        let matches = try makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        // Three action anime qualify, and the strongest is offered first. All three match
        // the one genre asked for, so the 9.0 rating is what puts the long epic on top.
        #expect(matches.count == 3)
        #expect(matches[0].anime.id == TestAnimeRepository.longAction.id)
        #expect(matches[0].matchPercentage >= matches[1].matchPercentage)
        #expect(matches[1].matchPercentage >= matches[2].matchPercentage)
    }

    @Test func search_excludesUnpickedGenres() throws {
        // A viewer who asked for Action should never be shown the romance series,
        // however well rated it is.
        let matches = try makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        #expect(!matches.contains { $0.anime.id == TestAnimeRepository.romanceOnly.id })
    }

    @Test func search_includesAnime_atExactlyTheBudget() throws {
        // The short action show is exactly 6.0 hours and "A few evenings" allows 6.0.
        // A budget of 6 hours has to include something that takes 6 hours, or the
        // boundary is off and the viewer loses a title they could have watched.
        let matches = try makeUseCase().execute(
            preferences: makePreferences(genres: [.action], time: .aFewEvenings)
        )

        #expect(matches.contains { $0.anime.id == TestAnimeRepository.shortAction.id })
        // The 24-hour epic is the only action title that should be dropped.
        #expect(matches.count == 2)
    }

    @Test func search_fails_whenGenreHasNothing() {
        // There are no sports anime in the test repository at all.
        #expect(throws: FindAnimeRecommendationsError.noAnimeInChosenGenres(genreNames: "Sports")) {
            try makeUseCase().execute(preferences: makePreferences(genres: [.sports]))
        }
    }

    @Test func search_fails_whenBudgetTooSmall() {
        // The only romance anime runs 9.6 hours, so a viewer with a 6 hour budget needs
        // to be told that number, otherwise they don't know how far to move the control.
        #expect(throws: FindAnimeRecommendationsError.timeBudgetTooSmall(shortestHours: 10)) {
            try makeUseCase().execute(
                preferences: makePreferences(genres: [.romance], time: .aFewEvenings)
            )
        }
    }

    @Test func searchErrors_nameAControlToChange() {
        // Section 3 of the brief asks what the person can do next, so every message
        // has to contain an actual instruction rather than just naming the problem.
        let allErrors: [FindAnimeRecommendationsError] = [
            .noAnimeInChosenGenres(genreNames: "Sports"),
            .everythingAlreadyWatched(genreNames: "Action"),
            .noFinishedSeriesAvailable,
            .noAiringSeriesAvailable,
            .timeBudgetTooSmall(shortestHours: 10)
        ]

        for error in allErrors {
            let message = error.localizedDescription
            let givesAdvice = message.contains("Try") || message.contains("try") || message.contains("Set")
            #expect(givesAdvice, "This message doesn't say what to do next: \(message)")
        }
    }

    @Test func reasons_quoteTheRealRating() throws {
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

    @Test func reasons_quoteHoursAndEpisodes() throws {
        // The viewer set a budget, so the reason has to say what this one actually costs.
        // Both units appear: hours is what they chose in, episodes is what they will see
        // on any other site.
        let matches = try makeUseCase().execute(
            preferences: makePreferences(genres: [.action], time: .aFewEvenings)
        )
        let short = try #require(matches.first { $0.anime.id == TestAnimeRepository.shortAction.id })

        #expect(short.reasons.contains("15 episodes, about 6 hours in total"))
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

    @Test func search_excludesAnime_onceMarkedWatched() throws {
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

    @Test func search_fails_whenGenreAllWatched() throws {
        let (search, markSeen) = makeUseCases()

        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.longAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.lowRatedAction.id)

        // The message names the genre rather than just saying "no results".
        #expect(throws: FindAnimeRecommendationsError.everythingAlreadyWatched(genreNames: "Action")) {
            try search.execute(preferences: makePreferences(genres: [.action]))
        }
    }

    @Test func markWatched_fails_whenAlreadyMarked() throws {
        let (_, markSeen) = makeUseCases()
        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)

        // Usually a double tap. The app says so rather than saving a duplicate.
        #expect(throws: MarkAsAlreadyWatchedError.alreadyMarkedAsWatched(animeTitle: "Short Action Show")) {
            try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)
        }
    }

    @Test func markWatched_fails_whenNotInCatalogue() {
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

    @Test func choose_succeeds_forTheSuggestionOnScreen() throws {
        // The normal case: the viewer taps "I'll watch this" on the anime in front
        // of them.
        let match = makeMatch(TestAnimeRepository.shortAction)

        let chosen = try useCase.execute(chosenMatch: match, currentSuggestion: match)

        #expect(chosen.id == match.id)
    }

    @Test func choose_fails_forAStaleSuggestion() {
        // A tap arriving for an anime the app has already moved past. Letting it
        // through would commit the viewer to something they are no longer looking at.
        let onScreen = makeMatch(TestAnimeRepository.shortAction)
        let stale = makeMatch(TestAnimeRepository.romanceOnly)

        #expect(throws: ChooseAnimeError.notTheCurrentSuggestion) {
            try useCase.execute(chosenMatch: stale, currentSuggestion: onScreen)
        }
    }
}
