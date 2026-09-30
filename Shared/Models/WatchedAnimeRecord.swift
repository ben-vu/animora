//
//  WatchedAnimeRecord.swift
//  Animora
//
//  Created by Benjamin Vu on 23/9/2026.
//

import Foundation

/// A note that the viewer has seen an anime, with a time attached.
///
/// There are two ways to end up with one of these:
/// - The viewer taps 'Already seen it' on a suggestion, because they watched it
///   before they ever used Animora.
/// - The viewer ticks off the last episode of something on their Now watching list.
///
/// - The same anime can only be recorded once. Marking it twice is a mistake, and the
///   app says so rather than silently saving a duplicate.
/// - Only an anime that actually exists in the catalogue can be recorded.
/// - Once recorded, that anime is never recommended again.
struct WatchedAnimeRecord: Identifiable, Hashable {

    /// Which anime was watched.
    let animeID: Int

    /// The anime's title at the time it was marked, so it can be displayed.
    let animeTitle: String

    /// When the viewer marked it.
    let markedAt: Date

    /// How the viewer came to have seen it.
    ///
    /// I added this in Assessment 3 once the history was saved for good. The
    /// "Already seen" screen reads a lot better when it can tell apart the shows
    /// Animora actually helped with from the ones the viewer had seen already.
    var reason: WatchedReason = .seenBeforeAnimora

    /// A viewer can only have one record per anime, so the anime's id works as the
    /// record id too.
    var id: Int { animeID }
}

/// How an anime ended up on the viewer's watched list.
enum WatchedReason: String, CaseIterable, Hashable {

    /// They told us they had already seen it.
    case seenBeforeAnimora

    /// They picked it through Animora and ticked off every episode.
    case finishedWithAnimora

    var displayName: String {
        switch self {
        case .seenBeforeAnimora: return "Seen before"
        case .finishedWithAnimora: return "Finished with Animora"
        }
    }
}
