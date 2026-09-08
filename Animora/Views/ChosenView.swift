//
//  ChosenView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// Screen 4: the confirmation, once the viewer has picked something.
///
/// A short screen on purpose. The job of the app is finished at this point, so it says
/// what was chosen and gets out of the way rather than trying to keep the viewer in it.
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

                Text("\(chosen.anime.episodes) episodes · rated \(String(format: "%.1f", chosen.anime.score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                viewModel.startOver()
                // Emptying the path goes all the way back to the home screen, which is
                // where a brand new request starts.
                path.removeAll()
            } label: {
                Text("Find another")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.animoraPurple)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .navigationTitle("All set")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ChosenView(path: .constant([]))
            .environmentObject(RecommendationViewModel(repository: LocalAnimeRepository()))
    }
}
