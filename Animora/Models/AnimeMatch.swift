//
//  AnimeMatch.swift
//  Animora
//
//  Created by Benjamin Vu on 1/9/2026.
//

import Foundation

/// Anything Animora puts in front of a viewer must be able to say why it is being shown.
///
/// Animora's whole idea is that a recommendation comes with a reason. A suggestion with
/// nothing behind it is just a random pick, and people do not trust those.
protocol ViewerExplainable {

    /// The first line the viewer reads, normally the anime's title.
    var explanationHeadline: String { get }

    /// The plain-English reasons this was recommended, in the order to show them.
    func reasonsForViewer() -> [String]
}

/// One anime that passed all the rules, with how well it fits and why.
///
/// This is what the suggestion screen shows: the anime, how well it fits, and the ticks
/// explaining why it was picked.
struct AnimeMatch: Identifiable, Hashable {

    /// The anime being recommended.
    let anime: Anime

    /// How well it fits the request, from 0 to 100.
    let matchPercentage: Int

    /// The reasons shown under the title.
    let reasons: [String]

    /// `Identifiable` needs an `id`, and the anime's own id is already unique, so
    /// there is no point inventing a second one.
    var id: Int { anime.id }

    /// The percentage the way the UI shows it, like "92% MATCH".
    var matchLabel: String {
        "\(matchPercentage)% MATCH"
    }
}

// MARK: - ViewerExplainable

extension AnimeMatch: ViewerExplainable {

    var explanationHeadline: String {
        anime.title
    }

    func reasonsForViewer() -> [String] {
        reasons
    }
}
