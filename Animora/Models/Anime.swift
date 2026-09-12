//
//  Anime.swift
//  Animora
//
//  Created by Benjamin Vu on 1/9/2026.
//

import Foundation

/// One anime series that Animora can recommend.
struct Anime: Identifiable, Hashable {

    /// The number that tells this anime apart from every other one.
    let id: Int

    /// The name shown to the viewer.
    let title: String

    /// A short description for the detail screen.
    let synopsis: String

    /// How many episodes the whole series has.
    let episodes: Int

    /// How long a single episode runs, in minutes.
    ///
    /// Almost all TV anime run about 24 minutes, so on its own this number is not very
    /// interesting. It matters because it turns an episode count into an amount of
    /// time, which is the unit the viewer actually thinks in.
    let episodeMinutes: Int

    /// The average score out of 10 that viewers gave it.
    let score: Double

    /// Whether the series has finished or is still coming out.
    let status: AnimeStatus

    /// Every genre this anime belongs to.
    let genres: [AnimeGenre]

    /// Roughly how many hours it takes to watch the whole series.
    var totalHours: Double {
        Double(episodes * episodeMinutes) / 60.0
    }

    /// The commitment written the way it is shown on screen, like "about 10 hours".
    var commitmentSummary: String {
        if totalHours < 1.0 {
            return "under an hour"
        }
        return "about \(Int(totalHours.rounded())) hours"
    }

    /// A small line like "Action • Drama • Fantasy" for the UI to show.
    ///
    /// This lives here rather than in a View because it is a fact about the anime,
    /// not a fact about one particular screen.
    var genreSummary: String {
        var names: [String] = []
        for genre in genres {
            names.append(genre.displayName)
        }
        return names.joined(separator: " • ")
    }
}

/// The genres a viewer can pick from.
enum AnimeGenre: String, CaseIterable, Identifiable, Hashable {

    case action = "Action"
    case adventure = "Adventure"
    case comedy = "Comedy"
    case drama = "Drama"
    case fantasy = "Fantasy"
    case romance = "Romance"
    case sciFi = "Sci-Fi"
    case sliceOfLife = "Slice of Life"
    case sports = "Sports"
    case thriller = "Thriller"

    var id: String { rawValue }

    var displayName: String { rawValue }

    /// A plain-English hint about what the genre actually means.
    ///
    /// The person this app is built for is new to anime, so genre names on their own
    /// do not tell them much. The hint lives on the genre itself so every screen that
    /// shows a genre can show the explanation too.
    var beginnerHint: String {
        switch self {
        case .action: return "Fights, chases and big set pieces"
        case .adventure: return "A journey to somewhere new"
        case .comedy: return "Made to make you laugh"
        case .drama: return "Heavy on emotion and character"
        case .fantasy: return "Magic, monsters and made-up worlds"
        case .romance: return "The relationship is the main story"
        case .sciFi: return "Future tech, space and robots"
        case .sliceOfLife: return "Calm, everyday, low stakes"
        case .sports: return "Training, teams and competition"
        case .thriller: return "Tense, with a mystery to solve"
        }
    }
}

/// Whether a series has finished airing or is still releasing episodes.
///
/// This matters because someone who wants to watch a whole series tonight cannot do
/// that with a show that is still coming out one episode a week.
enum AnimeStatus: String, CaseIterable, Identifiable, Hashable {

    case finished = "Finished"
    case airing = "Currently Airing"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
