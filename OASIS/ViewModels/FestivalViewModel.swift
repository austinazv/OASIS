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
    
    private let db = Firestore.firestore()
    
    @Published var festivalDraftsID: Array<UUID> = []
    @Published var publishedFestivalsID: Array<UUID> = []
    
    @Published var myFestivals = Array<DataSet.Festival>() {
        didSet {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(myFestivals)
                UserDefaults.standard.set(data, forKey: (saveName + "/myFestivals"))
            } catch {
                print("Failed to save myFestival: \(myFestivals): ", error)
            }
        }
    }
    
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
    
    private var userId: String {
        guard let uid = Auth.auth().currentUser?.uid else {
            fatalError("❌ No logged-in user found")
        }
        return uid
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
        
        if let myFestivalsData = UserDefaults.standard.data(forKey: saveName + "/myFestivals"),
           let tryMyFestivals = try? JSONDecoder().decode([DataSet.Festival].self, from: myFestivalsData) {
            myFestivals = tryMyFestivals
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
        
        silentlyRefreshFestivalsIfNeeded()
    }
    
    
    func festivalIsFavorited(festivalID: UUID) -> Bool {
        return myFestivals.contains(where: { $0.id == festivalID })
    }
    
//    func addFestivalToMyFestivals
    func festivalStarPressed(festival: DataSet.Festival) {
        if let index = myFestivals.firstIndex(where: { $0.id == festival.id }) {
            myFestivals.remove(at: index)
        } else {
            myFestivals.append(festival)
            cacheFestivalAssets(festival)
        }
    }
    
    func cacheFestivalAssets(_ festival: DataSet.Festival) {
        Task {
            // Cache festival logo
            if let url = festival.logoPath {
                await cacheImageIfNeeded(url)
            }

            // Cache each artist image
            for artist in festival.artistList {
                await cacheImageIfNeeded(artist.imageURL)
            }
        }
    }

    func cacheImageIfNeeded(_ urlString: String) async {
        guard ImageCache.shared.getCachedImage(for: urlString) == nil else { return }

        guard let url = URL(string: urlString),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let _ = UIImage(data: data) else { return }

        ImageCache.shared.cacheImage(data, for: urlString)
    }
    
    func silentlyRefreshFestivalsIfNeeded() {
        guard !myFestivals.isEmpty else { return }

        let ids = myFestivals.map { $0.id.uuidString }
        let db = Firestore.firestore()

        Task.detached(priority: .background) {
            do {
                let snapshot = try await db
                    .collection("festivals")
                    .whereField(FieldPath.documentID(), in: ids)
                    .getDocuments()

                var updated = self.myFestivals
                var didChange = false

                for doc in snapshot.documents {
                    let firestoreFestival = try doc.data(as: DataSet.Festival.self)

                    if let index = updated.firstIndex(where: { $0.id == firestoreFestival.id }) {
                        let localFestival = updated[index]

                        if firestoreFestival.saveDate > localFestival.saveDate {
                            updated[index] = firestoreFestival
                            didChange = true
                        }
                    }
                }

                if didChange {
                    let newFestivals = updated
                    await MainActor.run {
                        self.myFestivals = newFestivals
                    }
                }
            } catch {
                // totally fine — offline or transient failure
                print("Silent festival sync failed:", error)
            }
        }
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
        
        if festivalToUpload.ownerName == "Unknown" {
            let userDocRef = db.collection("users").document(festivalToUpload.ownerID)
            userDocRef.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists,
                   let userData = snapshot.data(),
                   let userName = userData["name"] as? String {
                    festivalToUpload.ownerName = userName
                }
            }
        }
        
        let artistNames = festivalToUpload.artistList.map { $0.name }
        
        let adjustedEndDate = festivalToUpload.secondWeekend
                ? festivalToUpload.endDate.addingTimeInterval(7 * 24 * 60 * 60)
                : festivalToUpload.endDate
        
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
                                var festivalData = try Firestore.Encoder().encode(festivalToUpload)
                                festivalData["artistNames"] = artistNames
                                festivalData["adjustedEndDate"] = adjustedEndDate
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
                var festivalData = try Firestore.Encoder().encode(festivalToUpload)
                festivalData["artistNames"] = artistNames
                festivalData["adjustedEndDate"] = adjustedEndDate
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
//            unlikeArtist(id)
        } else {
            favoriteList.append(id)
            if let index = dislikeList.firstIndex(where: { $0 == id }) {
                dislikeList.remove(at: index)
            }
            //TODO: Add festival to favorites
//            likeArtist(id)
        }
        updateFavoritesList()
    }
    
    func updateFavoritesList() {
        guard let festival = currentFestival else {
            print("⚠️ No current festival selected")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.getDocument { snapshot, _ in
            // Get existing festivalFavorites dictionary, or start empty
            var festivalFavorites = snapshot?.data()?["festivalFavorites"] as? [String: [String]] ?? [:]

            // Update or add the festival
            festivalFavorites[festival.id.uuidString] = self.favoriteList

            // Write back the full dictionary
            userRef.setData(
                ["festivalFavorites": festivalFavorites],
                merge: true
            ) { _ in
                // Ignore errors — app works offline
            }
        }
    }

    
//    func updateFavoritesList() {
//        guard let festival = currentFestival else {
//            print("⚠️ No current festival selected")
//            return
//        }
//        
//        let db = Firestore.firestore()
//        let userRef = db.collection("users").document(userId)
//
//        userRef.getDocument { snapshot, _ in
//            // Start with an empty array if the field doesn't exist
//            var festivalFavorites: [[String: [String]]] =
//                snapshot?.data()?["festivalFavorites"] as? [[String: [String]]] ?? []
//
//            var didUpdate = false
//
//            // Try to update existing festival entry
//            for index in 0..<festivalFavorites.count {
//                if festivalFavorites[index][festival.id.uuidString] != nil {
//                    festivalFavorites[index][festival.id.uuidString] = self.favoriteList
//                    didUpdate = true
//                    break
//                }
//            }
//
//            // If festival entry does not exist, append it
//            if !didUpdate {
//                festivalFavorites.append([festival.id.uuidString: self.favoriteList])
//            }
//
//            // Write back to Firestore (silent failure allowed)
//            userRef.setData(
//                ["festivalFavorites": festivalFavorites],
//                merge: true
//            ) { _ in
//                // Intentionally ignore errors
//                // App continues to function even if offline
//            }
//        }
//    }

    
    
    
    func likeArtist(_ artistId: String) {
        guard let festival = currentFestival else {
            print("⚠️ No current festival selected")
            return
        }
        
        let festivalRef = db
            .collection("users")
            .document(userId)
            .collection("favorites")
            .document(festival.id.uuidString)
        
        festivalRef.getDocument { document, error in
            if let error = error {
                print("❌ Error fetching festival: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                // Festival exists → add artist to array
                festivalRef.updateData([
                    "artists": FieldValue.arrayUnion([artistId])
                ]) { error in
                    if let error = error {
                        print("❌ Error adding artist: \(error.localizedDescription)")
                    } else {
                        print("✅ Added artist \(artistId) to existing festival \(festival.name)")
                    }
                }
            } else {
                // Festival doesn't exist → create it with first artist
                let newFestivalData: [String: Any] = [
                    "name": festival.name,
                    "artists": [artistId]
                ]
                
                festivalRef.setData(newFestivalData) { error in
                    if let error = error {
                        print("❌ Error creating new festival: \(error.localizedDescription)")
                    } else {
                        print("✅ Created new festival \(festival.name) with artist \(artistId)")
                    }
                }
            }
        }
    }
    
    func unlikeArtist(_ artistId: String) {
        guard let festival = currentFestival else {
            print("⚠️ No current festival selected")
            return
        }
        
        let festivalRef = db
            .collection("users")
            .document(userId)
            .collection("favorites")
            .document(festival.id.uuidString)
        
        // First, fetch the festival document
        festivalRef.getDocument { document, error in
            if let error = error {
                print("❌ Error fetching festival: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                print("⚠️ Festival document does not exist, nothing to remove")
                return
            }
            
            // Remove the artistId from the artists array
            festivalRef.updateData([
                "artists": FieldValue.arrayRemove([artistId])
            ]) { error in
                if let error = error {
                    print("❌ Error removing artist: \(error.localizedDescription)")
                } else {
                    print("✅ Removed artist \(artistId) from festival \(festival.name)")
                }
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
                unlikeArtist(id)
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
    
    func getArtistListFromID(artistIDs: Array<String>, festival: DataSet.Festival) -> Array<DataSet.Artist> {
        let idSet = Set(artistIDs)
        return festival.artistList.filter { idSet.contains($0.id) }
    }
    
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
            return(sortGenre(currList: newList, secondWeekend: secondWeekend).allGenres)
        case .addDate:
            return(sortDateAdded(currList: newList))
        case .modifyDate:
            return(sortDateModified(currList: newList))
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
    
    func sortGenre(currList: [DataSet.Artist], secondWeekend: Bool) -> (allGenres: [String: [DataSet.Artist]], topGenres: [String: [DataSet.Artist]]) {

        // Build the unsorted dictionary
        var dictionary = [String: [DataSet.Artist]]()
        let newList = checkSettings(currList: currList, secondWeekend: secondWeekend)
        for artist in newList {
            for genre in artist.genres {
                dictionary[genre, default: []].append(artist)
            }
        }

        // Filter and sort artist arrays by name (same behavior as before)
        let sortedDictionary: [String: [DataSet.Artist]] = dictionary
            .filter { $0.value.count >= 3 }
            .mapValues { artists in
                artists.sorted { removeArticles(str: $0.name) < removeArticles(str: $1.name) }
            }

        // Create an array of (key, value) tuples with explicit types, then sort by count desc
        let sortedArray: [(String, [DataSet.Artist])] = sortedDictionary
            .map { (key: $0.key, value: $0.value) }        // make array of tuples
            .sorted { $0.1.count > $1.1.count }            // sort by counts descending

        // Take the first 5 and build the top-five dictionary
        let topFiveArray: [(String, [DataSet.Artist])] = Array(sortedArray.prefix(5))
        let topFive: [String: [DataSet.Artist]] = Dictionary(uniqueKeysWithValues: topFiveArray)

        return (allGenres: sortedDictionary, topGenres: topFive)
    }
    
    func sortDateAdded(currList: Array<DataSet.Artist>) -> [String : Array<DataSet.Artist>] {
        let returnList = currList.sorted(by: {
            $0.addDate > $1.addDate
        })
        return ["" : returnList]
//        return ["" : currList]
    }
    
    func sortDateModified(currList: Array<DataSet.Artist>) -> [String : Array<DataSet.Artist>] {
        let returnList = currList.sorted(by: {
            $0.modifyDate > $1.modifyDate
        })
        return ["" : returnList]
//        return ["" : currList]
    }
    
    func reverseArtistDict(currDict: [String : Array<DataSet.Artist>]) -> [String : Array<DataSet.Artist>] {
        let newList = Array(currDict.values.first!.reversed())
        return ["" : newList]
    }

    
    func listHasDays(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortDay(currList: currList, secondWeekend: secondWeekend).isEmpty
    }
    
    func listHasGenres(currList: Array<DataSet.Artist>, secondWeekend: Bool) -> Bool {
        return !sortGenre(currList: currList, secondWeekend: secondWeekend).allGenres.isEmpty
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
            shuffleList = shuffleList.filter { $0 != artist }
        }
        shuffleList = shuffleList.filter { !dislikeList.contains($0.id) }
        if !shuffleList.isEmpty {
            return shuffleList.randomElement()!
        }
        return nil
    }
    
    
    func splitFestivals(_ festivals: [DataSet.Festival]) -> (attended: [DataSet.Festival], upcoming: [DataSet.Festival]) {
        let today = Date()
        
        var attendedFestivals: [DataSet.Festival] = []
        var upcomingFestivals: [DataSet.Festival] = []
        
        for festival in festivals {
            // Adjust endDate if it's a second weekend
            let adjustedEndDate = festival.secondWeekend
                ? Calendar.current.date(byAdding: .day, value: 7, to: festival.endDate) ?? festival.endDate
                : festival.endDate
            
            if adjustedEndDate >= today {
                upcomingFestivals.append(festival)
            } else {
                attendedFestivals.append(festival)
            }
        }
        
        return (attended: attendedFestivals, upcoming: upcomingFestivals)
    }

    
    
    
    
    
    let NA_TITLE_BLOCK = "-- N/A --"
    
    
    struct FestivalNavTarget: Hashable {
        let festival: DataSet.Festival
        let draftView: Bool
        var previewView: Bool = false
    }
    
//    struct
}
