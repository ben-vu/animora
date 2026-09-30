//
//  CoreDataWatchlistRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation
import CoreData

/// Saves the Now watching list with Core Data.
///
/// The app and the widget both create one of these, and both end up reading and
/// writing the same file in the App Group container.
class CoreDataWatchlistRepository: WatchlistRepository {

    private let database: AnimoraDatabase

    init(database: AnimoraDatabase = AnimoraDatabase.shared) {
        self.database = database
    }

    var entries: [WatchlistEntry] {
        // Pick up anything the widget or share extension wrote since the last read.
        database.refreshFromOtherProcesses()
        let context = database.context
        var entries: [WatchlistEntry] = []

        context.performAndWait {
            let request: NSFetchRequest<WatchlistEntryEntity> = WatchlistEntryEntity.fetchRequest()

            // Only shows that are still in progress: ones with episodes left, or ones
            // still airing with no episode count yet (saved as 0). A finished show is
            // moved to the history by the Use Case, so this is a safety net that makes
            // sure the widget can never show something the viewer has already finished.
            request.predicate = NSPredicate(format: "anime.episodes == 0 OR episodesWatched < anime.episodes")

            // Most recently touched first, because that is the one the viewer is on.
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]

            do {
                let results = try context.fetch(request)
                for entity in results {
                    if let entry = makeEntry(from: entity) {
                        entries.append(entry)
                    }
                }
            } catch {
                print("Couldn't load the watchlist: \(error.localizedDescription)")
            }
        }

        return entries
    }

    func entry(forAnimeID animeID: Int) -> WatchlistEntry? {
        let context = database.context
        var found: WatchlistEntry? = nil

        context.performAndWait {
            if let entity = fetchEntity(forAnimeID: animeID, in: context) {
                found = makeEntry(from: entity)
            }
        }

        return found
    }

    func add(_ entry: WatchlistEntry) {
        let context = database.context

        context.performAndWait {
            let savedAnime = SavedAnimeEntity.findOrCreate(for: entry.anime, in: context)

            let entity = savedAnime.watchlistEntry ?? WatchlistEntryEntity(context: context)
            entity.episodesWatched = Int64(entry.episodesWatched)
            entity.startedAt = entry.startedAt
            entity.updatedAt = entry.updatedAt
            entity.anime = savedAnime
        }

        database.save()
    }

    func update(_ entry: WatchlistEntry) {
        let context = database.context

        context.performAndWait {
            guard let entity = fetchEntity(forAnimeID: entry.anime.id, in: context) else { return }
            entity.episodesWatched = Int64(entry.episodesWatched)
            entity.updatedAt = entry.updatedAt
        }

        database.save()
    }

    func remove(animeID: Int) {
        let context = database.context

        context.performAndWait {
            if let entity = fetchEntity(forAnimeID: animeID, in: context) {
                // Only the entry goes. The saved anime stays, because the watch history
                // or a friend's pick may still point at it.
                context.delete(entity)
            }
        }

        database.save()
    }

    // MARK: - Helpers

    private func fetchEntity(forAnimeID animeID: Int, in context: NSManagedObjectContext) -> WatchlistEntryEntity? {
        let request: NSFetchRequest<WatchlistEntryEntity> = WatchlistEntryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "anime.animeID == %@", NSNumber(value: animeID))
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Couldn't find that watchlist entry: \(error.localizedDescription)")
            return nil
        }
    }

    private func makeEntry(from entity: WatchlistEntryEntity) -> WatchlistEntry? {
        guard let savedAnime = entity.anime else { return nil }

        return WatchlistEntry(
            anime: savedAnime.toAnime(),
            episodesWatched: Int(entity.episodesWatched),
            startedAt: entity.startedAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date()
        )
    }
}
