//
//  ContentView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// The main view.
///
/// Pick what you're in the mood for, see the results, look at one, pick it
struct ContentView: View {

    /// The one shared view model, handed down to every screen.
    ///
    /// This line is the only place in the whole app that names a concrete repository.
    /// Everything below here talks to the `AnimeRepository` protocol, so swapping the
    /// built-in list for a web API later means changing this one line.
    @StateObject private var viewModel = RecommendationViewModel(repository: LocalAnimeRepository())

    /// Which screens are currently stacked on top of the home screen.
    @State private var path: [Route] = []

    /// Every screen reachable from the home screen.
    ///
    /// Using an enum instead of raw strings means the compiler checks my navigation.
    /// I cannot navigate to a screen that does not exist.
    enum Route: Hashable {
        case request
        case suggestion
        case chosen
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .environmentObject(viewModel)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .request:
                        RecommendationRequestView(path: $path)
                            .environmentObject(viewModel)
                    case .suggestion:
                        SuggestionView(path: $path)
                            .environmentObject(viewModel)
                    case .chosen:
                        ChosenView(path: $path)
                            .environmentObject(viewModel)
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
