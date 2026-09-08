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

                // MARK: Episode limit
                VStack(alignment: .leading, spacing: 8) {
                    Text("How long?")
                        .font(.headline)

                    Picker("How long?", selection: $viewModel.preferences.episodeLimit) {
                        ForEach(EpisodeLimit.allCases) { limit in
                            Text(limit.displayName).tag(limit)
                        }
                    }
                    .pickerStyle(.segmented)
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
                    if viewModel.findAnime() {
                        path.append(.suggestion)
                    }
                } label: {
                    Text("Suggest me something")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.animoraPurple)
                        .cornerRadius(12)
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
            .environmentObject(RecommendationViewModel(repository: LocalAnimeRepository()))
    }
}
