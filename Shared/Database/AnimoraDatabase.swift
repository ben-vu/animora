//
//  AnimoraDatabase.swift
//  Animora
//
//  Created by Benjamin Vu on 21/9/2026.
//

import Foundation
import CoreData
import WidgetKit

/// Opens Animora's Core Data database and saves changes to it.
///
/// The database file lives in the App Group shared container rather than inside the
/// app. That is the whole reason the widget can show what the viewer is watching and
/// the share extension can save a friend's pick: all three of them open this same
/// file. If it lived inside the app, the extensions would each get an empty database
/// of their own.
///
/// Only the Core Data repositories use this class. The Use Cases, ViewModels and
/// Views never see it, so none of them import Core Data.
class AnimoraDatabase {

    /// The App Group the app, the widget and the share extension all belong to. It
    /// has to match the entitlements files exactly, or each one ends up with its own
    /// empty database.
    static let appGroupID = "group.iOSdD.Animora"

    /// The one database every repository shares.
    static let shared = AnimoraDatabase()

    let container: NSPersistentContainer

    /// The context all the repositories read and write through.
    var context: NSManagedObjectContext {
        container.viewContext
    }

    init() {
        container = NSPersistentContainer(name: "Animora")

        if let groupFolder = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AnimoraDatabase.appGroupID
        ) {
            let storeURL = groupFolder.appendingPathComponent("Animora.sqlite")
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        } else {
            // This only happens when the App Group is missing from the entitlements.
            // The app still works on its own, but the widget and share extension will
            // not see the same data, so I want it to be loud in the console.
            print("⚠️ App Group \(AnimoraDatabase.appGroupID) is not set up. The widget and share extension won't see the app's data.")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("Animora couldn't open its database: \(error.localizedDescription)")
            }
        }

        // If the widget and the app both change the same row, the newest change wins
        // instead of the save failing.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Never trust a cached copy of a row. Another process may have changed the file
        // since it was cached. The data here is tiny, so reading it fresh costs nothing.
        container.viewContext.stalenessInterval = 0
    }

    /// Saves anything that changed, then tells the widget to redraw.
    ///
    /// Reloading the widget here, rather than remembering to do it in every screen,
    /// means there is no way to change the watchlist and leave the widget showing old
    /// data.
    func save() {
        let context = self.context
        var didSave = false

        context.performAndWait {
            guard context.hasChanges else { return }
            do {
                try context.save()
                didSave = true
            } catch {
                print("Animora couldn't save: \(error.localizedDescription)")
                context.rollback()
            }
        }

        if didSave {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    /// Throws away anything cached in memory so the next read comes from the file.
    ///
    /// The widget and the share extension run as separate processes and write to the
    /// file behind the app's back. Without this the app would keep showing what it
    /// had in memory, so a "Watched it" tap on the widget would not show up in the app.
    /// The repositories call this at the start of every list they load.
    func refreshFromOtherProcesses() {
        let context = self.context
        context.performAndWait {
            context.refreshAllObjects()
        }
    }
}
