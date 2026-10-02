//
//  SaveFriendPickView.swift
//  AnimoraShare
//
//  Created by Benjamin Vu on 29/9/2026.
//

import SwiftUI

/// The form that pops up when the viewer shares something to Animora.
///
/// It is kept really short on purpose. The viewer is in the middle of a chat with the
/// friend who recommended the anime, so all it asks is the name and who said it. The
/// looking up happens later in the main app.
struct SaveFriendPickView: View {

    @ObservedObject var viewModel: SaveFriendPickViewModel

    /// Called after a successful save, so the share sheet can close.
    let onSaved: () -> Void

    /// Called when the viewer taps Cancel.
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    TextField("Anime name, like Frieren", text: $viewModel.title)
                        .autocorrectionDisabled()
                } header: {
                    Text("Title")
                } footer: {
                    if let linkDescription = viewModel.linkDescription {
                        Text("Link from \(linkDescription) will be saved with it.")
                    }
                }

                Section {
                    TextField("Their name (optional)", text: $viewModel.friendName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Who recommended it?")
                } footer: {
                    Text("Animora will put this anime first in your next suggestions and remind you who said to watch it.")
                }

                if let message = viewModel.errorMessage {
                    Section {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.orange)
                            Text(message)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Save a friend's pick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if viewModel.save() {
                            onSaved()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .tint(Color.animoraPurple)
    }
}

#Preview {
    SaveFriendPickView(
        viewModel: SaveFriendPickViewModel(
            title: "Sousou no Frieren",
            sharedLink: URL(string: "https://myanimelist.net/anime/52991/Sousou_no_Frieren"),
            friendPicks: InMemoryFriendPickRepository()
        ),
        onSaved: {},
        onCancel: {}
    )
}
