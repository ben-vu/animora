//
//  SavedAnimeEntity+Anime.swift
//  Animora
//
//  Created by Benjamin Vu on 21/9/2026.
//

import Foundation
import CoreData

/// Converting between the Core Data copy of an anime and my own `Anime` struct.
///
/// The rest of the app only ever sees `Anime`. The Core Data classes stay inside the
/// repositories, so if I changed databases later nothing above them would notice.
extension SavedAnimeEntity {

    /// Builds an `Anime` from what was saved.
    func toAnime() -> Anime {

        var genres: [AnimeGenre] = []
        let genreNames = (genresText ?? "").components(separatedBy: ",")
        for name in genreNames {
            if let genre = AnimeGenre(rawValue: name) {
                genres.append(genre)
            }
        }

        var imageURL: URL? = nil
        if let link = imageLink {
            imageURL = URL(string: link)
        }

        // 0 episodes is how I save "not announced yet". No real series has 0
        // episodes, so it can't be mistaken for a real count.
        var episodeCount: Int? = nil
        if episodes > 0 {
            episodeCount = Int(episodes)
        }

        return Anime(
            id: Int(animeID),
            title: title ?? "Untitled",
            synopsis: synopsis ?? "",
            episodes: episodeCount,
            episodeMinutes: Int(episodeMinutes),
            score: score,
            status: AnimeStatus(rawValue: statusText ?? "") ?? .finished,
            genres: genres,
            imageURL: imageURL
        )
    }

    /// Copies an anime's details onto this saved copy.
    func copyDetails(from anime: Anime) {
        animeID = Int64(anime.id)
        title = anime.title
        synopsis = anime.synopsis
        episodes = Int64(anime.episodes ?? 0)
        episodeMinutes = Int64(anime.episodeMinutes)
        score = anime.score
        statusText = anime.status.rawValue

        var genreNames: [String] = []
        for genre in anime.genres {
            genreNames.append(genre.rawValue)
        }
        genresText = genreNames.joined(separator: ",")

        imageLink = anime.imageURL?.absoluteString
        savedAt = Date()
    }

    /// Finds the saved copy of an anime, or makes a new one.
    ///
    /// Every anime is only ever saved once. The watched record, the watchlist entry
    /// and any friends' picks all point at the same saved copy, which is what the
    /// relationships in the model are for.
    static func findOrCreate(for anime: Anime, in context: NSManagedObjectContext) -> SavedAnimeEntity {

        let request: NSFetchRequest<SavedAnimeEntity> = SavedAnimeEntity.fetchRequest()
        request.predicate = NSPredicate(format: "animeID == %@", NSNumber(value: anime.id))
        request.fetchLimit = 1

        var saved: SavedAnimeEntity? = nil
        do {
            saved = try context.fetch(request).first
        } catch {
            print("Couldn't look for a saved anime: \(error.localizedDescription)")
        }

        if saved == nil {
            saved = SavedAnimeEntity(context: context)
        }

        // Always refresh the details, so a rating that changed on the catalogue is
        // updated here too.
        saved!.copyDetails(from: anime)
        return saved!
    }
}
