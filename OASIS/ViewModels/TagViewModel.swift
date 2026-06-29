//
//  TagViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 4/18/26.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class TagViewModel: ObservableObject {
    private let saveName: String
    
                              //[festivalID: [tagID: Tag]]
    @Published var festivalTags: [UUID: [UUID: ArtistTag]] = [:] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(festivalTags)
                UserDefaults.standard.set(data, forKey: (saveName + "/festivalTags"))
                //print("myTags saved")
            } catch {
                //print("Failed to save myTags:", error)
            }
        }
    }

    @Published var artistTagDictionary: [UUID: Set<String>] = [:] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(artistTagDictionary)
                UserDefaults.standard.set(data, forKey: (saveName + "/artistTagDictionary"))
                //print("myTags saved")
            } catch {
                //print("Failed to save myTags:", error)
            }
        }
    }
    
    
    
    
    
    
    
//    @Published var myTags: [ArtistTag] = [] {
//        didSet {
//            do {
//                let encoder = JSONEncoder()
//                let data = try encoder.encode(myTags)
//                UserDefaults.standard.set(data, forKey: (saveName + "/myTags"))
//                //print("myTags saved")
//            } catch {
//                //print("Failed to save myTags:", error)
//            }
//        }
//    }
    
//    @Published var artistTagDictionaryOLD: [String : Set<UUID>] = [:] {
//        didSet {
//            do {
//                let encoder = JSONEncoder()
//                let data = try encoder.encode(artistTagDictionaryOLD)
//                UserDefaults.standard.set(data, forKey: (saveName + "/artistTagDictionary"))
//                //print("artistTagDictionary saved")
//            } catch {
//                //print("Failed to save artistTagDictionary:", error)
//            }
//        }
//    }
    
    @Published var myFavorites: [String] = [] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(myFavorites)
                UserDefaults.standard.set(data, forKey: (saveName + "/myFavorites"))
                //print("myFavorites saved")
                
            } catch {
                //print("Failed to save myFavorites:", error)
            }
        }
    }
    
    @Published var myDNSTs: [String] = [] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(myDNSTs)
                UserDefaults.standard.set(data, forKey: (saveName + "/myDoNotSuggestTags"))
                //print("myFavorites saved")
                
            } catch {
                //print("Failed to save myFavorites:", error)
            }
        }
    }
    
    
    func addTag(tag: ArtistTag, festivalID: UUID) {
        festivalTags[festivalID, default: [:]][tag.id] = tag
        
        
//        if let index = myTags.firstIndex(where: { $0.id == tag.id }) {
//            myTags[index] = tag
//        } else {
//            myTags.append(tag)
//        }
//        myTags = myTags.sorted(by: { $0.name > $1.name })
    }
    
    func removeTag(tag: ArtistTag, festivalID: UUID) {
        festivalTags[festivalID]?[tag.id] = nil
//        if let index = myTags.firstIndex(where: { $0.id == tag.id }) {
//            myTags.remove(at: index)
//        }
//        for (artist, tagSet) in artistTagDictionaryOLD {
//            if tagSet.contains(tag.id) {
//                var newTagSet = tagSet
//                newTagSet.remove(tag.id)
//                artistTagDictionaryOLD[artist] = newTagSet
//            }
//        }
    }
    
    func getSortedTag(festivalID: UUID) -> [ArtistTag] {
        guard let tags = festivalTags[festivalID] else { return [] }

        return tags.values.sorted {
            $0.name.lowercased() < $1.name.lowercased()
        }
    }
    
//    func getSortedTag(festivalID: UUID) -> [ArtistTag] {
//        return Array(festivalTags[festivalID]?.values ?? [])
////        var sortedTags =  myTags.sorted(by: { $0.name < $1.name })
////        sortedTags.insert(DONOTSUGGESTTAG, at: 0)
////        return sortedTags
//    }
    
    func sortTags(_ tags: [ArtistTag]) -> [ArtistTag] {
        var sortedTags =  tags.sorted(by: { $0.name < $1.name })
        if let index = sortedTags.firstIndex(where: { $0 == DONOTSUGGESTTAG }) {
            sortedTags.remove(at: index)
            sortedTags.insert(DONOTSUGGESTTAG, at: 0)
        }
        return sortedTags
    }
    
//    func getTagIDsForArtist(artistID: String, festivalID: UUID) -> Set<UUID> {
//    }
    
//    func getArtistTagIDs(artistID: String) -> Set<UUID> {
//        if let artistTags = artistTagDictionaryOLD[artistID] {
//            return artistTags
//        }
//        return []
//    }
    
    func getArtistTags(artistID: String, festivalID: UUID) -> [ArtistTag] {
        guard let tags = festivalTags[festivalID] else { return [] }

        return tags.values.filter { tag in
            artistTagDictionary[tag.id]?.contains(artistID) == true
        }
    }
    
    func getTagArtists(tagID: UUID, festival: Festival) -> [Artist] {
        guard let artistIDs = artistTagDictionary[tagID] else {
            return []
        }

        return festival.artistList.filter { artist in
            artistIDs.contains(artist.id)
        }
    }
    
//    func getAllTagsExcept(_ festivalID: UUID) -> [ArtistTag] {
//        return festivalTags
//            .filter { $0.key != festivalID }
//            .flatMap { $0.value.values }
//            .sorted {
//                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
//            }
//    }
    
    func getAllTagsExcept(_ festivalID: UUID) -> [ArtistTag] {

        let excludedFestivalTags = Array(
            festivalTags[festivalID]?.values ?? [:].values
        )

        let excludedSignatures = Set(
            excludedFestivalTags.map {
                TagSignature(
                    name: $0.name,
                    symbol: $0.symbol,
                    color: $0.color
                )
            }
        )

        let allTags = festivalTags
            .filter { $0.key != festivalID }
            .flatMap { $0.value.values }

        var seen: Set<TagSignature> = []

        return allTags
            .filter { tag in

                let signature = TagSignature(
                    name: tag.name,
                    symbol: tag.symbol,
                    color: tag.color
                )

                // Exclude tags matching one already
                // in the excluded festival
                guard !excludedSignatures.contains(signature) else {
                    return false
                }

                // Remove duplicates from remaining festivals
                return seen.insert(signature).inserted
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }
    }

    private struct TagSignature: Hashable {
        let name: String
        let symbol: String
        let color: Int
    }
    
//    func getArtistTags(artistID: String) -> [ArtistTag] {
//        if let artistTags = artistTagDictionaryOLD[artistID] {
//            return getTagsFromIDs(artistTags)
//        }
//        return []
//    }
//    
//    func getTagsFromIDs(_ ids: Set<UUID>) -> [ArtistTag] {
//        var sortedTags = [ArtistTag]()
//        var addDNST = false
//        for tagID in ids {
//            if let tag = getTag(tagID) {
//                sortedTags.append(tag)
//            } else if tagID == DONOTSUGGESTTAG.id {
//                addDNST = true
//            }
//        }
//        
//        sortedTags =  sortedTags.sorted(by: { $0.name < $1.name })
//        if addDNST { sortedTags.insert(DONOTSUGGESTTAG, at: 0) }
//        
//        return sortedTags
//    }
    
    func updateArtistTags(artistID: String, selectedTagIDs: Set<UUID>, festivalID: UUID, tagsToAdd: Set<ArtistTag>) {
        if let tags = festivalTags[festivalID] {
            
            for tagID in tags.keys {
                
                var artists = artistTagDictionary[tagID] ?? []
                
                if selectedTagIDs.contains(tagID) {
                    // ensure artist is included
                    artists.insert(artistID)
                } else {
                    // ensure artist is removed
                    artists.remove(artistID)
                }
                
                artistTagDictionary[tagID] = artists
            }
        }
        
        for tag in tagsToAdd {
            let newID = UUID()
            var newTag = tag
            newTag.id = newID
            festivalTags[festivalID, default: [:]][newID] = newTag
            artistTagDictionary[newID] = [artistID]
        }
        
        //DO STUFF HERE REGARDLESS
    }
    
    func addArtistsToTag(tagID: UUID, artistIDs: Set<String>) {
        artistTagDictionary[tagID, default: []].formUnion(artistIDs)
    }
    
    func tagAlreadyExists(tagID: UUID, festivalID: UUID) -> Bool {
        return festivalTags[festivalID]?[tagID] != nil
    }
    
    func getTagDictionary(festival: Festival) -> [ArtistTag: [Artist]] {
        guard let tags = festivalTags[festival.id] else { return [:] }

        var result: [ArtistTag: [Artist]] = [:]

        for tag in tags.values {
            let artistsForTag: [Artist] = festival.artistList.filter { artist in
                artistTagDictionary[tag.id]?.contains(artist.id) == true
            }

            if !artistsForTag.isEmpty {
                result[tag] = artistsForTag
            }
        }

        return result
    }
    
//    func getTagDictionary(currList: [Artist]) -> [ArtistTag: [Artist]] {
//        var result: [ArtistTag: [Artist]] = [:]
//        
//        for artist in currList {
//            guard let tagIDs = artistTagDictionaryOLD[artist.id] else { continue }
//            
//            for tagID in tagIDs {
//                if let tag = getTag(tagID) {
//                    result[tag, default: []].append(artist)
//                } else if tagID == DONOTSUGGESTTAG.id {
//                    result[DONOTSUGGESTTAG, default: []].append(artist)
//                }
//                //                guard let tag = getTag(tagID) else { continue }
//                
//                //                result[tag, default: []].append(artist)
//            }
//        }
//        
//        return result
//    }
    
//    func getArtistList(_ tagID: UUID, currentList: Array<Artist>) -> Array<Artist> {
//        var returnArray = [Artist]()
//        for artist in currentList {
//            if let artistTagSet = artistTagDictionaryOLD[artist.id] {
//                if artistTagSet.contains(tagID) {
//                    returnArray.append(artist)
//                }
//            }
//        }
//        return returnArray
//    }
//    
//    func isDNSTSelected(_ artistID: String) -> Bool {
//        if let artistTags = artistTagDictionaryOLD[artistID] {
//            return artistTags.contains(DONOTSUGGESTTAG.id)
//        }
//        return false
//    }
//    
//    func addDNST(_ artistID: String) {
//        artistTagDictionaryOLD[artistID, default: []].insert(DONOTSUGGESTTAG.id)
//    }
//    
//    func getDNSTArtists(currList: [Artist]) -> Set<String> {
//        Set(
//            currList
//                .filter { artistTagDictionaryOLD[$0.id]?.contains(DONOTSUGGESTTAG.id) == true }
//                .map(\.id)
//        )
//    }
//    
//    func doesArtistHaveTags(_ artistID: String) -> Bool {
//        return artistTagDictionaryOLD[artistID] != nil
//    }
    
    func heartPressed(_ artistID: String) {
        if let index = myFavorites.firstIndex(where: { $0 == artistID }) {
            myFavorites.remove(at: index)
        } else {
            myFavorites.append(artistID)
        }
        updateFavoritesList()
    }
    
    func isArtistFavorited(_ artistID: String) -> Bool {
        return myFavorites.contains(artistID)
    }
    
    func getFavoritesList(currList: [Artist]) -> [Artist] {
        return currList.filter { myFavorites.contains($0.id) }
    }
    
    func updateFavoritesList() {
        let db = Firestore.firestore()

        guard let uid = Auth.auth().currentUser?.uid else {
            //print("No userID found")
            return
        }

        let userRef = db.collection("users").document(uid)

        userRef.setData([
            "favoriteArtistsList": myFavorites
        ], merge: true)
    }
    
    
    
    func isArtistDNS(_ artistID: String) -> Bool {
        return myDNSTs.contains(artistID)
    }
    
    func getDNSList(currList: [Artist]) -> [Artist] {
        return currList.filter { myDNSTs.contains($0.id) }
    }
    
    func getDNSIDSet(currList: [Artist]) -> Set<String> {
        return Set(currList.compactMap { artist in
            myDNSTs.contains(artist.id) ? artist.id : nil
        })
    }
    
    func updateDNST(artistID: String, DNS: Bool) {
        if DNS {
            if !myDNSTs.contains(artistID) { myDNSTs.append(artistID) }
        } else {
            if let index = myDNSTs.firstIndex(where: { $0 == artistID }) { myDNSTs.remove(at: index) }
        }
    }
    
//    func sortTagIDs(_ tagIDs: [UUID]) -> [UUID] {
//        var sortedTags = [ArtistTag]()
//        for tagID in tagIDs {
//            if let tag = getTag(tagID) {
//                sortedTags.append(tag)
//            }
//        }
//        
//        sortedTags =  sortedTags.sorted(by: { $0.name < $1.name })
//        
//        if let index = sortedTags.firstIndex(where: { $0 == DONOTSUGGESTTAG }) {
//            sortedTags.remove(at: index)
//            sortedTags.insert(DONOTSUGGESTTAG, at: 0)
//        }
//        
//        return []
////        return sortedTag
////        return sortedTags
//    }
    
//    func getTag(_ id: UUID) -> ArtistTag? {
//        myTags.first(where: { $0.id == id })
//    }
    
    
    init(name: String) {
        self.saveName = name
        
        
        
        
        
//        if let tagsData = UserDefaults.standard.data(forKey: saveName + "/myTags"),
//           let tryTags = try? JSONDecoder().decode([ArtistTag].self, from: tagsData) {
//            myTags = tryTags
//        }
//        
//        if let artistDictData = UserDefaults.standard.data(forKey: saveName + "/artistTagDictionary"),
//           let tryArtistDict = try? JSONDecoder().decode([String : Set<UUID>].self, from: artistDictData) {
//            artistTagDictionaryOLD = tryArtistDict
//        }
        
        
        if let tagsData = UserDefaults.standard.data(forKey: saveName + "/festivalTags"),
           let tryTags = try? JSONDecoder().decode([UUID: [UUID: ArtistTag]].self, from: tagsData) {
            festivalTags = tryTags
        }
        
        if let artistDictData = UserDefaults.standard.data(forKey: saveName + "/artistTagDictionary"),
           let tryArtistDict = try? JSONDecoder().decode([UUID: Set<String>].self, from: artistDictData) {
            artistTagDictionary = tryArtistDict
        }
    
        
        
        if let myFavoritesData = UserDefaults.standard.data(forKey: saveName + "/myFavorites"),
           let tryMyFavorites = try? JSONDecoder().decode([String].self, from: myFavoritesData) {
            myFavorites = tryMyFavorites
        }
        
        if let myDNSTData = UserDefaults.standard.data(forKey: saveName + "/myDoNotSuggestTags"),
           let tryMyDNST = try? JSONDecoder().decode([String].self, from: myDNSTData) {
            myDNSTs = tryMyDNST
        }
    }
    
    
    let DONOTSUGGESTTAG = ArtistTag(id: UUID(uuidString: "034D0705-95BC-44BE-B3CB-DF8E52B7AFAE")!, name: "Do Not Suggest", symbol: "nosign", color: 12)
}

struct ArtistTag: Hashable, Identifiable, Codable {
    var id = UUID()
    var name = ""
    var symbol: String = "flame"
    var color: Int = 0
}
