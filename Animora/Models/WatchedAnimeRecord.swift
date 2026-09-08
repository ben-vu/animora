//
//  WatchedAnimeRecord.swift
//  Animora
//
//  Created by Benjamin Vu on 1/9/2026.
//

import Foundation

/// The moment someone taps 'Already watched, pick another' on the detail screen. It is
/// a single event with a time attached, not a running total.
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

    /// A viewer can only have one record per anime, so the anime's id works as the
    /// record id too.
    var id: Int { animeID }
}
