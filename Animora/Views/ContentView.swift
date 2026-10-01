//
//  ContentView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// The main view.
///
/// Pick what you're in the mood for, see the suggestion, pick it, then keep track of it
/// on Now watching until it is finished.
struct ContentView: View {

    /// The shared view models, handed down to every screen.
    ///
    /// These lines are the only place in the Views that the real repositories are named,
    /// and they come from `AppRepositories`. Everything below here talks to protocols.
    @StateObject private var viewModel = RecommendationViewModel(
        repository: AppRepositories.catalogue,
        watchHistory: AppRepositories.watchHistory,
        watchlist: AppRepositories.watchlist,
        friendPicks: AppRepositories.friendPicks
    )

    @StateObject private var watchlistViewModel = WatchlistViewModel(
        watchlist: AppRepositories.watchlist,
        watchHistory: AppRepositories.watchHistory
    )

    @StateObject private var friendPicksViewModel = FriendPicksViewModel(
        friendPicks: AppRepositories.friendPicks,
        catalogue: AppRepositories.catalogue
    )

    /// Which screens are currently stacked on top of the home screen.
    @State private var path: [Route] = []

    /// Whether the app is on screen, so it can refresh when the viewer comes back to it.
    @Environment(\.scenePhase) private var scenePhase

    /// Every screen reachable from the home screen.
    ///
    /// Using an enum instead of raw strings means the compiler checks my navigation.
    /// I cannot navigate to a screen that does not exist.
    enum Route: Hashable {
        case request
        case suggestion
        case chosen
        case watchlist
        case friendPicks
        case history
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .request:
                        RecommendationRequestView(path: $path)
                    case .suggestion:
                        SuggestionView(path: $path)
                    case .chosen:
                        ChosenView(path: $path)
                    case .watchlist:
                        WatchlistView(path: $path)
                    case .friendPicks:
                        FriendPicksView(path: $path)
                    case .history:
                        WatchHistoryView()
                    }
                }
        }
        // Put on the stack itself, so every screen pushed onto it gets all three
        // without me repeating these lines for each route.
        .environmentObject(viewModel)
        .environmentObject(watchlistViewModel)
        .environmentObject(friendPicksViewModel)
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            // The widget and the share extension can change things while the app is
            // closed, so every time it comes to the front it reloads, and looks up any
            // picks friends have sent since last time.
            if newPhase == .active {
                watchlistViewModel.refresh()
                Task {
                    await friendPicksViewModel.lookUpNewPicks()
                }
            }
        }
        .onOpenURL { url in
            // Tapping the Up next widget opens animora://watchlist, which should land
            // the viewer on their list rather than the home screen.
            if url.host == "watchlist" {
                path = [.watchlist]
            }
        }
    }
}

#Preview {
    ContentView()
}
