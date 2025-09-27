//
//  FestivalViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/18/25.
//

import Foundation
import Combine
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage


class FestivalViewModel: ObservableObject {
    
    private let saveName: String
    
    @Published var festivalDraftsID: Array<UUID> = []
    @Published var publishedFestivalsID: Array<UUID> = []
    
    @Published var currentFestival: DataSet.Festival? {
        didSet {
            if let currFest = currentFestival {
                if let favsData = UserDefaults.standard.data(forKey: (saveName + currFest.id.uuidString + "/favorites")),
                   let tryFavs = try? JSONDecoder().decode([String].self, from: favsData) {
                    favoriteList = tryFavs
                } else {
                    favoriteList = []
                }
                
                if let dislikeData = UserDefaults.standard.data(forKey: (saveName + currFest.id.uuidString + "/dislikes")),
                   let tryDislikes = try? JSONDecoder().decode([String].self, from: dislikeData) {
                    dislikeList = tryDislikes
                } else {
                    dislikeList = []
                }
                
                if let settingsData = UserDefaults.standard.data(forKey: (saveName + currFest.id.uuidString + "/settings")),
                   let trySettings = try? JSONDecoder().decode(FestivalSettings.self, from: settingsData) {
                    settings = trySettings
                } else {
                    let dayDictionary = makeFestivalDays(startDate: currFest.startDate, endDate: currFest.endDate)
                    settings = FestivalSettings(festivalDays: dayDictionary)
                }
            }
        }
    }
    
    @Published var favoriteList: Array<String> = [] {
        didSet {
            do {
                if let currFest = currentFestival {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(favoriteList)
                    UserDefaults.standard.set(data, forKey: (saveName + currFest.id.uuidString + "/favorites"))
                }
            } catch {
                print("Failed to save favorites for Current Festival \(currentFestival?.name ?? "NIL"): ", error)
            }
        }
    }
    
    @Published var dislikeList: Array<String> = [] {
        didSet {
            do {
                if let currFest = currentFestival {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(dislikeList)
                    UserDefaults.standard.set(data, forKey: (saveName + currFest.id.uuidString + "/dislikes"))
                }
            } catch {
                print("Failed to save dislikes for Current Festival \(currentFestival?.name ?? "NIL"): ", error)
            }
        }
    }
    
    @Published var settings = FestivalSettings() {
        didSet {
            do {
                if let currFest = currentFestival {
                    let encoder = JSONEncoder()
                    let data = try encoder.encode(settings)
                    UserDefaults.standard.set(data, forKey: (saveName + currFest.id.uuidString + "/settings"))
                }
            } catch {
                print("Failed to save settings for Current Festival \(currentFestival?.name ?? "NIL"): ", error)
            }
        }
    }
    
    struct FestivalSettings: Encodable, Decodable {
        var festivalWeekend: String = "Both"
//        var festivalDays: Array<Bool> = []
        var festivalDays = [String : Bool]()
    }
    
    func getAmountOfFestivalDays(startDate: Date, endDate: Date) -> Int {
        let calendar = Calendar.current
        // Ensure we only compare at the day granularity
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let components = calendar.dateComponents([.day], from: start, to: end)
        if let dayCount = components.day {
            return dayCount + 1 // inclusive
        }
        return 0
    }
    
    func makeFestivalDays(startDate: Date, endDate: Date) -> [String: Bool] {
        var festivalDays = [String: Bool]()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // full day name, e.g. "Tuesday"

        var currentDate = startDate
        while currentDate <= endDate {
            let dayName = formatter.string(from: currentDate)
            festivalDays[dayName] = true

            // move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return festivalDays
    }
    
    func dayOfWeek(for date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Full day name, e.g. "Friday"
            return formatter.string(from: date)
        }
    
//    @Published var tags: [String : Array<String>] = [:] {
//        didSet {
//
//        }
//    }
    
//    @Published var dislikesList: Array<String> = [] {
//        didSet {
//            do {
//                if let currFest = currentFestival {
//                    let encoder = JSONEncoder()
//                    let data = try encoder.encode(favoriteList)
//                    UserDefaults.standard.set(data, forKey: (saveName + currFest.id.uuidString + "/favorites"))
//                }
//            } catch {
//                print("Failed to save favorites for Current Festival \(currentFestival?.name ?? "NIL"): ", error)
//            }
//        }
//    }
    
    @Published var festivalDrafts: Array<DataSet.Festival> = [] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(festivalDrafts)
                UserDefaults.standard.set(data, forKey: (saveName + "festivalDrafts"))
            } catch {
                print("Failed to save festivalDrafts:", error)
            }
        }
    }
    
    @Published var publishedFestivals: Array<DataSet.Festival> = [] {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(publishedFestivals)
                UserDefaults.standard.set(data, forKey: (saveName + "publishedFestivals"))
            } catch {
                print("Failed to save publishedFestivals:", error)
            }
        }
    }
    
    
    
    private var cancellables = Set<AnyCancellable>()
    
    init(name: String) {
        self.saveName = name
        
        if let draftsData = UserDefaults.standard.data(forKey: saveName + "festivalDrafts"),
           let tryDrafts = try? JSONDecoder().decode([DataSet.Festival].self, from: draftsData) {
            festivalDrafts = tryDrafts
        }
        
        if let publishedData = UserDefaults.standard.data(forKey: saveName + "publishedFestivals"),
           let tryPublished = try? JSONDecoder().decode([DataSet.Festival].self, from: publishedData) {
            publishedFestivals = tryPublished
        }
        
        
        
        // Load saved drafts
        if let draftsDataOLD = UserDefaults.standard.data(forKey: saveName + "draftsListOLD"),
           let tryDraftsOLD = try? JSONDecoder().decode([UUID].self, from: draftsDataOLD) {
            festivalDraftsID = tryDraftsOLD
        }
        
        // Load saved published festivals
        if let publishedDataOLD = UserDefaults.standard.data(forKey: saveName + "publishedListOLD"),
           let tryPublishedOLD = try? JSONDecoder().decode([UUID].self, from: publishedDataOLD) {
            publishedFestivalsID = tryPublishedOLD
        }
        
        // Auto-save drafts
        $festivalDraftsID
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: self.saveName + "draftsList")
                }
            }
            .store(in: &cancellables)
        
        // Auto-save published festivals
        $publishedFestivalsID
            .dropFirst()
            .sink { [weak self] newValue in
                guard let self = self else { return }
                if let encoded = try? JSONEncoder().encode(newValue) {
                    UserDefaults.standard.set(encoded, forKey: self.saveName + "publishedList")
                }
            }
            .store(in: &cancellables)
    }
    
//    func addToDrafts(id: UUID) {
//        if !festivalDraftsID.contains(id) {
//            festivalDraftsID.append(id)
//        }
//    }
    
//    func removeFromDrafts(id: UUID) {
//        festivalDraftsID.removeAll { $0 == id }
//    }
    
    func getDates(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        // Case: same day
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startDate)
        }

        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)

        formatter.dateFormat = "MMM d"
        let startString = formatter.string(from: startDate)

        if startMonth == endMonth {
            // Same month: "April 11 - 13"
            formatter.dateFormat = "d"
            let endDay = formatter.string(from: endDate)
            return "\(startString) - \(endDay)"
        } else {
            // Different months: "June 30 - July 3"
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        }
    }
    
    func getSecondWeekendText(startDate: Date, endDate: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM" // For month names
        
        // Add 7 days
        guard let shiftedStart = calendar.date(byAdding: .day, value: 7, to: startDate),
              let shiftedEnd = calendar.date(byAdding: .day, value: 7, to: endDate) else {
            return ""
        }
        
        return(getDates(startDate: shiftedStart, endDate: shiftedEnd))
    }
    
    
    
    func saveImageForFestival(_ image: UIImage, festivalID: UUID) -> String? {
        // Convert UUID to string
        let festivalIDString = festivalID.uuidString
        
        // Build relative path
        let relativePath = "\(festivalIDString)/logo.jpg"
        
        // Full file URL
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(relativePath)
        
        // Ensure folder exists
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            
            // Convert UIImage to JPEG data
            guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
            
            // Write to disk
            try data.write(to: fileURL)
            
            return relativePath // safe to store in UserDefaults
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }


    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    

    static func loadFestivalImage(path: String, completion: @escaping (UIImage?) -> Void) {
        // Case 1: Remote Firebase URL
        if path.hasPrefix("http") {
            guard let url = URL(string: path) else {
                completion(nil)
                return
            }
            // Fetch from network
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                } else {
                    print("Failed to load remote image:", error ?? "Unknown error")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                }
            }.resume()
            
        } else {
            // Case 2: Local file in Documents directory
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(path)
            
            let image = UIImage(contentsOfFile: fileURL.path)
            completion(image)
        }
    }
    
    
    func saveDraft(_ festival: DataSet.Festival) {
        var newFestival = festival
        newFestival.saveDate = Date()
        
        if let index = festivalDrafts.firstIndex(where: { $0.id == newFestival.id }) {
            festivalDrafts[index] = newFestival
        } else {
            festivalDrafts.append(newFestival)
        }
        festivalDrafts = Array(festivalDrafts)
        currentFestival = newFestival
    }

    func removeFromDrafts(id: UUID) {
        festivalDrafts.removeAll { $0.id == id }
        currentFestival = nil
    }
    
    func isFestivalDraft(id: UUID) -> Bool {
        return festivalDrafts.contains(where: {$0.id == id })
    }
    
    func moveToPublished(_ festival: DataSet.Festival) {
        removeFromDrafts(id: festival.id)
        if let index = publishedFestivals.firstIndex(where: { $0.id == festival.id }) {
            publishedFestivals[index] = festival
        } else {
            publishedFestivals.append(festival)
        }
        currentFestival = festival
    }
    
    func isNewFestival(_ festival: DataSet.Festival) -> Bool {
        let newFestival = DataSet.Festival.newFestival()
        return (festival.name == newFestival.name &&
                festival.verified == newFestival.verified &&
                festival.secondWeekend == newFestival.secondWeekend &&
                festival.location == newFestival.location &&
                festival.logoPath == newFestival.logoPath &&
                festival.artistList == newFestival.artistList &&
                festival.stageList == newFestival.stageList &&
                festival.website == newFestival.website &&
                festival.published == newFestival.published &&
                isSameDay(festival.saveDate, newFestival.saveDate) &&
                isSameDay(festival.startDate, newFestival.startDate) &&
                isSameDay(festival.endDate, newFestival.endDate)
        )
    }
    
    
    func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    

    func uploadFestival(_ festival: DataSet.Festival, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        var festivalToUpload = festival // Make a mutable copy
        festivalToUpload.published = true
        festivalToUpload.saveDate = Date()
        
        // Step 1: If there's a local logo image, upload it to Firebase Storage
        if let logoPath = festivalToUpload.logoPath {
            FestivalViewModel.loadFestivalImage(path: logoPath) { logo in
                if let logo = logo,
                   let imageData = logo.jpegData(compressionQuality: 0.8) {
                    let storageRef = storage.reference().child("festival_logos/\(festivalToUpload.id.uuidString).jpg")
                    
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    storageRef.putData(imageData, metadata: metadata) { _, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        // Step 2: Get the download URL and update festivalToUpload
                        storageRef.downloadURL { url, error in
                            if let error = error {
                                completion(.failure(error))
                                return
                            }
                            
                            festivalToUpload.logoPath = url?.absoluteString // Replace local path with download URL
                            
                            // Step 3: Upload festival to Firestore (merge)
                            do {
                                let festivalData = try Firestore.Encoder().encode(festivalToUpload)
                                db.collection("festivals")
                                    .document(festivalToUpload.id.uuidString)
                                    .setData(festivalData, merge: true) { error in
                                        if let error = error {
                                            completion(.failure(error))
                                        } else {
                                            self.moveToPublished(festivalToUpload)
                                            completion(.success(()))
                                        }
                                    }
                            } catch {
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        } else {
            do {
                let festivalData = try Firestore.Encoder().encode(festivalToUpload)
                db.collection("festivals")
                    .document(festivalToUpload.id.uuidString)
                    .setData(festivalData, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self.moveToPublished(festivalToUpload)
                            completion(.success(()))
                        }
                    }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func deleteFestival(_ festival: DataSet.Festival, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()

        // Step 1: Delete logo from Storage if it's a Firebase URL
        if let logoPath = festival.logoPath, logoPath.starts(with: "https://") {
            let storageRef = storage.reference(forURL: logoPath)
            storageRef.delete { error in
                if let error = error {
                    print("⚠️ Failed to delete logo: \(error.localizedDescription)")
                    // Continue anyway — not fatal to block Firestore delete
                }

                // Step 2: Delete the Firestore document
                db.collection("festivals")
                    .document(festival.id.uuidString)
                    .delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
            }
        } else {
            // No logo stored in Firebase, just delete Firestore doc
            db.collection("festivals")
                .document(festival.id.uuidString)
                .delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        }
    }
    
    func unpublishAndSave(_ festival: DataSet.Festival, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteFestival(festival) { result in
            switch result {
            case .success:
                self.publishedFestivals.removeAll { $0.id == festival.id }
                var festivalDraft = festival
                festivalDraft.published = false
                self.saveDraft(festivalDraft)
                completion(.success(()))
            case .failure(let error):
                print("❌ Error deleting festival: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    func unpublishAndDelete(_ festival: DataSet.Festival, completion: @escaping (Result<Void, Error>) -> Void) {
        deleteFestival(festival) { result in
            switch result {
            case .success:
                self.publishedFestivals.removeAll { $0.id == festival.id }
                self.currentFestival = nil
                completion(.success(()))
            case .failure(let error):
                print("❌ Error deleting festival: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func favoriteButtonPressed(_ id: String) {
        if let index = favoriteList.firstIndex(where: { $0 == id }) {
            favoriteList.remove(at: index)
        } else {
            favoriteList.append(id)
            if let index = dislikeList.firstIndex(where: { $0 == id }) {
                dislikeList.remove(at: index)
            }
        }
    }
    
    func dislikeButtonPressed(_ id: String) {
        if let index = dislikeList.firstIndex(where: { $0 == id }) {
            dislikeList.remove(at: index)
        } else {
            dislikeList.append(id)
            if let index = favoriteList.firstIndex(where: { $0 == id }) {
                favoriteList.remove(at: index)
            }
        }
    }
    
    func getFavorites() -> Array<DataSet.Artist> {
        var favorites = Array<DataSet.Artist>()
        if let currFest = currentFestival {
            for artist in currFest.artistList {
                if favoriteList.contains(artist.id) {
                    favorites.append(artist)
                }
            }
        }
        return favorites
    }

    
    func unpublish(id: UUID) {
        publishedFestivals.removeAll { $0.id == id }
        currentFestival = nil
    }
    
    func isPublishedFestival(id: UUID) -> Bool {
        return publishedFestivals.contains(where: {$0.id == id })
    }
    
    func eventAlreadyExists(id: UUID) -> Bool {
        return (isFestivalDraft(id: id) || isPublishedFestival(id: id))
    }
    
    func deleteEvent(id: UUID) {
        removeFromDrafts(id: id)
        unpublish(id: id)
    }
    
    //MARK: Festival Sort Section
    
    func getArtistDict(currList: Array<DataSet.Artist>, sort: DataSet.sortType, secondWeekend: Bool) -> [String : Array<DataSet.Artist>] {
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        switch(sort) {
        case .alpha:
            return(sortAlpha(currList: newList, secondWeekend: secondWeekend))
        case .billing:
            return(sortTier(currList: newList, secondWeekend: secondWeekend))
        case .day:
            return(sortDay(currList: newList, secondWeekend: secondWeekend))
        case .stage:
            return(sortStage(currList: newList, secondWeekend: secondWeekend))
        case .genre:
            return(sortGenre(currList: newList, secondWeekend: secondWeekend))
        }
    }
    
    func checkSettings(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Array<DataSet.Artist> {
        var newList = Array<DataSet.Artist>()
        for artist in currList {
            if settings.festivalDays[artist.day] ?? true {
                if secondWeekend {
                    if artist.weekend == "Both" || settings.festivalWeekend == "Both" || artist.weekend == settings.festivalWeekend {
                        newList.append(artist)
                    }
                } else {
                    newList.append(artist)
                }
            }
        }
        
        return newList
    }
    
    func sortAlpha(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> [String : Array<DataSet.Artist>] {
        var listByAplha = checkSettings(currList: currList, secondWeekend: secondWeekend)
        listByAplha.sort {
            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
        }
        return ["All Artists" : listByAplha]
    }
    
    func sortTier(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> [String : Array<DataSet.Artist>] {
        var dictionary = [String  : Array<DataSet.Artist>]()
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        for a in newList {
            if a.tier != NA_TITLE_BLOCK {
                if var artistArray = dictionary[a.tier] {
                    artistArray.append(a)
                    artistArray.sort {
                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
                    }
                    dictionary[a.tier] = artistArray
                } else {
                    dictionary[a.tier] = [a]
                }
            }
        }
        return dictionary
    }
    
    func sortDay(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> [String: Array<DataSet.Artist>] {
        var dictionary = [String: [DataSet.Artist]]()
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        
        for artist in newList {
            guard artist.day != NA_TITLE_BLOCK else { continue }
            
            // figure out which keys this artist belongs to
            let dayKeys: [String]
            if secondWeekend && settings.festivalWeekend == "Both" {
                switch artist.weekend {
                case "Weekend 1":
                    dayKeys = ["\(artist.day) (Weekend 1)"]
                case "Weekend 2":
                    dayKeys = ["\(artist.day) (Weekend 2)"]
                case "Both":
                    dayKeys = ["\(artist.day) (Weekend 1)", "\(artist.day) (Weekend 2)"]
                default:
                    dayKeys = []
                }
            } else {
                dayKeys = [artist.day]
            }
            
            // group into dictionary without sorting yet
            for key in dayKeys {
                dictionary[key, default: []].append(artist)
            }
        }
        
        // sort once per bucket
        for (day, artists) in dictionary {
            dictionary[day] = artists.sorted {
                if $0.tier == $1.tier {
                    removeArticles(str: $0.name) < removeArticles(str: $1.name)
                } else {
                    $0.tier < $1.tier
                }
            }
        }
        
        return dictionary
    }
    
    func sortStage(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> [String : Array<DataSet.Artist>] {
        var dictionary = [String  : Array<DataSet.Artist>]()
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        for a in newList {
            if a.stage != NA_TITLE_BLOCK {
                if var artistArray = dictionary[a.stage] {
                    artistArray.append(a)
                    artistArray.sort {
                        if $0.tier == $1.tier {
                            return removeArticles(str: $0.name) < removeArticles(str: $1.name)
                        }
                        return $0.tier < $0.tier
                    }
                    dictionary[a.stage] = artistArray
                } else {
                    dictionary[a.stage] = [a]
                }
            }
        }
        return dictionary
    }
    
    func sortGenre(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> [String: Array<DataSet.Artist>] {
        var dictionary = [String: Array<DataSet.Artist>]()
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        for a in newList {
            for genre in a.genres {
                if var artistArray = dictionary[genre] {
                    artistArray.append(a)
//                    artistArray.sort {
//                        return removeArticles(str: $0.name) < removeArticles(str: $1.name)
//                    }
                    dictionary[genre] = artistArray
                } else {
                    dictionary[genre] = [a]
                }
            }
        }
        
        return dictionary
            .filter { $0.value.count >= 3 }
            .mapValues { $0.sorted { removeArticles(str: $0.name) < removeArticles(str: $1.name) } }
    }
    
    func listHasDays(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortDay(currList: currList, secondWeekend: secondWeekend).isEmpty
    }
    
    func listHasGenres(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortGenre(currList: currList, secondWeekend: secondWeekend).isEmpty
    }
    
    func listHasStages(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortStage(currList: currList, secondWeekend: secondWeekend).isEmpty
    }
    
    func listHasTiers(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortTier(currList: currList, secondWeekend: secondWeekend).isEmpty
    }
    
    func getDayList(currArtist: DataSet.Artist, currList: [DataSet.Artist], secondWeekend: Bool) -> [DataSet.Artist] {
        var list = [DataSet.Artist]()
        
        if !secondWeekend || currArtist.weekend == "Both" {
            for artist in currList {
                if artist.day == currArtist.day {
                    list.append(artist)
                }
            }
        } else {
            for artist in currList {
                if artist.day == currArtist.day && artist.weekend == currArtist.weekend {
                    list.append(artist)
                }
            }
        }
        
        list = list.sorted {
            if $0.tier == $1.tier {
                removeArticles(str: $0.name) < removeArticles(str: $1.name)
            } else {
                $0.tier < $1.tier
            }
        }
        
        return list
    }
    
    func getWeekendList(weekend: String, currList: [DataSet.Artist]) -> [DataSet.Artist] {
        if weekend == "Both" { return currList }
        
        var list = [DataSet.Artist]()
        
        for artist in currList {
            if artist.weekend == weekend || artist.weekend == "Both" {
                list.append(artist)
            }
        }
        
        list = list.sorted {
            if $0.tier == $1.tier {
                removeArticles(str: $0.name) < removeArticles(str: $1.name)
            } else {
                $0.tier < $1.tier
            }
        }
        
        return list
    }
    
    
    func getStageList(stage: String, currList: [DataSet.Artist]) -> [DataSet.Artist] {
        var list = [DataSet.Artist]()
        
        for artist in currList {
            if artist.stage == stage {
                list.append(artist)
            }
        }
        
        list = list.sorted {
            if $0.tier == $1.tier {
                removeArticles(str: $0.name) < removeArticles(str: $1.name)
            } else {
                $0.tier < $1.tier
            }
        }
        
        return list
    }
    
    
    func getTierList(tier: String, currList: [DataSet.Artist]) -> [DataSet.Artist] {
        var list = [DataSet.Artist]()
        
        for artist in currList {
            if artist.tier == tier {
                list.append(artist)
            }
        }
        
        list = list.sorted {
            removeArticles(str: $0.name) < removeArticles(str: $1.name)
        }
        
        return list
    }
    
    
    func getGenreList(genre: String, currList: [DataSet.Artist]) -> [DataSet.Artist] {
        var list = [DataSet.Artist]()
        
        for artist in currList {
            if artist.genres.contains(genre) {
                list.append(artist)
            }
        }
        
        list = list.sorted {
            removeArticles(str: $0.name) < removeArticles(str: $1.name)
        }
        
        return list
    }
    
    
    func removeArticles(str: String) -> String {
        let articles = ["the ", "a ", "los ", "las ", "el ", "la "]
        for a in articles {
            if str.lowercased().hasPrefix(a) {
                return(String(str.dropFirst(a.count)).lowercased())
            }
        }
        return str.lowercased()
    }
    
    func shuffleArtist(currentList: Array<DataSet.Artist>, currentArtist: DataSet.Artist? = nil, secondWeekend: Bool) -> DataSet.Artist? {
        var shuffleList = checkSettings(currList: currentList, secondWeekend: secondWeekend)
        if let artist = currentArtist {
            shuffleList = shuffleList.filter{ $0 != artist }
        }
        if !shuffleList.isEmpty {
            return shuffleList.randomElement()!
        }
        return nil
    }
    
    
    
    
    
    let NA_TITLE_BLOCK = "-- N/A --"
    
    
    struct FestivalNavTarget: Hashable {
        let festival: DataSet.Festival
        let draftView: Bool
        var previewView: Bool = false
    }
    
//    struct
}
