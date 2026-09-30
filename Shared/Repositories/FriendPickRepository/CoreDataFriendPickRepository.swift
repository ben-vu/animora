//
//  CoreDataFriendPickRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 27/9/2026.
//

import Foundation
import CoreData

/// Saves friends' picks with Core Data.
///
/// The share extension adds picks through this, and the main app reads them back
/// through this, which is how a link shared from Messages ends up in the app.
class CoreDataFriendPickRepository: FriendPickRepository {

    private let database: AnimoraDatabase

    init(database: AnimoraDatabase = AnimoraDatabase.shared) {
        self.database = database
    }

    var picks: [FriendPick] {
        fetchPicks(matching: nil)
    }

    var picksWaitingForLookup: [FriendPick] {
        // Not matched to an anime yet, and not already tried and failed. The failed
        // ones are left alone so the app does not ask the catalogue for the same
        // missing title every time it opens.
        fetchPicks(matching: NSPredicate(format: "anime == nil AND couldNotBeFound == NO"))
    }

    func add(_ pick: FriendPick) {
        let context = database.context

        context.performAndWait {
            let entity = FriendPickEntity(context: context)
            entity.pickID = pick.id
            entity.sharedTitle = pick.sharedTitle
            entity.sharedLink = pick.sharedLink?.absoluteString
            entity.friendName = pick.friendName
            entity.receivedAt = pick.receivedAt
            entity.couldNotBeFound = pick.couldNotBeFound

            if let anime = pick.anime {
                entity.anime = SavedAnimeEntity.findOrCreate(for: anime, in: context)
            }
        }

        database.save()
    }

    func update(_ pick: FriendPick) {
        let context = database.context

        context.performAndWait {
            guard let entity = fetchEntity(pickID: pick.id, in: context) else { return }

            entity.couldNotBeFound = pick.couldNotBeFound
            if let anime = pick.anime {
                entity.anime = SavedAnimeEntity.findOrCreate(for: anime, in: context)
            }
        }

        database.save()
    }

    func remove(pickID: UUID) {
        let context = database.context

        context.performAndWait {
            if let entity = fetchEntity(pickID: pickID, in: context) {
                context.delete(entity)
            }
        }

        database.save()
    }

    // MARK: - Helpers

    private func fetchPicks(matching predicate: NSPredicate?) -> [FriendPick] {
        // Pick up anything the widget or share extension wrote since the last read.
        database.refreshFromOtherProcesses()
        let context = database.context
        var picks: [FriendPick] = []

        context.performAndWait {
            let request: NSFetchRequest<FriendPickEntity> = FriendPickEntity.fetchRequest()
            request.predicate = predicate
            request.sortDescriptors = [NSSortDescriptor(key: "receivedAt", ascending: false)]

            do {
                let results = try context.fetch(request)
                for entity in results {
                    picks.append(makePick(from: entity))
                }
            } catch {
                print("Couldn't load friends' picks: \(error.localizedDescription)")
            }
        }

        return picks
    }

    private func fetchEntity(pickID: UUID, in context: NSManagedObjectContext) -> FriendPickEntity? {
        let request: NSFetchRequest<FriendPickEntity> = FriendPickEntity.fetchRequest()
        request.predicate = NSPredicate(format: "pickID == %@", pickID as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Couldn't find that pick: \(error.localizedDescription)")
            return nil
        }
    }

    private func makePick(from entity: FriendPickEntity) -> FriendPick {
        var link: URL? = nil
        if let linkText = entity.sharedLink {
            link = URL(string: linkText)
        }

        return FriendPick(
            id: entity.pickID ?? UUID(),
            sharedTitle: entity.sharedTitle ?? "",
            sharedLink: link,
            friendName: entity.friendName ?? "A friend",
            receivedAt: entity.receivedAt ?? Date(),
            anime: entity.anime?.toAnime(),
            couldNotBeFound: entity.couldNotBeFound
        )
    }
}
