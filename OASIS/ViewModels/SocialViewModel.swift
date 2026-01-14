//
//  SocialViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 10/6/25.
//

import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class SocialViewModel: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var friends: [DataSet.FriendProfile] = []
    @Published var groups: [SocialGroup] = []
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        isLoading = true
        Task {
            await loadFriends()
        }

    }
    
    
    @MainActor
    func loadFriends() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ No logged-in user.")
            return
        }
        
        isLoading = true
        
        do {
            let friendsSnapshot = try await db.collection("users")
                .document(userId)
                .collection("friends")
                .getDocuments()
            
            var fetchedFriends: [DataSet.FriendProfile] = []
            
            try await withThrowingTaskGroup(of: DataSet.FriendProfile.self) { group in
                for friendDoc in friendsSnapshot.documents {
                    group.addTask {
                        let friendId = friendDoc.documentID
                        let name = friendDoc.get("name") as? String ?? "Unknown"
                        let profilePic = friendDoc.get("profilePic") as? String
                        
                        var favorites: [DataSet.FestivalFavorite] = []
                        let favoritesSnapshot = try await self.db.collection("users")
                            .document(friendId)
                            .collection("favorites")
                            .getDocuments()
                        
                        for favDoc in favoritesSnapshot.documents {
                            if let fav = try? favDoc.data(as: DataSet.FestivalFavorite.self) {
                                favorites.append(fav)
                            } else {
                                let id = favDoc.documentID
                                let festivalName = favDoc.get("festivalName") as? String ?? "Unknown"
                                let logoPath = favDoc.get("logoPath") as? String
                                let likedArtistIds = favDoc.get("likedArtistIds") as? [String] ?? []
                                
                                favorites.append(DataSet.FestivalFavorite(
                                    id: id,
                                    festivalName: festivalName,
                                    logoPath: logoPath,
                                    likedArtistIds: likedArtistIds
                                ))
                            }
                        }
                        
                        return DataSet.FriendProfile(
                            id: friendId,
                            name: name,
                            profilePic: profilePic,
                            favorites: favorites
                        )
                    }
                }
                
                for try await friend in group {
                    fetchedFriends.append(friend)
                }
            }
            
            self.friends = fetchedFriends.sorted(by: { $0.name < $1.name })
        } catch {
            print("❌ Error fetching friends: \(error)")
        }
        
        isLoading = false
    }
    
    func getInviteLink() -> String {
        guard let senderUUID = Auth.auth().currentUser?.uid else {
            return "Error: User not logged in"
        }
        let inviteLink = "https://oasis-austinzv.web.app/share/friend/?user=\(senderUUID)"
        return inviteLink
    }
    
    
    func fetchFavoritedFestivals(
        festivalIDs: [String]
    ) async throws -> [DataSet.Festival] {
        print("FESTIVAL IDs: \(festivalIDs)")
        let db = Firestore.firestore()
        
        // 1. Extract Festival IDs from the dictionary keys
//        let festivalIDs = Array(festivalFavs.keys)
        
        guard !festivalIDs.isEmpty else {
            return []
        }
        
        // 2. Fetch in parallel using TaskGroup
        return try await withThrowingTaskGroup(of: DataSet.Festival?.self) { group in
            
            for festivalID in festivalIDs {
                group.addTask {
                    let docRef = db
                        .collection("festivals")
                        .document(festivalID)
                    
                    let snapshot = try await docRef.getDocument()
                    
                    guard snapshot.exists else {
                        return nil
                    }

                    var festival = try snapshot.data(as: DataSet.Festival.self)
                    
                    // 3. Inject Firestore document ID as UUID
                    guard let uuid = UUID(uuidString: festivalID) else {
                        return nil
                    }
                    
                    festival.id = uuid
                    return festival
                }
            }
            
            // 4. Collect results
            var results: [DataSet.Festival] = []
            
            for try await festival in group {
                if let festival {
                    results.append(festival)
                }
            }
            
            return results
        }
    }

    func fetchUsers(from ids: [String]) async throws -> [UserProfile] {
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



}
