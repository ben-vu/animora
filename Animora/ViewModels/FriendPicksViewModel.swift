//
//  FriendPicksViewModel.swift
//  Animora
//
//  Created by Benjamin Vu on 20/9/2026.
//

import Foundation
import Combine

/// Holds the anime friends have sent through the share sheet.
class FriendPicksViewModel: ObservableObject {

    /// Every pick, newest first.
    @Published private(set) var picks: [FriendPick] = []

    /// Whether picks are being looked up in the catalogue right now.
    @Published private(set) var isLookingUp = false

    /// The message to show if the lookup failed.
    @Published var errorMessage: String? = nil

    private let friendPicks: FriendPickRepository
    private let lookUpFriendPicks: LookUpFriendPicksUseCase

    init(friendPicks: FriendPickRepository, catalogue: AnimeRepository) {
        self.friendPicks = friendPicks
        self.lookUpFriendPicks = LookUpFriendPicksUseCase(
            catalogue: catalogue,
            friendPicks: friendPicks
        )
    }

    /// How many picks have been matched to a real anime, and so can be suggested.
    var readyCount: Int {
        var count = 0
        for pick in picks where pick.anime != nil {
            count += 1
        }
        return count
    }

    /// Loads the latest picks, including any the share extension just saved.
    func refresh() {
        picks = friendPicks.picks
    }

    /// Looks up any picks that were shared since last time.
    ///
    /// This runs every time the app comes to the front. Most of the time there is
    /// nothing waiting and it returns straight away without touching the internet.
    func lookUpNewPicks() async {
        refresh()
        if isLookingUp { return }
        if friendPicks.picksWaitingForLookup.isEmpty { return }

        errorMessage = nil
        isLookingUp = true

        do {
            try await lookUpFriendPicks.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLookingUp = false
        refresh()
    }

    /// Deletes a pick the viewer doesn't want any more.
    func remove(_ pick: FriendPick) {
        friendPicks.remove(pickID: pick.id)
        refresh()
    }
}
