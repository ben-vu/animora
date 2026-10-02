//
//  SaveFriendPickUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 24/9/2026.
//

import Foundation

/// The ways saving a friend's pick can go wrong.
///
/// The viewer meets these inside the share sheet, on top of whatever app they shared
/// from. They cannot go anywhere else to fix things, so every message says what to do
/// right there in the sheet.
enum SaveFriendPickError: LocalizedError, Equatable {

    /// No title was typed and the link was not a MyAnimeList link, so there is
    /// nothing the app could look up later.
    case nothingToLookUp

    /// The text is far longer than any anime title, usually because a whole message
    /// was shared instead of just the name.
    case titleTooLong(characterLimit: Int)

    /// This anime is already in the viewer's friends' picks.
    case alreadySaved(title: String, friendName: String)

    var errorDescription: String? {
        switch self {

        case .nothingToLookUp:
            return "There's nothing here Animora can look up yet. Type the anime's name in the Title box, then tap Save."

        case .titleTooLong(let characterLimit):
            return "That looks like a whole message rather than a title. Cut it down to just the anime's name (under \(characterLimit) characters), then tap Save."

        case .alreadySaved(let title, let friendName):
            return "\(title) is already in your friends' picks, from \(friendName). You don't need to save it again, so tap Cancel to go back."
        }
    }
}

/// Saves an anime a friend recommended, from the share sheet.
///
/// Business rules:
/// 1. There has to be something to look up later: either a MyAnimeList link, or a
///    title. A link from any other site on its own is not enough, because the app
///    has no way to tell which anime it points at.
/// 2. The title has to be short enough to be a title. Shared messages like "omg you
///    HAVE to watch frieren it's so good" won't find anything in the catalogue.
/// 3. The same anime can't be saved twice, whether it comes back as the same link or
///    the same name. Two friends recommending the same show is common, and a list
///    with it on twice looks broken.
/// 4. If no friend's name is given, it is saved as "A friend" so every suggestion can
///    still say who it came from.
struct SaveFriendPickUseCase {

    let friendPicks: FriendPickRepository

    /// The longest title allowed. The longest well-known anime titles are around 60
    /// characters, so 80 leaves room without letting a whole message through.
    static let titleCharacterLimit = 80

    @discardableResult
    func execute(title: String, link: URL?, friendName: String, on date: Date = Date()) throws -> FriendPick {

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        var myAnimeListID: Int? = nil
        if let link = link {
            myAnimeListID = FriendPick.myAnimeListID(from: link)
        }

        // Rule 1: something to look up.
        if cleanTitle.isEmpty && myAnimeListID == nil {
            throw SaveFriendPickError.nothingToLookUp
        }

        // Rule 2: short enough to be a title.
        if cleanTitle.count > SaveFriendPickUseCase.titleCharacterLimit {
            throw SaveFriendPickError.titleTooLong(characterLimit: SaveFriendPickUseCase.titleCharacterLimit)
        }

        // Rule 3: not already saved.
        for existing in friendPicks.picks {
            let sameLink = myAnimeListID != nil && existing.myAnimeListID == myAnimeListID
            let sameTitle = cleanTitle.isEmpty == false
                && existing.sharedTitle.lowercased() == cleanTitle.lowercased()

            if sameLink || sameTitle {
                throw SaveFriendPickError.alreadySaved(
                    title: existing.displayTitle,
                    friendName: existing.friendName
                )
            }
        }

        // Rule 4: always have a name to show.
        var cleanFriendName = friendName.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanFriendName.isEmpty {
            cleanFriendName = "A friend"
        }

        // If only a link was given, show something sensible until the app looks it up.
        var titleToSave = cleanTitle
        if titleToSave.isEmpty, let myAnimeListID = myAnimeListID {
            titleToSave = "MyAnimeList anime #\(myAnimeListID)"
        }

        let pick = FriendPick(
            id: UUID(),
            sharedTitle: titleToSave,
            sharedLink: link,
            friendName: cleanFriendName,
            receivedAt: date
        )

        friendPicks.add(pick)
        return pick
    }
}
