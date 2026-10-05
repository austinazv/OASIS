//
//  AppIntent.swift
//  OASISWidget
//
//  Created by Austin Zambito-Valente on 7/3/26.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {

    static var title: LocalizedStringResource = "OASIS Widget"
    static var description = IntentDescription("Choose which festival to display.")

    @Parameter(title: "Festival")
    var festival: FestivalEntity?
}

struct RefreshFestivalIntent: AppIntent {

    @Parameter(title: "Festival")
    var festival: FestivalEntity?

    static var title: LocalizedStringResource = "Shuffle Artist"

    func perform() async throws -> some IntentResult {

        guard let festival else {
            return .result()
        }

        guard let selectedFestival = sharedFestival(for: festival.id) else {
            return .result()
        }

        guard selectedFestival.artistList.count > 3 else {
            return .result()
        }

        let currentArtists = artistsForToday(from: selectedFestival)
        let currentIDs = Set(currentArtists.map(\.id))

        let choices = selectedFestival.artistList.filter {
            !currentIDs.contains($0.id)
        }

        guard choices.count >= 3 else {
            return .result()
        }

        let newArtists = Array(choices.shuffled().prefix(3))

        saveArtistOverride(
            festivalID: selectedFestival.id.uuidString,
            artistIDs: newArtists.map(\.id)
        )

        WidgetCenter.shared.reloadTimelines(ofKind: "OASISWidget")

        return .result()
    }
}

//struct RefreshFestivalIntent: AppIntent {
//
//    @Parameter(title: "Festival")
//    var festival: FestivalEntity?
//
//    static var title: LocalizedStringResource = "Shuffle Artist"
//
//    func perform() async throws -> some IntentResult {
//        
//        guard let festival else {
//            return .result()
//        }
//        
//        guard let selectedFestival = sharedFestival(for: festival.id) else {
//            return .result()
//        }
//
////        guard let festival = loadSharedFestival() else {
////            return .result()
////        }
//
//        guard selectedFestival.artistList.count > 1 else {
//            return .result()
//        }
//
//        let currentArtist = artistForToday(from: selectedFestival)
//
//        let choices = selectedFestival.artistList.filter {
//            $0.id != currentArtist?.id
//        }
//
//        guard let newArtist = choices.randomElement() else {
//            return .result()
//        }
//
//        saveArtistOverride(
//            festivalID: selectedFestival.id.uuidString,
//            artistID: newArtist.id
//        )
//
//        WidgetCenter.shared.reloadTimelines(ofKind: "OASISWidget")
//
//        return .result()
//    }
//}

//struct ConfigurationAppIntent: WidgetConfigurationIntent {
//    static var title: LocalizedStringResource { "Configuration" }
//    static var description: IntentDescription { "This is an example widget." }
//
//    // An example configurable parameter.
//    @Parameter(title: "Favorite Emoji", default: "😃")
//    var favoriteEmoji: String
//}
