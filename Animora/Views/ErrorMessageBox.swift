//
//  ErrorMessageBox.swift
//  Animora
//
//  Created by Benjamin Vu on 19/9/2026.
//

import SwiftUI

/// The orange box every screen uses to show an error message.
///
/// I had this copied into two screens in Assessment 2. With three new screens it was
/// time to make it one view.
struct ErrorMessageBox: View {

    let message: String

    var body: some View {
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
}

/// The small cover picture, loaded from the catalogue.
///
/// While it loads, or if there is no picture, it shows a purple tile instead so the
/// layout doesn't jump around.
struct AnimeCoverImage: View {

    let url: URL?
    var width: CGFloat = 60
    var height: CGFloat = 85

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            ZStack {
                Color.animoraSoft
                Image(systemName: "play.tv")
                    .foregroundColor(.animoraPurple)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .cornerRadius(8)
    }
}

#Preview {
    VStack {
        ErrorMessageBox(message: "Animora couldn't reach the anime catalogue. Check you're connected to Wi-Fi or mobile data, then try again.")
        AnimeCoverImage(url: nil)
    }
    .padding()
}
