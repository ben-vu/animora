//
//  TenraiResponses.swift
//  Animora
//
//  Created by Benjamin Vu on 22/9/2026.
//

import Foundation

// These structs match the JSON the Tenrai API sends back, field for field.
//
// They are kept separate from my `Anime` struct on purpose. The JSON uses the
// catalogue's words ("mal_id", "Finished Airing", "24 min per ep"), and I don't want
// those leaking into the rest of the app. `TenraiAnimeRepository` reads these and turns
// them into `Anime`, which uses Animora's words.
//
// Every field I don't strictly need is optional, so one odd entry in the catalogue
// can't make a whole search fail to decode.
//
// The decoder converts snake_case to camelCase for me, so "title_english" in the JSON
// becomes `titleEnglish` here.

/// The reply to a search, like `/anime?genres=1`.
struct TenraiAnimeListResponse: Decodable {
    let data: [TenraiAnime]
}

/// The reply to a single lookup, like `/anime/52991`.
struct TenraiAnimeResponse: Decodable {
    let data: TenraiAnime
}

/// One anime, as the catalogue describes it.
struct TenraiAnime: Decodable {
    let malId: Int
    let title: String
    let titleEnglish: String?
    let type: String?
    let episodes: Int?
    let status: String?
    let duration: String?
    let score: Double?
    let synopsis: String?
    let genres: [TenraiGenre]?
    let images: TenraiImages?
}

/// A genre tag on an anime.
struct TenraiGenre: Decodable {
    let malId: Int
    let name: String
}

/// The cover pictures.
struct TenraiImages: Decodable {
    let jpg: TenraiImageLinks?
}

struct TenraiImageLinks: Decodable {
    let imageUrl: String?
    let largeImageUrl: String?
}
