//
//  ExploreViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 9/13/25.
//

import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Search

class ExploreViewModel: ObservableObject {
    @Published var festivals: [DataSet.Festival] = []
    @Published var isLoading = false
    @Published var searchIsLoading = false
    @Published var errorMessage: String?
    
    let client: SearchClient

    init() {
        isLoading = true
        
        do {
            client = try SearchClient(
                appID: "OJ3ASBA9K5",
                apiKey: "8c2bcea1fd5707e2e7227ba6ae5ae967"
            )
            print("Client created successfully")
        } catch {
            fatalError("Failed to create Algolia client: \(error)")
        }
        
        fetchVerifiedFestivals()
    }
    
    func fetchVerifiedFestivals() {
//        guard !isLoading else { return } // prevent double fetch
//        isLoading = true
        
        downloadVerifiedFestivals { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let festivals):
                    self?.festivals = festivals
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func downloadVerifiedFestivals(completion: @escaping (Result<[DataSet.Festival], Error>) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        // Start of "today" in the user's current calendar/time zone
        let startOfToday = Calendar.current.startOfDay(for: Date())
        
        db.collection("festivals")
            .whereField("verified", isEqualTo: true)
            // Only festivals starting today or later (ignores time-of-day by using startOfDay)
            .whereField("startDate", isGreaterThanOrEqualTo: startOfToday)
            // Optional but recommended for deterministic ordering and to align with range filter
            .order(by: "startDate", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var festivals: [DataSet.Festival] = []
                let group = DispatchGroup()
                
                for doc in documents {
                    do {
                        var festival = try doc.data(as: DataSet.Festival.self)
                        
                        // Handle logo image if URL exists
                        if let logoURLString = festival.logoPath, let logoURL = URL(string: logoURLString) {
                            group.enter()
                            let storageRef = storage.reference(forURL: logoURL.absoluteString)
                            storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
                                defer { group.leave() }
                                
                                if let data = data, let image = UIImage(data: data) {
                                    if let localURL = self.saveImageForFestival(image, festivalID: festival.id) {
                                        festival.logoPath = localURL
                                    }
                                }
                            }
                        }
                        
                        festivals.append(festival)
                        
                    } catch {
                        print("Failed to decode festival:", error)
                    }
                }
                
                // Wait for all image downloads to finish
                group.notify(queue: .main) {
                    completion(.success(festivals))
                }
            }
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
    
    @MainActor
    func fetchFestivalsByIDs(
        ids: [String]
//        client: SearchClient
    ) async -> [DataSet.Festival] {
        
        guard !ids.isEmpty else { return [] }
        
        var festivals: [DataSet.Festival] = []
        
        let filters = ids.map { "objectID:\($0)" }.joined(separator: " OR ")
        
        let request = SearchForHits(
            query: "", // empty query, since we only want by ID
            filters: filters,
            indexName: "festivals"
        )
        
        let searchParams = SearchMethodParams(requests: [.searchForHits(request)])
        
        do {
            let hits: [DataSet.Festival] = try await client.searchForHits(
                searchMethodParams: searchParams
            )
            festivals = hits
        } catch {
            print("Algolia fetch by IDs failed:", error)
        }
        
        return festivals
    }

    
    @MainActor
    func searchAlgoliaDatabase(
        query: String,
        searchBy: SearchBy,
        searchDate: SearchDate,
        date1: Date,
        date2: Date,
        verified: Bool
    ) async -> [DataSet.Festival] {
        
        searchIsLoading = true
        
        var filters: [String] = []
        
        // VERIFIED FILTER
        if verified {
            filters.append("verified:true")
        }
        
        // Convert dates to UNIX timestamps
        let ts1 = Int(date1.timeIntervalSince1970)
        let ts2 = Int(date2.timeIntervalSince1970)
        
        // DATE FILTER
        switch searchDate {
        case .After:
            filters.append("adjustedEndDate >= \(ts1)")
        case .Before:
            filters.append("startDate <= \(ts1)")
        case .Between:
            filters.append("startDate <= \(ts2)")
            filters.append("adjustedEndDate >= \(ts1)")
        case .On:
            filters.append("startDate <= \(ts1)")
            filters.append("adjustedEndDate >= \(ts1)")
        }
        
        // RESTRICT SEARCHABLE ATTRIBUTE
        let searchableAttribute: String
        switch searchBy {
        case .Name:
            searchableAttribute = "name"
        case .Location:
            searchableAttribute = "location"
        case .Artist:
            searchableAttribute = "artistNames"
        case .Creator:
            searchableAttribute = "ownerName"
        }
        
        let joinedFilters = filters.joined(separator: " AND ")
        
        // Build a single SearchForHits request targeting the "festivals" index
        let request = SearchForHits(
            query: query,
            filters: joinedFilters.isEmpty ? nil : joinedFilters,
            restrictSearchableAttributes: [searchableAttribute],
            indexName: "festivals"
        )
        
        // Wrap in SearchQuery and create SearchMethodParams
        let searchParams = SearchMethodParams(requests: [.searchForHits(request)])
        
        do {
            // Explicitly constrain the generic to your hit type
            let algoliaHits: [AlgoliaFestival] = try await client.searchForHits(
                searchMethodParams: searchParams
            )
            let festivals = convertAlgoliaFestivalsToFestivals(algoliaHits)
            searchIsLoading = false
            return festivals
        } catch {
            print("Algolia search failed:", error)
            searchIsLoading = false
            return []
        }
    }
    
    enum SearchBy {
        case Name
        case Location
        case Artist
        case Creator
    }
    
    enum SearchDate {
        case After
        case Before
        case Between
        case On
    }
    
    
    func convertAlgoliaArtistsToArtists(_ algoliaArtists: [AlgoliaArtist]?) -> [DataSet.Artist] {
        guard let algoliaArtists = algoliaArtists else { return [] }
        return algoliaArtists.map { aa in
            DataSet.Artist(
                id: aa.id,
                name: aa.name,
                genres: aa.genres,
                imageURL: aa.imageURL,
                imageLocalPath: aa.imageLocalPath,
                day: aa.day ?? "-- N/A --",
                weekend: aa.weekend ?? "Both",
                tier: aa.tier ?? "-- N/A --",
                stage: aa.stage ?? "-- N/A --"
                // Future performanceDate can be added here if needed:
                // performanceDate: aa.performanceDate != nil ? Date(timeIntervalSince1970: aa.performanceDate! / 1000) : nil
            )
        }
    }
    
    func convertAlgoliaFestivalsToFestivals(_ algoliaFestivals: [AlgoliaFestival]) -> [DataSet.Festival] {
        return algoliaFestivals.map { af in
            DataSet.Festival(
                id: UUID(), // or use af.id / af.objectID
                ownerID: af.ownerID,
                ownerName: af.ownerName,
                saveDate: af.saveDate != nil ? Date(timeIntervalSince1970: af.saveDate! / 1000) : Date(),
                verified: af.verified,
                name: af.name,
                startDate: Date(timeIntervalSince1970: af.startDate / 1000),
                endDate: Date(timeIntervalSince1970: af.endDate / 1000),
                secondWeekend: af.secondWeekend,
                location: af.location,
                logoPath: af.logoPath,
                artistList: convertAlgoliaArtistsToArtists(af.artistList),
                stageList: af.stageList ?? [],
                website: af.website,
                published: af.published
            )
        }
    }
    
    
    struct AlgoliaFestival: Codable {
        var objectID: String
        var id: String?
        var ownerID: String
        var ownerName: String
        var saveDate: Double?            // milliseconds
        var verified: Bool
        var name: String
        var startDate: Double            // milliseconds
        var endDate: Double              // milliseconds
        var secondWeekend: Bool
        var location: String?
        var logoPath: String?
        var artistList: [AlgoliaArtist]?
        var stageList: [String]?
        var website: String?
        var published: Bool
    }
    
    struct AlgoliaArtist: Codable {
        var id: String
        var name: String
        var genres: [String]
        var imageURL: String
        var imageLocalPath: String?
        var day: String?
        var weekend: String?
        var tier: String?
        var stage: String?
//        var performanceDate: Double? // Future Date field in milliseconds
    }

}
