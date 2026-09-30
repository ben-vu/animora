//
//  InMemoryFriendPickRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 27/9/2026.
//

import Foundation

/// Keeps friends' picks in memory. Used by the unit tests and the previews.
class InMemoryFriendPickRepository: FriendPickRepository {

    private(set) var picks: [FriendPick] = []

    init() {
        // Nobody has sent anything yet.
    }

    var picksWaitingForLookup: [FriendPick] {
        var waiting: [FriendPick] = []
        for pick in picks where pick.isWaitingForLookup {
            waiting.append(pick)
        }
        return waiting
    }

    func add(_ pick: FriendPick) {
        // Newest first, the same as the Core Data version.
        picks.insert(pick, at: 0)
    }

    func update(_ pick: FriendPick) {
        for index in 0..<picks.count {
            if picks[index].id == pick.id {
                picks[index] = pick
            }
        }
    }

    func remove(pickID: UUID) {
        var kept: [FriendPick] = []
        for pick in picks {
            if pick.id != pickID {
                kept.append(pick)
            }
        }
        picks = kept
    }
}
