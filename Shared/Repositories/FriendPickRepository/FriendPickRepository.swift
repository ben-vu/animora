//
//  FriendPickRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 27/9/2026.
//

import Foundation

/// Anything that remembers the anime friends have told the viewer to watch.
///
/// The share extension writes to this and the main app reads from it, which is why it
/// lives in the Shared folder.
protocol FriendPickRepository {

    /// Every pick, newest first.
    var picks: [FriendPick] { get }

    /// Only the picks the main app still has to look up in the catalogue.
    var picksWaitingForLookup: [FriendPick] { get }

    /// Saves a new pick.
    func add(_ pick: FriendPick)

    /// Saves a change to a pick, like the anime it turned out to be.
    func update(_ pick: FriendPick)

    /// Deletes a pick the viewer no longer wants.
    func remove(pickID: UUID)
}
