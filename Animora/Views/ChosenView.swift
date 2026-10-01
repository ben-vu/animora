//
//  ChosenView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// Screen 4: the confirmation, once the viewer has picked something.
///
/// A short screen on purpose. It says what was chosen and gets out of the way rather
/// than trying to keep the viewer in the app.
///
/// In Assessment 2 this was the end of the road. Now it tells the viewer the anime is
/// on their Now watching list, and that the Up next widget can keep it in front of
/// them, because picking a show was never the hard part for a newcomer. Coming back to
/// it was.
struct ChosenView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
    @Binding var path: [ContentView.Route]

    var body: some View {
        VStack(spacing: 18) {

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.animoraPurple)

            if let chosen = viewModel.chosenMatch {
                Text("Enjoy \(chosen.anime.title)")
                    .font(.title2)
                    .bold()
                    .multilineTextAlignment(.center)

                Text("\(chosen.anime.episodeCountText) · \(chosen.anime.commitmentSummary) · rated \(String(format: "%.1f", chosen.anime.score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Where it went, and how to keep it in sight.
            VStack(alignment: .leading, spacing: 8) {
                Label("It's on your Now watching list, starting at episode 1.", systemImage: "play.circle")
                Label("Add the Animora Up next widget to your Home Screen or Lock Screen to see which episode is next, and tick them off without opening the app.", systemImage: "square.grid.2x2")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(12)
            .background(Color.animoraSoft)
            .cornerRadius(10)

            Spacer()

            Button {
                // Straight to the list, with the home screen underneath it so Back
                // goes somewhere sensible.
                viewModel.startOver()
                path = [.watchlist]
            } label: {
                Text("See Now watching")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraPurple)
                    .cornerRadius(12)
            }

            Button {
                viewModel.startOver()
                // Emptying the path goes all the way back to the home screen, which is
                // where a brand new request starts.
                path.removeAll()
            } label: {
                Text("Back to home")
                    .font(.headline)
                    .foregroundColor(.animoraPurple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraSoft)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .navigationTitle("All set")
        .navigationBarTitleDisplayMode(.inline)
        // There is nothing to go back to. The suggestion has been chosen, so the
        // suggestion screen would only offer the same choice again.
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    let viewModel = PreviewData.makeRecommendationViewModel()
    viewModel.chosenMatch = PreviewData.frierenMatch

    return NavigationStack {
        ChosenView(path: .constant([]))
            .environmentObject(viewModel)
    }
}
