//
//  SuggestionView.swift
//  Animora
//
//  Created by Benjamin Vu on 8/9/2026.
//

import SwiftUI

/// Screen 3: one suggestion at a time.
///
/// The whole app comes down to this screen. The viewer sees a single anime with the
/// reasons it was picked, and has exactly two answers: watch it, or say they've already
/// seen it. One choice is much easier to make than a list of five, which is the problem
/// this app exists to solve.
///
/// Saying "already seen" writes the anime to the watch history, so it is gone from this
/// search and from every search after it.
struct SuggestionView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @Binding var path: [ContentView.Route]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                if let match = viewModel.currentSuggestion {
                    suggestion(for: match)
                } else {
                    ranOutMessage
                }
            }
            .padding(20)
        }
        .navigationTitle("Watch this")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - The suggestion

    @ViewBuilder
    private func suggestion(for match: AnimeMatch) -> some View {

        Text(match.matchLabel)
            .font(.caption)
            .bold()
            .foregroundColor(.animoraPurple)

        Text(match.anime.title)
            .font(.largeTitle)
            .bold()

        Text(match.anime.genreSummary)
            .font(.subheadline)
            .foregroundColor(.secondary)

        HStack(spacing: 26) {
            fact(label: "Rating", value: String(format: "★ %.1f", match.anime.score))
            fact(label: "Episodes", value: "\(match.anime.episodes)")
            fact(label: "Total", value: match.anime.commitmentSummary)
            fact(label: "Status", value: match.anime.status.displayName)
        }

        Divider()

        // The reasons. Every suggestion says why it is here.
        VStack(alignment: .leading, spacing: 8) {
            Text("Why this one")
                .font(.headline)

            ForEach(match.reasonsForViewer(), id: \.self) { reason in
                HStack(alignment: .top, spacing: 8) {
                    Text("✓").foregroundColor(.green)
                    Text(reason).font(.subheadline)
                }
            }
        }

        Divider()

        Text(match.anime.synopsis)
            .font(.subheadline)
            .foregroundColor(.secondary)

        if let message = viewModel.errorMessage {
            errorBox(message)
        }

        // MARK: The two answers

        Button {
            if viewModel.chooseCurrent() {
                path.append(.chosen)
            }
        } label: {
            Text("I'll watch this")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.animoraPurple)
                .cornerRadius(12)
        }

        Button {
            // This is the one place the viewer can tell Animora it got something
            // wrong. The app writes it down and moves on, so the same anime is never
            // suggested to them again.
            viewModel.markCurrentAsAlreadyWatched()
        } label: {
            Text("Already seen it — show me another")
                .font(.headline)
                .foregroundColor(.animoraPurple)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.animoraSoft)
                .cornerRadius(12)
        }

        // Telling the viewer there is more behind this one is what makes "already
        // seen" feel safe to press.
        if viewModel.remainingCount > 0 {
            Text("\(viewModel.remainingCount) more if this isn't it.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Text("This is the last one we found.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Nothing left

    private var ranOutMessage: some View {
        VStack(spacing: 12) {
            Text("You've seen them all")
                .font(.title3)
                .bold()

            Text("You've already watched everything we found for this request. Try a different genre or a longer episode limit.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                // Back to the request screen, which is where the controls they need
                // to change actually are.
                path.removeLast()
            } label: {
                Text("Change my request")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraPurple)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Small pieces

    private func fact(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }

    private func errorBox(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
            Text(message).font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(10)
    }
}

#Preview {
    let viewModel = RecommendationViewModel(repository: LocalAnimeRepository())
    viewModel.preferences.genres = [.action]
    viewModel.findAnime()

    return NavigationStack {
        SuggestionView(path: .constant([]))
            .environmentObject(viewModel)
    }
}
