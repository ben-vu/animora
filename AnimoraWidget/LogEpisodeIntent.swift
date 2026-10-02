//
//  LogEpisodeIntent.swift
//  AnimoraWidget
//
//  Created by Benjamin Vu on 30/9/2026.
//

import AppIntents
import WidgetKit

/// What happens when the viewer taps "Watched ep 4" on the widget.
///
/// This runs inside the widget, without opening the app. The whole point is that
/// ticking off an episode should take one tap at the end of an episode, from the
/// Home Screen, rather than: unlock, find the app, open it, find the list, tap.
/// That's the sort of friction that makes people stop tracking, and then lose their
/// place.
///
/// It calls the same `LogEpisodeWatchedUseCase` the app does, through the same Core
/// Data repositories, so the rules can't be different on the widget.
struct LogEpisodeIntent: AppIntent {

    static let title: LocalizedStringResource = "Watched an episode"

    /// Which anime to tick off an episode of.
    @Parameter(title: "Anime ID")
    var animeID: Int

    /// App Intents need an empty init to rebuild the intent when it runs.
    init() {}

    init(animeID: Int) {
        self.animeID = animeID
    }

    func perform() async throws -> some IntentResult {
        let logEpisodeWatched = LogEpisodeWatchedUseCase(
            watchlist: CoreDataWatchlistRepository(),
            watchHistory: CoreDataWatchHistoryRepository()
        )

        do {
            try logEpisodeWatched.execute(animeID: animeID)
        } catch {
            // The widget has no room for a message. The usual cause is a double tap
            // after the last episode, and in that case redrawing the widget already
            // shows the viewer what is true now, which is the best answer anyway.
            print("Couldn't tick off the episode from the widget: \(error.localizedDescription)")
        }

        // Saving already asks the widget to reload, and WidgetKit also redraws it
        // after any button intent finishes.
        return .result()
    }
}
