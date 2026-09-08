//
//  RecommendationViewModel.swift
//  Animora
//
//  Created by Benjamin Vu on 5/9/2026.
//

import Foundation

/// Holds what the viewer chose and which anime is being suggested right now.
///
/// The screens only talk to this, and this only talks to the Use Cases, so none of my
/// Views contain any business rules.
///
/// It is a `class` because SwiftUI needs an `ObservableObject`, and because every screen
/// shares this one object.
class RecommendationViewModel: ObservableObject {

    /// The request the viewer is building up.
    @Published var preferences = AnimePreferences()

    /// The remaining suggestions, best first. The viewer only ever sees the first one.
    ///
    /// I keep the rest rather than throwing them away, so that saying "already seen"
    /// has something to fall back on straight away instead of running another search.
    @Published private(set) var suggestions: [AnimeMatch] = []

    /// The message to show if something went wrong. The error enums already write this
    /// in the viewer's language, so the View can show it exactly as it is.
    @Published var errorMessage: String? = nil

    /// The anime the viewer settled on.
    @Published var chosenMatch: AnimeMatch? = nil

    private let findRecommendations: FindAnimeRecommendationsUseCase
    private let markAsAlreadyWatched: MarkAsAlreadyWatchedUseCase
    private let chooseAnime: ChooseAnimeUseCase

    /// The repository is passed in from outside rather than created in here, so
    /// `ContentView` decides what the app runs on and tests can hand in a fake.
    init(repository: AnimeRepository,
         watchHistory: WatchHistoryRepository = InMemoryWatchHistoryRepository()) {
        self.findRecommendations = FindAnimeRecommendationsUseCase(
            repository: repository,
            watchHistory: watchHistory
        )
        self.markAsAlreadyWatched = MarkAsAlreadyWatchedUseCase(
            animeRepository: repository,
            watchHistory: watchHistory
        )
        self.chooseAnime = ChooseAnimeUseCase()
    }

    // MARK: - What the screens read

    /// The one anime being suggested right now.
    var currentSuggestion: AnimeMatch? {
        suggestions.first
    }

    /// How many more are lined up behind this one.
    var remainingCount: Int {
        max(0, suggestions.count - 1)
    }

    /// Whether the viewer has been through every suggestion.
    var hasRunOut: Bool {
        suggestions.isEmpty
    }

    // MARK: - What the screens can do

    /// Turns a genre on if it is off, or off if it is on.
    func toggleGenre(_ genre: AnimeGenre) {
        if preferences.genres.contains(genre) {
            preferences.genres.remove(genre)
        } else {
            preferences.genres.insert(genre)
        }
    }

    /// Whether a genre button should look selected.
    func isGenreChosen(_ genre: AnimeGenre) -> Bool {
        preferences.genres.contains(genre)
    }

    /// Runs the search. Returns `true` when there is something to suggest.
    @discardableResult
    func findAnime() -> Bool {
        errorMessage = nil

        do {
            suggestions = try findRecommendations.execute(preferences: preferences)
            return true
        } catch {
            errorMessage = error.localizedDescription
            suggestions = []
            return false
        }
    }

    /// Records that the viewer has seen the current suggestion, and moves to the next.
    ///
    /// The anime is written to the watch history, so it will not come back in this
    /// search or in any search after it.
    func markCurrentAsAlreadyWatched() {
        guard let current = currentSuggestion else { return }
        errorMessage = nil

        do {
            try markAsAlreadyWatched.execute(animeID: current.anime.id)
            suggestions.removeFirst()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Records the anime the viewer picked. Returns `true` when it was accepted.
    @discardableResult
    func chooseCurrent() -> Bool {
        guard let current = currentSuggestion else { return false }
        errorMessage = nil

        do {
            chosenMatch = try chooseAnime.execute(
                chosenMatch: current,
                currentSuggestion: currentSuggestion
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Clears the current search, ready for a brand new request.
    ///
    /// The watch history is deliberately not cleared. 'I have already seen this' is a
    /// fact about the viewer, not part of one search, so it has to outlive the request
    /// that produced it.
    func startOver() {
        preferences = AnimePreferences()
        suggestions = []
        errorMessage = nil
        chosenMatch = nil
    }
}
