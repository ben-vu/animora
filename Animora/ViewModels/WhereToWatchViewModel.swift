//
//  WhereToWatchViewModel.swift
//  Animora
//
//  Created by Benjamin Vu on 2/10/2026.
//

import Foundation
import Combine

/// The ViewModel for the Where to watch sheet.
///
/// It loads the services once when the sheet opens. The View only shows what is in
/// here and never talks to the catalogue itself.
class WhereToWatchViewModel: ObservableObject {

    @Published var options: [WatchOption] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    let anime: Anime
    private let findWhereToWatch: FindWhereToWatchUseCase

    init(anime: Anime, catalogue: AnimeRepository) {
        self.anime = anime
        self.findWhereToWatch = FindWhereToWatchUseCase(catalogue: catalogue)
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            options = try await findWhereToWatch.execute(for: anime)
        } catch let error as FindWhereToWatchError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong finding where to watch. Try again in a minute."
        }

        isLoading = false
    }

    /// True when the only option is a search, so the sheet can explain why.
    var onlyHasASearch: Bool {
        options.count == 1 && options[0].isSearch
    }
}
