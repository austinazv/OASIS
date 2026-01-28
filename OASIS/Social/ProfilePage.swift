//
//  FriendPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/23/25.
//

import SwiftUI

struct ProfilePage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var social: SocialViewModel
    
    @Binding var navigationPath: NavigationPath
    
//    var profile: DataSet.FriendProfile
    @State var profile: UserProfile
    
    @State var unfriendAlert = false
    @State var isLoading = false
    
//    @State var likedFestivals = Array<DataSet.Festival>()
    
    @State var upcomingFestivals = Array<DataSet.Festival>()
    @State var attendedFestivals = Array<DataSet.Festival>()
    
    @State var following = Array<UserProfile>()
    @State var followers = Array<UserProfile>()
    
    
    var body: some View {
//        NavigationStack(path: $navigationPath) {
            
            VStack(spacing: 0) {
                UserHeaderSection
                UserInfoSection
                
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .foregroundStyle(.black)
                    Spacer()
                } else {
                    ZStack {
                        switch selectedSection {
                        case .festivals:
                            FestivalsView
                                .transition(pageSlideTransition)

                        case .followers:
                            FollowersView
                                .id(profile.safeFollowers.count)
                                .transition(pageSlideTransition)

                        case .following:
                            FollowingView
                                .id(profile.safeFollowing.count)
                                .transition(pageSlideTransition)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: selectedSection)

//                    FestivalsView
                }
                Spacer()
            }
            .background(Color(.white))
            .task {
                loadUser()
            }
            .onChange(of: profile.safeFollowers) { newFollowerIDs in
                Task {
                    followers = await firestore.users(from: newFollowerIDs)
                }
            }
            .onChange(of: profile.safeFollowing) { newFollowingIDs in
                Task {
                    following = await firestore.users(from: newFollowingIDs)
                }
            }
//            .onAppear {
//                loadUser()
//            }
//            .onChange(of: firestore.profileDidChange) { bool in
//                print("CALLED")
//                if bool {
//                    print("LOADING")
//                    loadUser()
//                    print("NEW PROFILE: \(profile)")
//                    firestore.profileDidChange = false
//                }
//            }
            .toolbar {
                if true {
                    ToolbarItem(placement: .principal) {
                        Group {
                            if let id = profile.id, id == firestore.getUserID() {
                                Text("My Profile")
                            } else {
//                                Text("\(profile.name)'s Profile")
                                OASISTitle(fontSize: 30, kerning: 2)
                            }
                        }
                        .foregroundStyle(.black)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Group {
                        if let profileID = profile.id {
                            if profileID == firestore.getUserID() {
                                Button {
                                    navigationPath.append("Settings")
                                } label: {
                                    Image(systemName: "gear")
                                        .imageScale(.large)
                                        .accessibilityLabel("Settings")
                                }
                            } else {
                                Menu(content: {
                                    if firestore.myUserProfile.safeFollowing.contains(profileID) {
                                        Button (action: {
                                            firestore.unfollowUser(profileID) { success in
                                                if success {
                                                    profile.followers?.removeAll(where: { $0 == firestore.myUserProfile.id! })
                                                }
                                            }
                                            
                                        }, label: {
                                            Text("Unfollow \(profile.name)")
                                        })
                                    } else {
                                        Button (action: {
                                            firestore.followUser(profileID) { success in
                                                if success {
                                                    profile.followers?.append(firestore.myUserProfile.id!)
                                                }
                                            }
                                        }, label: {
                                            Text("Follow \(profile.name)")
                                        })
                                    }
                                    
                                }, label: {
                                    Group {
                                        Image(systemName: "person.2.badge.gearshape.fill")
                                    }
                                })
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            //        .toolbarRole(ToolbarRole)
            
            
            
            //            if let favList = profile.favorites, !favList.isEmpty {
            //                ArtistList(currDict: [String(profile.name + "'s Favorites") : data.getArtistListFromID(artists: favList) as [DataSet.artist]],
            //                           titleText: String(profile.name + "'s Favorites"),
            ////                           favorites: false,
            ////                           friendList: true,
            //                           sortType: .alpha,
            //                           subsectionLen: data.getSortLables(sort: .alpha).count)
            //                    .environmentObject(data)
            //            } else {
            //                Text("\(profile.name) has no Starred Artist yet.")
            //                    .multilineTextAlignment(.center)
            //                    .padding(.top, 20)
            //                Spacer()
            //            }
            
            //        .navigationBarTitleDisplayMode(.inline)
            
            //        .toolbar {
            //            ToolbarItem(placement: .topBarTrailing) {
            //                Menu(content: {
            //                    Button (action: {
            ////                        unfriendAlert = true
            //                    }, label: {
            //                        HStack {
            //                            Spacer()
            //                            Text("❌ Unfriend")
            //
            //                        }.foregroundStyle(Color.red)
            //                    })
            //
            //                }, label: {
            //                    Image(systemName: "gear")
            //                    .foregroundStyle(Color.blue)
            //                })
            //            }
            //        }
            .alert(isPresented: self.$unfriendAlert) {
                Alert(title: Text("Unfriend"),
                      message: Text("Are you sure you want to unfriend \(profile.name)?"),
                      primaryButton: .destructive(Text("Unfriend")) {
                    data.unfriendUser(currentUserID: data.userInfo!.id!, friendID: profile.id!) { error in
                        if let error = error {
                            print("Error unfriending user: \(error.localizedDescription)")
                        } else {
                            
                            print("Successfully unfriended user.")
                            if !navigationPath.isEmpty {  // Ensure there is something to pop
                                navigationPath.removeLast()
                            }
                        }
                    }
                }, secondaryButton: .cancel()
                )
            }
//        }
    }
    
    func loadUser() {
        isLoading = true
        
        Task {
            defer { isLoading = false }
            
            let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: Array(profile.safeFestivalFavorites.keys))
            let split = festivalVM.splitFestivals(likedFestivals)
            attendedFestivals = split.attended
            upcomingFestivals = split.upcoming
            
            followers = await firestore.users(from: profile.safeFollowers)
            following = await firestore.users(from: profile.safeFollowing)
        }
    }
//            do {
//                profile = (try? await firestore.fetchUserProfile(userID: profile.id!)) ?? profile
//                
//                // ✅ 1. Fetch festivals
//                if !profile.safeFestivalFavorites.isEmpty {
//                    let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: Array(profile.safeFestivalFavorites.keys))
//                    
//                    let split = festivalVM.splitFestivals(likedFestivals)
//                    attendedFestivals = split.attended
//                    upcomingFestivals = split.upcoming
//                }
//                
//                // ✅ 2. Fetch following
//                if profile.safeFollowing.isEmpty {
//                    following = []
//                } else {
//                    following = try await social.fetchUsers(from: profile.safeFollowing)
//                }
//                
//                // ✅ 3. Fetch followers
//                if profile.safeFollowers.isEmpty  {
//                    followers = []
//                } else {
//                    print("UPDATING USER'S FOLLOWERS")
//                    followers = try await social.fetchUsers(from: profile.safeFollowers)
//                }
//                
//                isLoading = false
//                
//            } catch {
//                print("Error:", error)
//                isLoading = false
//            }
//        }
//    }
    
    var UserHeaderSection: some View {
            HStack {
                SocialImage(imageURL: profile.profilePic, name: profile.name, frame: 110)
                    .padding(.leading, 40)
                Spacer()
                VStack {
                    Text(profile.name)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .font(Font.system(size: 25))
                    ProfileButton(profile: $profile)
                    //                if profile.id! != firestore.getUserID() && !firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                    //                    FollowButtonLong(profile: profile/*, longView: true*/)
                    //                }
                }
                Spacer()
                
            }
            //        .padding(.top, 20)
            .padding(.bottom, 20)
        
    }
    
    @State private var selectedSection: SectionType = .festivals
    @State private var previousSection: SectionType = .festivals
    @State private var slideDirection: SlideDirection = .forward

    
    var UserInfoSection: some View {
        ZStack(alignment: .bottom){
            
            Rectangle()
                .fill(Color.black.opacity(0.25))
//                .fill(.black)
                .frame(height: 1)
                .offset(y: -4)

            HStack(spacing: 8) {
                Button {
                    switchTab(.festivals)
                } label: {
                    UserNumber(number: profile.safeFestivalFavorites.keys.count,
                               text: "Festivals",
                               isSelected: selectedSection == .festivals
                    )
                }

                Button {
                    switchTab(.following)
                } label: {
                    UserNumber(number: profile.safeFollowing.count,
                               text: "Following",
                               isSelected: selectedSection == .following)
                }

                Button {
                    switchTab(.followers)
                } label: {
                    UserNumber(number: profile.safeFollowers.count,
                               text: "Followers",
                               isSelected: selectedSection == .followers)
                }
            }
            .frame(height: 65)
//
            /// The continuous line you want
//
        }
        .padding(.top, 5)
        
    }
    
    func switchTab(_ new: SectionType) {
        guard new != selectedSection else { return }

        previousSection = selectedSection
        slideDirection = new.rawValue > selectedSection.rawValue ? .forward : .backward

        withAnimation(.easeInOut(duration: 0.3)) {
            selectedSection = new
        }
    }



    
    enum SectionType: Int {
        case festivals = 0
        case following = 1
        case followers = 2
    }
    
    enum SlideDirection {
        case forward
        case backward
    }
    
    var pageSlideTransition: AnyTransition {
        switch slideDirection {
        case .forward:
            // New comes from RIGHT, old exits LEFT
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )

        case .backward:
            // New comes from LEFT, old exits RIGHT
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }

    
    var slideTransition: AnyTransition {
        if selectedSection.rawValue > previousSection.rawValue {
            // Moving RIGHT → LEFT
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        } else {
            // Moving LEFT → RIGHT
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }
    
    let LIST_PADDING: CGFloat = 8
    
    
    var FestivalsView: some View {
        VStack {
            if upcomingFestivals.isEmpty && attendedFestivals.isEmpty {
                Spacer()
                Group {
                    if let id = profile.id, id == firestore.getUserID() {
                        Text("You have no saved festivals yet.")
                    } else {
                        Text("\(profile.name) has no saved festivals yet.")
                        
                    }
                }
                .foregroundStyle(.black)
                Spacer()
            } else {
                Group {
                    FestivalsListed(navigationPath: $navigationPath, festivalList: upcomingFestivals, title: "Upcoming", collapsable: true)
                    FestivalsListed(navigationPath: $navigationPath, festivalList: attendedFestivals, title: "Attended", collapsable: true)
                }
                .padding(.top, LIST_PADDING)
            }
        }
    }
    
    var FollowingView: some View {
        VStack {
            if following.isEmpty {
                Spacer()
                Group {
                    if let id = profile.id, id == firestore.getUserID() {
                        Text("You are not following anyone yet.")
                    } else {
                        Text("\(profile.name) is not following anyone yet.")
                    }
                }
                .foregroundStyle(.black)
                Spacer()
            } else {
                ProfilesListed(navigationPath: $navigationPath, profiles: following, maxHeight: 370)
                    .padding(.top, LIST_PADDING)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
        }
    }
    
    var FollowersView: some View {
        VStack {
            if followers.isEmpty {
                Spacer()
                Group {
                    if let id = profile.id, id == firestore.getUserID() {
                        Text("You have no followers yet.")
                    } else {
                        Text("\(profile.name) has no followers yet.")
                    }
                }
                .foregroundStyle(.black)
                Spacer()
            } else {
                ProfilesListed(navigationPath: $navigationPath, profiles: followers)
                    .padding(.top, LIST_PADDING)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    
}

//#Preview {
//    FriendPage()
//}

struct UserNumber: View {
    var number: Int
    var text: String
    var isSelected: Bool
    var width: CGFloat = 110
//    var color: Color = .white
    
    var body: some View {
        VStack {
            VStack(spacing: 2) {
                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                Text(text)
                    .font(.caption)
            }
            .padding(.vertical, 10)
            .frame(width: width)
            .foregroundColor(isSelected ? .oasisDarkOrange : .black)
            .background(
                ZStack {
                    if isSelected {
                        // Selected tab: filled
                        RoundedCorners(topLeft: 12, topRight: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.gray.opacity(0.2), .white],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }/* else {*/
                    RoundedCorners(topLeft: 12, topRight: 12)
                        .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    //                }
                }
            )
            if isSelected {
                SideStrokedRect()
                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
                    .frame(width: width, height: 8)
                    .background(.white)
                    .offset(y: -8)
            }
        }
    }
}

struct SideStrokedRect: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Left edge
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        // Right edge
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        return path
    }
}


struct RoundedCorners: Shape {
    var topLeft: CGFloat = 0.0
    var topRight: CGFloat = 0.0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeft))
        path.addQuadCurve(to: CGPoint(x: rect.minX + topLeft, y: rect.minY),
                          control: CGPoint(x: rect.minX, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + topRight),
                          control: CGPoint(x: rect.maxX, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))

        return path
    }
}






