//
//  AnimeRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 3/9/2026.
//

import Foundation

/// Anything that can supply Animora with anime.
///
/// The Use Cases talk to this protocol and never name a concrete type, so they have no
/// idea whether the anime came from a list built into the app or a web API. In
/// Assessment 2 this was a hard-coded list of 15. In Assessment 3 it is the Tenrai
/// catalogue, and swapping them did not change a single Use Case rule, which was the
/// whole point of putting the protocol here in the first place.
///
/// The methods are `async` now because the anime come from the internet, and they
/// `throw` because the internet can fail.
protocol AnimeRepository {

    /// Every anime this source has loaded so far in this session.
    ///
    /// The 'Already seen it' Use Case checks this to make sure the anime is real
    /// before it records it.
    var anime: [Anime] { get }

    /// Loads the anime that could suit this request.
    ///
    /// This does a first rough cut (genres and airing status) so the app does not
    /// download the whole catalogue. The actual rules are still applied by
    /// `FindAnimeRecommendationsUseCase`.
    func load(for preferences: AnimePreferences) async throws -> [Anime]

    /// Looks up one anime by its id, or returns `nil` if there isn't one.
    func findAnime(withID id: Int) async throws -> Anime?

    /// Looks up the best match for a title a friend sent, or returns `nil`.
    func searchAnime(titled title: String) async throws -> Anime?
}

/// The ways fetching from the catalogue can go wrong.
///
/// These are thrown by the repository and are about the connection, not about the
/// viewer's request. The Use Cases turn them into messages in the viewer's language,
/// which is why there is no `errorDescription` here.
enum AnimeCatalogueError: Error, Equatable {

    /// The phone is not connected to the internet.
    case noConnection

    /// The catalogue said too many requests were made too quickly.
    case tooManyRequests

    /// The catalogue answered with something unexpected, or not at all.
    case unavailable
}
