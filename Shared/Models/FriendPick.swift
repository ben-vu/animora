//
//  FriendPick.swift
//  Animora
//
//  Created by Benjamin Vu on 23/9/2026.
//

import Foundation

/// An anime a friend told the viewer to watch, saved through the share sheet.
///
/// This is how most people actually end up starting anime: a friend says "you have to
/// watch this" in a group chat, and the message gets buried. The share extension lets
/// the viewer send that link or name straight to Animora, where it is looked up and
/// put at the top of their next suggestions.
///
/// A pick is saved straight away by the share extension, but it can't be looked up
/// there, because a share sheet should close in a second or two and not wait on the
/// internet. So a pick starts with no `anime` attached, and the main app fills it in
/// the next time it opens.
struct FriendPick: Identifiable, Hashable {

    /// Picks have no natural id of their own (two friends can send the same show), so
    /// each one gets a random one.
    let id: UUID

    /// The title the viewer confirmed in the share sheet, like "Frieren".
    let sharedTitle: String

    /// The link that was shared, if there was one.
    let sharedLink: URL?

    /// Who recommended it. Always filled in, even if only with "A friend".
    let friendName: String

    /// When it was shared into Animora.
    let receivedAt: Date

    /// The anime this turned out to be, once the main app has looked it up.
    var anime: Anime? = nil

    /// Set when the lookup ran and found nothing, so the app does not keep asking the
    /// catalogue for the same thing every time it opens.
    var couldNotBeFound: Bool = false

    /// Whether the main app still needs to look this one up.
    var isWaitingForLookup: Bool {
        anime == nil && couldNotBeFound == false
    }

    /// The MyAnimeList id inside the shared link, if it was a MyAnimeList link.
    var myAnimeListID: Int? {
        guard let link = sharedLink else { return nil }
        return FriendPick.myAnimeListID(from: link)
    }

    /// The name shown on screen before the lookup has happened.
    var displayTitle: String {
        if let anime = anime {
            return anime.title
        }
        return sharedTitle
    }

    // MARK: - Reading shared links

    /// Pulls the anime id out of a link like
    /// `https://myanimelist.net/anime/52991/Sousou_no_Frieren`.
    ///
    /// Tenrai uses the same ids as MyAnimeList, so if a friend sends one of these I
    /// can look up the exact anime instead of guessing from its name.
    static func myAnimeListID(from link: URL) -> Int? {
        guard let host = link.host, host.contains("myanimelist.net") else {
            return nil
        }

        let parts = link.pathComponents
        for index in 0..<parts.count {
            if parts[index] == "anime" && index + 1 < parts.count {
                return Int(parts[index + 1])
            }
        }
        return nil
    }

    /// A readable title from the end of a MyAnimeList link, so the share sheet can
    /// fill in the title box for the viewer. "Sousou_no_Frieren" becomes
    /// "Sousou no Frieren".
    static func titleFromLink(_ link: URL) -> String? {
        guard myAnimeListID(from: link) != nil else { return nil }

        let parts = link.pathComponents
        guard parts.count >= 4 else { return nil }

        let slug = parts[3]
        let title = slug.replacingOccurrences(of: "_", with: " ")
        if title.isEmpty {
            return nil
        }
        return title
    }
}
