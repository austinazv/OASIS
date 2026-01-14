//
//  SpotifyViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/16/25.
//

import Foundation
import SwiftUI
import UIKit

class SpotifyViewModel: ObservableObject {
    
    private let saveName: String
    
    @Published var isLoggedIn: Bool = false
    
    @Published var progress: Float = 0.0
    var playlistArtistCount: Int = 1
    
    @Published var isLoading = true
    
    init(name: String) {
        self.saveName = name
        isUserLoggedIn { [weak self] loggedIn in
            DispatchQueue.main.async {
                self?.isLoggedIn = loggedIn
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.isLoading = false
            }
        }
    }
    
    func isUserLoggedIn(completion: @escaping (Bool) -> Void) {
        if let expiry = UserDefaults.standard.value(forKey: String(self.saveName + "spotify_token_expiry")) as? TimeInterval {
            
            let currentTime = Date().timeIntervalSince1970
            if currentTime < expiry {
                print("✅ Token is still valid")
                completion(true)
            } else {
                print("⏳ Token expired, refreshing...")
                refreshAccessToken { newToken in
                    completion(newToken != nil)
                }
            }
        } else {
            print("❌ No access token found")
            completion(false)
        }
    }
    
    func exchangeCodeForToken(_ code: String) {
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        let bodyParams = "grant_type=authorization_code&code=\(code)&redirect_uri=\(SpotifyAuth.redirectURI)"
        request.httpBody = bodyParams.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error exchanging code for token: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let accessToken = json["access_token"] as? String,
                   let refreshToken = json["refresh_token"] as? String {
                    UserDefaults.standard.set(accessToken, forKey: String(self.saveName + "spotify_access_token"))
                    UserDefaults.standard.set(refreshToken, forKey: String(self.saveName + "spotify_refresh_token"))
                    UserDefaults.standard.set(Date().timeIntervalSince1970 + 3600, forKey: String(self.saveName + "spotify_token_expiry")) // Token valid for 1 hour
                    
                    self.fetchSpotifyUserProfile(accessToken: accessToken)
                }
            }
        }.resume()
    }
    
    func getValidAccessToken(completion: @escaping (String?) -> Void) {
        if let expiry = UserDefaults.standard.double(forKey: "\(saveName)spotify_token_expiry") as Double?,
           let token = UserDefaults.standard.string(forKey: "\(saveName)spotify_access_token") {
            
            let currentTime = Date().timeIntervalSince1970
            if currentTime < expiry {
                completion(token)
            } else {
                refreshAccessToken { newToken in
                    completion(newToken)
                }
            }
        } else {
            completion(nil)
        }
    }
    
    func fetchSpotifyUserProfile(accessToken: String) {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                return
            }
            
            do {
                let userProfile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
                
                // Store in UserDefaults or another state management system
                if let encodedProfile = try? JSONEncoder().encode(userProfile) {
                    UserDefaults.standard.set(encodedProfile, forKey: String(self.saveName + "spotify_user_profile"))
                }
                
            } catch {
                //                print("Failed to decode JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    
    
    func refreshAccessToken(completion: @escaping (String?) -> Void) {
        guard let refreshToken = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_refresh_token")) else {
            print("No refresh token found")
            completion(nil)
            return
        }
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)"
        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
        request.addValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
        
        let bodyParams = "grant_type=refresh_token&refresh_token=\(refreshToken)"
        request.httpBody = bodyParams.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error refreshing token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let newAccessToken = json["access_token"] as? String {
                
                UserDefaults.standard.set(newAccessToken, forKey: String(self.saveName + "spotify_access_token"))
                UserDefaults.standard.set(Date().timeIntervalSince1970 + 3600, forKey: String(self.saveName + "spotify_token_expiry")) // New expiry time
                
                print("🔄 Refreshed Access Token: \(newAccessToken)")
                completion(newAccessToken)
            } else {
                print("Failed to refresh access token")
                completion(nil)
            }
        }.resume()
    }
    
    func logoutFromSpotify() -> Bool {
        let defaults = UserDefaults.standard
        let keys = [
            String(self.saveName + "spotify_access_token"),
            String(self.saveName + "spotify_refresh_token"),
            String(self.saveName + "spotify_token_expiry")
        ]
        
        var success = false
        for key in keys {
            if defaults.object(forKey: key) != nil {
                defaults.removeObject(forKey: key)
                success = true
            }
        }
        
        defaults.synchronize()
        
        return success
    }


    func revokeSpotifyAccessToken(completion: @escaping (Bool) -> Void) {
        guard let _ = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_refresh_token")) else {
            print("⚠️ No refresh token found, already logged out")
            self.isLoggedIn = false
            completion(true)
            return
        }

        // Remove stored tokens
        let success = logoutFromSpotify()
        if success { self.isLoggedIn = false }
        completion(success)
    }
    
    func getValidSpotifyAccessToken(completion: @escaping (String?) -> Void) {
        // Check if a token exists and isn’t expired
        if let token = UserDefaults.standard.string(forKey: self.saveName + "spotify_access_token"),
           let expiryDate = UserDefaults.standard.object(forKey: self.saveName + "spotify_token_expiry") as? Date,
           Date() < expiryDate {
            completion(token)
            return
        }
        
        // Otherwise refresh
        self.refreshAccessToken { newToken in
            completion(newToken)
        }
    }
    
    func fetchArtistLatestAlbum(artistID: String, completion: @escaping (SpotifyAlbum?) -> Void) {
        // Step 1: Make sure we have a valid token
        getValidSpotifyAccessToken { accessToken in
            guard let accessToken = accessToken else {
                print("❌ Could not get valid Spotify access token")
                completion(nil)
                return
            }
            
            // Step 2: Use the token to fetch the artist’s most recent album
            self.fetchMostRecentAlbum(artistID: artistID, accessToken: accessToken) { album in
                if let album = album {
                    print("""
                    ✅ Latest album fetched:
                    Name: \(album.name)
                    Release Date: \(album.release_date)
                    Cover Art: \(album.images.first?.url ?? "No image")
                    Link: \(album.external_urls.spotify)
                    """)
                    completion(album)
                } else {
                    print("❌ No album found for artist \(artistID)")
                    completion(nil)
                }
            }
        }
    }

    
    func makeNewSpotifyPlaylist(
        artistList: [String],
        playlistName: String,
        isPublic: Bool,
        completion: @escaping (String?) -> Void
    ) {
        // ✅ Step 1: Make sure we have a valid token
        getValidSpotifyAccessToken { accessToken in
            guard let accessToken = accessToken else {
                print("❌ Could not retrieve valid Spotify access token")
                completion(nil)
                return
            }
            
            // ✅ Step 2: Check if we already have the user profile saved
            if let data = UserDefaults.standard.data(forKey: self.saveName + "spotify_user_profile"),
               let userProfile = try? JSONDecoder().decode(SpotifyUserProfile.self, from: data) {
                
                // 🎯 Proceed directly to playlist creation
                self.createPlaylistAndAddSongs(
                    userProfile: userProfile,
                    artistList: artistList,
                    playlistName: playlistName,
                    isPublic: isPublic,
                    accessToken: accessToken,
                    completion: completion
                )
                
            } else {
                print("⚠️ No user profile found, fetching now...")
                
                // ✅ Step 3: Fetch user profile if not already cached
                self.fetchSpotifyUserProfile(accessToken: accessToken) { userProfile in
                    guard let userProfile = userProfile else {
                        print("❌ Failed to fetch user profile")
                        completion(nil)
                        return
                    }
                    
                    // 🎯 Save user profile locally for next time
                    if let encoded = try? JSONEncoder().encode(userProfile) {
                        UserDefaults.standard.set(encoded, forKey: self.saveName + "spotify_user_profile")
                    }
                    
                    // ✅ Step 4: Now create the playlist
                    self.createPlaylistAndAddSongs(
                        userProfile: userProfile,
                        artistList: artistList,
                        playlistName: playlistName,
                        isPublic: isPublic,
                        accessToken: accessToken,
                        completion: completion
                    )
                }
            }
        }
    }
    
    
//    func makeNewSpotifyPlaylistOLD(artistList: Array<DataSet.artist>, playlistName: String, isPublic: Bool, completion: @escaping (String?) -> Void) {
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
    
    
    
    func extractArtistID(url: URL) -> String? {
        if let components = URLComponents(string: url.absoluteString),
           let lastPathComponent = components.path.split(separator: "/").last {
            return String(lastPathComponent)
        }
        return nil
    }
    
    
    
//    func createPlaylistAndAddSongs(userProfile: SpotifyUserProfile, artistList: Array<artist>, playlistName: String, isPublic: Bool, accessToken: String, completion: @escaping (String?) -> Void) {
//        let userID = userProfile.id
//
//        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
//
//            if let playlistID = playlistID {
//                let totalArtists = artistList.count
//                print ("TOTAL: \(totalArtists)")
//                var processedArtists = 0
//                let lock = NSLock() // Prevent race conditions when incrementing `processedArtists`
//                let checkCompletion = {
//                    lock.lock()
//                    processedArtists += 1
//                    print("Processed Artists: \(processedArtists) / Total Artists: \(totalArtists)")
//                    if processedArtists == totalArtists {
//                        print("✅ All \(processedArtists) artists processed. Calling final completion.")
//                        completion(playlistID)
//                    }
//                    lock.unlock()
//                }
//
//                for (index, artist) in artistList.enumerated() {
//                    print("Processing Artist \(index + 1): \(artist.name)")
//
//                    DispatchQueue.global().asyncAfter(deadline: .now() + (Double(index) / 2)) {
//                        print("Attempting to fetch top tracks for Artist #\(index + 1): \(artist.name)")
//                        if let artistID = self.extractArtistID(url: artist.artistPage) {
//
//                            self.getArtistTopTracks(artistID: artistID, accessToken: accessToken, playlistID: playlistID) {
//                                checkCompletion() // ✅ Ensures each artist is counted
//                            }
//                        } else {
//                            print("❌ Failed to extract artist ID from \(artist.artistPage)")
//                            checkCompletion() // ✅ Even if artist is skipped, still counts
//                        }
//                    }
//                }
//            } else {
//                print("❌ Failed to create playlist")
//                completion(nil)
//            }
//        }
//    }
    
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
    
//    func createPlaylistAndAddSongsOLD(userProfile: SpotifyUserProfile, artistList: Array<DataSet.artist>, playlistName: String, isPublic: Bool, accessToken: String, completion: @escaping (String?) -> Void) {
//        let userID = userProfile.id
//
//        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
//            
//            if let playlistID = playlistID {
//                self.playlistArtistCount = artistList.count
////                let totalArtists = artistList.count
////                print("TOTAL: \(totalArtists)")
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
////                                print(self.progress)
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



    
    
    func fetchSpotifyUserProfile(accessToken: String, completion: @escaping (SpotifyUserProfile?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw JSON response from Spotify API: \(jsonString)")
            } else {
                print("❌ Failed to convert API response to string")
            }
            do {
                let userProfile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
                let encodedData = try JSONEncoder().encode(userProfile)
                UserDefaults.standard.set(encodedData, forKey: String(self.saveName + "spotify_user_profile")) // ✅ Save to UserDefaults
                print("✅ User profile saved: \(userProfile.id)")
                completion(userProfile)
            } catch {
                print("❌ Failed to decode user profile: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
    
    
    var addedTrackIDs = Set<String>() // to prevent duplicates

    func createPlaylistAndAddSongs(
        userProfile: SpotifyUserProfile,
        artistList: [String],
        playlistName: String,
        isPublic: Bool,
        accessToken: String,
        completion: @escaping (String?) -> Void
    ) {
        
        self.progress = 0.0
        self.addedTrackIDs.removeAll()
        
        let userID = userProfile.id
        
        self.createPlaylist(userID: userID, accessToken: accessToken, playlistName: playlistName, isPublic: isPublic) { playlistID in
            guard let playlistID = playlistID else {
                print("❌ Failed to create playlist")
                completion(nil)
                return
            }
            
            self.playlistArtistCount = artistList.count
            let dispatchGroup = DispatchGroup()
            
            var allTrackURIs = [String]() // store all URIs for deduplication + batching
            
            for (index, artistID) in artistList.enumerated() {
                dispatchGroup.enter()
                
                DispatchQueue.global().asyncAfter(deadline: .now() + (Double(index) / 10.0)) {
                    self.getArtistTopTracks(artistID: artistID, accessToken: accessToken) { uris in
                        // Deduplicate
                        let newURIs = uris.filter {
                            let trackID = $0.replacingOccurrences(of: "spotify:track:", with: "")
                            return self.addedTrackIDs.insert(trackID).inserted
                        }
                        allTrackURIs.append(contentsOf: newURIs)
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                print("✅ All top tracks gathered. Total unique: \(allTrackURIs.count)")
                
                // Batch into groups of 100
                let batches = stride(from: 0, to: allTrackURIs.count, by: 100).map {
                    Array(allTrackURIs[$0 ..< min($0 + 100, allTrackURIs.count)])
                }
                
                let batchGroup = DispatchGroup()
                for batch in batches {
                    batchGroup.enter()
                    self.addTracksToPlaylistWithRetry(
                        playlistID: playlistID,
                        accessToken: accessToken,
                        trackURIs: batch,
                        completion: {
                            batchGroup.leave()
                        }
                    )
                }
                
                batchGroup.notify(queue: .main) {
                    print("🎉 All batches added successfully")
                    completion(playlistID)
                }
            }
        }
    }

    func getArtistTopTracks(artistID: String, accessToken: String, completion: @escaping ([String]) -> Void) {
        let topTracksURL = URL(string: "https://api.spotify.com/v1/artists/\(artistID)/top-tracks?market=US")!
        var request = URLRequest(url: topTracksURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching top tracks for \(artistID): \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tracks = json["tracks"] as? [[String: Any]] {
                    let uris = tracks.prefix(5).compactMap { $0["uri"] as? String }
                    completion(uris)
                } else {
                    completion([])
                }
            } catch {
                print("❌ Failed to parse JSON for \(artistID): \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }

    func addTracksToPlaylistWithRetry(
        playlistID: String,
        accessToken: String,
        trackURIs: [String],
        retryCount: Int = 0,
        maxRetries: Int = 5,
        completion: @escaping () -> Void
    ) {
        guard !trackURIs.isEmpty else {
            completion()
            return
        }
        
        let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["uris": trackURIs]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                self.retryAddTracks(playlistID, accessToken, trackURIs, retryCount, maxRetries, completion)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                self.retryAddTracks(playlistID, accessToken, trackURIs, retryCount, maxRetries, completion)
                return
            }
            
            if httpResponse.statusCode == 429 || httpResponse.statusCode == 502 {
                print("⚠️ Rate limit or server error: \(httpResponse.statusCode)")
                self.retryAddTracks(playlistID, accessToken, trackURIs, retryCount, maxRetries, completion)
                return
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Batch of \(trackURIs.count) tracks added")
                DispatchQueue.main.async {
                    self.progress += Float(trackURIs.count) / (Float(self.playlistArtistCount) * 5.0)
                    print("PROGRESS: \(self.progress)")
                }
                completion()
            } else {
                print("❌ Unexpected status: \(httpResponse.statusCode)")
                self.retryAddTracks(playlistID, accessToken, trackURIs, retryCount, maxRetries, completion)
            }
        }.resume()
    }

    private func retryAddTracks(
        _ playlistID: String,
        _ accessToken: String,
        _ trackURIs: [String],
        _ retryCount: Int,
        _ maxRetries: Int,
        _ completion: @escaping () -> Void
    ) {
        if retryCount < maxRetries {
            let retryAfter = min(2.0 * pow(2.0, Double(retryCount)), 60.0)
            print("🔄 Retrying batch in \(retryAfter) seconds (attempt \(retryCount + 1))")
            DispatchQueue.global().asyncAfter(deadline: .now() + retryAfter) {
                self.addTracksToPlaylistWithRetry(
                    playlistID: playlistID,
                    accessToken: accessToken,
                    trackURIs: trackURIs,
                    retryCount: retryCount + 1,
                    maxRetries: maxRetries,
                    completion: completion
                )
            }
        } else {
            print("❌ Max retries reached. Skipping this batch of \(trackURIs.count) tracks.")
            completion()
        }
    }

    
    
    
    
//
//    
//    
//    
    func createPlaylist(userID: String, accessToken: String, playlistName: String, isPublic: Bool, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.spotify.com/v1/users/\(userID)/playlists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Define the playlist details
        let body: [String: Any] = [
            "name": playlistName,
            "public": isPublic,
            "description": "Created using OASIS"
        ]
        
        // Convert to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        print("📡 Sending request to: \(url)")
        print("📜 Request body: \(body)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error creating playlist: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw API response: \(jsonString)")
            } else {
                print("❌ Failed to convert API response to string")
            }
            
            // Try to decode the response
            do {
                let playlistResponse = try JSONDecoder().decode(SpotifyPlaylist.self, from: data)
                print("Created Playlist: \(playlistResponse.name) (ID: \(playlistResponse.id))")
                UserDefaults.standard.set(playlistResponse.id, forKey: String(self.saveName + "spotify_playlist_id"))
                completion(playlistResponse.id)
            } catch {
                print("Failed to decode playlist response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }
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
//    func addTracksToPlaylist(
//        playlistID: String,
//        accessToken: String,
//        trackURIs: [String],
//        retryCount: Int = 0,
//        maxRetries: Int = 3,
//        completion: @escaping () -> Void
//    ) {
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
//            // Handle rate limiting
//            if httpResponse.statusCode == 429 {
//                let retryAfter = min(2.0 * pow(2.0, Double(retryCount)), 60.0)
//                print("⚠️ Rate limit exceeded (429). Retrying in \(retryAfter) seconds...")
//
//                if retryCount < maxRetries {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + retryAfter) {
//                        self.addTracksToPlaylist(
//                            playlistID: playlistID,
//                            accessToken: accessToken,
//                            trackURIs: trackURIs,
//                            retryCount: retryCount + 1,
//                            maxRetries: maxRetries,
//                            completion: completion
//                        )
//                    }
//                } else {
//                    print("❌ Max retries reached for rate limit. Skipping.")
//                    completion()
//                }
//                return
//            }
//
//            // Handle server errors
//            if httpResponse.statusCode == 502 {
//                let retryAfter = min(2.0 * pow(2.0, Double(retryCount)), 60.0)
//                print("⚠️ Server error (502). Retrying in \(retryAfter) seconds...")
//
//                if retryCount < maxRetries {
//                    DispatchQueue.global().asyncAfter(deadline: .now() + retryAfter) {
//                        self.addTracksToPlaylist(
//                            playlistID: playlistID,
//                            accessToken: accessToken,
//                            trackURIs: trackURIs,
//                            retryCount: retryCount + 1,
//                            maxRetries: maxRetries,
//                            completion: completion
//                        )
//                    }
//                } else {
//                    print("❌ Max retries reached for server errors. Skipping.")
//                    completion()
//                }
//                return
//            }
//
//            // Handle successful responses
//            if (200...299).contains(httpResponse.statusCode) {
//                do {
//                    let responseJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//                    if let snapshotID = responseJSON?["snapshot_id"] as? String, !snapshotID.isEmpty {
//                        print("✅ Tracks added successfully: \(snapshotID)")
//                    } else {
//                        print("⚠️ Success status but no snapshot_id. Assuming tracks were added.")
//                    }
//
//                    DispatchQueue.main.async {
//                        self.progress += Float(1.0) / Float(self.playlistArtistCount)
//                        print("PROGRESS: \(self.progress)")
//                    }
//                    completion()
//                    return
//                } catch {
//                    print("⚠️ Success status but failed to parse JSON. Assuming tracks were added.")
//                    DispatchQueue.main.async {
//                        self.progress += Float(1.0) / Float(self.playlistArtistCount)
//                    }
//                    completion()
//                    return
//                }
//            }
//
//            // Non-success case (not retried, just logged)
//            print("❌ Unexpected status code: \(httpResponse.statusCode)")
//            completion()
//
//        }.resume()
//    }



    
    
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
////                self.ERRORCOUNT += 1
////                print("ERROR: \(self.ERRORCOUNT)")
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
////                self.ERRORCOUNT += 1
////                print("ERROR: \(self.ERRORCOUNT)")
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
////                        print("Add \(Float(1.0)/Float(self.playlistArtistCount))")
//                        self.progress += Float(1.0)/Float(self.playlistArtistCount)
//                        print("PROGRESS: \(self.progress)")
////                        self.progress = max(Float(index) / Float(artistList.count), self.progress)
//                    }
//                    completion()
//                } else {
////                    self.ERRORCOUNT += 1
////                    print("ERROR: \(self.ERRORCOUNT)")
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

    func getPlaylistURL() -> URL? {
        if let playlistID = UserDefaults.standard.string(forKey: String(self.saveName + "spotify_playlist_id")) {
            return URL(string: "https://open.spotify.com/playlist/\(playlistID)")
        }
        return nil
    }
    
    
    
    func fetchMostRecentAlbum(artistID: String, accessToken: String, completion: @escaping (SpotifyAlbum?) -> Void) {
        let urlString = "https://api.spotify.com/v1/artists/\(artistID)/albums?include_groups=album&market=US&limit=20"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(AlbumResponse.self, from: data)
                
                // Sort by release_date (descending)
                let sorted = decoded.items.sorted {
                    $0.release_date > $1.release_date
                }
                
                completion(sorted.first)
                
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    func fetchArtistThisIsPlaylist(artistName: String, completion: @escaping (Playlist?) -> Void) {
        getValidSpotifyAccessToken { accessToken in
            guard let accessToken = accessToken else {
                print("❌ Could not get valid Spotify access token")
                completion(nil)
                return
            }
            
            self.fetchThisIsPlaylist(artistName: artistName, accessToken: accessToken) { playlist in
                if let playlist = playlist {
                    print("""
                    ✅ Found "This Is \(artistName)" playlist:
                    Name: \(playlist.name)
                    URL: \(playlist.external_urls.spotify)
                    Cover: \(playlist.images?.first?.url ?? "No image")
                    Owner: \(playlist.owner.display_name ?? playlist.owner.id)
                    """)
                    completion(playlist)
                } else {
                    print("❌ No official 'This Is \(artistName)' playlist found")
                    completion(nil)
                }
            }
        }
    }
    
    func fetchThisIsPlaylist(artistName: String, accessToken: String, completion: @escaping (Playlist?) -> Void) {
        // 1️⃣ Encode the query
        let query = "This Is \(artistName)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artistName
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=playlist&limit=10" // slightly higher limit
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        // 2️⃣ Perform the request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching This Is playlist: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            // 3️⃣ Optional: print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("RAW JSON: \(jsonString)")
            }
            
            do {
                let decoded = try JSONDecoder().decode(PlaylistSearchResponse.self, from: data)
                
                // 4️⃣ Remove nulls from items
                let validPlaylists = decoded.playlists.items.compactMap { $0 }
                
                // 5️⃣ Look for playlist starting with "This Is <ArtistName>"
                // Normalize both strings to lowercase
                let normalizedArtist = artistName.lowercased()
                let thisIsPlaylist = validPlaylists.first { playlist in
                    playlist.name.lowercased().hasPrefix("this is \(normalizedArtist)")
                }
                
                completion(thisIsPlaylist)
                
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }

    
    func openSpotifyLogin() {
        UIApplication.shared.open(SpotifyAuth.authURL)
    }
    
    struct SpotifyUserProfile: Codable {
        let display_name: String?
        let id: String
        let email: String?
        let images: [SpotifyImage]?
        let followers: SpotifyFollowers?
    }
    
    struct SpotifyImage: Codable {
        let url: String
    }
    
    struct SpotifyFollowers: Codable {
        let total: Int
    }
    
    struct SpotifyPlaylist: Codable {
        let id: String
        let name: String
    }
    
    struct SpotifyArtist: Identifiable, Decodable {
        let id: String
        let name: String
        let images: [SpotifyImage]

        var imageURL: URL? {
            images.first?.url
        }

        struct SpotifyImage: Decodable {
            let url: URL
        }
    }
    
    struct SpotifyAlbum: Decodable {
        let name: String
        let release_date: String
        let images: [SpotifyImage]
        let external_urls: ExternalURLs
        
        struct SpotifyImage: Decodable {
            let url: String
            let height: Int?
            let width: Int?
        }
        
        struct ExternalURLs: Decodable {
            let spotify: String
        }
    }
    
    struct AlbumResponse: Decodable {
        let items: [SpotifyAlbum]
    }
    
    struct SpotifySearchResponse: Decodable {
        let artists: ArtistItems
        
        struct ArtistItems: Decodable {
            let items: [SpotifyArtistRaw]
        }
        
        struct SpotifyArtistRaw: Decodable {
            let id: String
            let name: String
            let genres: [String]
            let images: [SpotifyImage]
            
            struct SpotifyImage: Decodable {
                let url: String
            }
        }
    }
    
    struct PlaylistSearchResponse: Decodable {
        let playlists: Playlists
        
        struct Playlists: Decodable {
            let items: [Playlist?]
        }
    }

    struct Playlist: Decodable {
        let name: String
        let description: String?
        let images: [SpotifyImage]?
        let external_urls: ExternalURLs
        let owner: Owner
        
        struct SpotifyImage: Decodable {
            let url: String
        }
        
        struct ExternalURLs: Decodable {
            let spotify: String
        }
        
        struct Owner: Decodable {
            let id: String
            let display_name: String?
        }
    }
}
