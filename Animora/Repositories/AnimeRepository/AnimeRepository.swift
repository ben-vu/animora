//
//  AnimeRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 3/9/2026.
//

import Foundation

/// Anything that can supply Animora with anime.
///
/// The Use Cases talk to this protocol and never name a concrete type, so they have no
/// idea whether the anime came from a list built into the app, a JSON file on disk, or
/// a web API. That means a new source is a new file, not a rewrite.
///
protocol AnimeRepository {

    /// Every anime this source knows about.
    var anime: [Anime] { get }

    /// Reads the anime in from wherever this source keeps them.
    func load() -> [Anime]
}
