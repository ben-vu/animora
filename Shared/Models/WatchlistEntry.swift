//
//  WatchlistEntry.swift
//  Animora
//
//  Created by Benjamin Vu on 23/9/2026.
//

import Foundation

/// One anime the viewer has picked and is partway through.
///
/// In Assessment 2 the app stopped the moment the viewer tapped 'I'll watch this'.
/// Talking to people new to anime, the problem did not stop there though. They would
/// pick something, watch two episodes, get busy, and a week later not remember what
/// they were watching or how far in they were. This is the thing that remembers for
/// them, and it is what the Up next widget shows.
struct WatchlistEntry: Identifiable, Hashable {

    /// The anime being watched.
    let anime: Anime

    /// How many episodes the viewer has ticked off so far.
    var episodesWatched: Int

    /// When they picked it.
    let startedAt: Date

    /// The last time they ticked off an episode. The widget shows whichever entry was
    /// touched most recently, because that is almost always the one they are on.
    var updatedAt: Date

    /// One entry per anime, so the anime's id works as the entry id too.
    var id: Int { anime.id }

    /// The episode they will watch next.
    var nextEpisodeNumber: Int {
        episodesWatched + 1
    }

    /// How many episodes are left, or `nil` when the series has not said how many
    /// episodes it will have.
    var episodesLeft: Int? {
        guard let total = anime.episodes else { return nil }
        return max(0, total - episodesWatched)
    }

    /// Whether every episode has been ticked off.
    ///
    /// A series with an unknown episode count can never be finished this way, which
    /// is right: nobody can finish a show that is still coming out.
    var isFinished: Bool {
        guard let left = episodesLeft else { return false }
        return left == 0
    }

    /// How far through they are, from 0 to 1, for the progress bars.
    var progress: Double {
        guard let total = anime.episodes, total > 0 else { return 0 }
        return min(1.0, Double(episodesWatched) / Double(total))
    }

    /// Where they are, the way it is shown on screen, like "Episode 4 of 12".
    var progressSummary: String {
        if let total = anime.episodes {
            return "Episode \(min(nextEpisodeNumber, total)) of \(total)"
        }
        return "Episode \(nextEpisodeNumber)"
    }

    /// How much time is left, like "about 3 hours left".
    ///
    /// This is the same idea as the time control on the request screen. Someone new
    /// to anime knows what three hours costs them. "9 episodes left" makes them do
    /// maths first.
    var timeLeftSummary: String {
        guard let left = episodesLeft else {
            return "Still airing, no end date yet"
        }
        let minutesLeft = left * anime.episodeMinutes
        if minutesLeft == 0 {
            return "All done"
        }
        if minutesLeft < 60 {
            return "under an hour left"
        }
        let hoursLeft = Int((Double(minutesLeft) / 60.0).rounded())
        if hoursLeft == 1 {
            return "about 1 hour left"
        }
        return "about \(hoursLeft) hours left"
    }
}
