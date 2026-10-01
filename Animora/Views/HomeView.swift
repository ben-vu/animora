//
//  HomeView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// Screen 1: the home screen.
///
/// This screen does one job, which is to get the viewer into the flow quickly. The whole
/// point is a decision in under a minute, so there is nothing here to read or scroll past.
///
/// Since Assessment 3 it also shows what the viewer is partway through. Someone coming
/// back after a week should see "you're on episode 4 of Frieren" before they see "find
/// something new", because the most common way newcomers drop anime is simply losing
/// their place.
struct HomeView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @EnvironmentObject var watchlistViewModel: WatchlistViewModel
    @EnvironmentObject var friendPicksViewModel: FriendPicksViewModel
    @Binding var path: [ContentView.Route]

    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            Text("ANIMORA")
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(.animoraPurple)

            Text("Find your next anime.")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            // MARK: Up next
            if let upNext = watchlistViewModel.upNext {
                Button {
                    path.append(.watchlist)
                } label: {
                    upNextCard(upNext)
                }
                .buttonStyle(.plain)
            }

            // MARK: The main button
            Button {
                // Start a fresh request every time, so an old search cannot leak into
                // a new one.
                viewModel.startOver()
                path.append(.request)
            } label: {
                Text("Get started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraPurple)
                    .cornerRadius(12)
            }

            // MARK: The other lists
            HStack(spacing: 10) {
                shortcut(
                    title: "Now watching",
                    count: watchlistViewModel.entries.count,
                    systemImage: "play.circle",
                    route: .watchlist
                )
                shortcut(
                    title: "From friends",
                    count: friendPicksViewModel.picks.count,
                    systemImage: "person.2",
                    route: .friendPicks
                )
                shortcut(
                    title: "Already seen",
                    count: watchlistViewModel.history.count,
                    systemImage: "checkmark.circle",
                    route: .history
                )
            }

            Text("No account needed.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding(24)
        .onAppear {
            watchlistViewModel.refresh()
            friendPicksViewModel.refresh()
        }
    }

    // MARK: - Small pieces

    private func upNextCard(_ entry: WatchlistEntry) -> some View {
        HStack(spacing: 12) {
            AnimeCoverImage(url: entry.anime.imageURL, width: 48, height: 68)

            VStack(alignment: .leading, spacing: 4) {
                Text("UP NEXT")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.animoraPurple)
                Text(entry.anime.title)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(entry.progressSummary) · \(entry.timeLeftSummary)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ProgressView(value: entry.progress)
                    .tint(.animoraPurple)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.animoraSoft)
        .cornerRadius(12)
    }

    private func shortcut(title: String, count: Int, systemImage: String, route: ContentView.Route) -> some View {
        Button {
            path.append(route)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .bold()
                Text("\(count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.animoraPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.animoraSoft)
            .cornerRadius(10)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(path: .constant([]))
            .environmentObject(PreviewData.makeRecommendationViewModel())
            .environmentObject(PreviewData.makeWatchlistViewModel())
            .environmentObject(PreviewData.makeFriendPicksViewModel())
    }
}
