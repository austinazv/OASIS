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
    
    @Published var myTags: [ArtistTag] = [] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(myTags)
                UserDefaults.standard.set(data, forKey: (saveName + "/myTags"))
                //print("myTags saved")
            } catch {
                //print("Failed to save myTags:", error)
            }
        }
    }
    
    @Published var artistTagDictionary: [String : Set<UUID>] = [:] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(artistTagDictionary)
                UserDefaults.standard.set(data, forKey: (saveName + "/artistTagDictionary"))
                //print("artistTagDictionary saved")
            } catch {
                //print("Failed to save artistTagDictionary:", error)
            }
        }
    }
    
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
    
    func addTag(_ tag: ArtistTag) {
        if let index = myTags.firstIndex(where: { $0.id == tag.id }) {
            myTags[index] = tag
        } else {
            myTags.append(tag)
        }
        myTags = myTags.sorted(by: { $0.name > $1.name })
    }
    
    func removeTag(_ tag: ArtistTag) {
        if let index = myTags.firstIndex(where: { $0.id == tag.id }) {
            myTags.remove(at: index)
        }
        for (artist, tagSet) in artistTagDictionary {
            if tagSet.contains(tag.id) {
                var newTagSet = tagSet
                newTagSet.remove(tag.id)
                artistTagDictionary[artist] = newTagSet
            }
        }
    }
    
    func getSortedTag() -> [ArtistTag] {
        var sortedTags =  myTags.sorted(by: { $0.name < $1.name })
        sortedTags.insert(DONOTSUGGESTTAG, at: 0)
        return sortedTags
    }
    
    func sortTags(_ tags: [ArtistTag]) -> [ArtistTag] {
        var sortedTags =  tags.sorted(by: { $0.name < $1.name })
        if let index = sortedTags.firstIndex(where: { $0 == DONOTSUGGESTTAG }) {
            sortedTags.remove(at: index)
            sortedTags.insert(DONOTSUGGESTTAG, at: 0)
        }
        return sortedTags
    }
    
    func getArtistTagIDs(artistID: String) -> Set<UUID> {
        if let artistTags = artistTagDictionary[artistID] {
            return artistTags
        }
        return []
    }
    
    func getArtistTags(artistID: String) -> [ArtistTag] {
        if let artistTags = artistTagDictionary[artistID] {
            return getTagsFromIDs(artistTags)
        }
        return []
    }
    
    func getTagsFromIDs(_ ids: Set<UUID>) -> [ArtistTag] {
        var sortedTags = [ArtistTag]()
        var addDNST = false
        for tagID in ids {
            if let tag = getTag(tagID) {
                sortedTags.append(tag)
            } else if tagID == DONOTSUGGESTTAG.id {
                addDNST = true
            }
        }
        
        sortedTags =  sortedTags.sorted(by: { $0.name < $1.name })
        if addDNST { sortedTags.insert(DONOTSUGGESTTAG, at: 0) }
        
        return sortedTags
    }
    
    func setTags(artistID: String, tagIDs: Set<UUID>) {
        artistTagDictionary[artistID] = tagIDs
    }
    
    func getTagDictionary(currList: [Artist]) -> [ArtistTag: [Artist]] {
        var result: [ArtistTag: [Artist]] = [:]
        
        for artist in currList {
            guard let tagIDs = artistTagDictionary[artist.id] else { continue }
            
            for tagID in tagIDs {
                if let tag = getTag(tagID) {
                    result[tag, default: []].append(artist)
                } else if tagID == DONOTSUGGESTTAG.id {
                    result[DONOTSUGGESTTAG, default: []].append(artist)
                }
                //                guard let tag = getTag(tagID) else { continue }
                
                //                result[tag, default: []].append(artist)
            }
        }
        
        return result
    }
    
    func getArtistList(_ tagID: UUID, currentList: Array<Artist>) -> Array<Artist> {
        var returnArray = [Artist]()
        for artist in currentList {
            if let artistTagSet = artistTagDictionary[artist.id] {
                if artistTagSet.contains(tagID) {
                    returnArray.append(artist)
                }
            }
        }
        return returnArray
    }
    
    func isDNSTSelected(_ artistID: String) -> Bool {
        if let artistTags = artistTagDictionary[artistID] {
            return artistTags.contains(DONOTSUGGESTTAG.id)
        }
        return false
    }
    
    func addDNST(_ artistID: String) {
        artistTagDictionary[artistID, default: []].insert(DONOTSUGGESTTAG.id)
    }
    
    func getDNSTArtists(currList: [Artist]) -> Set<String> {
        Set(
            currList
                .filter { artistTagDictionary[$0.id]?.contains(DONOTSUGGESTTAG.id) == true }
                .map(\.id)
        )
    }
    
    func doesArtistHaveTags(_ artistID: String) -> Bool {
        return artistTagDictionary[artistID] != nil
    }
    
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
    
    func getTag(_ id: UUID) -> ArtistTag? {
        myTags.first(where: { $0.id == id })
    }
    
    
    init(name: String) {
        self.saveName = name
        
        if let tagsData = UserDefaults.standard.data(forKey: saveName + "/myTags"),
           let tryTags = try? JSONDecoder().decode([ArtistTag].self, from: tagsData) {
            myTags = tryTags
        }
        
        if let artistDictData = UserDefaults.standard.data(forKey: saveName + "/artistTagDictionary"),
           let tryArtistDict = try? JSONDecoder().decode([String : Set<UUID>].self, from: artistDictData) {
            artistTagDictionary = tryArtistDict
        }
        
        if let myFavoritesData = UserDefaults.standard.data(forKey: saveName + "/myFavorites"),
           let tryMyFavorites = try? JSONDecoder().decode([String].self, from: myFavoritesData) {
            myFavorites = tryMyFavorites
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
