//
//  WatchHistoryView.swift
//  Animora
//
//  Created by Benjamin Vu on 19/9/2026.
//

import SwiftUI

/// Screen 7: Already seen.
///
/// Everything Animora will never suggest again, and why. Mostly this is here so the
/// viewer can trust the app: if they wonder why a show never comes up, the answer is
/// on this list.
struct WatchHistoryView: View {

    @EnvironmentObject var watchlistViewModel: WatchlistViewModel

    var body: some View {
        List {
            if watchlistViewModel.history.isEmpty {
                Text("Nothing here yet. When you tell Animora you've already seen something, or finish a show on Now watching, it's listed here and won't be suggested again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(watchlistViewModel.history) { record in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(record.animeTitle)
                            .font(.headline)
                        Text("\(record.reason.displayName) · \(record.markedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(record.reason == .finishedWithAnimora ? .animoraPurple : .secondary)
                    }
                }
            }
        }
        .navigationTitle("Already seen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            watchlistViewModel.refresh()
        }
    }
}

#Preview {
    NavigationStack {
        WatchHistoryView()
            .environmentObject(PreviewData.makeWatchlistViewModel())
    }
}
