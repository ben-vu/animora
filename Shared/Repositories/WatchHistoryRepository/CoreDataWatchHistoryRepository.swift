//
//  CoreDataWatchHistoryRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 26/9/2026.
//

import Foundation
import CoreData

/// Saves the watch history with Core Data, so 'Already seen it' is remembered after
/// the app is closed.
///
/// In Assessment 2 the history only lived in memory, so closing the app wiped it and
/// the viewer got the same suggestions again the next day. That was the most obvious
/// gap in the MVP, and fixing it only meant writing this one class, because
/// everything else already talked to the `WatchHistoryRepository` protocol.
class CoreDataWatchHistoryRepository: WatchHistoryRepository {

    private let database: AnimoraDatabase

    init(database: AnimoraDatabase = AnimoraDatabase.shared) {
        self.database = database
    }

    var watchedRecords: [WatchedAnimeRecord] {
        // Pick up anything the widget or share extension wrote since the last read.
        database.refreshFromOtherProcesses()
        let context = database.context
        var records: [WatchedAnimeRecord] = []

        context.performAndWait {
            let request: NSFetchRequest<WatchedAnimeEntity> = WatchedAnimeEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "markedAt", ascending: false)]

            do {
                let results = try context.fetch(request)
                for entity in results {
                    guard let anime = entity.anime else { continue }

                    let record = WatchedAnimeRecord(
                        animeID: Int(anime.animeID),
                        animeTitle: anime.title ?? "Untitled",
                        markedAt: entity.markedAt ?? Date(),
                        reason: WatchedReason(rawValue: entity.reasonText ?? "") ?? .seenBeforeAnimora
                    )
                    records.append(record)
                }
            } catch {
                print("Couldn't load the watch history: \(error.localizedDescription)")
            }
        }

        return records
    }

    func add(_ record: WatchedAnimeRecord, anime: Anime) {
        let context = database.context

        context.performAndWait {
            let savedAnime = SavedAnimeEntity.findOrCreate(for: anime, in: context)

            // One record per anime. If there is one already I update it rather than
            // making a second, although the Use Case should have stopped that already.
            let entity = savedAnime.watchedRecord ?? WatchedAnimeEntity(context: context)
            entity.markedAt = record.markedAt
            entity.reasonText = record.reason.rawValue
            entity.anime = savedAnime
        }

        database.save()
    }

    func hasWatched(animeID: Int) -> Bool {
        let context = database.context
        var count = 0

        context.performAndWait {
            let request: NSFetchRequest<WatchedAnimeEntity> = WatchedAnimeEntity.fetchRequest()
            request.predicate = NSPredicate(format: "anime.animeID == %@", NSNumber(value: animeID))

            do {
                count = try context.count(for: request)
            } catch {
                print("Couldn't check the watch history: \(error.localizedDescription)")
            }
        }

        return count > 0
    }
}
