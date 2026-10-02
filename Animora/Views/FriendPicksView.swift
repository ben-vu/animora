//
//  FriendPicksView.swift
//  Animora
//
//  Created by Benjamin Vu on 18/9/2026.
//

import SwiftUI

/// Screen 6: From your friends.
///
/// Every anime a friend has recommended, sent in through the share sheet. The viewer
/// doesn't have to do anything with these here, since they are already ranked first
/// in suggestions. This screen is mainly so they can see what's been saved, delete
/// ones they aren't interested in, and learn how to add more.
struct FriendPicksView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @EnvironmentObject var friendPicksViewModel: FriendPicksViewModel
    @Binding var path: [ContentView.Route]

    var body: some View {
        List {

            Section {
                howToAddOne
            }

            if friendPicksViewModel.isLookingUp {
                Section {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Looking up your new picks…")
                            .font(.subheadline)
                    }
                }
            }

            if let message = friendPicksViewModel.errorMessage {
                Section {
                    ErrorMessageBox(message: message)
                    Button("Try again") {
                        Task {
                            await friendPicksViewModel.lookUpNewPicks()
                        }
                    }
                }
            }

            Section("Picks") {
                if friendPicksViewModel.picks.isEmpty {
                    Text("No picks from friends yet. The next time someone tells you to watch something, share it to Animora and it'll be waiting here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(friendPicksViewModel.picks) { pick in
                        pickRow(pick)
                    }
                    .onDelete { offsets in
                        // Work out which picks first. Removing one reloads the list,
                        // which would shift the positions of the rest.
                        var picksToRemove: [FriendPick] = []
                        for index in offsets {
                            picksToRemove.append(friendPicksViewModel.picks[index])
                        }
                        for pick in picksToRemove {
                            friendPicksViewModel.remove(pick)
                        }
                    }
                }
            }

            if friendPicksViewModel.readyCount > 0 {
                Section {
                    Button {
                        viewModel.startOver()
                        path = [.request]
                    } label: {
                        Text("Suggest me something")
                            .font(.headline)
                            .foregroundColor(.animoraPurple)
                    }
                } footer: {
                    Text("Your friends' picks go to the top of any request they fit.")
                }
            }
        }
        .navigationTitle("From your friends")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            friendPicksViewModel.refresh()
        }
        .refreshable {
            await friendPicksViewModel.lookUpNewPicks()
        }
    }

    // MARK: - Pieces

    private var howToAddOne: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Got a recommendation?", systemImage: "square.and.arrow.up")
                .font(.headline)
                .foregroundColor(.animoraPurple)
            Text("In Messages, Safari or any app, tap Share on the link or the name, then choose Animora. Add who sent it, and it'll be suggested first next time it fits what you're in the mood for.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func pickRow(_ pick: FriendPick) -> some View {
        HStack(alignment: .top, spacing: 12) {
            AnimeCoverImage(url: pick.anime?.imageURL, width: 44, height: 62)

            VStack(alignment: .leading, spacing: 3) {
                Text(pick.displayTitle)
                    .font(.headline)

                Text("From \(pick.friendName) · \(pick.receivedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Where this pick is up to, in words the viewer can act on.
                if let anime = pick.anime {
                    Text("\(anime.episodeCountText) · \(anime.commitmentSummary)")
                        .font(.caption)
                        .foregroundColor(.animoraPurple)
                } else if pick.couldNotBeFound {
                    Text("We couldn't find this one in the catalogue. Swipe left to delete it, then share it again with the exact title.")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Waiting to be looked up. Pull down to try now.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendPicksView(path: .constant([]))
            .environmentObject(PreviewData.makeRecommendationViewModel())
            .environmentObject(PreviewData.makeFriendPicksViewModel())
    }
}
