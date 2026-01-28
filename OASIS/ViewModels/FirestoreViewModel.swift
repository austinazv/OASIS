//
//  FirestoreViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/20/25.
//

import Foundation

import Foundation
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CryptoKit

class FirestoreViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var hasAcctName: Bool = false
    @Published var phoneConnected: Bool = false
    
    @Published var myUserProfile = UserProfile()
    @Published var usersByID: [String: UserProfile] = [:]
    @Published var mySocialGroups = Array<SocialGroup>()
    
    @Published var socialLoading = true

//    @Published var myFollowing = Array<UserProfile>()
//    @Published var myFollowers = Array<UserProfile>()
    
    
    var currentUploadTask: StorageUploadTask?
    @Published var isUploading = false

    private let saveName: String
    
    var publicFestivals: Array<DataSet.Festival>
    
    let db = Firestore.firestore()
    
    @Published var profileDidChange = false
    
    
    
    init(name: String) {
        self.saveName = name
        self.publicFestivals = []
        self.isLoggedIn = (Auth.auth().currentUser != nil)

        Task {
            defer {
                Task { @MainActor in
                    self.socialLoading = false
                }
            }

            await loadMyUserProfile()
            guard isLoggedIn else { return }

            let hasPhone = await userHasPhoneHash()
            await MainActor.run {
                self.phoneConnected = hasPhone
            }
            guard hasPhone else { return }

            do {
                // 1️⃣ Fetch groups (final usable structs)
                let groups = try await fetchGroups(from: myUserProfile.safeGroups)

                // 2️⃣ Collect all user IDs
                let allUserIDs = Array(
                    Set(
                        myUserProfile.safeFollowing +
                        myUserProfile.safeFollowers +
                        groups.flatMap { $0.members }
                    )
                )

                // 3️⃣ Fetch all users once
                let fetchedUsersByID = try await fetchUsersByID(allUserIDs)

                // 4️⃣ Publish results
                await MainActor.run {
                    self.mySocialGroups = groups
                    self.usersByID = fetchedUsersByID
                }

            } catch {
                print("❌ Social init failed: \(error)")
            }
        }
    }

    
//    init(name: String) {
//        self.saveName = name
//        self.publicFestivals = []
//        
//        self.isLoggedIn = (Auth.auth().currentUser != nil)
//        
//        Task {
//            await loadMyUserProfile()   // 🔥 Load user profile on init
//            if self.isLoggedIn {
//                let result = await userHasPhoneHash()
//                await MainActor.run {
//                    self.phoneConnected = result
//                }
//            }
//        }
//    }
    
    //        TODO: Remove
    //        let phoneNumber = "5419082599"
    //        let phoneData = Data(phoneNumber.utf8)
    //        let phoneHash = SHA256.hash(data: phoneData)
    //        let toPrint = phoneHash.compactMap { String(format: "%02x", $0) }.joined()
    //        print("Eitan hash: \(toPrint)")

    
//    struct UserProfile: Identifiable, Codable, Hashable {
//        var id: String
//        var name: String
//        var profilePic: String?
//        var favorites: [FestivalFavorite] = []
//    }

    struct FestivalFavorite: Identifiable, Codable, Hashable {
        var id: String            // festivalId
        var festivalName: String
        var logoPath: String?
        var likedArtistIds: [String]
    }
    
//    func isLoggedIn() -> Bool {
//        return Auth.auth().currentUser != nil
//    }
    
//    @MainActor
    func loadMyUserProfile() async {
        let defaultsKey = "\(saveName)/myUserProfile"

        // 1. Try Firestore first
        if let firebaseUID = Auth.auth().currentUser?.uid {
            do {
                let profile = try await fetchUserProfile(userID: firebaseUID)
                
                // Save to published var
                await MainActor.run {
                    self.myUserProfile = profile
                }
                
                // Save to UserDefaults
                UserDefaults.standard.saveCodable(profile, forKey: defaultsKey)
                
                return
            } catch {
                print("❌ Failed to fetch from Firestore: \(error)")
            }
        }

        // 2. Try UserDefaults fallback
        if let saved = UserDefaults.standard.loadCodable(UserProfile.self, forKey: defaultsKey) {
            print("📦 Loaded from UserDefaults")
            self.myUserProfile = saved
            return
        }

        // 3. Final fallback: empty UserProfile
        print("⚪ Using default empty UserProfile")
        self.myUserProfile = UserProfile(
            id: nil,
            name: "",
            profilePic: nil,
            following: [],
            followers: [],
            festivalFavorites: [:],
            groups: []
        )
    }
    
    func fetchUsersByID(_ ids: [String]) async throws -> [String: UserProfile] {
        let db = Firestore.firestore()

        // Defensive: avoid wasted work
        let uniqueIDs = Array(Set(ids))
        guard !uniqueIDs.isEmpty else { return [:] }

        return try await withThrowingTaskGroup(of: UserProfile?.self) { group in

            for id in uniqueIDs {
                group.addTask {
                    let snapshot = try await db
                        .collection("users")
                        .document(id)
                        .getDocument()

                    guard snapshot.exists else {
                        return nil
                    }

                    let user = try snapshot.data(as: UserProfile.self)

                    guard let userID = user.id else {
                        return nil
                    }

                    return user
                }
            }

            var usersByID: [String: UserProfile] = [:]

            for try await user in group {
                if let user {
                    usersByID[user.id!] = user
                }
            }

            return usersByID
        }
    }
    
    private var userFetchTasks: [String: Task<UserProfile?, Error>] = [:]
    
    func user(_ id: String) async throws -> UserProfile? {
        if let cached = usersByID[id] {
            return cached
        }

        if let task = userFetchTasks[id] {
            return try await task.value
        }

        let task = Task<UserProfile?, Error> {
            let snapshot = try await Firestore.firestore()
                .collection("users")
                .document(id)
                .getDocument()

            guard snapshot.exists else { return nil }

            let user = try snapshot.data(as: UserProfile.self)
            guard let userID = user.id else { return nil }

            await MainActor.run {
                self.usersByID[userID] = user
            }

            return user
        }

        userFetchTasks[id] = task

        defer { userFetchTasks[id] = nil }

        return try await task.value
    }


    func users(from ids: [String]) async -> [UserProfile] {
        await withTaskGroup(of: UserProfile?.self) { group in
            for id in Set(ids) {   // defensive dedupe
                group.addTask {
                    try? await self.user(id)
                }
            }

            var results: [UserProfile] = []

            for await user in group {
                if let user {
                    results.append(user)
                }
            }

            return results
        }
    }


    
    
    func fetchUserProfile(userID: String) async throws -> UserProfile {
        let doc = try await Firestore.firestore()
            .collection("users")
            .document(userID)
            .getDocument()
        return try doc.data(as: UserProfile.self)
    }
    
    func fetchFollowingFollowers(
        followingIDs: [String],
        followerIDs: [String]
    ) async throws -> (following: [UserProfile], followers: [UserProfile]) {

        let allIDs = Array(Set(followingIDs + followerIDs))
        let db = Firestore.firestore()

        let usersByID: [String: UserProfile] = try await withThrowingTaskGroup(
            of: UserProfile?.self
        ) { group in

            for id in allIDs {
                group.addTask {
                    let snapshot = try await db
                        .collection("users")
                        .document(id)
                        .getDocument()

                    guard snapshot.exists else { return nil }

                    let user = try snapshot.data(as: UserProfile.self)
                    guard let id = user.id else { return nil }

                    return user
                }
            }

            var dict: [String: UserProfile] = [:]

            for try await user in group {
                if let user {
                    dict[user.id!] = user
                }
            }

            return dict
        }

        let following = followingIDs.compactMap { usersByID[$0] }
        let followers = followerIDs.compactMap { usersByID[$0] }

        return (following, followers)
    }

    
    
    func fetchUsersOLD(from ids: [String]) async throws -> [UserProfile] {
        let db = Firestore.firestore()
        
        return try await withThrowingTaskGroup(of: UserProfile?.self) { group in
            for id in ids {
                group.addTask {
                    let snapshot = try await db
                        .collection("users")
                        .document(id)
                        .getDocument()

                    guard snapshot.exists else {
                        return nil
                    }

                    let user = try snapshot.data(as: UserProfile.self)

                    guard user.id != nil else {
                        return nil
                    }

                    return user
                }
            }
            
            var users: [UserProfile] = []
            
            for try await user in group {
                if let user {
                    users.append(user)
                }
            }
            return users
        }
    }
    
    func fetchGroups(from ids: [String]) async throws -> [SocialGroup] {
        print("IDs: \(ids)")
        
        let db = Firestore.firestore()
        
        return try await withThrowingTaskGroup(of: SocialGroup?.self) { group in
            for id in ids {
                group.addTask {
                    let snapshot = try await db
                        .collection("groups")
                        .document(id)
                        .getDocument()

                    guard snapshot.exists else {
                        return nil
                    }

                    let socialGroup = try snapshot.data(as: SocialGroup.self)

//                    guard socialGroup.id != nil else {
//                        return nil
//                    }

                    return socialGroup
                }
            }
            
            var socialGroups: [SocialGroup] = []
            
            for try await socialGroup in group {
                if let socialGroup {
                    socialGroups.append(socialGroup)
                }
            }
            
            print("Groups: \(socialGroups)")
            
            return socialGroups
        }
    }

    func fetchFriendsFestivalFavs(festivalID: String, friendIDs: [String]) async -> [UserProfile: [String]] {
        
        let db = Firestore.firestore()
        var result: [UserProfile : [String]] = [:]

        await withTaskGroup(of: (UserProfile?, [String]?).self) { group in
            
            for friendID in friendIDs {
                group.addTask {
                    do {
                        let doc = try await db.collection("users")
                            .document(friendID)
                            .getDocument()

                        if let profile = try? doc.data(as: UserProfile.self) {
                            print("CURRENT PROFILE: \(profile)")
                            let artists = profile.safeFestivalFavorites[festivalID] ?? []
                            return (profile, artists.isEmpty ? nil : artists)
                        }

                    } catch {
                        print("❌ Error fetching \(friendID): \(error)")
                    }
                    
                    return (nil, nil)
                }
            }
            
            for await (profile, artists) in group {
                if let profile, let artists {
                    result[profile] = artists
                }
            }
        }

        return result
    }

    func createGroup(
        name: String,
        photo: String? = nil
    ) async throws -> SocialGroup {

        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AuthError", code: 401, userInfo: nil)
        }

        let db = Firestore.firestore()

        // Create refs
        let groupRef = db.collection("groups").document()
        let userRef = db.collection("users").document(uid)

        let group = SocialGroup(
            id: groupRef.documentID,
            ownerID: uid,
            name: name,
            photo: photo,
            members: [uid],
            festivals: []
        )

        let batch = db.batch()

        // 1️⃣ Create group document
        batch.setData([
            "ownerID": group.ownerID,
            "name": group.name,
            "photo": group.photo as Any,
            "members": group.members,
            "festivals": group.festivals
        ], forDocument: groupRef)

        // 2️⃣ Add groupID to user's `groups` array
        batch.updateData([
            "groups": FieldValue.arrayUnion([group.id!])
        ], forDocument: userRef)

        // Commit atomically
        try await batch.commit()
        
//        myUserProfile.groups?.append(<#T##newElement: String##String#>)
        
        return group
    }

    
    func joinGroup(groupID: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(uid)

        let batch = db.batch()

        batch.updateData([
            "members": FieldValue.arrayUnion([uid])
        ], forDocument: groupRef)

        batch.updateData([
            "groups": FieldValue.arrayUnion([groupID])
        ], forDocument: userRef)

        batch.commit { error in
            if let error = error {
                print("joinGroup failed:", error)
                completion(false)
            } else {
                self.myUserProfile.groups?.append(groupID)
                completion(true)
            }
        }
    }

    
    func leaveGroup(groupID: String, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupID)
        let userRef = db.collection("users").document(uid)

        groupRef.getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch group:", error)
                completion(false)
                return
            }

            guard
                let snapshot = snapshot,
                let group = try? snapshot.data(as: SocialGroup.self)
            else {
                completion(false)
                return
            }

            let batch = db.batch()

            // Always remove group from user's groups
            batch.updateData([
                "groups": FieldValue.arrayRemove([groupID])
            ], forDocument: userRef)

            let remainingMembers = group.members.filter { $0 != uid }

            // CASE 1: Leaving user is the OWNER
            if group.ownerID == uid {

                // No members left → delete group
                if remainingMembers.isEmpty {
                    batch.deleteDocument(groupRef)

                // Members remain → transfer ownership
                } else {
                    let newOwnerID = remainingMembers[0] // cheapest + deterministic

                    batch.updateData([
                        "ownerID": newOwnerID,
                        "members": remainingMembers
                    ], forDocument: groupRef)
                }

            // CASE 2: Leaving user is NOT the owner
            } else {
                batch.updateData([
                    "members": FieldValue.arrayRemove([uid])
                ], forDocument: groupRef)
            }

            batch.commit { error in
                if let error = error {
                    print("leaveGroup failed:", error)
                    completion(false)
                } else {
                    self.myUserProfile.groups?.removeAll(where: { $0 == groupID })
                    completion(true)
                }
            }
        }
    }
    
    func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    func userHasName() async -> Bool {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No logged-in user.")
            return false
        }
        
        let userRef = db.collection("users").document(userId)
        
        do {
            let document = try await userRef.getDocument()
            guard document.exists else { return false }
            
            if let name = document.get("name") as? String,
               !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            } else {
                return false
            }
        } catch {
            print("❌ Error fetching user document: \(error.localizedDescription)")
            return false
        }
    }
    
    func userHasPhoneHash() async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            return false
        }

        let userRef = Firestore.firestore().collection("users").document(uid)

        do {
            let snapshot = try await userRef.getDocument()
            let data = snapshot.data()
            return data?["phoneHash"] != nil
        } catch {
            print("❌ Error checking phoneHash: \(error.localizedDescription)")
            return false
        }
    }
    
    func signOutUser(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            print("Attempting to sign out user...")
            try Auth.auth().signOut()
//            DispatchQueue.main.async {
//                self.userInfo = nil
//                self.userInfo = UserProfile(id: "", name: "", profilePic: nil, favorites: [], friends: [])
//            }
            self.isLoggedIn = false
            completion(.success(()))
        } catch let signOutError {
            completion(.failure(signOutError))
        }
    }
    
    func saveName(name: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("false")
            completion(false)
            return
        }
        
        let userRef = db.collection("users").document(user.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                userRef.updateData(["name": name]) { error in
                    if let error {
                        print("❌ Error updating name: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Name updated successfully!")
                        self.hasAcctName = true
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
    
    func saveNamePhoneAndHash(name: String, phoneNumber: String?, phoneHash: String?, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }

        let userRef = db.collection("users").document(user.uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                var dataToUpdate: [String: Any] = ["name": name]
                if let phoneNumber = phoneNumber { dataToUpdate["phoneNumber"] = phoneNumber }
                if let phoneHash = phoneHash { dataToUpdate["phoneHash"] = phoneHash }

                userRef.updateData(dataToUpdate) { error in
                    if let error = error {
                        print("❌ Error updating user: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ User updated successfully!")
                        self.hasAcctName = true
                        completion(true)
                    }
                }
            } else {
                var dataToSet: [String: Any] = [
                    "name": name,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                if let phoneNumber = phoneNumber { dataToSet["phoneNumber"] = phoneNumber }
                if let phoneHash = phoneHash { dataToSet["phoneHash"] = phoneHash }

                userRef.setData(dataToSet) { error in
                    if let error = error {
                        print("❌ Error saving user: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ User saved successfully!")
                        self.hasAcctName = true
                        completion(true)
                    }
                }
            }
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
    
    @Published var followUnfollowLoading: Bool = false
    @Published var followUnfollowLoadingArray = Array<String>()

    func followUser(_ userID: String, completion: @escaping (Bool) -> Void) {
        followUnfollowLoadingArray.append(userID)

        addFollowerFirestore(userID: userID) { result in
            switch result {
            case .success:
                self.myUserProfile.following?.append(userID)
                self.followUnfollowLoadingArray.removeAll { $0 == userID }
                self.profileDidChange = true
                print("Successfully followed new user.")
                completion(true)

            case .failure(let error):
                self.followUnfollowLoadingArray.removeAll { $0 == userID }
                print("Failed to follow user: \(error.localizedDescription)")
                completion(false)
            }
        }
    }


    func addFollowerFirestore(userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No current user", code: 0)))
            return
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        let myUserRef = db.collection("users").document(currentUserID)
        let otherUserRef = db.collection("users").document(userID)

        // Add to my following
        batch.setData([
            "following": FieldValue.arrayUnion([userID])
        ], forDocument: myUserRef, merge: true)

        // Add to their followers
        batch.setData([
            "followers": FieldValue.arrayUnion([currentUserID])
        ], forDocument: otherUserRef, merge: true)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }


//    func addFollowerFirestore(userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        guard let currentUserID = Auth.auth().currentUser?.uid else {
//            completion(.failure(NSError(domain: "No current user", code: 0)))
//            return
//        }
//
//        let db = Firestore.firestore()
//        let userRef = db.collection("users").document(currentUserID)
//
//        // Merge ensures the document is created if it doesn't exist
//        userRef.setData([
//            "following": FieldValue.arrayUnion([userID])
//        ], merge: true) { error in
//            if let error = error {
//                completion(.failure(error))
//            } else {
//                completion(.success(()))
//            }
//        }
//    }
    
    func unfollowUser(_ userID: String, completion: @escaping (Bool) -> Void) {
        followUnfollowLoading = true
        followUnfollowLoadingArray.append(userID)

        removeFollowerFirestore(userID: userID) { result in
            switch result {
            case .success:
                self.myUserProfile.following?.removeAll { $0 == userID }
                self.followUnfollowLoadingArray.removeAll { $0 == userID }
                self.followUnfollowLoading = false
                self.profileDidChange = true
                print("Successfully unfollowed user.")
                completion(true)

            case .failure(let error):
                self.followUnfollowLoadingArray.removeAll { $0 == userID }
                self.followUnfollowLoading = false
                print("Failed to unfollow user: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func removeFollowerFirestore(userID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "No current user", code: 0)))
            return
        }

        let db = Firestore.firestore()
        let batch = db.batch()

        let myUserRef = db.collection("users").document(currentUserID)
        let otherUserRef = db.collection("users").document(userID)

        // Remove from my following
        batch.setData([
            "following": FieldValue.arrayRemove([userID])
        ], forDocument: myUserRef, merge: true)

        // Remove me from their followers
        batch.setData([
            "followers": FieldValue.arrayRemove([currentUserID])
        ], forDocument: otherUserRef, merge: true)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    func addFestivalToGroups(
        groupIDs: [String],
        festivalID: String
    ) {
        let db = Firestore.firestore()
        let groupsRef = db.collection("groups")

        for groupID in groupIDs {
            let docRef = groupsRef.document(groupID)

            docRef.updateData([
                "festivals": FieldValue.arrayUnion([festivalID])
            ]) { error in
                if let error = error as NSError? {
                    // Ignore "not found" errors, log anything else if you want
                    if error.code != FirestoreErrorCode.notFound.rawValue {
                        print("Failed to update group \(groupID): \(error.localizedDescription)")
                    }
                }
            }
        }
    }




}
