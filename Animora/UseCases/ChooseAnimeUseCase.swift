//
//  ChooseAnimeUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 4/9/2026.
//

import Foundation

/// The ways choosing an anime can go wrong.
///
/// If the viewer taps 'I'll watch this' on a suggestion that is
/// no longer the one on screen e.g after the screen has moved on.
enum ChooseAnimeError: LocalizedError, Equatable {

    case notTheCurrentSuggestion

    var errorDescription: String? {
        switch self {
        case .notTheCurrentSuggestion:
            return "That suggestion has already moved on. Have a look at the one on screen instead."
        }
    }
}

/// Records which anime the viewer has decided to watch.
///
/// You can only choose the anime currently being
/// suggested. Without this rule a stale tap could commit the viewer to something the
/// app has already moved past.
///
/// This is its own Use Case rather than the ViewModel just setting a property, so the
/// rule lives in one obvious, testable place.
struct ChooseAnimeUseCase {

    func execute(chosenMatch: AnimeMatch, currentSuggestion: AnimeMatch?) throws -> AnimeMatch {

        guard let current = currentSuggestion, current.id == chosenMatch.id else {
            throw ChooseAnimeError.notTheCurrentSuggestion
        }

        return chosenMatch
    }
}
