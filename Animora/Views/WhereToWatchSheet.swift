//
//  WhereToWatchSheet.swift
//  Animora
//
//  Created by Benjamin Vu on 2/10/2026.
//

import SwiftUI

/// The sheet that takes the viewer to a streaming service to start watching.
///
/// Each button is a `Link`, so iOS opens the service's own app when it is installed
/// (like the Crunchyroll app), and Safari when it isn't.
struct WhereToWatchSheet: View {

    @StateObject private var viewModel: WhereToWatchViewModel
    @Environment(\.dismiss) private var dismiss

    init(anime: Anime, catalogue: AnimeRepository = AppRepositories.catalogue) {
        _viewModel = StateObject(wrappedValue: WhereToWatchViewModel(anime: anime, catalogue: catalogue))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {

                    Text(viewModel.anime.title)
                        .font(.title3)
                        .bold()

                    if viewModel.isLoading {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Finding where it's streaming…")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                    } else if let message = viewModel.errorMessage {
                        ErrorMessageBox(message: message)

                        Button("Try again") {
                            Task {
                                await viewModel.load()
                            }
                        }
                        .foregroundColor(.animoraPurple)
                    } else {
                        if viewModel.onlyHasASearch {
                            Text("The catalogue doesn't list a streaming service for this one yet, so here's a search instead.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ForEach(viewModel.options) { option in
                            Link(destination: option.link) {
                                HStack {
                                    Image(systemName: option.isSearch ? "magnifyingglass" : "play.tv.fill")
                                    Text(option.buttonTitle)
                                        .bold()
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.animoraPurple)
                                .cornerRadius(12)
                            }
                        }

                        // The catalogue's links are worldwide. A show can be on Netflix
                        // in one country and not another, so I say so up front.
                        Text("What's available depends on your country, and some services need a subscription.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Where to watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await viewModel.load()
        }
    }
}

#Preview {
    Text("Animora")
        .sheet(isPresented: .constant(true)) {
            WhereToWatchSheet(anime: PreviewData.frieren, catalogue: TenraiAnimeRepository())
        }
}
