//
//  AnimePreferences.swift
//  Animora
//
//  Created by Benjamin Vu on 1/9/2026.
//

import Foundation

/// This is one recommendation request. Nothing here is saved anywhere
/// it only lives in memory for the length of one search, which matches the idea
/// that Animora has no accounts and every request starts fresh.
struct AnimePreferences: Hashable {

    /// The genres the viewer tapped. Empty means "no preference".
    var genres: Set<AnimeGenre> = []

    /// How long a series the viewer is willing to commit to.
    var episodeLimit: EpisodeLimit = .any

    /// Whether they want something finished, still airing, or don't mind.
    var status: AnimeStatusPreference = .any

    /// The genres written out the way a person would say them,
    /// like "Action and Drama".
    var genreSummary: String {
        var names: [String] = []
        for genre in genres.sorted(by: { $0.displayName < $1.displayName }) {
            names.append(genre.displayName)
        }
        return AnimePreferences.sentenceList(names)
    }

    /// Joins names the way a person would say them: one on its own, two joined with
    /// "and", three or more with commas and then "and".
    static func sentenceList(_ names: [String]) -> String {
        if names.isEmpty { return "" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return names[0] + " and " + names[1] }

        var allButLast: [String] = []
        for index in 0..<(names.count - 1) {
            allButLast.append(names[index])
        }
        return allButLast.joined(separator: ", ") + " and " + names[names.count - 1]
    }
}

/// How many episodes the viewer will commit to.
enum EpisodeLimit: CaseIterable, Identifiable, Hashable {

    case under12
    case under24
    case under50
    case any

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .under12: return "Under 12"
        case .under24: return "Under 24"
        case .under50: return "Under 50"
        case .any: return "Any length"
        }
    }

    /// The most episodes that still fits this choice, or `nil` when there is no limit.
    var maximumEpisodes: Int? {
        switch self {
        case .under12: return 12
        case .under24: return 24
        case .under50: return 50
        case .any: return nil
        }
    }
}

/// Whether the viewer wants a finished series, one still airing, or doesn't mind.
enum AnimeStatusPreference: CaseIterable, Identifiable, Hashable {

    case finished
    case airing
    case any

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .finished: return "Finished"
        case .airing: return "Currently Airing"
        case .any: return "Any"
        }
    }
}
