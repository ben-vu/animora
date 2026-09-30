//
//  Anime.swift
//  Animora
//
//  Created by Benjamin Vu on 23/9/2026.
//

import Foundation

/// One anime series that Animora can recommend.
struct Anime: Identifiable, Hashable {

    /// The number that tells this anime apart from every other one.
    ///
    /// Since moving to the Tenrai catalogue this is the MyAnimeList id, which is
    /// handy because it is the same number that appears in a MyAnimeList link a
    /// friend might share.
    let id: Int

    /// The name shown to the viewer.
    let title: String

    /// A short description for the detail screen.
    let synopsis: String

    /// How many episodes the whole series has.
    ///
    /// This is optional because a lot of series that are still airing have not
    /// announced how many episodes they will have. I would rather say "we don't know
    /// yet" than guess a number and have the viewer plan their week around it.
    let episodes: Int?

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

    /// The cover art, if the catalogue has one. The default of `nil` means the tests
    /// and older code that never had pictures still work without changes.
    var imageURL: URL? = nil

    /// Roughly how many hours it takes to watch the whole series, or `nil` when the
    /// episode count is not known yet.
    var totalHours: Double? {
        guard let episodes = episodes else { return nil }
        return Double(episodes * episodeMinutes) / 60.0
    }

    /// The commitment written the way it is shown on screen, like "about 10 hours".
    var commitmentSummary: String {
        guard let totalHours = totalHours else {
            return "length not known yet"
        }
        if totalHours < 1.0 {
            return "under an hour"
        }
        return "about \(Int(totalHours.rounded())) hours"
    }

    /// The episode count written out, like "12 episodes" or "1 episode".
    var episodeCountText: String {
        guard let episodes = episodes else {
            return "Episode count not announced"
        }
        if episodes == 1 {
            return "1 episode"
        }
        return "\(episodes) episodes"
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

    /// Whether this looks like a follow-on to another series, like "Season 2".
    ///
    /// The catalogue's popular list is full of these. "Attack on Titan Season 3" is
    /// very popular, but it is useless to someone who has not seen the first one, and
    /// my viewer is someone new to anime. The catalogue does not tell me directly
    /// whether something is a sequel in its search results, so I look for the words
    /// sequels nearly always have in their titles. It is not perfect, but it catches
    /// the common ones.
    var looksLikeASequel: Bool {
        let lowercasedTitle = " " + title.lowercased() + " "
        let sequelWords = [
            " season ", "2nd", "3rd", "4th", "5th", "6th",
            " part 2", " part ii", " ii ", " iii ",
            " arc ", " arc:", "the movie", ": final", " final season"
        ]
        for word in sequelWords {
            if lowercasedTitle.contains(word) {
                return true
            }
        }
        return false
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

    /// The number the Tenrai catalogue uses for this genre.
    ///
    /// These come from MyAnimeList, which Tenrai copies. MyAnimeList calls thrillers
    /// "Suspense", which is why that one does not line up with the name.
    var catalogueGenreID: Int {
        switch self {
        case .action: return 1
        case .adventure: return 2
        case .comedy: return 4
        case .drama: return 8
        case .fantasy: return 10
        case .romance: return 22
        case .sciFi: return 24
        case .sliceOfLife: return 36
        case .sports: return 30
        case .thriller: return 41
        }
    }

    /// Turns a genre name from the catalogue back into one of mine, or `nil` for
    /// genres Animora does not offer (like "Supernatural").
    static func fromCatalogueName(_ name: String) -> AnimeGenre? {
        switch name {
        case "Action": return .action
        case "Adventure": return .adventure
        case "Comedy": return .comedy
        case "Drama": return .drama
        case "Fantasy": return .fantasy
        case "Romance": return .romance
        case "Sci-Fi": return .sciFi
        case "Slice of Life": return .sliceOfLife
        case "Sports": return .sports
        // MyAnimeList splits what a newcomer would call a thriller into these two.
        case "Suspense", "Mystery": return .thriller
        default: return nil
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
