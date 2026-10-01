//
//  FindAnimeRecommendationsUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 4/9/2026.
//

import Foundation

/// The ways finding recommendations can go wrong.
///
/// Each case below knows which filter emptied the list, so the message can point at
/// the fix and quote a real number. The last three are new in Assessment 3: now that
/// the anime come from the internet, the search can fail for reasons that have
/// nothing to do with the viewer's request, and they still deserve a proper sentence.
enum FindAnimeRecommendationsError: LocalizedError, Equatable {

    case noAnimeInChosenGenres(genreNames: String)
    case everythingAlreadyWatched(genreNames: String)
    case onlySequelsFound(genreNames: String)
    case noFinishedSeriesAvailable
    case noAiringSeriesAvailable
    case timeBudgetTooSmall(shortestHours: Int)
    case onlyOpenEndedSeriesLeft
    case noConnection
    case catalogueBusy
    case catalogueUnavailable

    var errorDescription: String? {
        switch self {

        case .noAnimeInChosenGenres(let genreNames):
            return "We couldn't find anything in \(genreNames) that suits someone new to anime. Try adding another genre to widen the search."

        case .everythingAlreadyWatched(let genreNames):
            return "You've already seen, or are already watching, everything we found in \(genreNames). Try another genre to find something new."

        case .onlySequelsFound(let genreNames):
            return "Everything left in \(genreNames) is a sequel, so you'd need to watch another series first. Try adding another genre."

        case .noFinishedSeriesAvailable:
            return "Everything we found is still airing week to week. Set Status to Any if you don't mind waiting for new episodes."

        case .noAiringSeriesAvailable:
            return "Nothing we found is currently airing. Set Status to Any to include series that have already finished."

        case .timeBudgetTooSmall(let shortestHours):
            return "Everything we found asks for more time than that. The shortest is about \(shortestHours) hours, so try allowing a bit longer."

        case .onlyOpenEndedSeriesLeft:
            return "Everything left is still airing and hasn't said how many episodes it will have, so we can't promise it fits your time. Set time to However long to see them."

        case .noConnection:
            return "Animora couldn't reach the anime catalogue. Check you're connected to Wi-Fi or mobile data, then try again."

        case .catalogueBusy:
            return "The anime catalogue is very busy right now. Wait a few seconds, then try again."

        case .catalogueUnavailable:
            return "The anime catalogue isn't answering properly at the moment. Try again in a minute."
        }
    }
}

/// Takes what the viewer is in the mood for and returns a ranked list of anime.
///
/// **The business rules:**
/// 1. An anime must be in at least one genre the viewer picked.
/// 2. An anime the viewer has already watched, or is watching now, is never suggested.
/// 3. No sequels, unless a friend sent it. Someone new to anime has to start at the
///    start.
/// 4. It must have the airing status they asked for.
/// 5. It must fit inside the time the viewer said they have. A series that has not
///    announced its length can't be promised to fit, so it is left out when there is
///    a time limit.
/// 6. Anything a friend recommended goes to the top, as long as it passed the rules
///    above. A personal recommendation is worth more to a newcomer than a rating.
/// 7. Every result comes with at least one reason, quoting real numbers.
///
/// The viewer is only ever shown the first one. The app suggests a
/// single anime at a time, because one decision is far easier to make than a list of
/// five. The rest are kept so that "already seen it" can show the next one instantly
/// instead of running the whole search again.
struct FindAnimeRecommendationsUseCase {

    /// Where the anime come from. This is the protocol, not a specific list or API,
    /// so this Use Case does not care where they actually live.
    let repository: AnimeRepository

    /// What the viewer has already seen. The search consults this so a rejected
    /// suggestion never comes back.
    let watchHistory: WatchHistoryRepository

    /// What the viewer is partway through. Suggesting that again would be silly.
    let watchlist: WatchlistRepository

    /// Anime friends have sent through the share sheet.
    let friendPicks: FriendPickRepository

    init(repository: AnimeRepository,
         watchHistory: WatchHistoryRepository = InMemoryWatchHistoryRepository(),
         watchlist: WatchlistRepository = InMemoryWatchlistRepository(),
         friendPicks: FriendPickRepository = InMemoryFriendPickRepository()) {
        self.repository = repository
        self.watchHistory = watchHistory
        self.watchlist = watchlist
        self.friendPicks = friendPicks
    }

    /// Runs the search.
    ///
    /// - Parameter preferences: what the viewer asked for.
    /// - Returns: every match that passed the rules, best fit first.
    /// - Throws: a `FindAnimeRecommendationsError` naming the filter to change.
    func execute(preferences: AnimePreferences) async throws -> [AnimeMatch] {

        let genreNames = describeGenres(in: preferences)

        // Ask the catalogue first. Its errors are about the connection, so I turn them
        // into messages the viewer can act on here.
        let catalogueAnime: [Anime]
        do {
            catalogueAnime = try await repository.load(for: preferences)
        } catch let error as AnimeCatalogueError {
            throw translate(error)
        } catch {
            throw FindAnimeRecommendationsError.catalogueUnavailable
        }

        // Add in anything friends sent that has been looked up, and remember who sent
        // it. The picks come back newest first, so if two friends sent the same show
        // the most recent one gets the credit.
        var allAnime = catalogueAnime
        var friendNames: [Int: String] = [:]
        for pick in friendPicks.picks {
            guard let anime = pick.anime else { continue }

            if friendNames[anime.id] == nil {
                friendNames[anime.id] = pick.friendName
            }
            if allAnime.contains(where: { $0.id == anime.id }) == false {
                allAnime.append(anime)
            }
        }

        // I filter one rule at a time rather than all at once. It is a few more lines,
        // but it means that when the list comes back empty I know exactly which rule
        // emptied it, and I can tell the viewer which control to change.

        // Rule 1: keep only anime in a genre they picked.
        // An empty set means "no preference", so everything stays.
        var inChosenGenres: [Anime] = []
        if preferences.genres.isEmpty {
            inChosenGenres = allAnime
        } else {
            for anime in allAnime {
                if sharesAGenre(anime, with: preferences) {
                    inChosenGenres.append(anime)
                }
            }
        }

        if inChosenGenres.isEmpty {
            throw FindAnimeRecommendationsError.noAnimeInChosenGenres(genreNames: genreNames)
        }

        // Rule 2: drop anything the viewer has seen or is watching right now.
        // This goes straight after the genre filter because it is the most personal
        // exclusion — it is the viewer's own answer, not a preference they set.
        var notWatchedYet: [Anime] = []
        for anime in inChosenGenres {
            let alreadySeen = watchHistory.hasWatched(animeID: anime.id)
            let watchingNow = watchlist.entry(forAnimeID: anime.id) != nil
            if alreadySeen == false && watchingNow == false {
                notWatchedYet.append(anime)
            }
        }

        if notWatchedYet.isEmpty {
            throw FindAnimeRecommendationsError.everythingAlreadyWatched(genreNames: genreNames)
        }

        // Rule 3: no sequels, unless a friend sent it. If a friend says "watch season
        // 2", they probably know the viewer has seen season 1.
        var startsAtTheStart: [Anime] = []
        for anime in notWatchedYet {
            if anime.looksLikeASequel == false || friendNames[anime.id] != nil {
                startsAtTheStart.append(anime)
            }
        }

        if startsAtTheStart.isEmpty {
            throw FindAnimeRecommendationsError.onlySequelsFound(genreNames: genreNames)
        }

        // Rule 4: check the airing status next.
        // I do status before length so that if both are wrong, the message talks
        // about status, which is the bigger change for the viewer to make.
        var rightStatus: [Anime] = []
        switch preferences.status {
        case .any:
            rightStatus = startsAtTheStart
        case .finished:
            for anime in startsAtTheStart where anime.status == .finished {
                rightStatus.append(anime)
            }
            if rightStatus.isEmpty {
                throw FindAnimeRecommendationsError.noFinishedSeriesAvailable
            }
        case .airing:
            for anime in startsAtTheStart where anime.status == .airing {
                rightStatus.append(anime)
            }
            if rightStatus.isEmpty {
                throw FindAnimeRecommendationsError.noAiringSeriesAvailable
            }
        }

        // Rule 5: now the time budget.
        var shortEnough: [Anime] = []
        if let maximumHours = preferences.timeCommitment.maximumHours {
            for anime in rightStatus {
                // No known length means I can't promise it fits, so it is left out.
                if let hours = anime.totalHours, hours <= maximumHours {
                    shortEnough.append(anime)
                }
            }

            if shortEnough.isEmpty {
                // Telling them the shortest one we have is what makes this useful —
                // now they know how far to move the control.
                if let shortest = shortestCommitment(in: rightStatus) {
                    throw FindAnimeRecommendationsError.timeBudgetTooSmall(shortestHours: shortest)
                }
                throw FindAnimeRecommendationsError.onlyOpenEndedSeriesLeft
            }
        } else {
            shortEnough = rightStatus
        }

        // Score whatever survived and attach the reasons.
        var matches: [AnimeMatch] = []
        for anime in shortEnough {
            let friendName = friendNames[anime.id]
            let match = AnimeMatch(
                anime: anime,
                matchPercentage: matchPercentage(for: anime, preferences: preferences),
                reasons: buildReasons(for: anime, preferences: preferences, friendName: friendName),
                friendName: friendName
            )
            matches.append(match)
        }

        // Rule 6: friends' picks first, then best match. When two score the same I put
        // the higher rated one first, so the order is always the same and my tests are
        // reliable.
        matches.sort { first, second in
            let firstFromFriend = first.friendName != nil
            let secondFromFriend = second.friendName != nil
            if firstFromFriend != secondFromFriend {
                return firstFromFriend
            }
            if first.matchPercentage == second.matchPercentage {
                return first.anime.score > second.anime.score
            }
            return first.matchPercentage > second.matchPercentage
        }

        // The whole ranked list goes back. The ViewModel shows the first one and
        // keeps the rest for when the viewer says they have already seen it.
        return matches
    }

    // MARK: - Small helpers

    /// Whether this anime is in at least one genre the viewer picked.
    private func sharesAGenre(_ anime: Anime, with preferences: AnimePreferences) -> Bool {
        for genre in preferences.genres {
            if anime.genres.contains(genre) {
                return true
            }
        }
        return false
    }

    /// The genres for an error message. With nothing picked, "Action and Drama" would
    /// be an empty gap in the sentence, so it says "any genre" instead.
    private func describeGenres(in preferences: AnimePreferences) -> String {
        if preferences.genres.isEmpty {
            return "any genre"
        }
        return preferences.genreSummary
    }

    /// Turns a connection problem into something the viewer can act on.
    private func translate(_ error: AnimeCatalogueError) -> FindAnimeRecommendationsError {
        switch error {
        case .noConnection: return .noConnection
        case .tooManyRequests: return .catalogueBusy
        case .unavailable: return .catalogueUnavailable
        }
    }

    /// Scores one anime out of 100 against what the viewer asked for.
    ///
    /// I split the 100 points into two parts:
    /// - **60 points for genre fit.** This is the strongest signal, so it is worth the
    ///   most. An anime that hits both genres you picked beats one that only hits one.
    /// - **40 points for the score.** A well-liked anime is a safer bet for someone new,
    ///   but it matters less than actually wanting to watch that kind of show.
    ///
    /// When no genre was picked, the genre part is full marks, because every anime fits
    /// a request that did not ask for anything in particular.
    func matchPercentage(for anime: Anime, preferences: AnimePreferences) -> Int {

        var points = 0.0

        // Genre part, worth 60.
        if preferences.genres.isEmpty {
            points += 60.0
        } else {
            var matchingCount = 0.0
            for genre in preferences.genres {
                if anime.genres.contains(genre) {
                    matchingCount += 1.0
                }
            }
            let share = matchingCount / Double(preferences.genres.count)
            points += share * 60.0
        }

        // Score part, worth 40.
        points += (anime.score / 10.0) * 40.0

        // Round to a whole number, because "92% MATCH" reads better than
        // "91.7431% MATCH".
        var rounded = Int(points.rounded())
        if rounded > 100 { rounded = 100 }
        if rounded < 0 { rounded = 0 }
        return rounded
    }

    /// Builds the plain-English reasons shown under each recommendation.
    ///
    /// Every line here carries a real number or a real consequence. A reason that would
    /// be printed on every single result is not a reason, it is decoration, and it makes
    /// the whole explanation less believable.
    func buildReasons(for anime: Anime, preferences: AnimePreferences, friendName: String? = nil) -> [String] {

        var reasons: [String] = []

        // Reason 0: a friend sent it. This goes first because it is the reason the
        // viewer is most likely to act on.
        if let friendName = friendName {
            reasons.append("\(friendName) told you to watch this one")
        }

        // Reason 1: which of the genres they picked this anime actually has.
        // Sorted so the sentence comes out the same way every time.
        var matched: [String] = []
        var missing: [String] = []
        for genre in preferences.genres.sorted(by: { $0.displayName < $1.displayName }) {
            if anime.genres.contains(genre) {
                matched.append(genre.displayName)
            } else {
                missing.append(genre.displayName)
            }
        }

        if !matched.isEmpty {
            if missing.isEmpty {
                reasons.append("Matches the \(AnimePreferences.sentenceList(matched)) you picked")
            } else {
                // Being honest about the gap matters more than looking like a perfect
                // match. The viewer should see exactly what this one is missing.
                reasons.append("Matches \(AnimePreferences.sentenceList(matched)), but not \(AnimePreferences.sentenceList(missing))")
            }
        }

        // Reason 2: the actual score, not the word "highly".
        let scoreText = String(format: "%.1f", anime.score)
        if anime.score >= 8.0 {
            reasons.append("Rated \(scoreText) out of 10, which is high for this kind of show")
        } else {
            reasons.append("Rated \(scoreText) out of 10")
        }

        // Reason 3: the real time commitment against the budget they set.
        // Quoting both the hours and the episode count means the viewer can judge it
        // in the unit they think in, and still knows what they are signing up for.
        if preferences.timeCommitment.maximumHours != nil {
            reasons.append("\(anime.episodeCountText), \(anime.commitmentSummary) in total")
        }

        // Reason 4: what the status means for them, not just that it matched.
        switch preferences.status {
        case .finished:
            reasons.append("Already finished, so you can watch it all the way through")
        case .airing:
            reasons.append("Still airing, so new episodes are still coming out")
        case .any:
            break
        }

        return reasons
    }

    /// The smallest known time commitment in a list, in whole hours, used to tell the
    /// viewer how far to move the control. `nil` when nothing in the list has a known
    /// length.
    private func shortestCommitment(in anime: [Anime]) -> Int? {
        var shortest: Double? = nil
        for item in anime {
            guard let hours = item.totalHours else { continue }
            if shortest == nil || hours < shortest! {
                shortest = hours
            }
        }

        guard let shortestHours = shortest else { return nil }
        return Int(shortestHours.rounded())
    }
}
