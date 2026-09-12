//
//  LocalAnimeRepository.swift
//  Animora
//
//  Created by Benjamin Vu on 3/9/2026.
//

import Foundation

/// The anime list built into the app.
///
/// This is the first of what will be several sources. Later there can be a
/// `TenraiAnimeRepository` that fetches the same `Anime` values from a web API
class LocalAnimeRepository: AnimeRepository {

    /// The anime this source is currently holding.
    ///
    /// `private(set)` means any screen can read the list, but only this class can
    /// change it. That keeps the list from being edited behind the app's back.
    private(set) var anime: [Anime] = []

    init() {
        anime = load()
    }

    func load() -> [Anime] {
        LocalAnimeRepository.sampleAnime
    }

    static let sampleAnime: [Anime] = [

        Anime(
            id: 1,
            title: "Attack on Titan",
            synopsis: "Humanity lives behind enormous walls to stay safe from giant humanoid Titans. When the wall is breached, a young soldier joins the fight to take the world back.",
            episodes: 25,
            episodeMinutes: 24,
            score: 8.5,
            status: .finished,
            genres: [.action, .drama, .fantasy]
        ),

        Anime(
            id: 2,
            title: "Fullmetal Alchemist: Brotherhood",
            synopsis: "Two brothers break a fundamental law of alchemy and pay a terrible price. Their search for a way to restore their bodies pulls them into a national conspiracy.",
            episodes: 64,
            episodeMinutes: 24,
            score: 9.1,
            status: .finished,
            genres: [.action, .adventure, .drama, .fantasy]
        ),

        Anime(
            id: 3,
            title: "Death Note",
            synopsis: "A high school student finds a notebook that kills anyone whose name is written in it, and begins a long game of wits with the detective hunting him.",
            episodes: 37,
            episodeMinutes: 24,
            score: 8.6,
            status: .finished,
            genres: [.thriller, .drama, .sciFi]
        ),

        Anime(
            id: 4,
            title: "Your Lie in April",
            synopsis: "A pianist who lost the ability to hear his own playing meets a violinist who pushes him back towards music.",
            episodes: 22,
            episodeMinutes: 24,
            score: 8.6,
            status: .finished,
            genres: [.drama, .romance, .sliceOfLife]
        ),

        Anime(
            id: 5,
            title: "Haikyu!!",
            synopsis: "A short but determined student joins his high school volleyball club and has to learn to play alongside his former rival.",
            episodes: 25,
            episodeMinutes: 24,
            score: 8.7,
            status: .finished,
            genres: [.sports, .comedy, .drama]
        ),

        Anime(
            id: 6,
            title: "Spy x Family",
            synopsis: "A spy builds a fake family for a mission, not realising his new daughter reads minds and his new wife is an assassin.",
            episodes: 25,
            episodeMinutes: 24,
            score: 8.4,
            status: .airing,
            genres: [.comedy, .action, .sliceOfLife]
        ),

        Anime(
            id: 7,
            title: "Steins;Gate",
            synopsis: "A self-styled mad scientist accidentally invents a way to send messages into the past, then has to undo the damage it causes.",
            episodes: 24,
            episodeMinutes: 24,
            score: 9.0,
            status: .finished,
            genres: [.sciFi, .thriller, .drama]
        ),

        Anime(
            id: 8,
            title: "Mob Psycho 100",
            synopsis: "An immensely powerful young psychic just wants to be normal, and works part time for a con artist who claims to be a spirit medium.",
            episodes: 12,
            episodeMinutes: 24,
            score: 8.5,
            status: .finished,
            genres: [.action, .comedy, .sliceOfLife]
        ),

        Anime(
            id: 9,
            title: "Violet Evergarden",
            synopsis: "A former child soldier takes a job writing letters for other people and slowly learns what feelings are.",
            episodes: 13,
            episodeMinutes: 24,
            score: 8.7,
            status: .finished,
            genres: [.drama, .fantasy, .sliceOfLife]
        ),

        Anime(
            id: 10,
            title: "One Punch Man",
            synopsis: "A hero who can defeat anything with a single punch is mostly just bored, and struggles with the paperwork of official hero ranking.",
            episodes: 12,
            episodeMinutes: 24,
            score: 8.5,
            status: .finished,
            genres: [.action, .comedy, .sciFi]
        ),

        Anime(
            id: 11,
            title: "Toradora!",
            synopsis: "Two classmates agree to help each other win over their respective crushes, which goes about as well as expected.",
            episodes: 25,
            episodeMinutes: 24,
            score: 8.1,
            status: .finished,
            genres: [.romance, .comedy, .drama]
        ),

        Anime(
            id: 12,
            title: "Demon Slayer",
            synopsis: "After his family is killed and his sister turned into a demon, a young man joins the corps that hunts them.",
            episodes: 26,
            episodeMinutes: 24,
            score: 8.5,
            status: .airing,
            genres: [.action, .fantasy, .adventure]
        ),

        Anime(
            id: 13,
            title: "Run with the Wind",
            synopsis: "A group of students who mostly cannot run are talked into entering one of Japan's toughest relay marathons.",
            episodes: 23,
            episodeMinutes: 24,
            score: 8.3,
            status: .finished,
            genres: [.sports, .drama, .sliceOfLife]
        ),

        Anime(
            id: 14,
            title: "Erased",
            synopsis: "A man who involuntarily travels back in time is sent to his childhood, where he has a chance to stop a kidnapping.",
            episodes: 12,
            episodeMinutes: 24,
            score: 8.3,
            status: .finished,
            genres: [.thriller, .drama, .sciFi]
        ),

        Anime(
            id: 15,
            title: "Vinland Saga",
            synopsis: "A boy raised among Viking mercenaries chases revenge for his father, and slowly starts to ask what it is all for.",
            episodes: 24,
            episodeMinutes: 24,
            score: 8.8,
            status: .finished,
            genres: [.action, .adventure, .drama]
        )
    ]
}
