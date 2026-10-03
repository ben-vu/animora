# Animora

A personal anime recommendation app for iOS that suggests one anime at a time based on what the viewer is in the mood for, explains why each suggestion was made, and then helps them actually keep watching it. This app is designed for the iPhone running iOS 27 or higher.

You can find all version control and commit history for Animora in this [GitHub repository](https://github.com/ben-vu/animora).

## Project Overview

The Assessment 2 MVP this project builds on is archived at [ben-vu/animora-mvp](https://github.com/ben-vu/animora-mvp).

Animora started in Assessment 2 as a recommendation MVP running on a hard-coded list of 15 anime. Assessment 3 builds it out into a platform-integrated app:

* The hard-coded list is gone. Suggestions now come from the live [Tenrai API](https://api.tenrai.org/v1), a public anime catalogue that uses the same ids as MyAnimeList.
* Everything the viewer does is saved with **Core Data** in an **App Group** shared container, so it survives the app being closed.
* A **WidgetKit widget** shows what the viewer is watching and which episode is next, on the Home Screen and the Lock Screen, and can tick off an episode without opening the app.
* A **Share Extension** lets the viewer send a friend's recommendation straight from Messages, Safari or any other app into Animora.

## Domain Context

The stakeholder is **someone new to anime who wants to start watching but doesn't know where to begin**. There are thousands of series, many are hundreds of episodes long, the most popular titles are often sequels, and a newcomer has no way to tell which ones fit the few free evenings they actually have.

Three things go wrong for this person, and Animora is built around all three:

1. **Choosing.** They scroll lists of popular titles, can't judge them, and give up. Animora asks what they're in the mood for and how much time they have, then offers one anime with plain-English reasons.
2. **Continuing.** They pick something, watch two episodes, and a week later have forgotten what they were watching and which episode they were on. The Now watching list and the Up next widget keep their place for them.
3. **Friends' recommendations.** Most people start anime because a friend says "you have to watch this", but that message gets buried in a group chat. The share sheet saves it into Animora, and friends' picks are put first in the next suggestions.

The app uses this domain's vocabulary throughout: *viewer*, *suggestion*, *Now watching*, *Up next*, *episode*, *watch history*, *friend's pick*.

## Core Functionalities

* Building a recommendation request from genre, available viewing time, and airing status
* Filtering by total hours rather than episode count, since someone new to anime knows what 'about 6 hours' costs them but not what '12 episodes' means
* Leaving out sequels, and series with an unknown length when the viewer has a time limit
* Receiving one ranked anime suggestion at a time, each with plain-English reasons quoting its real rating and episode count
* Marking a suggestion as already watched so it is excluded from every future search
* Choosing a suggestion, which puts it on the **Now watching** list at episode 1
* **Where to watch**: one tap from a chosen anime to the streaming service that has it (for example Crunchyroll or Netflix), opening the service's app if it's installed
* Ticking off episodes in the app or straight from the widget, with a finished series moving to the **Watch history**
* Saving a friend's recommendation from the share sheet, which Animora then looks up and ranks first
* Error messages that say what went wrong in the viewer's words and what to do next

## Screens

1. **Home** – Up next card, Get started, and shortcuts to the lists
2. **Your request** – genre, time and status controls
3. **Watch this** – one suggestion, its cover, reasons, and "I'll watch this" / "Already seen it? Show me another one"
4. **All set** – confirmation, with a link to Now watching
5. **Now watching** – progress through each series, with a "Watched episode N" button
6. **From your friends** – everything saved through the share sheet
7. **Already seen** – the watch history, both seen before Animora and finished with it

Plus the **Where to watch** sheet (opened from All set and Now watching) and the **Save a friend's pick** form inside the share sheet.

## Architecture

Animora follows MVVM with a Use Case layer and a Repository layer:

```
Views  →  ViewModels  →  Use Cases  →  Repository protocols  →  Core Data / Tenrai API
```

* **Views** (SwiftUI) only show state and forward taps to a ViewModel.
* **ViewModels** (`RecommendationViewModel`, `WatchlistViewModel`, `FriendPicksViewModel`, `WhereToWatchViewModel`, `SaveFriendPickViewModel`) hold screen state and call Use Cases. None of them import Core Data.
* **Use Cases** hold every business rule. Each one has a domain name, at least one rule, and its own typed error enum with human-readable messages:
  * `FindAnimeRecommendationsUseCase` – genre, not watched, no sequels, status, time budget, friends' picks first
  * `MarkAsAlreadyWatchedUseCase` – must be a real anime, can't be marked twice
  * `ChooseAnimeUseCase` – must be the suggestion on screen, can't already be on Now watching
  * `LogEpisodeWatchedUseCase` – must be on Now watching, can't go past the last episode, the last episode finishes the series
  * `SaveFriendPickUseCase` – needs something to look up, title must be short enough, no duplicates
  * `LookUpFriendPicksUseCase` – links beat titles, missing anime are marked not found, a lost connection leaves picks waiting
  * `FindWhereToWatchUseCase` – old `http` links upgraded to `https`, each service shown once, anime services (Crunchyroll, HIDIVE) first, and a Crunchyroll search instead of a dead end when nothing is listed
* **Repositories** are protocols (`AnimeRepository`, `WatchlistRepository`, `WatchHistoryRepository`, `FriendPickRepository`), each with a real version (`TenraiAnimeRepository` or `CoreData…Repository`) and an `InMemory…` version used by the tests and previews. `AppRepositories` is the only place that names the real ones.

Code used by more than one target lives in the `Shared/` folder, which is a member of the app, the widget and the share extension. That way the widget and the app run the exact same `LogEpisodeWatchedUseCase`, rather than two copies that could drift apart.

## System Extensions

### Up next widget (WidgetKit)

**Scenario:** it's 9pm, the viewer has half an hour, and they pick up their phone. Without the widget, the anime they chose last week is buried in an app they haven't opened since. With it, their Home Screen or Lock Screen already says *Frieren, Episode 4 of 28, about 10 hours left*. When the episode ends they tap **Watched ep 4** on the widget itself, without opening the app.

* Families: `systemSmall`, `systemMedium`, `accessoryRectangular`, `accessoryInline`
* Reads the Now watching list from the App Group Core Data store through `CoreDataWatchlistRepository`
* The **Watched ep N** button is an interactive `AppIntent` (`LogEpisodeIntent`) that runs `LogEpisodeWatchedUseCase`
* Every save goes through `AnimoraDatabase.save()`, which calls `WidgetCenter.shared.reloadAllTimelines()`, so the widget is reloaded after every data change in the app, the widget and the share extension
* When nothing is on the go it tells the viewer what to do next, instead of showing "No data"
* Tapping the widget opens the app on the Now watching screen (`animora://watchlist`)

### Save a friend's pick (Share Extension)

**Scenario:** a friend messages "you HAVE to watch Frieren" with a MyAnimeList link. The viewer long-presses the link, taps Share, then **Animora**, adds the friend's name, and taps Save. The sheet closes and they're back in the chat in a few seconds.

* Appears for web links and text (`NSExtensionActivationSupportsWebURLWithMaxCount` and `NSExtensionActivationSupportsText`)
* MyAnimeList links are read for the anime's id and name, so the title box fills itself in
* Saves through `SaveFriendPickUseCase` into the App Group Core Data store
* Always dismisses: Save calls `completeRequest`, Cancel calls `cancelRequest`
* It deliberately doesn't use the internet, so the share sheet never hangs. The next time the main app opens it runs `LookUpFriendPicksUseCase` against the Tenrai API, and the pick is ranked first in the viewer's next suggestions, with "Mia told you to watch this one" as a reason

## Database Choice

Animora uses **Core Data**, not CloudKit. The data is personal (what one viewer is watching and what their friends told them), small, and needs to be read instantly and offline, including by a widget that has a tiny time and memory budget and can't wait on a network. It also has to be written by three separate processes. A local Core Data store in the App Group container does all of that. Sharing between users isn't something this stakeholder needs.

The model (`Shared/Database/Animora.xcdatamodeld`) has four related entities:

| Entity | What it is | Relationships |
|---|---|---|
| `SavedAnimeEntity` | One anime's details, saved once | to-one `watchlistEntry`, to-one `watchedRecord`, to-many `friendPicks` |
| `WatchlistEntryEntity` | A series on Now watching and the episodes ticked off | `anime` → SavedAnime |
| `WatchedAnimeEntity` | A series in the watch history, and why | `anime` → SavedAnime |
| `FriendPickEntity` | A friend's recommendation from the share sheet | `anime` → SavedAnime (empty until looked up) |

Examples of domain predicates:

* Now watching: `anime.episodes == 0 OR episodesWatched < anime.episodes`, newest first (a series with an unknown length is never "finished")
* Friends' picks still to look up: `anime == nil AND couldNotBeFound == NO`

## App Group

```
group.iOSdD.Animora
```

The app (`iOSdD.Animora`), the widget (`iOSdD.Animora.AnimoraWidget`) and the share extension (`iOSdD.Animora.AnimoraShare`) all have this App Group in their entitlements, and all three open the same `Animora.sqlite` file inside it.

## Dependencies

* Swift/SwiftUI and iOS 27+ language features
* Core Data, for persistence
* WidgetKit and App Intents, for the widget
* Combine framework (Swift), for `ObservableObject` in the ViewModel layer
* Swift Testing framework (Swift), for the unit test target
* The [Tenrai API](https://api.tenrai.org/v1) (free, no API key). Animora keeps to its public limit of 3 requests a second.

There are no third-party packages.

## Minimum Deployment

The minimum deployment of this project is iOS 27. It needs **Xcode 27 or later**.

## Setup

1. Clone the repository and open `Animora.xcodeproj` in Xcode 27 or later.
2. For each of the three targets (**Animora**, **AnimoraWidgetExtension**, **AnimoraShareExtension**), open **Signing & Capabilities**, choose your **Team**, and make sure the **App Groups** capability shows `group.iOSdD.Animora` ticked. If Xcode says the group is taken, change the bundle id prefix and the group to your own, and update `AnimoraDatabase.appGroupID` to match.
3. Select an iPhone simulator running iOS 27 or higher and press Run (`⌘R`). The simulator needs an internet connection for suggestions.
4. To try the widget, long-press the Home Screen, tap **Edit → Add Widget**, and search for **Animora**.
5. To try the share extension, open a MyAnimeList anime page in Safari (for example `https://myanimelist.net/anime/52991`), tap Share, then **Animora**. If Animora isn't in the row, tap **More** and turn it on.
6. To run the unit tests, press `⌘U`. All 47 tests use in-memory mock repositories and hand-written JSON, so they pass without a network connection and never touch Core Data.

Once running, tap **Get started**, choose one or more genres along with how much time you have and an airing status, then tap **Suggest me something**. Accept a suggestion with **I'll watch this** to put it on Now watching, or press **Already seen it? Show me another one**.
