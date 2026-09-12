# Animora

A personal anime recommendation app for the iOS platform, which suggests one anime at a time based on what the viewer is in the mood for and explains why each suggestion was made. This app is designed for the iPhone running iOS 17 or higher.

Animora is built for people new to anime who are wary of committing to something long. Rather than presenting a long list to scroll through, it asks about genre, how much time you actually have, and whether you mind a series still airing, then offers a single anime with the reasons it was picked. If the viewer has already seen that one, they can say so and the next-best suggestion takes its place. Anything marked as already seen is remembered, so it is never suggested again.

All version control and commit history for Animora can be found in this [GitHub repository](https://github.com/ben-vu/animora).

## Core Functionalities

* Building a recommendation request from genre, available viewing time and airing status,
* Filtering by total hours rather than episode count, since someone new to anime knows what 'about 6 hours' costs them but not what '12 episodes' means,
* Receiving one ranked anime suggestion at a time, each with plain-English reasons quoting its real rating and episode count,
* Marking a suggestion as already watched so it is excluded from every future search,
* Error messages that name the specific control to change when nothing matches, rather than reporting an empty result.

## Dependencies

* Swift/SwiftUI 5.9 and iOS 17+ language features
* Combine framework (Swift), for `ObservableObject` in the view model layer
* Swift Testing framework (Swift), for the unit test target

This project has no third-party package dependencies and makes no network requests. The anime catalogue is held locally in `LocalAnimeRepository`, behind the `AnimeRepository` protocol, so a networked source can be added later without changing any layer above it.

## Minimum Deployment

The minimum deployment of this project is iOS 17.0.

The unit tests use the Swift Testing framework, which requires **Xcode 16 or later** to build and run.

## Usage and Starting Up Details

Animora requires no API key, no account and no configuration. All data is bundled with the app, so it runs immediately after cloning. The steps to get it running are as follows:

1. Clone the repository and open `Animora.xcodeproj` in Xcode 16 or later.
2. Select any iPhone simulator running iOS 17.0 or higher from the scheme selector at the top of the window.
3. Press Run (`⌘R`) to build and launch the app.
4. To run the unit tests, press `⌘U`. All 13 tests should pass without a network connection.

Once running, tap **Get started**, choose one or more genres along with how much time you have and an airing status, then tap **Suggest me something**. From there, either accept the suggestion with **I'll watch this** or press **Already seen it — show me another** to be given the next one.

Note that the watch history is held in memory only, so the list of anime marked as already seen is cleared when the app is closed. Adding persistence means writing one new type conforming to the `WatchHistoryRepository` protocol; no other part of the app would need to change.
