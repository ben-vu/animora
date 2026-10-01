//
//  TenraiAnimeRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 22/9/2026.
//

import Foundation

/// Fetches anime from the Tenrai API (https://api.tenrai.org/v1).
///
/// Tenrai is a free copy of the MyAnimeList catalogue, so it has every anime a
/// newcomer is likely to hear about, with real ratings from millions of viewers. That
/// replaced the 15 anime I typed in by hand for Assessment 2, which was never going to
/// be enough for a viewer who has already seen the obvious ones.
///
/// Things I had to design around:
/// - **Rate limits.** The public API allows 3 requests a second and 60 a minute, so
///   every request waits until at least 0.4 seconds after the last one.
/// - **Genres are "and", not "or".** Asking for Action and Comedy together only
///   returns anime that are both. My rule is "at least one genre you picked", so I
///   ask once per genre and combine the results myself.
/// - **Popular, not top rated.** I sort by how many people have the anime on their
///   list rather than by score. The top rated list is full of long-running sequels
///   and niche shows, and my viewer wants something approachable.
///
/// This is a class so the anime it has loaded are kept between searches, which the
/// 'Already seen it' Use Case relies on.
class TenraiAnimeRepository: AnimeRepository {

    static let baseAddress = "https://api.tenrai.org/v1"

    /// How many anime to ask for per page. 25 is the most the API allows.
    static let pageSize = 25

    /// Every anime loaded so far this session.
    private(set) var anime: [Anime] = []

    private let session: URLSession

    /// When the last request went out, so the next one can wait if it is too soon.
    private var lastRequestAt: Date? = nil

    /// The gap to leave between requests. 0.4 seconds keeps Animora at 2.5 requests a
    /// second, just under the public limit of 3.
    static let secondsBetweenRequests = 0.4

    /// The session can be swapped in the tests, but the app always uses the shared one.
    init(session: URLSession = URLSession.shared) {
        self.session = session
    }

    // MARK: - AnimeRepository

    func load(for preferences: AnimePreferences) async throws -> [Anime] {

        // One search per genre they picked, or one search with no genre at all.
        // `nil` in this list means "no genre filter".
        var genreIDs: [Int?] = []
        if preferences.genres.isEmpty {
            genreIDs.append(nil)
        } else {
            for genre in preferences.genres.sorted(by: { $0.displayName < $1.displayName }) {
                genreIDs.append(genre.catalogueGenreID)
            }
        }

        // Short series are rarer near the top of the popular list, so when the viewer
        // has a time limit I look one page further down to give them a fair chance.
        var pagesPerGenre = 1
        if preferences.timeCommitment.maximumHours != nil {
            pagesPerGenre = 2
        }

        var found: [Anime] = []

        for genreID in genreIDs {
            for page in 1...pagesPerGenre {
                let address = makeSearchAddress(genreID: genreID, status: preferences.status, page: page)
                guard let data = try await fetch(address) else { continue }

                let results = try TenraiAnimeRepository.decodeAnimeList(from: data)
                for item in results {
                    // The same anime comes back once per genre it is in, so skip ones
                    // I already have.
                    if found.contains(where: { $0.id == item.id }) == false {
                        found.append(item)
                    }
                }
            }
        }

        remember(found)
        return found
    }

    func findAnime(withID id: Int) async throws -> Anime? {
        guard let address = URL(string: "\(TenraiAnimeRepository.baseAddress)/anime/\(id)") else {
            return nil
        }

        guard let data = try await fetch(address) else {
            // 404: there is no anime with that id.
            return nil
        }

        let decoder = TenraiAnimeRepository.makeDecoder()
        let response: TenraiAnimeResponse
        do {
            response = try decoder.decode(TenraiAnimeResponse.self, from: data)
        } catch {
            print("Couldn't read the anime from Tenrai: \(error)")
            throw AnimeCatalogueError.unavailable
        }

        guard let found = TenraiAnimeRepository.makeAnime(from: response.data) else {
            return nil
        }
        remember([found])
        return found
    }

    func searchAnime(titled title: String) async throws -> Anime? {
        var components = URLComponents(string: "\(TenraiAnimeRepository.baseAddress)/anime")
        components?.queryItems = [
            URLQueryItem(name: "q", value: title),
            // The most popular match is nearly always the one a friend meant. Searching
            // "Frieren" should give the series, not a recap special.
            URLQueryItem(name: "order_by", value: "members"),
            URLQueryItem(name: "sort", value: "desc"),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let address = components?.url else { return nil }
        guard let data = try await fetch(address) else { return nil }

        let results = try TenraiAnimeRepository.decodeAnimeList(from: data)
        guard let best = results.first else { return nil }

        remember([best])
        return best
    }

    // MARK: - Talking to the API

    /// Builds an address like
    /// `https://api.tenrai.org/v1/anime?genres=1&status=complete&order_by=members...`
    private func makeSearchAddress(genreID: Int?, status: AnimeStatusPreference, page: Int) -> URL {

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "order_by", value: "members"),
            URLQueryItem(name: "sort", value: "desc"),
            URLQueryItem(name: "limit", value: String(TenraiAnimeRepository.pageSize)),
            URLQueryItem(name: "page", value: String(page)),
            // Safe for work only. My viewer is new to anime and I do not want the first
            // thing Animora shows them to be something they would be embarrassed by.
            URLQueryItem(name: "sfw", value: "true")
        ]

        if let genreID = genreID {
            queryItems.append(URLQueryItem(name: "genres", value: String(genreID)))
        }

        switch status {
        case .finished:
            queryItems.append(URLQueryItem(name: "status", value: "complete"))
        case .airing:
            queryItems.append(URLQueryItem(name: "status", value: "airing"))
        case .any:
            break
        }

        var components = URLComponents(string: "\(TenraiAnimeRepository.baseAddress)/anime")!
        components.queryItems = queryItems
        return components.url!
    }

    /// Downloads one address. Returns `nil` for a 404, and throws an
    /// `AnimeCatalogueError` for everything else that goes wrong.
    private func fetch(_ address: URL) async throws -> Data? {

        // Stay under the rate limit. Every request goes through here, so this one
        // check covers searches and friends' pick lookups alike.
        if let lastRequestAt = lastRequestAt {
            let secondsSince = Date().timeIntervalSince(lastRequestAt)
            if secondsSince < TenraiAnimeRepository.secondsBetweenRequests {
                let wait = TenraiAnimeRepository.secondsBetweenRequests - secondsSince
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
        }
        lastRequestAt = Date()

        let result: (Data, URLResponse)
        do {
            result = try await session.data(from: address)
        } catch let error as URLError {
            print("Tenrai request failed: \(error)")
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .timedOut:
                throw AnimeCatalogueError.noConnection
            default:
                throw AnimeCatalogueError.unavailable
            }
        } catch {
            print("Tenrai request failed: \(error)")
            throw AnimeCatalogueError.unavailable
        }

        let data = result.0
        guard let httpResponse = result.1 as? HTTPURLResponse else {
            throw AnimeCatalogueError.unavailable
        }

        switch httpResponse.statusCode {
        case 200:
            return data
        case 404:
            return nil
        case 429:
            throw AnimeCatalogueError.tooManyRequests
        default:
            print("Tenrai answered with status \(httpResponse.statusCode) for \(address)")
            throw AnimeCatalogueError.unavailable
        }
    }

    /// Keeps hold of anime I have loaded, without doubling any up.
    private func remember(_ newAnime: [Anime]) {
        for item in newAnime {
            if anime.contains(where: { $0.id == item.id }) == false {
                anime.append(item)
            }
        }
    }

    // MARK: - Turning Tenrai's JSON into Animora's anime
    //
    // These are `static` and take plain data in, so the unit tests can check them with
    // a JSON string I wrote myself, without touching the internet.

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    /// Reads a search reply and keeps only the anime a newcomer can actually watch.
    static func decodeAnimeList(from data: Data) throws -> [Anime] {
        let response: TenraiAnimeListResponse
        do {
            response = try makeDecoder().decode(TenraiAnimeListResponse.self, from: data)
        } catch {
            print("Couldn't read the search results from Tenrai: \(error)")
            throw AnimeCatalogueError.unavailable
        }

        var list: [Anime] = []
        for item in response.data {
            if let converted = makeAnime(from: item) {
                list.append(converted)
            }
        }
        return list
    }

    /// Turns one catalogue entry into an `Anime`, or `nil` if it is something Animora
    /// should never suggest.
    static func makeAnime(from item: TenraiAnime) -> Anime? {

        // Only TV series, films and web series. The catalogue also has music videos,
        // adverts and 5 minute specials, and none of those are a good first anime.
        let watchableTypes = ["TV", "Movie", "ONA"]
        guard let type = item.type, watchableTypes.contains(type) else {
            return nil
        }

        // Every suggestion quotes its rating as a reason, so an unrated anime has
        // nothing to back it up.
        guard let score = item.score else {
            return nil
        }

        // "Not yet aired" is dropped too: there is nothing to watch yet.
        let status: AnimeStatus
        if item.status == "Finished Airing" {
            status = .finished
        } else if item.status == "Currently Airing" {
            status = .airing
        } else {
            return nil
        }

        // Only the genres Animora offers. Two catalogue genres can turn into the same
        // one of mine (Suspense and Mystery are both Thriller), so skip doubles.
        var genres: [AnimeGenre] = []
        for tag in item.genres ?? [] {
            if let genre = AnimeGenre.fromCatalogueName(tag.name), genres.contains(genre) == false {
                genres.append(genre)
            }
        }

        // The English title if there is one. "Attack on Titan" means something to a
        // newcomer. "Shingeki no Kyojin" does not.
        var title = item.title
        if let englishTitle = item.titleEnglish, englishTitle.isEmpty == false {
            title = englishTitle
        }

        var imageURL: URL? = nil
        if let link = item.images?.jpg?.largeImageUrl ?? item.images?.jpg?.imageUrl {
            imageURL = URL(string: link)
        }

        return Anime(
            id: item.malId,
            title: title,
            synopsis: shortSynopsis(from: item.synopsis),
            episodes: item.episodes,
            episodeMinutes: minutesPerEpisode(from: item.duration),
            score: score,
            status: status,
            genres: genres,
            imageURL: imageURL
        )
    }

    /// Reads a running time like "24 min per ep" or "1 hr 55 min" as minutes.
    ///
    /// If it can't be read I fall back to 24, which is what nearly every TV episode
    /// runs. A slightly wrong time estimate is better than dropping the anime.
    static func minutesPerEpisode(from duration: String?) -> Int {
        guard let duration = duration else { return 24 }

        let words = duration.components(separatedBy: " ")
        var minutes = 0

        for index in 0..<words.count {
            guard index > 0, let number = Int(words[index - 1]) else { continue }

            let unit = words[index]
            if unit == "hr" || unit == "hrs" {
                minutes += number * 60
            } else if unit == "min" || unit == "mins" {
                minutes += number
            }
        }

        if minutes == 0 {
            return 24
        }
        return minutes
    }

    /// Just the first paragraph of the synopsis.
    ///
    /// The full catalogue synopsis can run for several paragraphs and later ones tend
    /// to give away the plot. The first paragraph is the setup, which is all someone
    /// deciding whether to start needs.
    static func shortSynopsis(from synopsis: String?) -> String {
        guard let synopsis = synopsis else {
            return "No description yet."
        }

        let cleaned = synopsis.replacingOccurrences(of: "[Written by MAL Rewrite]", with: "")
        let paragraphs = cleaned.components(separatedBy: "\n")
        for paragraph in paragraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                return trimmed
            }
        }
        return "No description yet."
    }
}
