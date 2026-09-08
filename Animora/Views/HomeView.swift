//
//  HomeView.swift
//  Animora
//
//  Created by Benjamin Vu on 7/9/2026.
//

import SwiftUI

/// Screen 1: the home screen.
///
/// This screen does one job, which is toget the viewer into the flow quickly. The whole point is a
/// decision in under a minute, so there is nothing here to read or scroll past.
struct HomeView: View {

    @EnvironmentObject var viewModel: RecommendationViewModel
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

            Text("No account needed.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .padding(24)
    }
}

#Preview {
    NavigationStack {
        HomeView(path: .constant([]))
            .environmentObject(RecommendationViewModel(repository: LocalAnimeRepository()))
    }
}
