//
//  FindAnimeRecommendationsUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 4/9/2026.
//

import Foundation

/// The ways finding recommendations can go wrong.
///
/// I split 'nothing matched' into separate cases on purpose. Telling someone
/// "no results" is useless, because it does not tell them which control to change.
enum FindAnimeRecommendationsError: LocalizedError, Equatable {

    case noAnimeInChosenGenres(genreNames: String)
    case everythingAlreadyWatched(genreNames: String)
    case noFinishedSeriesAvailable
    case noAiringSeriesAvailable
    case episodeLimitTooShort(shortestAvailable: Int)

    var errorDescription: String? {
        switch self {

        case .noAnimeInChosenGenres(let genreNames):
            return "We don't have anything in \(genreNames) yet. Try adding another genre to widen the search."

        case .everythingAlreadyWatched(let genreNames):
            return "You've already watched everything we have in \(genreNames). Try another genre to find something new."

        case .noFinishedSeriesAvailable:
            return "Everything we found is still airing week to week. Set Status to Any if you don't mind waiting for new episodes."

        case .noAiringSeriesAvailable:
            return "Nothing we found is currently airing. Set Status to Any to include series that have already finished."

        case .episodeLimitTooShort(let shortestAvailable):
            return "Everything we found is longer than your limit. The shortest one is \(shortestAvailable) episodes, so try raising your episode limit."
        }
    }
}

/// Takes what the viewer is in the mood for and returns a short ranked list of anime.
///
/// **The business operation:** this is the heart of Animora. It is what happens when
/// the viewer taps "Find my anime".
///
/// **The business rules it protects:**
/// 1. An anime must be in at least one genre the viewer picked.
/// 2. An anime the viewer has already marked as watched is never suggested again.
/// 3. It must have the airing status they asked for.
/// 4. It must fit inside their episode limit.
/// 5. Every result comes with at least one reason, quoting real numbers.
///
/// **On how many results come back.** This returns *everything* that passed the rules,
/// ranked best first. The viewer is only ever shown the first one — the app suggests a
/// single anime at a time, because one decision is far easier to make than a list of
/// five. The rest are kept so that "already seen it" can show the next one instantly
/// instead of running the whole search again.
///
/// This is a `struct` because it holds no state of its own. It takes a request in and
/// gives an answer back — two copies would behave identically.
struct FindAnimeRecommendationsUseCase {

    /// Where the anime come from. This is the protocol, not a specific list or API,
    /// so this Use Case does not care where they actually live.
    let repository: AnimeRepository

    /// What the viewer has already seen. The search consults this so a rejected
    /// suggestion never comes back.
    let watchHistory: WatchHistoryRepository

    init(repository: AnimeRepository = LocalAnimeRepository(),
         watchHistory: WatchHistoryRepository = InMemoryWatchHistoryRepository()) {
        self.repository = repository
        self.watchHistory = watchHistory
    }

    /// Runs the search.
    ///
    /// - Parameter preferences: what the viewer asked for.
    /// - Returns: every match that passed the rules, best fit first.
    /// - Throws: a `FindAnimeRecommendationsError` naming the filter to change.
    func execute(preferences: AnimePreferences) throws -> [AnimeMatch] {

        let allAnime = repository.anime

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
            throw FindAnimeRecommendationsError.noAnimeInChosenGenres(
                genreNames: preferences.genreSummary
            )
        }

        // Rule 2: drop anything the viewer has already told us they have seen.
        // This goes straight after the genre filter because it is the most personal
        // exclusion — it is the viewer's own answer, not a preference they set.
        var notWatchedYet: [Anime] = []
        for anime in inChosenGenres {
            if watchHistory.hasWatched(animeID: anime.id) == false {
                notWatchedYet.append(anime)
            }
        }

        if notWatchedYet.isEmpty {
            throw FindAnimeRecommendationsError.everythingAlreadyWatched(
                genreNames: preferences.genreSummary
            )
        }

        // Rule 3: check the airing status next.
        // I do status before episodes so that if both are wrong, the message talks
        // about status, which is the bigger change for the viewer to make.
        var rightStatus: [Anime] = []
        switch preferences.status {
        case .any:
            rightStatus = notWatchedYet
        case .finished:
            for anime in notWatchedYet where anime.status == .finished {
                rightStatus.append(anime)
            }
            if rightStatus.isEmpty {
                throw FindAnimeRecommendationsError.noFinishedSeriesAvailable
            }
        case .airing:
            for anime in notWatchedYet where anime.status == .airing {
                rightStatus.append(anime)
            }
            if rightStatus.isEmpty {
                throw FindAnimeRecommendationsError.noAiringSeriesAvailable
            }
        }

        // Rule 4: now the episode limit.
        var shortEnough: [Anime] = []
        if let maximumEpisodes = preferences.episodeLimit.maximumEpisodes {
            for anime in rightStatus where anime.episodes <= maximumEpisodes {
                shortEnough.append(anime)
            }
            if shortEnough.isEmpty {
                // Telling them the shortest one we have is what makes this useful —
                // now they know how far to move the control.
                throw FindAnimeRecommendationsError.episodeLimitTooShort(
                    shortestAvailable: shortestLength(in: rightStatus)
                )
            }
        } else {
            shortEnough = rightStatus
        }

        // Score whatever survived and attach the reasons.
        var matches: [AnimeMatch] = []
        for anime in shortEnough {
            let match = AnimeMatch(
                anime: anime,
                matchPercentage: matchPercentage(for: anime, preferences: preferences),
                reasons: buildReasons(for: anime, preferences: preferences)
            )
            matches.append(match)
        }

        // Best match first. When two score the same I put the higher rated one first,
        // so the order is always the same and my tests are reliable.
        matches.sort { first, second in
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
    func buildReasons(for anime: Anime, preferences: AnimePreferences) -> [String] {

        var reasons: [String] = []

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

        // Reason 3: the real episode count against the limit they set.
        if let maximumEpisodes = preferences.episodeLimit.maximumEpisodes {
            reasons.append("\(anime.episodes) episodes, inside your limit of \(maximumEpisodes)")
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

    /// The shortest series in a list, used to tell the viewer how far to raise their
    /// episode limit.
    private func shortestLength(in anime: [Anime]) -> Int {
        // Starting from the first anime rather than a huge made-up number is easier to
        // read and cannot be wrong.
        guard var shortest = anime.first?.episodes else { return 0 }
        for item in anime {
            if item.episodes < shortest {
                shortest = item.episodes
            }
        }
        return shortest
    }
}
