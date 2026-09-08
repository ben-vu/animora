//
//  MarkAsAlreadyWatchedUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 4/9/2026.
//
import Foundation

/// The ways marking an anime as already watched can go wrong.
///
/// When they tap
/// "Already watched, pick another".
enum MarkAsAlreadyWatchedError: LocalizedError, Equatable {

    /// The anime is not in the catalogue, so there is nothing to record.
    case animeNotInCatalogue

    /// This anime is already on the viewer's watched list.
    case alreadyMarkedAsWatched(animeTitle: String)

    var errorDescription: String? {
        switch self {

        case .animeNotInCatalogue:
            // The viewer does not need to see an id. That is only useful to me while
            // I am debugging, so it stays out of the message.
            return "We can't find that anime any more, so we couldn't add it to your watched list. Go back and pick another recommendation."

        case .alreadyMarkedAsWatched(let animeTitle):
            return "\(animeTitle) is already on your watched list, so we won't suggest it again. Tap Start over for a fresh recommendation."
        }
    }
}

/// Records that the viewer has already seen an anime, so it is never suggested again.
///
/// This is what happens when the viewer taps
/// 'Already watched, pick another'. It is how the app learns from a rejected
/// suggestion instead of offering the same thing over and over.
///
/// This is the piece that makes Animora feel like it is listening. Without it, a viewer
/// who has already seen the top result has no way to say so, and every search gives
/// them the same answer.
///
/// Business rules:
/// 1. Only an anime that really exists in the catalogue can be recorded. Recording an
///    id we know nothing about would put a broken row on the watched list.
/// 2. The same anime cannot be recorded twice. A duplicate usually means the viewer
///    tapped twice by accident, so the app says so rather than saving two identical
///    rows.
///
/// This is a `struct` because it holds nothing itself. The list of watched anime lives
/// in the repository, which is where shared state belongs.
struct MarkAsAlreadyWatchedUseCase {

    /// Used to check the anime is real and to look up its title.
    let animeRepository: AnimeRepository

    /// Where the record gets saved.
    let watchHistory: WatchHistoryRepository

    /// Marks one anime as watched.
    ///
    /// - Parameters:
    ///   - animeID: which anime the viewer has seen.
    ///   - date: when they marked it. I pass this in rather than calling `Date()`
    ///     inside, so the tests can use a fixed date and check the saved record
    ///     exactly.
    /// - Returns: the record that was saved.
    /// - Throws: a `MarkAsAlreadyWatchedError` explaining what went wrong.
    @discardableResult
    func execute(animeID: Int, on date: Date = Date()) throws -> WatchedAnimeRecord {

        // Rule 1: find the anime, and stop if it does not exist.
        var foundAnime: Anime? = nil
        for anime in animeRepository.anime {
            if anime.id == animeID {
                foundAnime = anime
            }
        }

        guard let anime = foundAnime else {
            throw MarkAsAlreadyWatchedError.animeNotInCatalogue
        }

        // Rule 2: do not let the same anime be recorded twice.
        if watchHistory.hasWatched(animeID: animeID) {
            throw MarkAsAlreadyWatchedError.alreadyMarkedAsWatched(animeTitle: anime.title)
        }

        let record = WatchedAnimeRecord(
            animeID: anime.id,
            animeTitle: anime.title,
            markedAt: date
        )

        watchHistory.add(record)
        return record
    }
}
