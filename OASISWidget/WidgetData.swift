//
//  WidgetData.swift
//  OASISWidgetExtension
//

//  Created by Austin Zambito-Valente on 7/5/26.
//

import Foundation
import AppIntents
import WidgetKit

struct FestivalEntity: AppEntity, Codable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Upcoming Festival"
    )
    static var defaultQuery = FestivalQuery()

    let id: UUID
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

enum Shared {
    static let appGroup = "group.com.austinzambitovalente.OASIS"
}

struct FestivalQuery: EntityQuery {

    func entities(for identifiers: [UUID]) async throws -> [FestivalEntity] {
        loadSharedFestivals()
            .filter { identifiers.contains($0.id) }
            .map { FestivalEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [FestivalEntity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return loadSharedFestivals()
            .filter {
                calendar.startOfDay(for: $0.endDate) >= today
            }
            .map { FestivalEntity(id: $0.id, name: $0.name) }
    }
}

struct SharedFestival: Codable {
    let id: UUID
    let name: String
    let logoPath: String?
    let artistList: Array<Artist>
    let startDate: Date
    let endDate: Date
}

struct DailyArtistOverride: Codable {
    let festivalID: String
    let artistIDs: [String]
    let date: String
}


//func defaultArtistForToday(from festival: SharedFestival) -> Artist {
//
//    let shuffled = festival.artistList.seededShuffle(seed: festival.id)
//
//    let day = Calendar.current.ordinality(
//        of: .day,
//        in: .year,
//        for: Date()
//    ) ?? 0
//
//    return shuffled[day % shuffled.count]
//}
//
//
//func artistForToday(from festival: SharedFestival?) -> Artist? {
//
//    guard let festival,
//          !festival.artistList.isEmpty else {
//        return nil
//    }
//
//    if let override = loadArtistOverride(for: festival.id.uuidString),
//       override.date == todayString(),
//       let artist = festival.artistList.first(where: { $0.id == override.artistID }) {
//
//        return artist
//    }
//
//    return defaultArtistForToday(from: festival)
//}

func defaultArtistsForToday(from festival: SharedFestival) -> [Artist] {

    let shuffled = festival.artistList.seededShuffle(seed: festival.id)

    guard !shuffled.isEmpty else { return [] }

    let day = Calendar.current.ordinality(
        of: .day,
        in: .year,
        for: Date()
    ) ?? 0

    let startIndex = day % shuffled.count

    let offsets = [0, 10, 35]

    return offsets.map { offset in
        shuffled[(startIndex + offset) % shuffled.count]
    }
}

func artistsForToday(from festival: SharedFestival?) -> [Artist] {

    guard let festival,
          !festival.artistList.isEmpty else {
        return []
    }

    if let override = loadArtistOverride(for: festival.id.uuidString),
       override.date == todayString() {

        return override.artistIDs.compactMap { id in
            festival.artistList.first(where: { $0.id == id })
        }
    }

    return defaultArtistsForToday(from: festival)
}

func loadArtistOverride(for festivalID: String) -> DailyArtistOverride? {

    guard
        let data = defaults.data(forKey: "artistOverride-\(festivalID)"),
        let override = try? JSONDecoder().decode(DailyArtistOverride.self, from: data)
    else {
        return nil
    }

    return override
}


func loadSharedFestivals() -> [SharedFestival] {
    guard let defaults = UserDefaults(suiteName: Shared.appGroup),
          let data = defaults.data(forKey: "SharedFestivals")
    else {
        return []
    }

    do {
        return try JSONDecoder().decode(
            [SharedFestival].self,
            from: data
        )
    } catch {
        print("Failed to decode shared festivals:", error)
        return []
    }
}

func saveArtistOverride(festivalID: String, artistIDs: [String]) {

    let override = DailyArtistOverride(
        festivalID: festivalID,
        artistIDs: artistIDs,
        date: todayString()
    )

    if let data = try? JSONEncoder().encode(override) {
        defaults.set(data, forKey: "artistOverride-\(festivalID)")
    }
}

func todayString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
}

private let defaults = UserDefaults(suiteName: "YOUR_APP_GROUP")!

func sharedFestival(for id: UUID?) -> SharedFestival? {
    guard let id else { return nil }

    return loadSharedFestivals().first {
        $0.id == id
    }
}

let EMPTY_UUID_STRING = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
let DISPLAY_UUID_STRING = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!

let DISPLAY_ARTIST_ARRAY: Array<Artist> = [Artist(id: "ladygaga",
                                                  name: "Lady Gaga",
                                                  genres: ["Pop", "Dance", "Electronic", "Jazz"],
                                                  imageURL: "https://i.scdn.co/image/ab6761610000e5ebaadc18cac8d48124357c38e6"),
                                           Artist(id: "zedd",
                                                  name: "Zedd",
                                                  genres: ["House", "EDM", "Electronic"],
                                                  imageURL: "https://i.scdn.co/image/ab6761610000e5ebe28762aed82cde1178fb3873"),
                                           Artist(id: "faouzia",
                                                  name: "Faouzia",
                                                  genres: ["Pop", "Moroccan", "R&B"],
                                                  imageURL: "https://i.scdn.co/image/ab6761610000e5eb6310c4d3dcfe99b0a9da2a30")
]



func genresSortedByPopularity(
    genres: [String],
    genreCounts: [String: Int]
) -> [String] {

    genres.sorted { lhs, rhs in
        let lhsCount = genreCounts[lhs, default: 0]
        let rhsCount = genreCounts[rhs, default: 0]

        if lhsCount == rhsCount {
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }

        return lhsCount > rhsCount
    }
}


