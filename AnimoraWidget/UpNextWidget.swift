//
//  UpNextWidget.swift
//  AnimoraWidget
//
//  Created by Benjamin Vu on 30/9/2026.
//

import WidgetKit
import SwiftUI
import AppIntents

/// The Up next widget.
///
/// The scenario it is built for: it's 9pm, the viewer has half an hour, and they pick
/// up their phone. Without this, the anime they picked last week is buried in an app
/// they haven't opened since, and they end up scrolling something else instead. With
/// it, the Home Screen or Lock Screen already says "Frieren, episode 4 of 28, about
/// 10 hours left". The Home Screen sizes also have a button to tick the episode off
/// when it's done, without opening Animora at all.
struct UpNextWidget: Widget {

    let kind = "UpNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpNextProvider()) { entry in
            UpNextWidgetView(entry: entry)
                .containerBackground(Color.animoraSoft, for: .widget)
                // Tapping anywhere except the button opens the Now watching list.
                .widgetURL(URL(string: "animora://watchlist"))
        }
        .configurationDisplayName("Up next")
        .description("The anime you're watching, which episode is next, and how long is left.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - The data

/// What the widget shows at one point in time.
struct UpNextEntry: TimelineEntry {
    let date: Date

    /// The show the viewer touched most recently, or `nil` if nothing is on the go.
    let watching: WatchlistEntry?

    /// How many other shows are on the Now watching list.
    let othersOnTheGo: Int
}

/// Reads the Now watching list from the App Group database.
struct UpNextProvider: TimelineProvider {

    /// A made-up entry for the widget gallery, so it looks real before the viewer has
    /// picked anything.
    static let sampleEntry = UpNextEntry(
        date: Date(),
        watching: WatchlistEntry(
            anime: Anime(
                id: 52991,
                title: "Frieren: Beyond Journey's End",
                synopsis: "",
                episodes: 28,
                episodeMinutes: 24,
                score: 9.3,
                status: .finished,
                genres: [.adventure, .drama, .fantasy]
            ),
            episodesWatched: 3,
            startedAt: Date(),
            updatedAt: Date()
        ),
        othersOnTheGo: 1
    )

    func placeholder(in context: Context) -> UpNextEntry {
        UpNextProvider.sampleEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> Void) {
        let realEntry = loadEntry()

        // In the widget gallery, show the sample if there's nothing real yet, so the
        // viewer can see what they are adding.
        if context.isPreview && realEntry.watching == nil {
            completion(UpNextProvider.sampleEntry)
        } else {
            completion(realEntry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpNextEntry>) -> Void) {
        // One entry and `.never`, because nothing here changes with time on its own.
        // It only changes when the viewer does something, and every save in the app,
        // the widget and the share extension already calls reloadAllTimelines().
        let timeline = Timeline(entries: [loadEntry()], policy: .never)
        completion(timeline)
    }

    /// Reads what is on the go right now.
    ///
    /// This goes through the same repository protocol the app uses, so the widget
    /// sees the list in the same order as the app's home screen.
    private func loadEntry() -> UpNextEntry {
        let watchlist: WatchlistRepository = CoreDataWatchlistRepository()
        let entries = watchlist.entries

        return UpNextEntry(
            date: Date(),
            watching: entries.first,
            othersOnTheGo: max(0, entries.count - 1)
        )
    }
}

// MARK: - The views

struct UpNextWidgetView: View {

    @Environment(\.widgetFamily) var family

    let entry: UpNextEntry

    var body: some View {
        if let watching = entry.watching {
            switch family {
            case .accessoryInline:
                inline(watching)
            case .accessoryRectangular:
                rectangular(watching)
            case .systemMedium:
                medium(watching)
            default:
                small(watching)
            }
        } else {
            nothingOnTheGo
        }
    }

    // MARK: Lock Screen

    /// One line above the clock. The episode comes first because a very long title
    /// would push it off the end.
    private func inline(_ watching: WatchlistEntry) -> some View {
        Text("Ep \(watching.nextEpisodeNumber) · \(watching.anime.title)")
    }

    private func rectangular(_ watching: WatchlistEntry) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("UP NEXT")
                .font(.caption2)
                .bold()
            Text(watching.anime.title)
                .font(.headline)
                .lineLimit(1)
            Text(watching.progressSummary)
                .font(.caption)
            Text(watching.timeLeftSummary)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Home Screen

    private func small(_ watching: WatchlistEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("UP NEXT")
                .font(.caption2)
                .bold()
                .foregroundColor(.animoraPurple)

            Text(watching.anime.title)
                .font(.headline)
                .lineLimit(2)

            Text(watching.progressSummary)
                .font(.caption)
                .foregroundColor(.secondary)

            if watching.anime.episodes != nil {
                ProgressView(value: watching.progress)
                    .tint(.animoraPurple)
            }

            Spacer(minLength: 0)

            logButton(watching, short: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func medium(_ watching: WatchlistEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {

            VStack(alignment: .leading, spacing: 4) {
                Text("UP NEXT")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.animoraPurple)

                Text(watching.anime.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(watching.progressSummary) · \(watching.timeLeftSummary)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if watching.anime.episodes != nil {
                    ProgressView(value: watching.progress)
                        .tint(.animoraPurple)
                }

                Spacer(minLength: 0)

                if entry.othersOnTheGo > 0 {
                    Text("+\(entry.othersOnTheGo) more on the go")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            VStack {
                Spacer(minLength: 0)
                logButton(watching, short: false)
            }
        }
    }

    /// The button that ticks off the episode without opening the app.
    ///
    /// It names the episode number, so the viewer knows exactly what they are
    /// confirming. Tapping "+1" and hoping is how counts end up wrong.
    private func logButton(_ watching: WatchlistEntry, short: Bool) -> some View {
        Button(intent: LogEpisodeIntent(animeID: watching.anime.id)) {
            if short {
                Label("Watched ep \(watching.nextEpisodeNumber)", systemImage: "checkmark")
                    .font(.caption)
                    .bold()
                    .frame(maxWidth: .infinity)
            } else {
                Label("Watched\nep \(watching.nextEpisodeNumber)", systemImage: "checkmark")
                    .font(.caption)
                    .bold()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(.animoraPurple)
    }

    // MARK: Nothing on the go

    /// Shown until the viewer picks something. It says what to do rather than
    /// "No data", because it's a normal state for a new viewer, not a fault.
    @ViewBuilder
    private var nothingOnTheGo: some View {
        switch family {
        case .accessoryInline:
            Text("Animora: pick your next anime")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("ANIMORA")
                    .font(.caption2)
                    .bold()
                Text("Nothing on the go")
                    .font(.headline)
                Text("Open to pick your next anime")
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("ANIMORA")
                    .font(.caption2)
                    .bold()
                    .foregroundColor(.animoraPurple)
                Text("Nothing on the go")
                    .font(.headline)
                Text("Open Animora and pick something. It'll show up here with the episode you're on.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview(as: .systemSmall) {
    UpNextWidget()
} timeline: {
    UpNextProvider.sampleEntry
    UpNextEntry(date: Date(), watching: nil, othersOnTheGo: 0)
}

#Preview(as: .systemMedium) {
    UpNextWidget()
} timeline: {
    UpNextProvider.sampleEntry
}

#Preview(as: .accessoryRectangular) {
    UpNextWidget()
} timeline: {
    UpNextProvider.sampleEntry
}
