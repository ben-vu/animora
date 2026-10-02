//
//  ShareViewController.swift
//  AnimoraShare
//
//  Created by Benjamin Vu on 29/9/2026.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// The starting point of the share extension.
///
/// Share extensions still have to start from a UIKit view controller, so this one
/// reads what was shared, then shows the SwiftUI form inside it. Everything after that
/// is the same MVVM setup as the main app.
///
/// The one thing a share extension must always do is close properly. Every way out of
/// here calls either completeRequest or cancelRequest, otherwise the share sheet
/// would be stuck on screen over the app the viewer shared from.
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        Task {
            let shared = await readSharedContent()
            showForm(title: shared.title, link: shared.link)
        }
    }

    // MARK: - Reading what was shared

    /// Looks through what the other app shared and pulls out a link and some text.
    ///
    /// Different apps share in different ways. Safari sends a URL, Messages sends the
    /// text of the message, and some apps send both, so I check for each.
    private func readSharedContent() async -> (title: String, link: URL?) {
        var foundLink: URL? = nil
        var foundText = ""

        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return ("", nil)
        }

        for item in items {
            // Some apps put their text here instead of in an attachment.
            if let attributedText = item.attributedContentText, foundText.isEmpty {
                foundText = attributedText.string
            }

            guard let attachments = item.attachments else { continue }

            for provider in attachments {

                if foundLink == nil && provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let loaded = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) {
                        if let url = loaded as? URL {
                            foundLink = url
                        }
                    }
                }

                if foundText.isEmpty && provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let loaded = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) {
                        if let text = loaded as? String {
                            foundText = text
                        }
                    }
                }
            }
        }

        foundText = foundText.trimmingCharacters(in: .whitespacesAndNewlines)

        // When someone shares a link as text, the "text" is just the link. Treat it as
        // the link so the title box doesn't end up with a web address in it.
        if foundLink == nil, let textAsLink = URL(string: foundText), textAsLink.scheme?.hasPrefix("http") == true {
            foundLink = textAsLink
            foundText = ""
        }
        if let link = foundLink, foundText == link.absoluteString {
            foundText = ""
        }

        // If it's a MyAnimeList link, the anime's name is inside the link, so I can
        // fill in the title for the viewer.
        if foundText.isEmpty, let link = foundLink, let titleInLink = FriendPick.titleFromLink(link) {
            foundText = titleInLink
        }

        return (foundText, foundLink)
    }

    // MARK: - Showing the form

    private func showForm(title: String, link: URL?) {
        let viewModel = SaveFriendPickViewModel(
            title: title,
            sharedLink: link,
            friendPicks: CoreDataFriendPickRepository()
        )

        let form = SaveFriendPickView(
            viewModel: viewModel,
            onSaved: { [weak self] in
                self?.finish()
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )

        let hostingController = UIHostingController(rootView: form)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    // MARK: - Closing the share sheet

    /// The pick is saved in the App Group database, so the main app will find it next
    /// time it opens. Close the sheet and go back to where the viewer was.
    private func finish() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    /// The viewer changed their mind. Nothing was saved.
    private func cancel() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)
        extensionContext?.cancelRequest(withError: error)
    }
}
