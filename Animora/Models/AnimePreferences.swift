//
//  AnimePreferences.swift
//  Animora
//
//  Created by Benjamin Vu on 1/9/2026.
//

import Foundation

/// What the viewer said they were in the mood for.
///
/// This is one recommendation request. Nothing here is saved anywhere, it only lives
/// in memory for the length of one search, which matches the idea that Animora has no
/// accounts and every request starts fresh.
struct AnimePreferences: Hashable {

    /// The genres the viewer tapped. Empty means "no preference".
    var genres: Set<AnimeGenre> = []

    /// How much total watching time the viewer is willing to put in.
    var timeCommitment: TimeCommitment = .any

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

/// How much total watching time the viewer is willing to put in.
///
/// This replaced an earlier "under 12 / under 24 / under 50 episodes" control. The
/// episode count was the wrong unit: my audience is people new to anime, and a
/// newcomer has no feel for what 24 episodes costs them. Hours they can judge
/// immediately, because they can weigh it against the evenings they actually have.
enum TimeCommitment: CaseIterable, Identifiable, Hashable {

    case aFewEvenings
    case acoupleOfWeeks
    case any

    var id: String { displayName }

    var displayName: String {
        switch self {
        case .aFewEvenings: return "A few evenings"
        case .acoupleOfWeeks: return "A couple of weeks"
        case .any: return "However long"
        }
    }

    /// The rough hour figure behind each option, shown under the control so the
    /// viewer knows what they are actually choosing.
    var explanation: String {
        switch self {
        case .aFewEvenings: return "Under 6 hours in total"
        case .acoupleOfWeeks: return "Under 15 hours in total"
        case .any: return "Length doesn't matter"
        }
    }

    /// The most hours that still fits this choice, or `nil` when there is no limit.
    ///
    /// Returning an optional means "however long" is genuinely the absence of a limit,
    /// rather than a huge made-up number the rest of the code has to know about.
    var maximumHours: Double? {
        switch self {
        case .aFewEvenings: return 6.0
        case .acoupleOfWeeks: return 15.0
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
