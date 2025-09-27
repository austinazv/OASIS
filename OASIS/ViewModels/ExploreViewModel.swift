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

class ExploreViewModel: ObservableObject {
    @Published var festivals: [DataSet.Festival] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        isLoading = true
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
        
        db.collection("festivals")
            .whereField("verified", isEqualTo: true)
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
}

