//
//  DataSet.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/15/25.
//

import Foundation
import SwiftUI
import UIKit
import CryptoKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class DataSet: ObservableObject {
    @Published var createPlaylist: Bool = false
    @Published var userInfo: UserProfile?
    @Published var userInfoTemp: UserProfileTemp
    
    @Published var progress: Float = 0.0
    var playlistArtistCount: Int = 1
    
    private let saveName: String
//    let artistList: Array<artist>
//    let DEFAULTARTIST: artist
    
    var currentUploadTask: StorageUploadTask?
    var isUploading = false
    
    var ERRORCOUNT: Int = 0
    
    let NA_TITLE_BLOCK = "-- N/A --"
    
//    var favoritesList: Array<Array<artist>> = Array(repeating: Array<artist>(), count: 2) {
//        didSet {
//            UserDefaults.standard.set(dislikeData, forKey: String(self.saveName + "dislikes"))
//            UserDefaults.standard.set(likeData, forKey: String(self.saveName + "likes"))
//            self.updateFavorites(favorites: getFavsID(liking: 1))
//        }
//    }
    
//    var dislikeData: Data? {
//        return try? JSONEncoder().encode(getFavsID(liking: 0))
//    }
//    
//    var likeData: Data? {
//        return try? JSONEncoder().encode(getFavsID(liking: 1))
//    }
    
    var settings: settingsStruct {
        willSet {
            objectWillChange.send()
        }
        didSet {
//            UserDefaults.standard.set(festivalDaysData, forKey: String(self.saveName + "festivalDays"))
//            UserDefaults.standard.set(festivalWeekendData, forKey: String(self.saveName + "festivalWeekend"))
        }
    }
    
    var festivalDaysData: Data? {
        return try? JSONEncoder().encode(settings.festivalDays)
    }
    
    var festivalWeekendData: Data? {
        return try? JSONEncoder().encode(settings.festivalWeekend)
    }
    
//    func getFavsID(liking: Int) -> Array<String> {
//        var favIDs = Array<String>()
//        for a in favoritesList[liking] {
//            favIDs.append(a.id)
//        }
//        return favIDs
//    }
    
//    func getFavoritesList() -> Array<artist> {
//        return favoritesList[0]
//    }
    
    func updateFavorites(favorites: Array<String>) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData([
            "favorites": favorites
        ]) { error in
            if let error = error {
                print("Error updating likes: \(error.localizedDescription)")
            } else {
                print("Likes updated successfully")
            }
        }
    }
    
//    func getArtistListFromID(artists: [String]) -> [artist] {
//        var artistArray = [artist]()
//        for a in artists {
//            if let artist = getArtist(artistID: a) {
//                artistArray.append(artist)
//            }
//        }
//        return artistArray
//    }
    
//    func getArtist(artistID: String) -> artist? {
//        for a in artistList {
//            if a.id == artistID {
//                return a
//            }
//        }
//        return nil
//    }
    
//    func shuffleArtistNEW(currentList: Array<Artist>, currentArtist: Artist? = nil) -> Artist? {
//        var shuffleList = currentList
//        if let artist = currentArtist {
//            shuffleList = shuffleList.filter{ $0 != artist }
//        }
//        if !shuffleList.isEmpty {
//            return shuffleList.randomElement()!
//        }
//        return nil
//    }
    
//    func shuffleArtist(currentArtist: artist? = nil, currentList: Array<artist>? = nil, includeFavorites: Bool) -> artist {
//        var shuffleList = Array<artist>()
//        let fullList = currentList == nil ? getFullList() : currentList!
//        for a in fullList {
//            if (!favoritesList[0].contains(where: { $0.id == a.id }) &&
//                (includeFavorites || !favoritesList[1].contains(where: { $0.id == a.id })) &&
//                (currentArtist == nil || currentArtist!.id != a.id)) {
//                shuffleList.append(a)
//            }
//        }
//        
//        if shuffleList.count > 0 {
//            return shuffleList.randomElement()!
//        } else if currentArtist != nil && currentArtist!.favorability != -1 {
//            return currentArtist!
//        }
//        return DEFAULTARTIST
//    }
    
//    func getShuffleableArtists(currentArtistID: String? = nil, currentList: Array<artist>) -> Array<artist> {
//        var shuffleList = Array<artist>()
//        for a in currentList {
//            if (!favoritesList[0].contains(where: { $0.id == a.id }) && (currentArtistID == nil || currentArtistID != a.id)) {
//                shuffleList.append(a)
//            }
//        }
//        return shuffleList
//    }
    
    func getDefaultColor() -> Color {
        return Color(hue: 0.76, saturation: 0.2, brightness: 0.85)
    }
    
    
//    func setFavorability(liking: Int, artist: artist) -> Int {
//        //-1 == dislike, 1 == like
//        let arrayNum = (liking+1)/2
//        for (i,a_1) in favoritesList[arrayNum].enumerated() {
//            if a_1.id == artist.id {
//                favoritesList[arrayNum].remove(at: i)
//                return 0
//                
//            }
//        }
//        favoritesList[arrayNum].append(artist)
//        for (i,a_1) in favoritesList[1-arrayNum].enumerated() {
//            if a_1.id == artist.id {
//                favoritesList[1-arrayNum].remove(at: i)
//                break
//            }
//        }
//        return liking
//    }
    
//    func getFavorability(artistID: String) -> Int {
//        if favoritesList[0].contains(where: { $0.id == artistID }) {
//            return -1
//        }
//        if favoritesList[1].contains(where: { $0.id == artistID }) {
//            return 1
//        }
//        return 0
//    }
    
//    func getArtistDict(currDict: [String : Array<artist>]? = nil, favorites: Bool = false, sort: sortType, lable: String? = nil, sortDict: [String : [String]]? = nil) -> [String : Array<artist>] {
//        if var dict = sortDict {
//            dict = self.addMyFavorites(groupFavorites: dict)
//            for (_,list) in currDict! {
//                var sortedList = list
//                sortedList.sort {
//                    let artist1num = dict[$0.id]!.count
//                    let artist2num = dict[$1.id]!.count
//                    if artist1num == artist2num {
//                        return self.removeArticles(str: $0.name) < self.removeArticles(str: $1.name)
//                    }
//                    return artist1num > artist2num
//                }
//                return ["All Artists" : sortedList]
//            }
//        } else {
//            if currDict != nil {
//                var artistList = Array<artist>()
//                for key in currDict!.keys {
//                    for a in currDict![key]! {
//                        if !artistList.contains(a) {
//                            artistList.append(a)
//                        }
//                    }
//                }
//                if favorites {
//                    
//                }
//                return getArtistDictFromList(currList: artistList, favorites: favorites, sort: sort, lable: lable)
//            } else {
//                return getArtistDictFromList(favorites: favorites, sort: sort, lable: lable)
//            }
//        }
//        return currDict!
//        //        return artistList
//    }
    
    //    func updateFavoritesList(currList = )
    
//    func getArtistDictFromListNEW(currList: Array<Artist>, sort: sortType, secondWeekend: Bool) -> [String : Array<Artist>] {
//        switch(sort) {
//        case .alpha:
//            return(sortAlpha(currList: currList))
//        case .billing:
//            return(sortTier(currList: currList))
//        case .day:
//            return(sortDay(currList: currList, secondWeekend: secondWeekend))
//        case .stage:
//            return(sortStage(currList: currList))
//        case .genre:
//            return(sortGenre(currList: currList))
//        }
//    }
    
    func getDictKeysSorted(currDict: [String : Array<Artist>], sort: sortType) -> Array<String> {
        var dictKeys = Array(currDict.keys)
        switch(sort) {
        case .alpha:
            break
        case .billing:
            dictKeys = sortByTier(tiers: dictKeys)
            break
        case .day:
            dictKeys = sortByDate(days: dictKeys)
            break
        case .stage:
            dictKeys = dictKeys.sorted(by: {
                $0.lowercased() < $1.lowercased()
            })
            if dictKeys.contains(NA_TITLE_BLOCK) {
                dictKeys.removeAll(where: { $0 == NA_TITLE_BLOCK })
                dictKeys.append(NA_TITLE_BLOCK)
            }
            break
        case .genre:
            dictKeys = dictKeys.sorted(by: {
                $0.lowercased() < $1.lowercased()
            })
            break
        case .addDate:
            break
        case .modifyDate:
            break
        }
        return dictKeys
    }
    
    func sortByDate(days: [String]) -> [String] {
        // Week starting on Tuesday
        let dayOrder: [String: Int] = [
            "Tuesday": 0,
            "Wednesday": 1,
            "Thursday": 2,
            "Friday": 3,
            "Saturday": 4,
            "Sunday": 5,
            "Monday": 6
        ]
        
        func parseDay(_ str: String) -> (dayIndex: Int, weekendIndex: Int) {
            let components = str.components(separatedBy: " (")
            let dayName = components.first?.trimmingCharacters(in: .whitespaces) ?? ""
            let dayIndex = dayOrder[dayName] ?? 999  // fallback if not found
            
            var weekendIndex = 0
            if str.contains("Weekend 1") {
                weekendIndex = 1
            } else if str.contains("Weekend 2") {
                weekendIndex = 2
            }
            
            return (dayIndex, weekendIndex)
        }
        
        return days.sorted { str1, str2 in
            let d1 = parseDay(str1)
            let d2 = parseDay(str2)
            
            if d1.weekendIndex != d2.weekendIndex {
                return d1.weekendIndex < d2.weekendIndex
            }
            return d1.dayIndex < d2.dayIndex
        }
    }

    
    func sortByTier(tiers: Array<String>) -> Array<String> {
        var retArray = Array<String>()
        for tierLable in tierLables {
            if tiers.contains(tierLable) {
                retArray.append(tierLable)
            }
        }
        if tiers.contains(NA_TITLE_BLOCK) {
            retArray.append(NA_TITLE_BLOCK)
        }
        return(retArray)
    }
    
//    func getArtistDictFromList(currList: Array<artist>? = nil, favorites: Bool = false, sort: sortType, lable: String? = nil) -> [String : Array<artist>] {
//        var artistList = Array<artist>()
//        if favorites {
//            artistList = favoritesList[1]
//        } else {
//            if currList == nil {
//                artistList = getFullList()
//            } else {
//                artistList = currList!
//            }
//        }
//        for (i,a) in artistList.enumerated() {
//            var artist = a
//            artist.favorability = getFavorability(artistID: a.id)
//            artistList[i] = artist
//        }
//        var currentDict = [String : Array<artist>]()
//        switch(sort) {
//        case .alpha:
//            currentDict = sortAlphaOLD(currList: artistList, lable: lable)
//        case .billing:
//            currentDict = sortTierOLD(currList: artistList)
//        case .day:
//            currentDict = sortDayOLD(currList: artistList)
//        case .stage:
//            currentDict = sortStageOLD(currList: artistList)
//        case .genre:
//            currentDict = sortGenreOLD(currList: artistList)
//        }
//        return (currentDict)
//        //        if index != nil {
//        
//        //        } else {
//        //            let lable = getSortLables(sort: sort)[index!]
//        //            return [lable : currentDict[lable]!]
//        //        }
//    }
    
    func isArtistDicEmpty(currDict: [String : Array<Artist>]) -> Bool {
        for key in currDict.keys {
            if !currDict[key]!.isEmpty {
                return false
            }
        }
        return true
    }
    
    //    func (currDict: [String: Array<artist>], sort: sortType) -> [String: Array<artist>] {
    
//    func updateArtistDict(currDict: [String: Array<artist>], sort: sortType) -> [String: Array<artist>] {
//        let keys = currDict.keys
//        var newDict = [String: Array<artist>]()
//        for k in keys {
//            for a in currDict[k]! {
//                var artist = a
//                artist.favorability = getFavorability(artistID: a.id)
//                if var artistArray = newDict[k] {
//                    artistArray.append(artist)
//                    newDict[k] = artistArray
//                } else {
//                    newDict[k] = [artist]
//                }
//            }
//        }
//        //        switch(sort) {
//        //        case .alpha:
//        //            newDict = sortAlpha(currList: newDict)
//        //        case .billing:
//        //            newDict = sortTier(currList: newDict)
//        //        case .day:
//        //            newDict = sortDay(currList: newDict)
//        //        case .genre:
//        //            newDict = sortGenre(currList: newDict)
//        //        }
//        return newDict
//    }
    
//    func getSubSectionList(sort: sortType, subsection: String) -> Array<artist>? {
//        let currentList = getFullList()
//        var artistArray = Array<artist>()
//        switch(sort) {
//        case .alpha:
//            break
//        case .billing:
//            for a in currentList {
//                if let artistTier = a.tier {
//                    if tierLables[artistTier] == subsection {
//                        artistArray.append(a)
//                    }
//                }
//            }
//            if !artistArray.isEmpty {
//                return artistArray
//            }
//        case .day:
//            for a in currentList {
//                let artistDay = a.day < 0 ? dayLables.last! : dayLables[a.day]
//                if artistDay == subsection {
//                    artistArray.append(a)
//                }
//            }
//            if !artistArray.isEmpty {
//                return artistArray
//            }
//            break
//        case .stage:
//            for a in currentList {
//                if let artistStage = a.stage {
//                    if artistStage == subsection {
//                        artistArray.append(a)
//                    }
//                }
//            }
//            if !artistArray.isEmpty {
//                return artistArray
//            }
//        case .genre:
//            for a in currentList {
//                if a.genres.contains(subsection) {
//                    artistArray.append(a)
//                }
//            }
//            if !artistArray.isEmpty {
//                return artistArray
//            }
//        }
//        return nil
//    }
    
    
    
    func getArtistList(currDict: [String : Array<Artist>]) -> Array<Artist> {
        var currList = Array<Artist>()
        let keys = currDict.keys
        for k in keys {
            currList.append(contentsOf: currDict[k]!)
        }
        return currList
    }
    
//    func sortAlpha(currList: Array<Artist>, lable: String? = nil) -> [String : Array<Artist>] {
//        var listByAplha = currList
//        listByAplha.sort {
//            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//        }
//        return ["All Artists" : listByAplha]
//    }
//    
//    func sortTier(currList: Array<Artist>) -> [String : Array<Artist>] {
//        var dictionary = [String  : Array<Artist>]()
//        for a in currList {
//            if a.tier != NA_TITLE_BLOCK {
//                if var artistArray = dictionary[a.tier] {
//                    artistArray.append(a)
//                    artistArray.sort {
//                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                    }
//                    dictionary[a.tier] = artistArray
//                } else {
//                    dictionary[a.tier] = [a]
//                }
//            }
//        }
//        return dictionary
//    }
//    
//    func sortDay(currList: [Artist], secondWeekend: Bool) -> [String: [Artist]] {
//        var dictionary = [String: [Artist]]()
//        
//        for artist in currList {
//            guard artist.day != NA_TITLE_BLOCK else { continue }
//            
//            // figure out which keys this artist belongs to
//            let dayKeys: [String]
//            if secondWeekend {
//                switch artist.weekend {
//                case "Weekend 1":
//                    dayKeys = ["\(artist.day) (Weekend 1)"]
//                case "Weekend 2":
//                    dayKeys = ["\(artist.day) (Weekend 2)"]
//                case "Both":
//                    dayKeys = ["\(artist.day) (Weekend 1)", "\(artist.day) (Weekend 2)"]
//                default:
//                    dayKeys = []
//                }
//            } else {
//                dayKeys = [artist.day]
//            }
//            
//            // group into dictionary without sorting yet
//            for key in dayKeys {
//                dictionary[key, default: []].append(artist)
//            }
//        }
//        
//        // sort once per bucket
//        for (day, artists) in dictionary {
//            dictionary[day] = artists.sorted {
//                if $0.tier == $1.tier {
//                    removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                } else {
//                    $0.tier < $1.tier
//                }
//            }
//        }
//        
//        return dictionary
//    }
//    
//    func sortStage(currList: Array<Artist>) -> [String : Array<Artist>] {
//        var dictionary = [String  : Array<Artist>]()
//        for a in currList {
//            if a.stage != NA_TITLE_BLOCK {
//                if var artistArray = dictionary[a.stage] {
//                    artistArray.append(a)
//                    artistArray.sort {
//                        if $0.tier == $1.tier {
//                            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                        }
//                        return $0.tier < $0.tier
//                    }
//                    dictionary[a.stage] = artistArray
//                } else {
//                    dictionary[a.stage] = [a]
//                }
//            }
//        }
//        return dictionary
//    }
//    
//    func sortGenre(currList: Array<Artist>) -> [String: Array<Artist>] {
//        var dictionary = [String: Array<Artist>]()
//        for a in currList {
//            for genre in a.genres {
//                if var artistArray = dictionary[genre] {
//                    artistArray.append(a)
////                    artistArray.sort {
////                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
////                    }
//                    dictionary[genre] = artistArray
//                } else {
//                    dictionary[genre] = [a]
//                }
//            }
//        }
//        
//        return dictionary
//            .filter { $0.value.count >= 3 }
//            .mapValues { $0.sorted { removeArticles(str: $0.name) < removeArticles(str: $1.name) } }
//    }
    
    
//    func listHasDays(currList: Array<Artist>) -> Bool {
//        return !sortDay(currList: currList, secondWeekend: false).isEmpty
//    }
//    
//    func listHasGenres(currList: Array<Artist>) -> Bool {
//        return !sortGenre(currList: currList).isEmpty
//    }
//    
//    func listHasStages(currList: Array<Artist>) -> Bool {
//        return !sortStage(currList: currList).isEmpty
//    }
//    
//    func listHasTiers(currList: Array<Artist>) -> Bool {
//        return !sortTier(currList: currList).isEmpty
//    }
    
    
//    func getDayList(currArtist: Artist, currList: [Artist], secondWeekend: Bool) -> [Artist] {
//        var list = [Artist]() 
//        
//        if !secondWeekend || currArtist.weekend == "Both" {
//            for artist in currList {
//                if artist.day == currArtist.day {
//                    list.append(artist)
//                }
//            }
//        } else {
//            for artist in currList {
//                if artist.day == currArtist.day && artist.weekend == currArtist.weekend {
//                    list.append(artist)
//                }
//            }
//        }
//        
//        list = list.sorted {
//            if $0.tier == $1.tier {
//                removeArticles(str: $0.name) < removeArticles(str: $1.name)
//            } else {
//                $0.tier < $1.tier
//            }
//        }
//        
//        return list
//    }
//    
//    func getWeekendList(weekend: String, currList: [Artist]) -> [Artist] {
//        if weekend == "Both" { return currList }
//        
//        var list = [Artist]()
//        
//        for artist in currList {
//            if artist.weekend == weekend || artist.weekend == "Both" {
//                list.append(artist)
//            }
//        }
//        
//        list = list.sorted {
//            if $0.tier == $1.tier {
//                removeArticles(str: $0.name) < removeArticles(str: $1.name)
//            } else {
//                $0.tier < $1.tier
//            }
//        }
//        
//        return list
//    }
//    
//    
//    func getStageList(stage: String, currList: [Artist]) -> [Artist] {
//        var list = [Artist]()
//        
//        for artist in currList {
//            if artist.stage == stage {
//                list.append(artist)
//            }
//        }
//        
//        list = list.sorted {
//            if $0.tier == $1.tier {
//                removeArticles(str: $0.name) < removeArticles(str: $1.name)
//            } else {
//                $0.tier < $1.tier
//            }
//        }
//        
//        return list
//    }
//    
//    
//    func getTierList(tier: String, currList: [Artist]) -> [Artist] {
//        var list = [Artist]()
//        
//        for artist in currList {
//            if artist.tier == tier {
//                list.append(artist)
//            }
//        }
//        
//        list = list.sorted {
//            removeArticles(str: $0.name) < removeArticles(str: $1.name)
//        }
//        
//        return list
//    }
//    
//    
//    func getGenreList(genre: String, currList: [Artist]) -> [Artist] {
//        var list = [Artist]()
//        
//        for artist in currList {
//            if artist.genres.contains(genre) {
//                list.append(artist)
//            }
//        }
//        
//        list = list.sorted {
//            removeArticles(str: $0.name) < removeArticles(str: $1.name)
//        }
//        
//        return list
//    }
    
    
//    func sortAlphaOLD(currList: Array<artist>, lable: String? = nil) -> [String : Array<artist>] {
//        var listByAplha = currList
//        listByAplha.sort {
//            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//            //            return $0.name.lowercased() < $1.name.lowercased()
//        }
////        var key = allLable[0]
////        if lable != nil {
////            key = lable!
////        }
//        return ["All Artists" : listByAplha]
//    }
//    
//    func sortTierOLD(currList: Array<artist>) -> [String : Array<artist>] {
//        var dictionary = [String  : Array<artist>]()
//        dictionary[NA_TITLE_BLOCK] = []
//        for a in currList {
//            if let artistTier = a.tier {
//                if var artistArray = dictionary[tierLables[artistTier]] {
//                    artistArray.append(a)
//                    artistArray.sort {
//                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                    }
//                    dictionary[tierLables[artistTier]] = artistArray
//                } else {
//                    dictionary[tierLables[artistTier]] = [a]
//                }
//            }
//            dictionary["Unannounced"]!.append(a)
//        }
//        return dictionary
//    }
//    
//    func sortStageOLD(currList: Array<artist>) -> [String : Array<artist>] {
//        var dictionary = [String  : Array<artist>]()
//        dictionary["Unannounced"] = []
//        for a in currList {
//            if let artistStage = a.stage {
//                if var artistArray = dictionary[artistStage] {
//                    artistArray.append(a)
//                    artistArray.sort {
//                        if $0.tier == $1.tier {
//                            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                        }
//                        let t0 = ($0.tier != nil ? $0.tier! : 10)
//                        let t1 = ($1.tier != nil ? $1.tier! : 10)
//                        return t0 < t1
//                    }
//                    dictionary[artistStage] = artistArray
//                } else {
//                    dictionary[artistStage] = [a]
//                }
//            } else {
//                dictionary["Unannounced"]!.append(a)
//            }
//        }
//        return dictionary
//    }
//    
//    func sortDayOLD(currList: Array<artist>) -> [String : Array<artist>] {
//        var dictionary = [String  : Array<artist>]()
//        for a in currList {
//            if a.day == -1 {
//                if var artistArray = dictionary[dayLables.last!] {
//                    artistArray.append(a)
//                    artistArray.sort {
//                        if $0.tier == $1.tier {
//                            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                        }
//                        let t0 = ($0.tier != nil ? $0.tier! : 10)
//                        let t1 = ($1.tier != nil ? $1.tier! : 10)
//                        return t0 < t1
//                    }
//                    dictionary[dayLables.last!] = artistArray
//                } else {
//                    dictionary[dayLables.last!] = [a]
//                }
//            } else if var artistArray = dictionary[dayLables[a.day]] {
//                artistArray.append(a)
//                artistArray.sort {
//                    if $0.tier == $1.tier {
//                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                    }
//                    let t0 = ($0.tier != nil ? $0.tier! : 10)
//                    let t1 = ($1.tier != nil ? $1.tier! : 10)
//                    return t0 < t1
//                }
//                dictionary[dayLables[a.day]] = artistArray
//            } else {
//                dictionary[dayLables[a.day]] = [a]
//            }
//        }
//        return dictionary
//    }
//    
//    func sortGenreOLD(currList: Array<artist>) -> [String: Array<artist>] {
//        var dictionary = [String: Array<artist>]()
//        for a in currList {
//            for genre in genreLables {
//                if a.genres.contains(genre) {
//                    if var artistArray = dictionary[genre] {
//                        artistArray.append(a)
//                        artistArray.sort {
//                            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                        }
//                        dictionary[genre] = artistArray
//                    } else {
//                        dictionary[genre] = [a]
//                    }
//                }
//            }
//        }
//        return dictionary
//    }
    
//    func getFullList() -> Array<artist> {
//        var fullList = Array<artist>()
//        for a in artistList {
//            if a.day == -1 || settings.festivalDays[a.day] {
//                if settings.festivalWeekend == 0 || a.weekend[settings.festivalWeekend-1] {
//                    fullList.append(a)
//                }
//            }
//        }
//        
//        
//        
//        
//        
////        var fullList = artistList
////        for a_1 in fullList {
////            if a_1.day != -1 && !settings.festivalDays[a_1.day] {
////                fullList.remove(at: fullList.firstIndex(where: { $0.id == a_1.id })!)
////            }
////        }
//        return fullList
//    }
    
    func getGenreDict(artistList: Array<Artist>) -> [String : Array<Artist>] {
        var genreDict = [String : Array<Artist>]()
        for artist in artistList {
            for genre in artist.genres {
                genreDict[genre, default: []].append(artist)
            }
        }
        return genreDict
    }
    
    func getDayDict(artistList: Array<Artist>) -> [String : Array<Artist>] {
//        let outputFormatter = DateFormatter()
//        outputFormatter.dateFormat = "EEEE (MMMM d)" // Example: "Thursday (July 31)"
//        outputFormatter.locale = Locale(identifier: "en_US")
        
        var dayDict = [String : Array<Artist>]()
        for artist in artistList {
            dayDict[artist.day, default: []].append(artist)
//            if let day = artist.day {
//                let dayString = outputFormatter.string(from: day)
                
//            }
        }
        return dayDict
    }
    
    func getStageDict(artistList: Array<Artist>) -> [String : Array<Artist>] {
        var stageDict = [String : Array<Artist>]()
        for artist in artistList {
//            if let stage = artist.stage {
                stageDict[artist.stage, default: []].append(artist)
//            }
        }
        return stageDict
    }
    
    func getBillingDict(artistList: Array<Artist>) -> [String : Array<Artist>] {
        var tierDict = [String : Array<Artist>]()
        for artist in artistList {
            tierDict[artist.tier, default: []].append(artist)
//            if let tier = artist.tier {
//                let str = getTierString(for: tier)
//                tierDict[str, default: []].append(artist)
//            }
        }
        return tierDict
    }
    
    func getTierString(for index: Int) -> String {
        if index == 0 {
            return "Headliner"
        }

        let ones = index % 10
        let tens = (index / 10) % 10

        let suffix: String
        if tens == 1 {
            suffix = "th"
        } else {
            switch ones {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }

        return "\(index)\(suffix) Line"
    }
    
    
    func getRelatedArtists(currentArtist: Artist, currentList: Array<Artist>) -> Array<Artist> {
//        let possibleList = getShuffleableArtists(currentArtistID: currentArtist.id, currentList: getFullList())
        var dictionary = [Artist: Int]()
        for a in currentList {
            if a.id != currentArtist.id {
                for g in currentArtist.genres {
                    if a.genres.contains(where: { $0 == g }) {
                        if let artistNum = dictionary[a] {
                            dictionary[a] = artistNum + 1
                        } else {
                            dictionary[a] = 1
                        }
                    }
                }
            }
        }
        var keys = Array(dictionary.keys)
        keys.sort {
            if  dictionary[$0]! == dictionary[$1]! {
                return $0.name.dropFirst() < $1.name.dropFirst()
            }
            return dictionary[$0]! > dictionary[$1]!
        }
        let MAXARTISTS = 6
        if keys.count > MAXARTISTS {
            return Array(keys[0..<MAXARTISTS])
        }
        return keys
    }
    
//    func getAlbumList(artist: artist) -> Array<album> {
//        var albums = artist.albums
//        albums.sort {
//            if $0.year == $1.year {
//                return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//            }
//            return $0.year > $1.year
//        }
//        return albums
//    }
    
//    func getNamesList(currDict: [String : Array<artist>]) -> Array<String> {
//        var nameList = Array<String>()
//        let keys = currDict.keys
//        for k in keys {
//            for a in currDict[k]! {
//                nameList.append(a.name)
//            }
//        }
//        return nameList
//    }
    
//    func getGroupFavorites() -> Array<artist> {
//        return artistList
//    }
    
//    func removeArticles(str: String) -> String {
//        let articles = ["the ", "a ", "los ", "las ", "el ", "la "]
//        for a in articles {
//            if str.lowercased().hasPrefix(a) {
//                return(String(str.dropFirst(a.count)).lowercased())
//            }
//        }
//        return str.lowercased()
//    }
    
    func loadArtistImage(artistID: String, imageURL: String) async -> UIImage? {
        // 1. Build local file path
        let fileName = "\(artistID).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        // 2. Try to load from disk
        if let imageData = try? Data(contentsOf: fileURL),
           let image = UIImage(data: imageData) {
            return image
        }
        
        // 3. Try to load from remote URL
        guard let url = URL(string: imageURL) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Save to disk for future use
            try? data.write(to: fileURL)
            
            return UIImage(data: data)
        } catch {
            print("Error loading image for \(artistID): \(error)")
            return nil
        }
    }
    
    func saveImageToDisk(image: UIImage, artistID: String) throws -> URL {
        // Convert UIImage to JPEG data (adjust compressionQuality if you want)
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "SaveImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to convert UIImage to JPEG data"])
        }

        // Get the Documents directory URL
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        // Create file URL using artistID as filename with .jpg extension
        let fileURL = documentsURL.appendingPathComponent("\(artistID).jpg")

        // Write the data to disk
        try imageData.write(to: fileURL, options: .atomic)

        return fileURL
    }
    
    func saveFestival(_ festival: DataSet.Festival) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(festival)
            let key = String(saveName + festival.id.uuidString)

            UserDefaults.standard.set(data, forKey: key)
            
            print("Festival saved with key:", key)
        } catch {
            print("Failed to save festival:", error)
        }
    }
    
    func loadFestival(id: UUID) -> DataSet.Festival? {
        let key = String(saveName + id.uuidString)
        
        guard let data = UserDefaults.standard.data(forKey: key) else {
            print("No festival found for key:", key)
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let festival = try decoder.decode(DataSet.Festival.self, from: data)
            return festival
        } catch {
            print("Failed to decode festival:", error)
            return nil
        }
    }
    
    func getFestivals(ids: Array<UUID>) -> Array<DataSet.Festival> {
        var festivalList = Array<DataSet.Festival>()
        for id in ids {
            if let festival = loadFestival(id: id) {
                festivalList.append(festival)
            }
        }
        return festivalList
    }

    
    //MARK: FIREBASE SECTION
    
    
    func fetchUserProfile(userID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).addSnapshotListener { document, error in
            if let document = document, document.exists {
                let userName = document.data()?["name"] as? String ?? "Unknown"
                let userProfilePic: String? = document.data()?["profileImageURL"] as? String ?? ""
                let userFavorites = document.data()?["favorites"] as? [String] ?? []
                
                self.fetchFriends(userID: userID) { userFriends in
                    var friendsSorted = userFriends
                    friendsSorted.sort { $0.name.lowercased() < $1.name.lowercased() }
                    self.fetchUserGroups(userID: userID, friendsList: userFriends) { userGroups in
                        var groupsSorted = userGroups
                        groupsSorted.sort { $0.name.lowercased() < $1.name.lowercased() }
                        if let urlString = userProfilePic, let url = URL(string: urlString) {
                            self.downloadAndSaveImage(url: url) { localPath in
                                DispatchQueue.main.async {
                                    self.userInfo = UserProfile(
//                                        id: userID,
                                        name: userName,
                                        profilePic: localPath,
//                                        favorites: userFavorites,
//                                        friends: friendsSorted,
//                                        groups: groupsSorted
                                    )
                                    completion(true) // ✅ Success
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.userInfo = UserProfile(
//                                    id: userID,
                                    name: userName,
                                    profilePic: nil,
//                                    favorites: userFavorites,
//                                    friends: friendsSorted,
//                                    groups: groupsSorted
                                )
                                completion(true) // ✅ Success
                            }
                        }
                    }
                }
            } else {
                print("❌ Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async { completion(false) } // ❌ Failure
            }
        }
    }
    

    func checkIfUserHasName(completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No authenticated user.")
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(userID)

        docRef.getDocument { document, error in
            if let error = error {
                print("Error fetching document: \(error)")
                completion(false)
                return
            }

            if let document = document, document.exists {
                if let name = document.get("name") as? String,
                   !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            } else {
                print("Document does not exist.")
                completion(false)
            }
        }
    }
    
    
    
    func downloadAndSaveImage(url: URL, completion: @escaping (String?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Failed to download image: \(error.localizedDescription)")
                completion(nil) // Ensure completion is always called
                return
            }
            
            guard let data = data else {
                print("❌ Downloaded data is nil")
                completion(nil)
                return
            }
            
            // Get a local file path to save the image
            if let localPath = self.saveImageToDisk(data: data, filename: url.lastPathComponent) {
                print("✅ Image successfully saved at: \(localPath)")
                completion(localPath)
            } else {
                print("❌ Failed to save image to disk")
                completion(nil)
                return
            }
        }.resume()
    }
    
    
    func saveImageToDisk(data: Data, filename: String) -> String? {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("✅ Image saved at: \(fileURL.path)")
            return fileURL.path
        } catch {
            print("❌ Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    func getInviteLink() -> String {
        guard let senderUUID = Auth.auth().currentUser?.uid else {
            return "Error: User not logged in"
        }
        let inviteLink = "https://oasis-austinzv.web.app/share/friend/?user=\(senderUUID)"
        return inviteLink
    }
    
    func addFriend(friendID: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let currentUserID = currentUser.uid
        
        let myRef = db.collection("users").document(currentUserID)
        let senderRef = db.collection("users").document(friendID)
        
        let group = DispatchGroup()
        var success = true // Track if all updates succeed
        
        group.enter()
        myRef.updateData(["friends": FieldValue.arrayUnion([friendID])]) { error in
            if let error = error {
                print("Error updating current user's friends: \(error)")
                success = false
            }
            group.leave()
        }
        
        group.enter()
        senderRef.updateData(["friends": FieldValue.arrayUnion([currentUserID])]) { error in
            if let error = error {
                print("Error updating sender's friends: \(error)")
                success = false
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(success) // Return true if both updates succeeded, false otherwise
        }
    }

    
    //    func fetchProfile(senderUUID: String, completion: @escaping (UserProfile?) -> Void) {
    //        let db = Firestore.firestore()
    //        let userRef = db.collection("users").document(senderUUID)
    //
    //        userRef.getDocument { document, error in
    //            if let error = error {
    //                print("Error fetching user profile: \(error.localizedDescription)")
    //                completion(nil)
    //                return
    //            }
    //
    //            guard let document = document, document.exists, let data = document.data() else {
    //                print("User not found")
    //                completion(nil)
    //                return
    //            }
    //
    //            // Assuming UserProfile is a model for user data
    //            let userProfile = UserProfile(
    //                id: senderUUID,
    //                name: data["name"] as? String ?? "Unknown",
    //                profilePic: data["profileImageURL"] as? String ?? "",
    //                favorites: data["favorites"] as? [String] ?? []
    //            )
    //
    //            completion(userProfile)
    //        }
    //    }
    
    func fetchFriends(userID: String, completion: @escaping ([FriendProfileOLD]) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).addSnapshotListener { document, error in
            if let document = document, document.exists,
               let friendUIDs = document.data()?["friends"] as? [String], !friendUIDs.isEmpty {
                self.fetchFriendDetails(friendUIDs, completion: completion)
            } else {
                print("Error fetching friends list: \(error?.localizedDescription ?? "Unknown error")")
                completion([]) // Return an empty array if no friends found
            }
        }
    }
    
    func fetchFriendDetails(_ friendUIDs: [String], completion: @escaping ([FriendProfileOLD]) -> Void) {
        let db = Firestore.firestore()
        var loadedFriends: [FriendProfileOLD] = []
        let group = DispatchGroup() // Ensures all fetch requests complete before returning
        
        for uid in friendUIDs {
            group.enter()
            db.collection("users").document(uid).getDocument { document, error in
                guard let document = document, document.exists else {
                    print("❌ Error fetching details for \(uid): \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async { group.leave() } // ✅ Ensure `group.leave()` is always called
                    return
                }
                
                let name = document.data()?["name"] as? String ?? "Unknown"
                let profilePicURL = document.data()?["profileImageURL"] as? String ?? ""
                let favorites = document.data()?["favorites"] as? [String] ?? []
                
                let filename = URL(string: profilePicURL)?.lastPathComponent ?? "\(uid).jpg"
                
                if let localPath = self.getLocalImagePath(filename: filename), FileManager.default.fileExists(atPath: localPath) {
                    DispatchQueue.main.async {
                        // ✅ Use the local file if it exists
                        loadedFriends.append(FriendProfileOLD(id: uid, name: name, profilePic: localPath, favorites: favorites))
                        print("✅ Using local file for \(uid): \(localPath)")
                        group.leave()
                    }
                } else {
                    // ❌ No local file, download and save
                    if let url = URL(string: profilePicURL) {
                        self.downloadAndSaveImage(url: url) { savedPath in
                            DispatchQueue.main.async {
                                let finalPath = savedPath ?? profilePicURL // Fallback to Firebase URL if saving fails
                                loadedFriends.append(FriendProfileOLD(id: uid, name: name, profilePic: finalPath, favorites: favorites))
                                print("✅ Downloaded and saved image for \(uid): \(finalPath)")
                                group.leave()
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            print("❌ Invalid URL for \(uid), using nil")
                            loadedFriends.append(FriendProfileOLD(id: uid, name: name, profilePic: nil, favorites: favorites))
                            group.leave()
                        }
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            print("✅ All friend details fetched, returning data.")
            completion(loadedFriends) // Return the array of friends
        }
    }
    
    
    func fetchUserGroups(userID: String, friendsList: [FriendProfileOLD], completion: @escaping ([SocialGroup]) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(userID).getDocument { document, error in
            if let document = document, document.exists,
               let groupIDs = document.data()?["groups"] as? [String], !groupIDs.isEmpty {
                self.fetchGroupDetails(groupIDs, friendsList: friendsList, completion: completion)
            } else {
                print("⚠️ No groups found for user \(userID) or error: \(error?.localizedDescription ?? "Unknown error")")
                completion([]) // Return an empty array if no groups are found
            }
        }
    }

    func fetchGroupDetails(_ groupIDs: [String], friendsList: [FriendProfileOLD], completion: @escaping ([SocialGroup]) -> Void) {
        let db = Firestore.firestore()
        var loadedGroups: [SocialGroup] = []
        let group = DispatchGroup() // Ensures all requests complete before returning

        for groupID in groupIDs {
            group.enter()
            db.collection("groups").document(groupID).getDocument { document, error in
                guard let document = document, document.exists else {
                    print("❌ Error fetching details for group \(groupID): \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }

                let data = document.data()
                let groupName = data?["groupName"] as? String ?? "Unnamed Group"
                let groupPhotoURL = data?["groupPhotoURL"] as? String ?? ""
                let memberIDs = data?["members"] as? [String] ?? []
                let inviteLink = data?["inviteLink"] as? String ?? ""
                let filename = URL(string: groupPhotoURL)?.lastPathComponent ?? "\(groupID).jpg"
                
                var membersList = [FriendProfileOLD]()
                var unloadedIDs = [String]()
                let friendDictionary = Dictionary(uniqueKeysWithValues: friendsList.map { ($0.id, $0) })
                for id in memberIDs {
                    if let friend = friendDictionary[id] {
                        membersList.append(friend)
                    } else {
                        unloadedIDs.append(id)
                    }
                }
                
                self.fetchFriendDetails(unloadedIDs) { unfriendedUsers in
                    membersList.append(contentsOf: unfriendedUsers)
                    let groupFavorites = self.getFavoritesDict(members: membersList)
                    if let localPath = self.getLocalImagePath(filename: filename), FileManager.default.fileExists(atPath: localPath) {
                        DispatchQueue.main.async {
                            // ✅ Use the local file if it exists
                            loadedGroups.append(SocialGroup(id: groupID, name: groupName, photo: localPath, members: membersList, favoritesDict: groupFavorites, inviteLink: inviteLink))
                            print("✅ Using local file for \(groupID): \(localPath)")
                            group.leave()
                        }
                    } else {
                        // ❌ No local file, download and save
                        if let url = URL(string: groupPhotoURL) {
                            self.downloadAndSaveImage(url: url) { savedPath in
                                DispatchQueue.main.async {
                                    let finalPath = savedPath ?? groupPhotoURL // Fallback to Firebase URL if saving fails
                                    loadedGroups.append(SocialGroup(id: groupID, name: groupName, photo: finalPath, members: membersList, favoritesDict: groupFavorites, inviteLink: inviteLink))
                                    print("✅ Downloaded and saved image for \(groupID): \(finalPath)")
                                    group.leave()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                print("❌ Invalid URL for \(groupID), using nil")
                                loadedGroups.append(SocialGroup(id: groupID, name: groupName, photo: nil, members: membersList, favoritesDict: groupFavorites, inviteLink: inviteLink))
                                group.leave()
                            }
                        }
                    }
                }
            }
        }

        group.notify(queue: .main) {
            print("✅ All group details fetched, returning data.")
            completion(loadedGroups)
        }
    }

    
    func getFavoritesDict(members: [FriendProfileOLD]) -> [String : [String]] {
        var favoritesDict = [String : [String]]()
        for m in members {
            if m.id != Auth.auth().currentUser?.uid {
                if let favorites = m.favorites {
                    for f in favorites {
                        favoritesDict[f, default: []].append(m.id)
                    }
                }
            }
        }
        return favoritesDict
    }
    
//    func addMyFavorites(groupFavorites: [String : [String]]) -> [String : [String]] {
//        var newFavoritesDict = groupFavorites
//        if let myID = Auth.auth().currentUser?.uid {
//            for artist in favoritesList[1] {
//                newFavoritesDict[artist.id, default: []].append(myID)
//            }
//        }
//        return newFavoritesDict
//    }
    
    
    func isFriends(memberID: String) -> Bool {
//        if let info = self.userInfo {
//            for friend in info.friends {
//                if friend.id == memberID {
//                    return true
//                }
//            }
//        }
        return false
    }
    
    
    
    func getLocalImagePath(filename: String) -> String? {
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = directory.appendingPathComponent(filename)
        
        // Check if the file exists at the local path
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL.path // Return the local file path if it exists
        } else {
            return nil // File does not exist locally
        }
    }
    
    
    
    
    func uploadImageAndSaveToFirestore(image: UIImage, completion: @escaping (Bool) -> Void) {
        // Cancel any ongoing upload before starting a new one
        cancelPreviousUpload()
        
        // Upload image to Firebase Storage and get the URL
        uploadImageToFirebase(image: image) { url in
            guard let imageURL = url else {
                print("❌ Failed to get image URL.")
                completion(false)
                return
            }
            
            // Save the URL to Firestore
            self.saveImageURLToFirestore(imageURL: imageURL) { success in
                if success {
                    print("✅ Image URL successfully saved to Firestore.")
                    completion(true)
                } else {
                    print("❌ Failed to save image URL to Firestore.")
                    completion(false)
                }
            }
        }
    }
    
    
    func cancelPreviousUpload() {
        // Check if there is an existing upload task and cancel it
        if let task = currentUploadTask, isUploading {
            print("Canceling previous upload task...")
            task.cancel()
            currentUploadTask = nil
            isUploading = false
        }
    }
    
    func uploadImageToFirebase(image: UIImage, completion: @escaping (String?) -> Void) {
        // Convert the UIImage to Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to data.")
            completion(nil)
            return
        }
        
        // Create a reference to Firebase Storage
        let storageRef = Storage.storage().reference()
        
        // Create a unique filename
        let imageID = UUID().uuidString
        let imageRef = storageRef.child("images/\(imageID).jpg")
        
        // Cancel any previous upload if it exists
        cancelPreviousUpload()
        
        // Start the new upload task
        isUploading = true
        currentUploadTask = imageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                self.isUploading = false // Mark as not uploading anymore
                return
            }
            
            // Get the download URL once the upload is successful
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    self.isUploading = false // Mark as not uploading anymore
                    return
                }
                
                // Return the download URL
                self.isUploading = false // Mark as not uploading anymore
                completion(url?.absoluteString)
            }
        }
    }
    
    func saveImageURLToFirestore(imageURL: String, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        userRef.updateData(["profileImageURL": imageURL]) { error in
            if let error = error {
                print("❌ Error saving image URL: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Image URL saved successfully!")
                completion(true)
            }
        }
    }
    
    func createGroup(groupName: String, groupPhoto: UIImage?, completion: @escaping (SocialGroup?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("❌ No authenticated user.")
            completion(nil)
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document()
        let groupID = groupRef.documentID
        let creatorID = user.uid

        // Construct the invite link
        let inviteLink = "https://oasis-austinzv.web.app/share/group/?group=\(groupID)"

        func saveGroupData(photoURL: String?) {
            let groupData: [String: Any] = [
                "groupID": groupID,
                "groupName": groupName,
                "groupPhotoURL": photoURL ?? "",
                "createdBy": creatorID,
                "members": [creatorID],
                "inviteLink": inviteLink,
                "createdAt": FieldValue.serverTimestamp()
            ]

            groupRef.setData(groupData) { error in
                if let error = error {
                    print("❌ Error creating group: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                print("✅ Group created successfully!")

                // Add the group to the current user's data
                let userRef = db.collection("users").document(creatorID)
                userRef.updateData([
                    "groups": FieldValue.arrayUnion([groupID])
                ]) { error in
                    if let error = error {
                        print("❌ Error adding group to user: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        print("✅ Group successfully added to user’s document!")
                        let info = self.userInfo!
                        let createdGroup = SocialGroup(id: groupID, name: groupName, photo: photoURL ?? nil, members: [FriendProfileOLD(id: info.id!, name: info.name, profilePic: info.profilePic, /*favorites: info.favorites*/)], inviteLink: inviteLink)
                        completion(createdGroup)
                    }
                }
            }
        }

        if let groupPhoto = groupPhoto {
            uploadImageToFirebase(image: groupPhoto) { url in
                guard let imageURL = url else {
                    print("❌ Failed to upload group photo.")
                    completion(nil)
                    return
                }
                saveGroupData(photoURL: imageURL)
            }
        } else {
            saveGroupData(photoURL: nil)
        }
    }
    
    func leaveGroup(groupID: String, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user.")
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(userID)
        let dispatchGroup = DispatchGroup()

        // Remove user from group's members array
        dispatchGroup.enter()
        groupRef.updateData([
            "members": FieldValue.arrayRemove([userID])
        ]) { error in
            if let error = error {
                print("❌ Error removing user from group: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("✅ User removed from group.")
            dispatchGroup.leave()
        }

        // Remove group from user's groups array
        dispatchGroup.enter()
        userRef.updateData([
            "groups": FieldValue.arrayRemove([groupID])
        ]) { error in
            if let error = error {
                print("❌ Error removing group from user: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("✅ Group removed from user.")
            dispatchGroup.leave()
        }

        // Notify when both operations are complete
        dispatchGroup.notify(queue: .main) {
            completion(true)
        }
    }

    func getMemberName(memberID: String) -> String {
//        if let info = userInfo {
//            for group in info.groups {
//                for member in group.members {
//                    if member.id == memberID {
//                        return member.name
//                    }
//                }
//            }
//        }
        return memberID
    }

    
//    func getGroupFavoritesSorted(memberIDs: [String], completion: @escaping ([DataSet.artist : Int]) -> Void) {
//        var groupFavIDDict = [String : Int]()
//        var groupFavDict = [DataSet.artist : Int]()
//        
//        fetchFavoritesForMembers(memberIDs: memberIDs) { favoritesDict in
//            for (_, favorites) in favoritesDict {
//                for a in favorites {
//                    if let artistInt = groupFavIDDict[a] {
//                        groupFavIDDict[a] = artistInt + 1
//                    } else {
//                        groupFavIDDict[a] = 1
//                    }
//                }
//            }
//            
//            for (artistID, artistNum) in groupFavIDDict {
//                if let artist = self.getArtist(artistID: artistID) {
//                    groupFavDict[artist] = artistNum
//                }
//            }
//            completion(groupFavDict)
//        }
//    }
    
    func getGroupFavoritesDict(members: [FriendProfileOLD], currentDict: [String: [DataSet.FriendProfileOLD]]?, completion: @escaping ([String: [DataSet.FriendProfileOLD]]) -> Void) {
        var groupFavDict = currentDict ?? [:] // Use existing dictionary or create new one
//
//        guard let info = userInfo else {
//            completion(groupFavDict)
//            return
//        }
//        
//        let updatedFavorites = self.getFavsID(liking: 1)
//
//        let myOwnFriend = FriendProfile(id: info.id, name: info.name, profilePic: info.profilePic, favorites: updatedFavorites)
//
//        // First-time dictionary build (if empty)
//        if currentDict == nil {
//            for member in members {
//                if let memberFavorites = member.favorites {
//                    for artistID in memberFavorites {
//                        groupFavDict[artistID, default: []].append(member)
//                    }
//                }
//            }
//        }
//
//        // Remove user from all previous favorite lists
//        for key in groupFavDict.keys {
//            groupFavDict[key]?.removeAll { $0.id == info.id }
//        }
//
//        // Add user to updated favorite artists
//        for artistID in updatedFavorites {
//            groupFavDict[artistID, default: []].append(myOwnFriend)
//        }

        completion(groupFavDict)
    }

        
        
        
        
//        var groupFavDict = [String : [DataSet.FriendProfile]]()
//        let dispatchGroup = DispatchGroup()
        
//        for
        
        
//        fetchFavoritesForMembers(memberIDs: memberIDs) { favoritesDict in
//            for (memberID, favorites) in favoritesDict {
//                dispatchGroup.enter() // Track each fetchFriendDetails call
//                
//                self.fetchFriendDetails([memberID]) { friend in
//                    if !friend.isEmpty {
//                        for a in favorites {
//                            if var fans = groupFavDict[a] {
//                                fans.append(friend.first!)
//                                groupFavDict[a] = fans
//                            } else {
//                                groupFavDict[a] = [friend.first!]
//                            }
//                        }
//                    }
//                    dispatchGroup.leave() // Mark this fetch as done
//                }
//            }
//            
//            // Ensure completion is called only when all async operations finish
//            dispatchGroup.notify(queue: .main) {
//                completion(groupFavDict)
//            }
//        }
    
    
    func getGroupFavoritesDictOLD(memberIDs: [String], completion: @escaping ([String: [DataSet.FriendProfileOLD]]) -> Void) {
        var groupFavDict = [String: [DataSet.FriendProfileOLD]]()
        let dispatchGroup = DispatchGroup()
        
        fetchFavoritesForMembers(memberIDs: memberIDs) { favoritesDict in
            for (memberID, favorites) in favoritesDict {
                dispatchGroup.enter() // Track each fetchFriendDetails call
                
                self.fetchFriendDetails([memberID]) { friend in
                    if !friend.isEmpty {
                        for a in favorites {
                            if var fans = groupFavDict[a] {
                                fans.append(friend.first!)
                                groupFavDict[a] = fans
                            } else {
                                groupFavDict[a] = [friend.first!]
                            }
                        }
                    }
                    dispatchGroup.leave() // Mark this fetch as done
                }
            }
            
            // Ensure completion is called only when all async operations finish
            dispatchGroup.notify(queue: .main) {
                completion(groupFavDict)
            }
        }
    }
    
    



    func fetchFavoritesForMembers(memberIDs: [String], completion: @escaping ([String: [String]]) -> Void) {
        let db = Firestore.firestore()
        var favoritesDict: [String: [String]] = [:]
        let group = DispatchGroup() // Ensures all fetch requests complete before returning
        
        for memberID in memberIDs {
            group.enter()
            db.collection("users").document(memberID).getDocument { document, error in
                if let document = document, document.exists {
                    let favorites = document.data()?["favorites"] as? [String] ?? []
                    favoritesDict[memberID] = favorites
                } else {
                    print("⚠️ Could not fetch favorites for \(memberID): \(error?.localizedDescription ?? "Unknown error")")
                    favoritesDict[memberID] = [] // Default to an empty array if the user doesn't have favorites
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            print("✅ All favorites fetched: \(favoritesDict)")
            completion(favoritesDict)
        }
    }
    
    
    func saveName(name: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("false")
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                userRef.updateData(["name": name]) { error in
                    if let error {
                        print("❌ Error updating name: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Name updated successfully!")
                        completion(true)
                    }
                }
            } else {
                userRef.setData([
                    "name": name,
                    "createdAt": FieldValue.serverTimestamp()
                ]) { error in
                    if let error {
                        print("❌ Error setting name: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Name saved successfully!")
                        completion(true)
                    }
                }
            }
        }
    }
    
    //    func reloadUserData() {
    //        guard let userID = Auth.auth().currentUser?.uid else { return }
    //
    //        let db = Firestore.firestore()
    //        db.collection("users").document(userID).getDocument { document, error in
    //            if let error = error {
    //                print("❌ Error fetching user data: \(error.localizedDescription)")
    //                return
    //            }
    //
    //            if let document = document, document.exists {
    //                DispatchQueue.main.async {
    //                    self.userInfo = DataSet.UserProfile(
    //                        id: userID,
    //                        name: document.data()?["name"] as? String ?? "Unknown",
    //                        profilePic: document.data()?["profileImageURL"] as? String,
    //                        favorites: document.data()?["favorites"] as? [String] ?? []
    //                    )
    //                    print("✅ User data refreshed!")
    //                }
    //            }
    //        }
    //    }
    
    
    
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            print("Attempting to sign out user...")
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userInfo = nil
                //                self.userInfo = UserProfile(id: "", name: "", profilePic: nil, favorites: [], friends: [])
            }
            completion(.success(()))
        } catch let signOutError {
            completion(.failure(signOutError))
        }
    }
    
    
    
    func unfriendUser(currentUserID: String, friendID: String, completion: @escaping (Error?) -> Void) {
        let db = Firestore.firestore()
        
        let currentUserRef = db.collection("users").document(currentUserID)
        let friendUserRef = db.collection("users").document(friendID)
        
        db.runTransaction({ transaction, errorPointer in
            let currentUserDoc: DocumentSnapshot
            let friendUserDoc: DocumentSnapshot
            
            do {
                currentUserDoc = try transaction.getDocument(currentUserRef)
                friendUserDoc = try transaction.getDocument(friendUserRef)
            } catch let fetchError {
                errorPointer?.pointee = fetchError as NSError
                return nil
            }
            
            // Remove friendID from current user's friend list
            if var currentFriends = currentUserDoc.data()?["friends"] as? [String],
               let index = currentFriends.firstIndex(of: friendID) {
                currentFriends.remove(at: index)
                transaction.updateData(["friends": currentFriends], forDocument: currentUserRef)
            }
            
            // Remove currentUserID from friend's friend list
            if var friendFriends = friendUserDoc.data()?["friends"] as? [String],
               let index = friendFriends.firstIndex(of: currentUserID) {
                friendFriends.remove(at: index)
                transaction.updateData(["friends": friendFriends], forDocument: friendUserRef)
            }
            
            db.collection("users").document(currentUserID).getDocument { document, error in
                if let document = document, document.exists {
//                    print("Updated friends list: \(document.data()?["friends"] as? [String] ?? [])")
                }
            }
            
            self.fetchFriends(userID: currentUserID) { userFriends in
                var friendsSorted = userFriends
                friendsSorted.sort {
                    return $0.name.lowercased() < $1.name.lowercased()
                }
//                DispatchQueue.main.async {
//                    self.userInfo!.friends = friendsSorted
//                }
            }
            
            return nil
        }) { _, error in
            completion(error)
        }
    }
    
    //MARK: SPOTIFY SECTION
    
//    func isUserLoggedIn(completion: @escaping (Bool) -> Void) {
//        if let expiry = UserDefaults.standard.value(forKey: String(self.saveName + "spotify_token_expiry")) as? TimeInterval {
//            
//            let currentTime = Date().timeIntervalSince1970
//            if currentTime < expiry {
//                print("✅ Token is still valid")
//                completion(true)
//            } else {
//                print("⏳ Token expired, refreshing...")
//                refreshAccessToken { newToken in
//                    completion(newToken != nil)
//                }
//            }
//        } else {
//            print("❌ No access token found")
//            completion(false)
//        }
//    }
//    
//    func exchangeCodeForToken(_ code: String) {
//        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
//        var request = URLRequest(url: tokenURL)
//        request.httpMethod = "POST"
//        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        
//        let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)"
//        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
//        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
//        
//        let bodyParams = "grant_type=authorization_code&code=\(code)&redirect_uri=\(SpotifyAuth.redirectURI)"
//        request.httpBody = bodyParams.data(using: .utf8)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error exchanging code for token: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                if let accessToken = json["access_token"] as? String,
//                   let refreshToken = json["refresh_token"] as? String {
//                    UserDefaults.standard.set(accessToken, forKey: String(self.saveName + "spotify_access_token"))
//                    UserDefaults.standard.set(refreshToken, forKey: String(self.saveName + "spotify_refresh_token"))
//                    UserDefaults.standard.set(Date().timeIntervalSince1970 + 3600, forKey: String(self.saveName + "spotify_token_expiry")) // Token valid for 1 hour
//                    
//                    self.fetchSpotifyUserProfile(accessToken: accessToken)
//                }
//            }
//        }.resume()
//    }
//    
//    func getValidAccessToken(completion: @escaping (String?) -> Void) {
//        if let expiry = UserDefaults.standard.double(forKey: "\(saveName)spotify_token_expiry") as Double?,
//           let token = UserDefaults.standard.string(forKey: "\(saveName)spotify_access_token") {
//            
//            let currentTime = Date().timeIntervalSince1970
//            if currentTime < expiry {
//                completion(token)
//            } else {
//                refreshAccessToken { newToken in
//                    completion(newToken)
//                }
//            }
//        } else {
//            completion(nil)
//        }
//    }
//    
//    func fetchSpotifyUserProfile(accessToken: String) {
//        let url = URL(string: "https://api.spotify.com/v1/me")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                return
//            }
//            
//            do {
//                let userProfile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
//                
//                // Store in UserDefaults or another state management system
//                if let encodedProfile = try? JSONEncoder().encode(userProfile) {
//                    UserDefaults.standard.set(encodedProfile, forKey: String(self.saveName + "spotify_user_profile"))
//                }
//                
//            } catch {
//                //                print("Failed to decode JSON: \(error.localizedDescription)")
//            }
//        }.resume()
//    }
//    
//    
//    
//    func refreshAccessToken(completion: @escaping (String?) -> Void) {
//        guard let refreshToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_refresh_token")) else {
//            print("No refresh token found")
//            completion(nil)
//            return
//        }
//        
//        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
//        var request = URLRequest(url: tokenURL)
//        request.httpMethod = "POST"
//        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//        
//        let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)"
//        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
//        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
//        
//        let bodyParams = "grant_type=refresh_token&refresh_token=\(refreshToken)"
//        request.httpBody = bodyParams.data(using: .utf8)
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error refreshing token: \(error?.localizedDescription ?? "Unknown error")")
//                completion(nil)
//                return
//            }
//            
//            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//               let newAccessToken = json["access_token"] as? String {
//                
//                UserDefaults.standard.set(newAccessToken, forKey: String(self.saveName + "spotify_access_token"))
//                UserDefaults.standard.set(Date().timeIntervalSince1970 + 3600, forKey: String(self.saveName + "spotify_token_expiry")) // New expiry time
//                
//                print("🔄 Refreshed Access Token: \(newAccessToken)")
//                completion(newAccessToken)
//            } else {
//                print("Failed to refresh access token")
//                completion(nil)
//            }
//        }.resume()
//    }
//    
//    func logoutFromSpotify() -> Bool {
//        let defaults = UserDefaults.standard
//        let keys = [
//            String(self.saveName + "spotify_access_token"),
//            String(self.saveName + "spotify_refresh_token"),
//            String(self.saveName + "spotify_token_expiry")
//        ]
//        
//        var success = false
//        for key in keys {
//            if defaults.object(forKey: key) != nil {
//                defaults.removeObject(forKey: key)
//                success = true
//            }
//        }
//        
//        defaults.synchronize()
//        
//        return success
//    }
//
//
//    func revokeSpotifyAccessToken(completion: @escaping (Bool) -> Void) {
//        guard let _ = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_refresh_token")) else {
//            print("⚠️ No refresh token found, already logged out")
//            completion(true)
//            return
//        }
//
//        // Remove stored tokens
//        let success = logoutFromSpotify()
//        completion(success)
//    }
//
//    
//    func makeNewSpotifyPlaylist(artistList: Array<String>, playlistName: String, isPublic: Bool, completion: @escaping (String?) -> Void) {
//        isUserLoggedIn { isLoggedIn in
//            guard isLoggedIn else {
//                print("❌ User is not logged in")
//                completion(nil)
//                return
//            }
//            
//            // ✅ Retrieve access token *after* confirming login status
//            guard let accessToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_access_token")) else {
//                print("❌ No valid access token found")
//                completion(nil)
//                return
//            }
//            
//            // ✅ Check if the user profile exists
//            if let data = UserDefaults.standard.data(forKey: String(self.saveName + "spotify_user_profile")),
//               let userProfile = try? JSONDecoder().decode(SpotifyUserProfile.self, from: data) {
//                // 🎯 User profile found → proceed with playlist creation
//                self.createPlaylistAndAddSongs(userProfile: userProfile, artistList: artistList, playlistName: playlistName, isPublic: isPublic, accessToken: accessToken, completion: completion)
//            } else {
//                print("⚠️ No user profile found, fetching now...")
//                
//                // 🎯 Fetch the user profile first, then retry the process
//                self.fetchSpotifyUserProfile(accessToken: accessToken) { userProfile in
//                    guard let userProfile = userProfile else {
//                        print("❌ Failed to fetch user profile")
//                        completion(nil)
//                        return
//                    }
//                    
//                    // ✅ Re-fetch the access token to ensure it's available before proceeding
//                    guard let refreshedAccessToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_access_token")) else {
//                        print("❌ No valid access token after profile fetch")
//                        completion(nil)
//                        return
//                    }
//                    
//                    self.createPlaylistAndAddSongs(userProfile: userProfile, artistList: artistList, playlistName: playlistName, isPublic: isPublic, accessToken: refreshedAccessToken, completion: completion)
//                }
//            }
//        }
//    }
//    
//    
//    func makeNewSpotifyPlaylistOLD(artistList: Array<artist>, playlistName: String, isPublic: Bool, completion: @escaping (String?) -> Void) {
//        isUserLoggedIn { isLoggedIn in
//            guard isLoggedIn else {
//                print("❌ User is not logged in")
//                completion(nil)
//                return
//            }
//            
//            // ✅ Retrieve access token *after* confirming login status
//            guard let accessToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_access_token")) else {
//                print("❌ No valid access token found")
//                completion(nil)
//                return
//            }
//            
//            // ✅ Check if the user profile exists
//            if let data = UserDefaults.standard.data(forKey: String(self.saveName + "spotify_user_profile")),
//               let userProfile = try? JSONDecoder().decode(SpotifyUserProfile.self, from: data) {
//                // 🎯 User profile found → proceed with playlist creation
//                self.createPlaylistAndAddSongsOLD(userProfile: userProfile, artistList: artistList, playlistName: playlistName, isPublic: isPublic, accessToken: accessToken, completion: completion)
//            } else {
//                print("⚠️ No user profile found, fetching now...")
//                
//                // 🎯 Fetch the user profile first, then retry the process
//                self.fetchSpotifyUserProfile(accessToken: accessToken) { userProfile in
//                    guard let userProfile = userProfile else {
//                        print("❌ Failed to fetch user profile")
//                        completion(nil)
//                        return
//                    }
//                    
//                    // ✅ Re-fetch the access token to ensure it's available before proceeding
//                    guard let refreshedAccessToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_access_token")) else {
//                        print("❌ No valid access token after profile fetch")
//                        completion(nil)
//                        return
//                    }
//                    
//                    self.createPlaylistAndAddSongsOLD(userProfile: userProfile, artistList: artistList, playlistName: playlistName, isPublic: isPublic, accessToken: refreshedAccessToken, completion: completion)
//                }
//            }
//        }
//    }
//    
//    
//    
//    func extractArtistID(url: URL) -> String? {
//        if let components = URLComponents(string: url.absoluteString),
//           let lastPathComponent = components.path.split(separator: "/").last {
//            return String(lastPathComponent)
//        }
//        return nil
//    }
//    
//    
//    
////    func createPlaylistAndAddSongs(userProfile: SpotifyUserProfile, artistList: Array<artist>, playlistName: String, isPublic: Bool, accessToken: String, completion: @escaping (String?) -> Void) {
////        let userID = userProfile.id
////
////        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
////            
////            if let playlistID = playlistID {
////                let totalArtists = artistList.count
////                print ("TOTAL: \(totalArtists)")
////                var processedArtists = 0
////                let lock = NSLock() // Prevent race conditions when incrementing `processedArtists`
////                let checkCompletion = {
////                    lock.lock()
////                    processedArtists += 1
////                    print("Processed Artists: \(processedArtists) / Total Artists: \(totalArtists)")
////                    if processedArtists == totalArtists {
////                        print("✅ All \(processedArtists) artists processed. Calling final completion.")
////                        completion(playlistID)
////                    }
////                    lock.unlock()
////                }
////
////                for (index, artist) in artistList.enumerated() {
////                    print("Processing Artist \(index + 1): \(artist.name)")
////                    
////                    DispatchQueue.global().asyncAfter(deadline: .now() + (Double(index) / 2)) {
////                        print("Attempting to fetch top tracks for Artist #\(index + 1): \(artist.name)")
////                        if let artistID = self.extractArtistID(url: artist.artistPage) {
////                            
////                            self.getArtistTopTracks(artistID: artistID, accessToken: accessToken, playlistID: playlistID) {
////                                checkCompletion() // ✅ Ensures each artist is counted
////                            }
////                        } else {
////                            print("❌ Failed to extract artist ID from \(artist.artistPage)")
////                            checkCompletion() // ✅ Even if artist is skipped, still counts
////                        }
////                    }
////                }
////            } else {
////                print("❌ Failed to create playlist")
////                completion(nil)
////            }
////        }
////    }
//    
//    func createPlaylistAndAddSongs(userProfile: SpotifyUserProfile, artistList: Array<String>, playlistName: String, isPublic: Bool, accessToken: String, completion: @escaping (String?) -> Void) {
//        let userID = userProfile.id
//
//        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
//            
//            if let playlistID = playlistID {
//                self.playlistArtistCount = artistList.count
//
//                // Create a DispatchGroup to track the completion of all tasks
//                let dispatchGroup = DispatchGroup()
//
//                for (index, artistID) in artistList.enumerated() {
////                    print("Processing Artist \(index + 1): \(artist.name)")
//                    
//                    // Enter the DispatchGroup before starting each asynchronous task
//                    dispatchGroup.enter()
//                    var asyncModifyer: Double = 10
//                    if artistList.count > 50 {
//                        asyncModifyer = 2
//                    }
//                    
//                    DispatchQueue.global().asyncAfter(deadline: .now() + (Double(index) / asyncModifyer)) {
//                        self.getArtistTopTracks(artistID: artistID, accessToken: accessToken, playlistID: playlistID) {
//                            print(self.progress)
//                            dispatchGroup.leave()
//                        }
//                        
//                        
////                        if let artistID = self.extractArtistID(url: artist.artistPage) {
////                            self.getArtistTopTracks(artistID: artistID, accessToken: accessToken, playlistID: playlistID) {
////                                // Leave the DispatchGroup once the task is done
//////                                DispatchQueue.main.async {
//////                                    self.progress = max(Float(index) / Float(artistList.count), self.progress)
//////                                }
////                                print(self.progress)
////                                dispatchGroup.leave()
////                            }
////                        } else {
////                            print("❌ Failed to extract artist ID from \(artist.artistPage)")
//////                            DispatchQueue.main.async {
//////                                self.progress = max(Float(index) / Float(artistList.count), self.progress)
//////                            }
////                            print(self.progress)
////                            // Leave the DispatchGroup even if the artist is skipped
////                            dispatchGroup.leave()
////                        }
//                    }
//                }
//
//                // Notify when all tasks are complete
//                dispatchGroup.notify(queue: .main) {
//                    print("✅ All artists processed. Calling final completion.")
//                    completion(playlistID)
//                }
//            } else {
//                print("❌ Failed to create playlist")
//                completion(nil)
//            }
//        }
//    }
//    
//    func createPlaylistAndAddSongsOLD(userProfile: SpotifyUserProfile, artistList: Array<artist>, playlistName: String, isPublic: Bool, accessToken: String, completion: @escaping (String?) -> Void) {
//        let userID = userProfile.id
//
//        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
//            
//            if let playlistID = playlistID {
//                self.playlistArtistCount = artistList.count
//                let totalArtists = artistList.count
//                print("TOTAL: \(totalArtists)")
//
//                // Create a DispatchGroup to track the completion of all tasks
//                let dispatchGroup = DispatchGroup()
//
//                for (index, artist) in artistList.enumerated() {
//                    print("Processing Artist \(index + 1): \(artist.name)")
//                    
//                    // Enter the DispatchGroup before starting each asynchronous task
//                    dispatchGroup.enter()
//                    var asyncModifyer: Double = 10
//                    if artistList.count > 50 {
//                        asyncModifyer = 2
//                    }
//                    
//                    DispatchQueue.global().asyncAfter(deadline: .now() + (Double(index) / asyncModifyer)) {
//                        print("Attempting to fetch top tracks for Artist #\(index + 1): \(artist.name)")
//
//                        if let artistID = self.extractArtistID(url: artist.artistPage) {
//                            self.getArtistTopTracks(artistID: artistID, accessToken: accessToken, playlistID: playlistID) {
//                                // Leave the DispatchGroup once the task is done
////                                DispatchQueue.main.async {
////                                    self.progress = max(Float(index) / Float(artistList.count), self.progress)
////                                }
//                                print(self.progress)
//                                dispatchGroup.leave()
//                            }
//                        } else {
//                            print("❌ Failed to extract artist ID from \(artist.artistPage)")
////                            DispatchQueue.main.async {
////                                self.progress = max(Float(index) / Float(artistList.count), self.progress)
////                            }
//                            print(self.progress)
//                            // Leave the DispatchGroup even if the artist is skipped
//                            dispatchGroup.leave()
//                        }
//                    }
//                }
//
//                // Notify when all tasks are complete
//                dispatchGroup.notify(queue: .main) {
//                    print("✅ All artists processed. Calling final completion.")
//                    completion(playlistID)
//                }
//            } else {
//                print("❌ Failed to create playlist")
//                completion(nil)
//            }
//        }
//    }
//
//
//
//    
//    
//    func fetchSpotifyUserProfile(accessToken: String, completion: @escaping (SpotifyUserProfile?) -> Void) {
//        let url = URL(string: "https://api.spotify.com/v1/me")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("❌ Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
//                completion(nil)
//                return
//            }
//            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("📦 Raw JSON response from Spotify API: \(jsonString)")
//            } else {
//                print("❌ Failed to convert API response to string")
//            }
//            do {
//                let userProfile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
//                let encodedData = try JSONEncoder().encode(userProfile)
//                UserDefaults.standard.set(encodedData, forKey: String(self.saveName + "spotify_user_profile")) // ✅ Save to UserDefaults
//                print("✅ User profile saved: \(userProfile.id)")
//                completion(userProfile)
//            } catch {
//                print("❌ Failed to decode user profile: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }.resume()
//    }
//    
//    
//    
//    func createPlaylist(userID: String, accessToken: String, playlistName: String, isPublic: Bool, completion: @escaping (String?) -> Void) {
//        let url = URL(string: "https://api.spotify.com/v1/users/\(userID)/playlists")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        // Define the playlist details
//        let body: [String: Any] = [
//            "name": playlistName,
//            "public": isPublic
//        ]
//        
//        // Convert to JSON
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//        
//        print("📡 Sending request to: \(url)")
//        print("📜 Request body: \(body)")
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//                print("Error creating playlist: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("📦 Raw API response: \(jsonString)")
//            } else {
//                print("❌ Failed to convert API response to string")
//            }
//            
//            // Try to decode the response
//            do {
//                let playlistResponse = try JSONDecoder().decode(SpotifyPlaylist.self, from: data)
//                print("Created Playlist: \(playlistResponse.name) (ID: \(playlistResponse.id))")
//                UserDefaults.standard.set(playlistResponse.id, forKey: String(self.saveName + "spotify_playlist_id"))
//                completion(playlistResponse.id)
//            } catch {
//                print("Failed to decode playlist response: \(error.localizedDescription)")
//                completion(nil)
//            }
//        }.resume()
//    }
//    
//    func getArtistTopTracks(artistID: String, accessToken: String, playlistID: String, completion: @escaping () -> Void) {
//        let topTracksURL = URL(string: "https://api.spotify.com/v1/artists/\(artistID)/top-tracks?market=US")!
//        var topTracksRequest = URLRequest(url: topTracksURL)
//        topTracksRequest.httpMethod = "GET"
//        topTracksRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: topTracksRequest) { topTracksData, _, topTracksError in
//            guard let topTracksData = topTracksData, topTracksError == nil else {
//                print("❌ Error fetching top tracks: \(topTracksError?.localizedDescription ?? "Unknown error")")
//                completion() // ✅ Completion is always called
//                return
//            }
//
//            do {
//                if let topTracksJSON = try JSONSerialization.jsonObject(with: topTracksData, options: []) as? [String: Any],
//                   let tracks = topTracksJSON["tracks"] as? [[String: Any]] {
//                    let trackURIs = tracks.prefix(5).compactMap { $0["uri"] as? String }
//                    
//                    if !trackURIs.isEmpty {
//                        self.addTracksToPlaylist(playlistID: playlistID, accessToken: accessToken, trackURIs: trackURIs, completion: completion)
//                    } else {
//                        print("⚠️ No tracks found for artist \(artistID)")
//                        completion()
//                    }
//                }
//            } catch {
//                print("❌ Failed to parse top tracks JSON: \(error.localizedDescription)")
//                completion()
//            }
//        }.resume()
//    }
//
//
//    
//    
//    func addTracksToPlaylist(playlistID: String, accessToken: String, trackURIs: [String], retryCount: Int = 0, maxRetries: Int = 3, completion: @escaping () -> Void) {
//        print("Adding Tracks to Playlist: \(playlistID), Tracks: \(trackURIs)")
//        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = ["uris": trackURIs]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil, let httpResponse = response as? HTTPURLResponse else {
//                print("❌ Network error: \(error?.localizedDescription ?? "Unknown error")")
//                completion()
//                return
//            }
//
//            if httpResponse.statusCode == 429 {
//                self.ERRORCOUNT += 1
//                print("ERROR: \(self.ERRORCOUNT)")
//                let retryAfter = min(2.0 * pow(2.0, Double(retryCount)), 60.0)
//                print("⚠️ Rate limit exceeded (429). Retrying in \(retryAfter) seconds...")
//
//                if retryCount < maxRetries {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + retryAfter) {
//                        self.addTracksToPlaylist(playlistID: playlistID, accessToken: accessToken, trackURIs: trackURIs, retryCount: retryCount + 1, maxRetries: maxRetries, completion: completion)
//                    }
//                } else {
//                    print("❌ Max retries reached for rate limit. Skipping.")
//                    completion() // ✅ Completion is called
//                }
//                return
//            }
//
//            if httpResponse.statusCode == 502 {
//                self.ERRORCOUNT += 1
//                print("ERROR: \(self.ERRORCOUNT)")
//                let retryAfter = min(2.0 * pow(2.0, Double(retryCount)), 60.0)
//                print("⚠️ Server error (502). Retrying in \(retryAfter) seconds...")
//
//                if retryCount < maxRetries {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + retryAfter) {
//                        self.addTracksToPlaylist(playlistID: playlistID, accessToken: accessToken, trackURIs: trackURIs, retryCount: retryCount + 1, maxRetries: maxRetries, completion: completion)
//                    }
//                } else {
//                    print("❌ Max retries reached for server errors. Skipping.")
//                    completion() // ✅ Completion is called
//                }
//                return
//            }
//
//            do {
//                let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                if let snapshotID = responseJSON?["snapshot_id"] as? String, !snapshotID.isEmpty {
//                    print("✅ Tracks added successfully: \(snapshotID)")
//                    DispatchQueue.main.async {
//                        print("Add \(Float(1.0)/Float(self.playlistArtistCount))")
//                        self.progress += Float(1.0)/Float(self.playlistArtistCount)
//                        print("PROGRESS: \(self.progress)")
////                        self.progress = max(Float(index) / Float(artistList.count), self.progress)
//                    }
//                    completion()
//                } else {
//                    self.ERRORCOUNT += 1
//                    print("ERROR: \(self.ERRORCOUNT)")
//                    if retryCount < maxRetries {
//                        print("⚠️ Warning: snapshot_id is null. Retrying in 2 seconds...")
//                        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//                            self.addTracksToPlaylist(playlistID: playlistID, accessToken: accessToken, trackURIs: trackURIs, retryCount: retryCount + 1, maxRetries: maxRetries, completion: completion)
//                        }
//                    } else {
//                        print("❌ Max retries reached, snapshot_id still null. Skipping this batch.")
//                        completion() // ✅ Completion is called
//                    }
//                }
//            } catch {
//                print("❌ Failed to parse response JSON: \(error.localizedDescription)")
//                completion()
//            }
//        }.resume()
//    }
//
//
//
//
//
//    
//    
//    func getPlaylistURL() -> URL? {
//        if let playlistID = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_playlist_id")) {
//            return URL(string: "https://open.spotify.com/playlist/\(playlistID)")
//        }
//        return nil
//    }
//    
//    func openSpotifyLogin() {
//        UIApplication.shared.open(SpotifyAuth.authURL)
//    }
//    
//    struct SpotifyUserProfile: Codable {
//        let display_name: String?
//        let id: String
//        let email: String?
//        let images: [SpotifyImage]?
//        let followers: SpotifyFollowers?
//    }
//    
//    struct SpotifyImage: Codable {
//        let url: String
//    }
//    
//    struct SpotifyFollowers: Codable {
//        let total: Int
//    }
//    
//    struct SpotifyPlaylist: Codable {
//        let id: String
//        let name: String
//    }
//    
//    struct SpotifyArtist: Identifiable, Decodable {
//        let id: String
//        let name: String
//        let images: [SpotifyImage]
//
//        var imageURL: URL? {
//            images.first?.url
//        }
//
//        struct SpotifyImage: Decodable {
//            let url: URL
//        }
//    }
//    
//    struct SpotifySearchResponse: Decodable {
//        let artists: ArtistItems
//        
//        struct ArtistItems: Decodable {
//            let items: [SpotifyArtistRaw]
//        }
//        
//        struct SpotifyArtistRaw: Decodable {
//            let id: String
//            let name: String
//            let genres: [String]
//            let images: [SpotifyImage]
//            
//            struct SpotifyImage: Decodable {
//                let url: String
//            }
//        }
//    }
    
    let tierLables = ["Headliner", "First Tier", "Second Tier", "Third+ Tier"]
    
    let allLable = ["All Artists"]
//    let tierLables = ["Headliners", "1st Line", "2nd Line", "3rd Line", "4th Line", "5th Line", "6th Line"]
    let dayLables = ["Thursday", "Friday", "Saturday", "Sunday", "Unannounced"]
    let genreLables = ["Alternative", "Children’s Music", "Classical", "Country", "Dance/Electronic", "Folk", "Hip-Hop/Rap", "Indie", "J-Pop", "Jazz", "K-Pop", "Latin", "Metal", "Pop", "R&B/Soul", "Reggae", "Rock", "World"]
    
    
    func getSortLables(sort: sortType) -> Array<String> {
        switch(sort) {
        case .alpha:
            return allLable
        case .billing:
            return tierLables
        case .day:
            return dayLables
        case .stage:
            return dayLables
        case .genre:
            return genreLables
        case .addDate:
            return allLable
        case .modifyDate:
            return allLable
        }
    }
    
//    func getStages() -> Array<String> {
//        var stageList = Array<String>()
//        for a in getFullList() {
//            if let stage = a.stage {
//                if !stageList.contains(stage) {
//                    stageList.append(stage)
//                }
//            }
//        }
//        stageList.sort {
//            $0.lowercased() < $1.lowercased()
//        }
//        return stageList
//    }
    
    
//    struct artist: Identifiable, Hashable {
//        var id: String
//        var name: String
//        var photo: UIImage
//        var genres: Array<String>
//        var tags: Array<String>
//        var weekend: Array<Bool> = [true, true]
//        var day: Int
//        var tier: Int?
//        var stage: String?
//        var favorability: Int = 0
//        var artistPage: URL
//        var artistPlaylist: URL?
//        var albums: Array<album>
//        var upcomingAlbum: album?
//        
//        init(name: String, photo: UIImage, genres: Array<String> = Array<String>(), tags: Array<String> = Array<String>(), weekend: Int? = nil, day: Int, tier: Int? = nil, stage: String? = nil, artistPage: URL, artistPlaylist: URL? = nil, albums: Array<album>, upcomingAlbum: album? = nil) {
//            self.name = name
//            self.photo = photo
//            self.genres = genres
//            self.tags = tags
//            self.day = day
//            self.tier = tier
//            self.stage = stage
//            self.artistPage = artistPage
//            self.artistPlaylist = artistPlaylist
//            self.albums = albums
//            self.upcomingAlbum = upcomingAlbum
//            
//            if let w = weekend {
//                self.weekend = [(w == 1), (w == 2)]
//            }
//            
//            self.id = consistentHash(for: name)
//            
//            func consistentHash(for string: String) -> String {
//                let data = Data(string.utf8)
//                let hash = SHA256.hash(data: data)
//                return hash.compactMap { String(format: "%02x", $0) }.joined()
//            }
//        }
//    }
    
    struct Artist: Identifiable, Hashable, Codable {
        var id: String
        var name: String
        var genres: [String]
        var imageURL: String
        var imageLocalPath: String?
        var day: String = "-- N/A --"
        var weekend: String = "Both"
        var tier: String = "-- N/A --"
        var stage: String = "-- N/A --"
        var addDate/*: Date?*/ = Date()
        var modifyDate/*: Date?*/ = Date()
    }
    
//    struct artistWithPhoto: ``
    
    
    struct album: Identifiable, Hashable {
        var id = UUID()
        var name: String
        var year: Int
        var day: String?
        var URLs: Array<URL>
    }
    
    struct Festival: Identifiable, Hashable, Codable {
        var id: UUID
        var ownerID: String
        var ownerName: String
        var saveDate = Date()
        var verified: Bool = true
        var name: String = ""
        var startDate = Date()
        var endDate = Date()
        var secondWeekend: Bool = false
        var location: String?
        var logoPath: String? = nil
        var artistList = Array<Artist>()
        var stageList = Array<String>()
        var website: String? = nil
        var published: Bool = false
        
        static func newFestival() -> Festival {
            let user = Auth.auth().currentUser
            return Festival(
                id: UUID(),
                ownerID: user?.uid ?? "Unknown",
                ownerName: user?.displayName ?? "Unknown" // displayName is the user's name
            )
        }
    }
    
    struct ArtistListStruct: Hashable {
//        let title: String
        var titleText: String? = nil
        let festival: Festival
        let list: Array<Artist>
//        let list: [String : Array<artistNEW>]
    }
    
    struct ArtistPageStruct: Hashable {
        let artist: Artist
        let shuffleTitle: String
        let shuffleList: Array<Artist>
    }
    
    struct settingsStruct: Encodable, Decodable {
        var festivalWeekend: Int
        var festivalDays: Array<Bool>
    }
    
    enum sortType {
        case alpha
        case billing
        case day
        case stage
        case genre
        case addDate
        case modifyDate
    }

    
    
    



    
    struct UserProfileTemp: Hashable, Identifiable {
        var id: String
        var festivalList: [Festival]
    }
    
    struct FriendProfileOLD: Hashable, Identifiable, Codable {
        var id: String
        var name: String
        var profilePic: String?
        var favorites: [String]?
    }
    
    
    struct FriendProfile: Identifiable, Codable, Hashable {
        var id: String
        var name: String
        var profilePic: String?
        var favorites: [FestivalFavorite] = []
    }

    struct FestivalFavorite: Identifiable, Codable, Hashable {
        var id: String            // festivalId
        var festivalName: String
        var logoPath: String?
        var likedArtistIds: [String]
    }
    
    
    struct SocialGroup: Hashable, Identifiable, Codable {
        var id: String
        var name: String
        var photo: String?
        var members: [FriendProfileOLD]
        var favoritesDict: [String : [String]] = [String : [String]]()
        var inviteLink: String
    }
    
    
    struct Request: Hashable, Identifiable {
        var id: String
        var name: String
        var photo: String?
        var groupMembers: [String]?
    }
    
    init(name: String) {
        self.saveName = name
        
        self.userInfoTemp = UserProfileTemp(id: "austinzv", festivalList: [])
        
        var dislikeArray = Array<String>()
        let dislikeData: Data? = UserDefaults.standard.data(forKey: String(self.saveName + "dislikes"))
        if dislikeData != nil, let tryDislikes: Array<String> = try? JSONDecoder().decode([String].self, from: dislikeData!) {
            dislikeArray = tryDislikes
        }
        
        var likeArray = Array<String>()
        let likeData: Data? = UserDefaults.standard.data(forKey: String(self.saveName + "likes"))
        //        print(likeData)
        if likeData != nil, let tryLikes: Array<String> = try? JSONDecoder().decode([String].self, from: likeData!) {
            likeArray = tryLikes
        }
        
        self.settings = settingsStruct(festivalWeekend: 1, festivalDays: [false,true,true,true])
        
        let festDaysData: Data? = UserDefaults.standard.data(forKey: String(self.saveName + "festivalDays"))
        if festDaysData != nil, let trySetDays: [Bool] = try? JSONDecoder().decode([Bool].self, from: festDaysData!) {
            if trySetDays.count == 4 {
                self.settings.festivalDays = trySetDays
            }
        }
        
        let festWeekendData: Data? = UserDefaults.standard.data(forKey: String(self.saveName + "festivalWeekend"))
        if festWeekendData != nil, let trySetW: Int = try? JSONDecoder().decode(Int.self, from: festWeekendData!) {
            self.settings.festivalWeekend = trySetW
        }
        
//        self.favoritesList = Array(repeating: Array<artist>(), count: 2)
//        
//        for a in artistList {
//            if dislikeArray.contains(where: { $0 == a.id }) {
//                favoritesList[0].append(a)
//            }
//            if likeArray.contains(where: { $0 == a.id }) {
//                favoritesList[1].append(a)
//            }
//        }
    }
}


extension UIImage {
    var averageColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}


struct UserProfile: Hashable, Identifiable, Codable {

    @DocumentID var id: String?

    var name: String
    var profilePic: String?

    var following: [String]?
    var followers: [String]?
    var festivalFavorites: [String : [String]]?
    
    var groups: [String]?

}

extension UserProfile {
    var safeFollowing: [String] { following ?? [] }
    var safeFollowers: [String] { followers ?? [] }
    var safeFestivalFavorites: [String: [String]] { festivalFavorites ?? [:] }
    var safeGroups: [String] { groups ?? [] }
    
    init() {
        self.id = nil
        self.name = ""
        self.profilePic = nil
        self.following = []
        self.followers = []
        self.festivalFavorites = [:]
        self.groups = []
    }
}

struct SocialGroup: Hashable, Identifiable, Codable {
    @DocumentID var id: String?
    var ownerID: String
    var name: String
    var photo: String?
    var members: [String] = []
    var festivals: [String] = []
}

//struct SocialGroup: Hashable, Identifiable, Codable {
//    var id: String
//    var ownerID: String
//    var name: String
//    var photo: String?
//    var members: [UserProfile] = []
//    var festivals: [String] = []
//}

extension UserDefaults {
    func saveCodable<T: Codable>(_ value: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(value) {
            set(data, forKey: key)
        }
    }

    func loadCodable<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: data)
    }
}
