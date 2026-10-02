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

/// A small fake catalogue used by the tests, standing in for the Tenrai API.
///
/// The tests hand the Use Cases a tiny list written by hand, so I can work out the
/// right answer myself and check against it. A test should only fail when a rule breaks,
/// not when the real catalogue changes, and the tests never touch the internet.
///
/// Every fixture runs approximately 24 minutes an episode, which is what almost all TV anime do.
/// That keeps the hours easy to work out by hand: 15 episodes is exactly 6 hours, 12 episodes
/// is 4.8, 24 episodes is 9.6, and 60 episodes is 24.
@MainActor
class TestAnimeRepository: AnimeRepository {

    /// Set this to pretend the phone is offline or the catalogue is busy.
    var failure: AnimeCatalogueError? = nil

    /// How many times the catalogue was asked for something, so a test can check the
    /// app didn't make pointless requests.
    private(set) var requestCount = 0

    private(set) var anime: [Anime] = []

    init() { anime = TestAnimeRepository.allFixtures }

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

    /// The only comedy, and it's a second season. Someone new can't start here.
    static let comedySequel = Anime(
        id: 105, title: "Comedy Club Season 2", synopsis: "For testing.",
        episodes: 12, episodeMinutes: 24, score: 8.8, status: .finished, genres: [.comedy]
    )

    /// The only adventure. Still airing, and the length hasn't been announced.
    static let openEndedAdventure = Anime(
        id: 106, title: "Open Ended Adventure", synopsis: "For testing.",
        episodes: nil, episodeMinutes: 24, score: 8.2, status: .airing, genres: [.adventure]
    )

    static let allFixtures: [Anime] = [
        shortAction, longAction, lowRatedAction, romanceOnly, comedySequel, openEndedAdventure
    ]

    func load(for preferences: AnimePreferences) async throws -> [Anime] {
        requestCount += 1
        if let failure = failure {
            throw failure
        }
        // I hand back everything. Filtering is the Use Case's job, and that's what
        // the tests are checking.
        return anime
    }

    func findAnime(withID id: Int) async throws -> Anime? {
        requestCount += 1
        if let failure = failure {
            throw failure
        }
        for item in anime where item.id == id {
            return item
        }
        return nil
    }

    func searchAnime(titled title: String) async throws -> Anime? {
        requestCount += 1
        if let failure = failure {
            throw failure
        }
        for item in anime where item.title.lowercased().contains(title.lowercased()) {
            return item
        }
        return nil
    }
}

/// Builds a request without repeating the same lines in every test.
@MainActor
func makePreferences(genres: Set<AnimeGenre> = [],
                     time: TimeCommitment = .any,
                     status: AnimeStatusPreference = .any) -> AnimePreferences {
    var preferences = AnimePreferences()
    preferences.genres = genres
    preferences.timeCommitment = time
    preferences.status = status
    return preferences
}

/// A fixed date, so saved records can be checked exactly.
let testDate = Date(timeIntervalSince1970: 1_790_000_000)

// MARK: - Suggesting an anime

@MainActor
struct FindAnimeRecommendationsUseCaseTests {

    private func makeUseCase(_ history: WatchHistoryRepository = InMemoryWatchHistoryRepository())
    -> FindAnimeRecommendationsUseCase {
        FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), watchHistory: history)
    }

    @Test func suggestions_rankedBestFirst() async throws {
        let matches = try await makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        // Three action anime qualify, and the strongest is offered first. All three match
        // the one genre asked for, so the 9.0 rating is what puts the long epic on top.
        #expect(matches.count == 3)
        #expect(matches[0].anime.id == TestAnimeRepository.longAction.id)
        #expect(matches[0].matchPercentage >= matches[1].matchPercentage)
        #expect(matches[1].matchPercentage >= matches[2].matchPercentage)
    }

    @Test func search_excludesUnpickedGenres() async throws {
        // A viewer who asked for Action should never be shown the romance series,
        // however well rated it is.
        let matches = try await makeUseCase().execute(preferences: makePreferences(genres: [.action]))

        #expect(!matches.contains { $0.anime.id == TestAnimeRepository.romanceOnly.id })
    }

    @Test func search_includesAnime_atExactlyTheBudget() async throws {
        // The short action show is exactly 6.0 hours and "A few evenings" allows 6.0.
        // A budget of 6 hours has to include something that takes 6 hours, or the
        // boundary is off and the viewer loses a title they could have watched.
        let matches = try await makeUseCase().execute(
            preferences: makePreferences(genres: [.action], time: .aFewEvenings)
        )

        #expect(matches.contains { $0.anime.id == TestAnimeRepository.shortAction.id })
        // The 24-hour epic is the only action title that should be dropped.
        #expect(matches.count == 2)
    }

    @Test func search_fails_whenGenreHasNothing() async {
        // There are no sports anime in the test repository at all.
        await #expect(throws: FindAnimeRecommendationsError.noAnimeInChosenGenres(genreNames: "Sports")) {
            try await makeUseCase().execute(preferences: makePreferences(genres: [.sports]))
        }
    }

    @Test func search_fails_whenBudgetTooSmall() async {
        // The only romance anime runs 9.6 hours, so a viewer with a 6 hour budget needs
        // to be told that number, otherwise they don't know how far to move the control.
        await #expect(throws: FindAnimeRecommendationsError.timeBudgetTooSmall(shortestHours: 10)) {
            try await makeUseCase().execute(
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
            .timeBudgetTooSmall(shortestHours: 10),
            .onlySequelsFound(genreNames: "Comedy"),
            .onlyOpenEndedSeriesLeft,
            .noConnection,
            .catalogueBusy,
            .catalogueUnavailable
        ]

        for error in allErrors {
            let message = error.localizedDescription
            let givesAdvice = message.contains("Try") || message.contains("try") || message.contains("Set")
            #expect(givesAdvice, "This message doesn't say what to do next: \(message)")
        }
    }

    @Test func reasons_quoteTheRealRating() async throws {
        let matches = try await makeUseCase().execute(preferences: makePreferences(genres: [.action]))
        let lowRated = try #require(matches.first { $0.anime.id == TestAnimeRepository.lowRatedAction.id })

        #expect(lowRated.reasons.contains("Matches the Action you picked"))
        #expect(lowRated.reasons.contains("Rated 6.4 out of 10"))
        // A 6.4 is not a selling point, so nothing should imply it is. A reason that
        // appears on every result whatever its score is not a reason.
        for reason in lowRated.reasons {
            #expect(!reason.contains("high"), "A 6.4 anime shouldn't be called high: \(reason)")
        }
    }

    @Test func reasons_quoteHoursAndEpisodes() async throws {
        // The viewer set a budget, so the reason has to say what this one actually costs.
        // Both units appear: hours is what they chose in, episodes is what they will see
        // on any other site.
        let matches = try await makeUseCase().execute(
            preferences: makePreferences(genres: [.action], time: .aFewEvenings)
        )
        let short = try #require(matches.first { $0.anime.id == TestAnimeRepository.shortAction.id })

        #expect(short.reasons.contains("15 episodes, about 6 hours in total"))
    }
}

// MARK: - Remembering what the viewer has already seen

@MainActor
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

    @Test func search_excludesAnime_onceMarkedWatched() async throws {
        let (search, markSeen) = makeUseCases()

        let before = try await search.execute(preferences: makePreferences(genres: [.action]))
        #expect(before.contains { $0.anime.id == TestAnimeRepository.shortAction.id })

        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)

        // This is the whole point of the feature: the app remembers, so a rejected
        // suggestion never comes back — not in this search, and not in a later one.
        let after = try await search.execute(preferences: makePreferences(genres: [.action]))
        #expect(!after.contains { $0.anime.id == TestAnimeRepository.shortAction.id })
        #expect(after.count == before.count - 1)
    }

    @Test func search_fails_whenGenreAllWatched() async throws {
        let (search, markSeen) = makeUseCases()

        try markSeen.execute(animeID: TestAnimeRepository.shortAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.longAction.id)
        try markSeen.execute(animeID: TestAnimeRepository.lowRatedAction.id)

        // The message names the genre rather than just saying "no results".
        await #expect(throws: FindAnimeRecommendationsError.everythingAlreadyWatched(genreNames: "Action")) {
            try await search.execute(preferences: makePreferences(genres: [.action]))
        }
    }

    @Test func markWatched_fails_whenAlreadyMarked() async throws {
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

@MainActor
struct ChooseAnimeUseCaseTests {

    private let useCase = ChooseAnimeUseCase()

    private func makeMatch(_ anime: Anime) -> AnimeMatch {
        AnimeMatch(anime: anime, matchPercentage: 90, reasons: ["A reason"])
    }

    @Test func choose_succeeds_forTheSuggestionOnScreen() async throws {
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

// MARK: - Rules that came with the real catalogue

/// These rules only exist because Animora now uses the real Tenrai catalogue instead
/// of my hand-picked list of 15. The real list has sequels, series still airing with
/// no episode count, and it can fail when the phone is offline.
@MainActor
struct CatalogueRulesTests {

    @Test func search_skipsSequels_forSomeoneNewToAnime() async {
        // The only comedy is a Season 2. It's rated 8.8, but a newcomer can't start
        // there, so the viewer is told why rather than being shown it.
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository())

        await #expect(throws: FindAnimeRecommendationsError.onlySequelsFound(genreNames: "Comedy")) {
            try await useCase.execute(preferences: makePreferences(genres: [.comedy]))
        }
    }

    @Test func search_leavesOutSeriesWithUnknownLength_whenTimeIsLimited() async {
        // The adventure hasn't announced how many episodes it will have. Animora
        // can't promise it fits in a few evenings, so it doesn't pretend to.
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository())

        await #expect(throws: FindAnimeRecommendationsError.onlyOpenEndedSeriesLeft) {
            try await useCase.execute(
                preferences: makePreferences(genres: [.adventure], time: .aFewEvenings)
            )
        }
    }

    @Test func search_includesSeriesWithUnknownLength_whenTimeDoesNotMatter() async throws {
        // The boundary on the other side: with no time limit, the open-ended series
        // is fine to suggest.
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository())

        let matches = try await useCase.execute(preferences: makePreferences(genres: [.adventure]))

        #expect(matches.count == 1)
        #expect(matches[0].anime.id == TestAnimeRepository.openEndedAdventure.id)
    }

    @Test func search_tellsViewerToCheckConnection_whenOffline() async {
        // Without this, being offline would look exactly like "nothing matched",
        // and the viewer would start changing their genres for no reason.
        let catalogue = TestAnimeRepository()
        catalogue.failure = .noConnection
        let useCase = FindAnimeRecommendationsUseCase(repository: catalogue)

        await #expect(throws: FindAnimeRecommendationsError.noConnection) {
            try await useCase.execute(preferences: makePreferences(genres: [.action]))
        }
    }

    @Test func search_asksViewerToWait_whenCatalogueIsBusy() async {
        let catalogue = TestAnimeRepository()
        catalogue.failure = .tooManyRequests
        let useCase = FindAnimeRecommendationsUseCase(repository: catalogue)

        await #expect(throws: FindAnimeRecommendationsError.catalogueBusy) {
            try await useCase.execute(preferences: makePreferences(genres: [.action]))
        }
    }

    @Test func search_skipsAnime_alreadyOnNowWatching() async throws {
        // Something the viewer is halfway through shouldn't be suggested again.
        let watchlist = InMemoryWatchlistRepository()
        watchlist.add(WatchlistEntry(
            anime: TestAnimeRepository.longAction, episodesWatched: 3,
            startedAt: testDate, updatedAt: testDate
        ))
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), watchlist: watchlist)

        let matches = try await useCase.execute(preferences: makePreferences(genres: [.action]))

        #expect(matches.contains { $0.anime.id == TestAnimeRepository.longAction.id } == false)
        #expect(matches.count == 2)
    }
}

// MARK: - Friends' picks in suggestions

@MainActor
struct FriendPickSuggestionTests {

    /// A pick that has already been looked up, the way it looks after the main app
    /// has run LookUpFriendPicksUseCase.
    private func makeLookedUpPick(_ anime: Anime, from friendName: String) -> FriendPick {
        var pick = FriendPick(
            id: UUID(), sharedTitle: anime.title, sharedLink: nil,
            friendName: friendName, receivedAt: testDate
        )
        pick.anime = anime
        return pick
    }

    @Test func friendsPick_isSuggestedFirst_evenWithALowerRating() async throws {
        // The 6.4 show would normally come last. A friend saying "watch this" matters
        // more to a newcomer than a rating, so it jumps to the top.
        let picks = InMemoryFriendPickRepository()
        picks.add(makeLookedUpPick(TestAnimeRepository.lowRatedAction, from: "Mia"))
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), friendPicks: picks)

        let matches = try await useCase.execute(preferences: makePreferences(genres: [.action]))

        #expect(matches[0].anime.id == TestAnimeRepository.lowRatedAction.id)
        #expect(matches[0].friendName == "Mia")
        #expect(matches[0].reasons.first == "Mia told you to watch this one")
    }

    @Test func friendsPick_canBeASequel() async throws {
        // If a friend says "watch season 2", they know the viewer has seen season 1.
        let picks = InMemoryFriendPickRepository()
        picks.add(makeLookedUpPick(TestAnimeRepository.comedySequel, from: "Sam"))
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), friendPicks: picks)

        let matches = try await useCase.execute(preferences: makePreferences(genres: [.comedy]))

        #expect(matches.count == 1)
        #expect(matches[0].anime.id == TestAnimeRepository.comedySequel.id)
    }

    @Test func friendsPick_stillHasToFitTheViewersTime() async throws {
        // A friend's pick jumps the queue, but it doesn't skip the viewer's own
        // limits. The 24 hour epic doesn't fit in a few evenings, whoever sent it.
        let picks = InMemoryFriendPickRepository()
        picks.add(makeLookedUpPick(TestAnimeRepository.longAction, from: "Mia"))
        let useCase = FindAnimeRecommendationsUseCase(repository: TestAnimeRepository(), friendPicks: picks)

        let matches = try await useCase.execute(
            preferences: makePreferences(genres: [.action], time: .aFewEvenings)
        )

        #expect(matches.contains { $0.anime.id == TestAnimeRepository.longAction.id } == false)
    }
}

// MARK: - Choosing adds to Now watching

@MainActor
struct ChooseAddsToWatchlistTests {

    @Test func choosing_putsAnimeOnNowWatching_atEpisodeOne() throws {
        let watchlist = InMemoryWatchlistRepository()
        let useCase = ChooseAnimeUseCase(watchlist: watchlist)
        let match = AnimeMatch(anime: TestAnimeRepository.shortAction, matchPercentage: 90, reasons: ["A reason"])

        try useCase.execute(chosenMatch: match, currentSuggestion: match, on: testDate)

        let entry = try #require(watchlist.entry(forAnimeID: TestAnimeRepository.shortAction.id))
        #expect(entry.episodesWatched == 0)
        #expect(entry.progressSummary == "Episode 1 of 15")
    }

    @Test func choosing_fails_whenAlreadyOnNowWatching() throws {
        // A second tap, or choosing it again from a later search. The viewer keeps
        // their progress instead of being reset to episode 1.
        let watchlist = InMemoryWatchlistRepository()
        let useCase = ChooseAnimeUseCase(watchlist: watchlist)
        let match = AnimeMatch(anime: TestAnimeRepository.shortAction, matchPercentage: 90, reasons: ["A reason"])
        try useCase.execute(chosenMatch: match, currentSuggestion: match, on: testDate)

        #expect(throws: ChooseAnimeError.alreadyOnWatchlist(animeTitle: "Short Action Show")) {
            try useCase.execute(chosenMatch: match, currentSuggestion: match, on: testDate)
        }
    }
}

// MARK: - Ticking off episodes (the app and the widget both use this)

@MainActor
struct LogEpisodeWatchedUseCaseTests {

    /// A watchlist with one anime on it, partway through.
    private func makeWatchlist(_ anime: Anime, episodesWatched: Int) -> InMemoryWatchlistRepository {
        let watchlist = InMemoryWatchlistRepository()
        watchlist.add(WatchlistEntry(
            anime: anime, episodesWatched: episodesWatched,
            startedAt: testDate, updatedAt: testDate
        ))
        return watchlist
    }

    @Test func loggingAnEpisode_movesUpNextOnByOne() throws {
        let watchlist = makeWatchlist(TestAnimeRepository.lowRatedAction, episodesWatched: 3)
        let useCase = LogEpisodeWatchedUseCase(watchlist: watchlist, watchHistory: InMemoryWatchHistoryRepository())

        let entry = try useCase.execute(animeID: TestAnimeRepository.lowRatedAction.id, on: testDate)

        #expect(entry.episodesWatched == 4)
        #expect(entry.progressSummary == "Episode 5 of 12")
        #expect(watchlist.entry(forAnimeID: TestAnimeRepository.lowRatedAction.id)?.episodesWatched == 4)
    }

    @Test func loggingTheFinalEpisode_movesAnimeToWatchHistory() throws {
        // Episode 12 of 12. The show should leave Now watching, so the widget moves on,
        // and land in the history, so it's never suggested again.
        let watchlist = makeWatchlist(TestAnimeRepository.lowRatedAction, episodesWatched: 11)
        let history = InMemoryWatchHistoryRepository()
        let useCase = LogEpisodeWatchedUseCase(watchlist: watchlist, watchHistory: history)

        let entry = try useCase.execute(animeID: TestAnimeRepository.lowRatedAction.id, on: testDate)

        #expect(entry.isFinished)
        #expect(watchlist.entry(forAnimeID: TestAnimeRepository.lowRatedAction.id) == nil)
        #expect(history.hasWatched(animeID: TestAnimeRepository.lowRatedAction.id))
        #expect(history.watchedRecords.first?.reason == .finishedWithAnimora)
    }

    @Test func loggingAnEpisode_ofAnOpenEndedSeries_neverFinishesIt() throws {
        // With no episode count, there is no "last episode", so it stays on the list.
        let watchlist = makeWatchlist(TestAnimeRepository.openEndedAdventure, episodesWatched: 40)
        let useCase = LogEpisodeWatchedUseCase(watchlist: watchlist, watchHistory: InMemoryWatchHistoryRepository())

        let entry = try useCase.execute(animeID: TestAnimeRepository.openEndedAdventure.id, on: testDate)

        #expect(entry.isFinished == false)
        #expect(entry.progressSummary == "Episode 42")
    }

    @Test func loggingAnEpisode_fails_whenNotOnNowWatching() {
        // This is what a widget tap looks like if the app removed the show a moment
        // before. It must be refused, not crash or make a new entry.
        let useCase = LogEpisodeWatchedUseCase(
            watchlist: InMemoryWatchlistRepository(),
            watchHistory: InMemoryWatchHistoryRepository()
        )

        #expect(throws: LogEpisodeWatchedError.notOnWatchlist) {
            try useCase.execute(animeID: TestAnimeRepository.shortAction.id, on: testDate)
        }
    }
}

// MARK: - Saving a friend's pick (the share extension uses this)

@MainActor
struct SaveFriendPickUseCaseTests {

    private let frierenLink = URL(string: "https://myanimelist.net/anime/52991/Sousou_no_Frieren")!

    @Test func savingAMyAnimeListLink_keepsTheAnimeID() throws {
        let picks = InMemoryFriendPickRepository()
        let useCase = SaveFriendPickUseCase(friendPicks: picks)

        let pick = try useCase.execute(title: "Sousou no Frieren", link: frierenLink, friendName: "Mia", on: testDate)

        #expect(pick.myAnimeListID == 52991)
        #expect(pick.isWaitingForLookup)
        #expect(picks.picks.count == 1)
    }

    @Test func savingWithoutAFriendsName_creditsAFriend() throws {
        let useCase = SaveFriendPickUseCase(friendPicks: InMemoryFriendPickRepository())

        let pick = try useCase.execute(title: "Frieren", link: nil, friendName: "   ", on: testDate)

        #expect(pick.friendName == "A friend")
    }

    @Test func saving_fails_whenThereIsNothingToLookUp() {
        // A link to some random site and no title: the app could never work out
        // which anime it is, so the viewer is asked to type the name.
        let useCase = SaveFriendPickUseCase(friendPicks: InMemoryFriendPickRepository())
        let otherLink = URL(string: "https://example.com/some-post")!

        #expect(throws: SaveFriendPickError.nothingToLookUp) {
            try useCase.execute(title: "", link: otherLink, friendName: "Mia", on: testDate)
        }
    }

    @Test func saving_fails_whenAWholeMessageIsShared() {
        let useCase = SaveFriendPickUseCase(friendPicks: InMemoryFriendPickRepository())
        let wholeMessage = String(repeating: "you HAVE to watch this it's so good ", count: 3)

        #expect(throws: SaveFriendPickError.titleTooLong(characterLimit: 80)) {
            try useCase.execute(title: wholeMessage, link: nil, friendName: "Mia", on: testDate)
        }
    }

    @Test func saving_acceptsATitle_atExactlyTheCharacterLimit() throws {
        // The boundary: 80 characters is allowed, 81 is not.
        let useCase = SaveFriendPickUseCase(friendPicks: InMemoryFriendPickRepository())
        let longestAllowed = String(repeating: "a", count: 80)

        let pick = try useCase.execute(title: longestAllowed, link: nil, friendName: "Mia", on: testDate)

        #expect(pick.sharedTitle.count == 80)
    }

    @Test func saving_fails_whenTheSameAnimeIsSentTwice() throws {
        // Two friends recommending the same show is common. The list should only
        // have it once, and say who sent it first.
        let picks = InMemoryFriendPickRepository()
        let useCase = SaveFriendPickUseCase(friendPicks: picks)
        try useCase.execute(title: "Frieren", link: frierenLink, friendName: "Mia", on: testDate)

        #expect(throws: SaveFriendPickError.alreadySaved(title: "Frieren", friendName: "Mia")) {
            try useCase.execute(title: "", link: frierenLink, friendName: "Sam", on: testDate)
        }
    }
}

// MARK: - Looking up friends' picks in the catalogue

@MainActor
struct LookUpFriendPicksUseCaseTests {

    @Test func lookUp_matchesALinkToTheExactAnime() async throws {
        let picks = InMemoryFriendPickRepository()
        let link = URL(string: "https://myanimelist.net/anime/104/Romance_Only_Show")!
        try SaveFriendPickUseCase(friendPicks: picks)
            .execute(title: "Some other name", link: link, friendName: "Mia", on: testDate)
        let useCase = LookUpFriendPicksUseCase(catalogue: TestAnimeRepository(), friendPicks: picks)

        let matched = try await useCase.execute()

        // The link wins over the typed title, because it points at one exact anime.
        #expect(matched == 1)
        #expect(picks.picks[0].anime?.id == TestAnimeRepository.romanceOnly.id)
    }

    @Test func lookUp_marksMissingAnime_asNotFound() async throws {
        let picks = InMemoryFriendPickRepository()
        try SaveFriendPickUseCase(friendPicks: picks)
            .execute(title: "A show that does not exist", link: nil, friendName: "Mia", on: testDate)
        let catalogue = TestAnimeRepository()
        let useCase = LookUpFriendPicksUseCase(catalogue: catalogue, friendPicks: picks)

        try await useCase.execute()
        let requestsAfterFirstLookUp = catalogue.requestCount
        try await useCase.execute()

        // Marked as not found, so opening the app again doesn't ask again.
        #expect(picks.picks[0].couldNotBeFound)
        #expect(picks.picksWaitingForLookup.isEmpty)
        #expect(catalogue.requestCount == requestsAfterFirstLookUp)
    }

    @Test func lookUp_keepsPicksWaiting_whenOffline() async throws {
        // Being offline isn't the pick's fault, so it must not be marked as not found.
        let picks = InMemoryFriendPickRepository()
        try SaveFriendPickUseCase(friendPicks: picks)
            .execute(title: "Short Action Show", link: nil, friendName: "Mia", on: testDate)
        let catalogue = TestAnimeRepository()
        catalogue.failure = .noConnection
        let useCase = LookUpFriendPicksUseCase(catalogue: catalogue, friendPicks: picks)

        await #expect(throws: LookUpFriendPicksError.noConnection) {
            try await useCase.execute()
        }
        #expect(picks.picksWaitingForLookup.count == 1)
    }
}

// MARK: - Reading the Tenrai catalogue

/// These check the part of TenraiAnimeRepository that turns the catalogue's JSON into
/// Animora's `Anime`. They use JSON I wrote by hand, so they never touch the internet.
@MainActor
struct TenraiCatalogueReadingTests {

    private let sampleReply = """
    {
      "data": [
        {
          "mal_id": 52991,
          "title": "Sousou no Frieren",
          "title_english": "Frieren: Beyond Journey's End",
          "type": "TV",
          "episodes": 28,
          "status": "Finished Airing",
          "duration": "24 min per ep",
          "score": 9.3,
          "synopsis": "An elf mage outlives her party.\\n\\nLater paragraphs spoil things.",
          "genres": [
            { "mal_id": 2, "name": "Adventure" },
            { "mal_id": 8, "name": "Drama" },
            { "mal_id": 10, "name": "Fantasy" }
          ]
        },
        {
          "mal_id": 99999,
          "title": "Announced Show",
          "type": "TV",
          "episodes": null,
          "status": "Not yet aired",
          "duration": "Unknown",
          "score": null,
          "genres": []
        },
        {
          "mal_id": 88888,
          "title": "Opening Music Video",
          "type": "Music",
          "episodes": 1,
          "status": "Finished Airing",
          "duration": "4 min",
          "score": 7.5,
          "genres": []
        }
      ]
    }
    """

    @Test func catalogueReply_becomesAnimoraAnime_withTheEnglishTitle() throws {
        let anime = try TenraiAnimeRepository.decodeAnimeList(from: Data(sampleReply.utf8))

        let frieren = try #require(anime.first)
        #expect(frieren.id == 52991)
        #expect(frieren.title == "Frieren: Beyond Journey's End")
        #expect(frieren.status == .finished)
        #expect(frieren.genres == [.adventure, .drama, .fantasy])
        #expect(frieren.synopsis == "An elf mage outlives her party.")
    }

    @Test func catalogueReply_skipsUnairedShowsAndMusicVideos() throws {
        // Nothing to watch yet, and not a series. Neither should ever be suggested.
        let anime = try TenraiAnimeRepository.decodeAnimeList(from: Data(sampleReply.utf8))

        #expect(anime.count == 1)
    }

    @Test func episodeLength_isReadFromTheCataloguesWording() {
        #expect(TenraiAnimeRepository.minutesPerEpisode(from: "24 min per ep") == 24)
        #expect(TenraiAnimeRepository.minutesPerEpisode(from: "1 hr 55 min") == 115)
        // Unreadable lengths fall back to a normal TV episode.
        #expect(TenraiAnimeRepository.minutesPerEpisode(from: "Unknown") == 24)
    }

    @Test func brokenCatalogueReply_isReportedAsUnavailable() {
        #expect(throws: AnimeCatalogueError.unavailable) {
            try TenraiAnimeRepository.decodeAnimeList(from: Data("not json".utf8))
        }
    }
}
