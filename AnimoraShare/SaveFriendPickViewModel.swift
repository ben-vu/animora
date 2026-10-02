//
//  SaveFriendPickViewModel.swift
//  AnimoraShare
//
//  Created by Benjamin Vu on 29/9/2026.
//

import Foundation
import Combine

/// The ViewModel for the share sheet form.
///
/// It holds what the viewer has typed and asks SaveFriendPickUseCase to save it. It
/// never touches Core Data itself, the same as the ViewModels in the main app. The
/// repository is passed in so a test or preview could give it an in-memory one.
class SaveFriendPickViewModel: ObservableObject {

    /// The anime's name. Filled in for them when the link has one in it.
    @Published var title: String

    /// Who told them to watch it.
    @Published var friendName: String = ""

    /// Shown under the form when saving fails.
    @Published var errorMessage: String? = nil

    /// The link that was shared, if there was one. The viewer can't edit this.
    let sharedLink: URL?

    private let saveFriendPick: SaveFriendPickUseCase

    init(title: String, sharedLink: URL?, friendPicks: FriendPickRepository) {
        self.title = title
        self.sharedLink = sharedLink
        self.saveFriendPick = SaveFriendPickUseCase(friendPicks: friendPicks)
    }

    /// Where the link came from, so the viewer can see what they shared, like
    /// "myanimelist.net".
    var linkDescription: String? {
        guard let link = sharedLink else { return nil }
        return link.host ?? link.absoluteString
    }

    /// Tries to save the pick. Returns true when it worked, so the share sheet knows
    /// it can close.
    func save() -> Bool {
        do {
            try saveFriendPick.execute(title: title, link: sharedLink, friendName: friendName)
            errorMessage = nil
            return true
        } catch let error as SaveFriendPickError {
            errorMessage = error.errorDescription
            return false
        } catch {
            errorMessage = "Animora couldn't save this pick. Tap Save to try again."
            return false
        }
    }
}
