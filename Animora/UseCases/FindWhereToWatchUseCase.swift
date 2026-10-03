//
//  FindWhereToWatchUseCase.swift
//  Animora
//
//  Created by Benjamin Vu on 3/10/2026.
//

import Foundation

/// The ways finding somewhere to watch can go wrong.
enum FindWhereToWatchError: LocalizedError, Equatable {

    case noConnection
    case catalogueBusy
    case catalogueUnavailable

    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Animora needs the internet to find where this anime is streaming. Connect to Wi-Fi or mobile data and try again."
        case .catalogueBusy:
            return "The anime catalogue is very busy right now. Try again in a few seconds."
        case .catalogueUnavailable:
            return "The anime catalogue isn't answering properly at the moment. Try again in a minute, or search for the title in your streaming app."
        }
    }
}

/// Works out where the viewer can actually watch an anime they've picked.
///
/// For a newcomer, "this sounds good" and "I'm watching episode 1" are two different
/// things. If they have to go and search for the show themselves, there is a good
/// chance they never do, so Animora takes them straight there.
///
/// Business rules:
/// 1. Old `http` links are changed to `https`. The catalogue still lists some services
///    (Crunchyroll included) with their old addresses.
/// 2. Only web links are offered. Anything else could open something unexpected.
/// 3. A service listed twice is only shown once.
/// 4. Services built for anime come first, because a newcomer is most likely to find
///    the whole series, with subtitles, on one of those. The rest keep the catalogue's
///    order.
/// 5. If the catalogue doesn't list anywhere, the viewer gets a Crunchyroll search for
///    the title instead of a dead end.
struct FindWhereToWatchUseCase {

    let catalogue: AnimeRepository

    /// Anime-only services, in the order I want them shown.
    static let animeServices = ["Crunchyroll", "HIDIVE"]

    func execute(for anime: Anime) async throws -> [WatchOption] {

        let listed: [WatchOption]
        do {
            listed = try await catalogue.streamingLinks(forAnimeID: anime.id)
        } catch AnimeCatalogueError.noConnection {
            throw FindWhereToWatchError.noConnection
        } catch AnimeCatalogueError.tooManyRequests {
            throw FindWhereToWatchError.catalogueBusy
        } catch {
            throw FindWhereToWatchError.catalogueUnavailable
        }

        // Rules 1, 2 and 3.
        var cleaned: [WatchOption] = []
        for option in listed {
            guard let link = FindWhereToWatchUseCase.secureLink(option.link) else { continue }

            var alreadyHave = false
            for existing in cleaned where existing.serviceName.lowercased() == option.serviceName.lowercased() {
                alreadyHave = true
            }
            if alreadyHave == false {
                cleaned.append(WatchOption(serviceName: option.serviceName, link: link))
            }
        }

        // Rule 5.
        if cleaned.isEmpty {
            return [FindWhereToWatchUseCase.crunchyrollSearch(for: anime.title)]
        }

        // Rule 4. Anime services first, in my order, then everything else as listed.
        var ordered: [WatchOption] = []
        for serviceName in FindWhereToWatchUseCase.animeServices {
            for option in cleaned where option.serviceName.lowercased() == serviceName.lowercased() {
                ordered.append(option)
            }
        }
        for option in cleaned where ordered.contains(option) == false {
            ordered.append(option)
        }
        return ordered
    }

    /// Turns `http` into `https`, keeps `https` as it is, and returns `nil` for
    /// anything that isn't a web link.
    static func secureLink(_ link: URL) -> URL? {
        guard let scheme = link.scheme?.lowercased() else { return nil }

        if scheme == "https" {
            return link
        }
        if scheme == "http" {
            var components = URLComponents(url: link, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            return components?.url
        }
        return nil
    }

    /// A Crunchyroll search page for the title, used when nothing else is listed.
    static func crunchyrollSearch(for title: String) -> WatchOption {
        var components = URLComponents(string: "https://www.crunchyroll.com/search")!
        components.queryItems = [URLQueryItem(name: "q", value: title)]
        return WatchOption(serviceName: "Crunchyroll", link: components.url!, isSearch: true)
    }
}
