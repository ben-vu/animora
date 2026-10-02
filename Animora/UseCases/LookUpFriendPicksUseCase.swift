//
//  LookUpFriendPicksUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 25/9/2026.
//

import Foundation

/// The ways looking up friends' picks can go wrong.
enum LookUpFriendPicksError: LocalizedError, Equatable {

    case noConnection
    case catalogueBusy
    case catalogueUnavailable

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Your friends' picks are saved, but Animora needs the internet to find out which anime they are. Connect to Wi-Fi or mobile data and try again."
        case .catalogueBusy:
            return "The anime catalogue is very busy right now. Your picks are saved, so try again in a few seconds."
        case .catalogueUnavailable:
            return "The anime catalogue isn't answering properly at the moment. Your picks are saved, so try again in a minute."
        }
    }
}

/// Works out which anime each new friend's pick actually is.
///
/// The share extension saves a pick as just a title and maybe a link, because a share
/// sheet should be done in a second and can't wait for the internet. This runs in the
/// main app afterwards and fills in the real anime, so the pick can be ranked in
/// suggestions.
///
/// Business rules:
/// 1. A MyAnimeList link is trusted over the typed title, because it points at one
///    exact anime. The title is only searched when there is no usable link.
/// 2. A pick that can't be matched is marked as not found rather than left waiting,
///    so the app doesn't keep asking the catalogue for the same missing title.
/// 3. If the connection drops part way through, the picks already matched stay
///    matched, and the rest are left waiting for next time rather than being marked
///    as not found. A bad connection isn't the pick's fault.
struct LookUpFriendPicksUseCase {

    let catalogue: AnimeRepository
    let friendPicks: FriendPickRepository

    /// Looks up every pick that is waiting.
    ///
    /// - Returns: how many picks were matched to an anime this time.
    /// - Throws: a `LookUpFriendPicksError` if the catalogue could not be reached.
    @discardableResult
    func execute() async throws -> Int {

        var matchedCount = 0

        for pick in friendPicks.picksWaitingForLookup {

            var found: Anime? = nil
            do {
                // Rule 1: the link first, then the title.
                if let myAnimeListID = pick.myAnimeListID {
                    found = try await catalogue.findAnime(withID: myAnimeListID)
                }
                if found == nil && pick.sharedTitle.isEmpty == false {
                    found = try await catalogue.searchAnime(titled: pick.sharedTitle)
                }
            } catch let error as AnimeCatalogueError {
                // Rule 3: stop, and leave this pick and the rest waiting.
                switch error {
                case .noConnection: throw LookUpFriendPicksError.noConnection
                case .tooManyRequests: throw LookUpFriendPicksError.catalogueBusy
                case .unavailable: throw LookUpFriendPicksError.catalogueUnavailable
                }
            } catch {
                throw LookUpFriendPicksError.catalogueUnavailable
            }

            var updated = pick
            if let anime = found {
                updated.anime = anime
                matchedCount += 1
            } else {
                // Rule 2: don't keep trying a pick that doesn't exist.
                updated.couldNotBeFound = true
            }
            friendPicks.update(updated)
        }

        return matchedCount
    }
}
