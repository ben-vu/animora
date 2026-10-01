//
//  WatchlistView.swift
//  Animora
//
//  Created by Benjamin Vu on 17/9/2026.
//

import SwiftUI

/// Screen 5: Now watching.
///
/// Everything the viewer has picked and hasn't finished, with where they are up to and
/// how much time is left. Ticking off the last episode moves a show to Already seen.
///
/// The button says which episode it is for ("Watched episode 4") rather than just "+1".
/// A newcomer watching a few episodes a week needs to know which episode they are
/// actually confirming, not do the maths.
struct WatchlistView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @EnvironmentObject var watchlistViewModel: WatchlistViewModel
    @Binding var path: [ContentView.Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let message = watchlistViewModel.finishedMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "party.popper.fill")
                            .foregroundColor(.animoraPurple)
                        Text(message)
                            .font(.subheadline)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.animoraSoft)
                    .cornerRadius(10)
                }

                if let message = watchlistViewModel.errorMessage {
                    ErrorMessageBox(message: message)
                }

                if watchlistViewModel.entries.isEmpty {
                    emptyMessage
                } else {
                    ForEach(watchlistViewModel.entries) { entry in
                        entryCard(entry)
                    }
                }

                Button {
                    viewModel.startOver()
                    path = [.request]
                } label: {
                    Text("Find your next anime")
                        .font(.headline)
                        .foregroundColor(.animoraPurple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.animoraSoft)
                        .cornerRadius(12)
                }
            }
            .padding(20)
        }
        .navigationTitle("Now watching")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            watchlistViewModel.refresh()
        }
        .refreshable {
            // Pull down to pick up anything ticked off on the widget.
            watchlistViewModel.refresh()
        }
    }

    // MARK: - One show

    private func entryCard(_ entry: WatchlistEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {

            HStack(alignment: .top, spacing: 12) {
                AnimeCoverImage(url: entry.anime.imageURL)

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.anime.title)
                        .font(.headline)
                    Text(entry.progressSummary)
                        .font(.subheadline)
                        .foregroundColor(.animoraPurple)
                        .bold()
                    Text(entry.timeLeftSummary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // A bar is only honest when the total is known. A series still airing with
            // no episode count gets no bar, rather than one that is always empty.
            if entry.anime.episodes != nil {
                ProgressView(value: entry.progress)
                    .tint(.animoraPurple)
            }

            Button {
                watchlistViewModel.logEpisode(for: entry)
            } label: {
                Label("Watched episode \(entry.nextEpisodeNumber)", systemImage: "checkmark")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.animoraPurple)
                    .cornerRadius(10)
            }
        }
        .padding(14)
        .background(Color.animoraSoft.opacity(0.6))
        .cornerRadius(12)
    }

    // MARK: - Nothing on the go

    private var emptyMessage: some View {
        VStack(spacing: 10) {
            Image(systemName: "play.circle")
                .font(.system(size: 40))
                .foregroundColor(.animoraPurple)

            Text("Nothing on the go")
                .font(.title3)
                .bold()

            Text("When you pick an anime with I'll watch this, it shows up here and on the Up next widget, so you never lose your place.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    NavigationStack {
        WatchlistView(path: .constant([]))
            .environmentObject(PreviewData.makeRecommendationViewModel())
            .environmentObject(PreviewData.makeWatchlistViewModel())
    }
}
