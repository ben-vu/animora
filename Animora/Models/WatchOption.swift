//
//  WatchOption.swift
//  Animora
//
//  Created by Benjamin Vu on 2/10/2026.
//

import Foundation

/// One place the viewer can go to actually watch an anime, like Crunchyroll or Netflix.
///
/// Animora doesn't play anything itself. Its job ends when the viewer is in front of
/// the first episode, so this is the last step: a button that takes them there.
struct WatchOption: Identifiable, Equatable {

    /// The service's name as the viewer knows it, like "Crunchyroll".
    let serviceName: String

    /// Where the button goes. If the viewer has the service's app installed, iOS opens
    /// the app instead of Safari.
    let link: URL

    /// True when this isn't a page for the anime itself, just a search on the service.
    /// Animora offers one of these when the catalogue doesn't list anywhere to watch,
    /// so the viewer is never left at a dead end.
    var isSearch: Bool = false

    var id: String { link.absoluteString }

    /// What the button says.
    var buttonTitle: String {
        if isSearch {
            return "Search for it on \(serviceName)"
        }
        return "Watch on \(serviceName)"
    }
}
