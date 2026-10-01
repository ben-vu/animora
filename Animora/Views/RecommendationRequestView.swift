//
//  RecommendationRequestView.swift
//  Animora
//
//  Created by Benjamin Vu on 8/9/2026.
//

import SwiftUI

/// Screen 2: where the viewer says what they're in the mood for.
///
/// The three controls match the three things that actually drive the decision: genre,
/// how long the series is, and whether it has finished.
struct RecommendationRequestView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @EnvironmentObject var friendPicksViewModel: FriendPicksViewModel
    @Binding var path: [ContentView.Route]

    /// Two columns of genre buttons.
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {

                // MARK: Genres
                VStack(alignment: .leading, spacing: 10) {
                    Text("What are you in the mood for?")
                        .font(.title2)
                        .bold()

                    Text("Pick one or more, or none for anything.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(AnimeGenre.allCases) { genre in
                            Button {
                                viewModel.toggleGenre(genre)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(genre.displayName)
                                        .font(.subheadline)
                                        .bold()
                                    // The plain-English hint, because someone new to
                                    // anime does not know what these names mean yet.
                                    Text(genre.beginnerHint)
                                        .font(.caption2)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(viewModel.isGenreChosen(genre) ? Color.animoraPurple : Color.animoraSoft)
                                .foregroundColor(viewModel.isGenreChosen(genre) ? .white : .primary)
                                .cornerRadius(10)
                            }
                        }
                    }
                }

                // MARK: Time commitment
                VStack(alignment: .leading, spacing: 8) {
                    Text("How much time have you got?")
                        .font(.headline)

                    Picker("Time", selection: $viewModel.preferences.timeCommitment) {
                        ForEach(TimeCommitment.allCases) { commitment in
                            Text(commitment.displayName).tag(commitment)
                        }
                    }
                    .pickerStyle(.segmented)

                    // Spelling out the hours matters. "A few evenings" is how people
                    // think, but they still need to know what they are agreeing to.
                    Text(viewModel.preferences.timeCommitment.explanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // MARK: Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finished or still airing?")
                        .font(.headline)

                    Picker("Status", selection: $viewModel.preferences.status) {
                        ForEach(AnimeStatusPreference.allCases) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // MARK: The error message
                // This is the whole reason for writing errors in the viewer's language.
                // The message appears right above the controls it is talking about.
                if let message = viewModel.errorMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.subheadline)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(10)
                }

                // MARK: Find
                Button {
                    // The view model runs the Use Case and tells us whether it worked.
                    // We only move to the results screen if there is something to show,
                    // so a failed search leaves the viewer here with the controls they
                    // need to change.
                    //
                    // The search goes over the internet now, so it runs in a Task and
                    // the screen stays usable while it waits.
                    Task {
                        if await viewModel.findAnime() {
                            path.append(.suggestion)
                        }
                    }
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isSearching {
                            ProgressView()
                                .tint(.white)
                            Text("Finding something for you…")
                        } else {
                            Text("Suggest me something")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraPurple)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isSearching)

                // Letting the viewer know their friends' picks count. Otherwise a pick
                // jumping to the top would look like a coincidence.
                if friendPicksViewModel.readyCount > 0 {
                    Text("Anything your friends sent that fits this request will be suggested first.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(20)
        }
        .navigationTitle("Your request")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        RecommendationRequestView(path: .constant([]))
            .environmentObject(PreviewData.makeRecommendationViewModel())
            .environmentObject(PreviewData.makeFriendPicksViewModel())
    }
}
