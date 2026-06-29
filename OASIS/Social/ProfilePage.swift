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
//    @EnvironmentObject var tags: TagViewModel
    
    @Binding var navigationPath: NavigationPath
    
//    var profile: DataSet.FriendProfile
    @State var profile: UserProfile
    
    @State var unfriendAlert = false
    @State var isLoading = false
    
//    @State var likedFestivals = Array<Festival>()
    
    @State var upcomingFestivals = Array<Festival>()
    @State var attendedFestivals = Array<Festival>()
    
    @State var following = Array<UserProfile>()
    @State var followers = Array<UserProfile>()
    
    @State private var photoExpanded = false
    
    var body: some View {
//        NavigationStack(path: $navigationPath) {
//        ScrollView {
        ZStack(alignment: photoExpanded ? .center : .topLeading) {
            SocialImage(imageURL: profile.profilePic, name: profile.name, frame: photoExpanded ? 320 : 110)
                .shadow(radius: photoExpanded ? 20 : 0)
                .padding(.leading, photoExpanded ? 0 : 40)
                .onTapGesture {
                    if profile.profilePic != nil {
                        toggleImage()
                    }
                }
                .zIndex(2)
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
//        }
//        .refreshable {
//            print("REFRESHED")
////            explore.fetchVerifiedFestivals()
//        }
            .background(Color(.white))
            .onAppear() {
                Task { @MainActor in
                    isLoading = true
                    defer { isLoading = false }
                    
                    if profile.id == firestore.myUserProfile.id { profile = firestore.myUserProfile }
                    await loadUser()
                }
            }
            .onChange(of: profile.safeFollowers) { _, newFollowerIDs in
                Task {
                    followers = await firestore.users(from: newFollowerIDs)
                }
            }
            .onChange(of: profile.safeFollowing) { _, newFollowingIDs in
                Task {
                    following = await firestore.users(from: newFollowingIDs)
                }
            }
//            .onAppear {
//                loadUser()
//            }
//            .onChange(of: firestore.profileDidChange) { bool in
//                //print("CALLED")
//                if bool {
//                    //print("LOADING")
//                    loadUser()
//                    //print("NEW PROFILE: \(profile)")
//                    firestore.profileDidChange = false
//                }
//            }
            .toolbar {
//                if true {
                    ToolbarItem(placement: .principal) {
                        Group {
                            if /*let id = profile.id,*/ profile.id == firestore.getUserID() {
                                Text("My Profile")
                            } else {
//                                Text("\(profile.name)'s Profile")
                                OASISTitle(fontSize: 30, kerning: 2)
                            }
                        }
                        .foregroundStyle(.black)
                    }
//                }
                ToolbarItem(placement: .topBarTrailing) {
                    Group {
//                        if let profileID = profile.id {
                        if profile.id == firestore.getUserID() {
                                Button {
                                    navigationPath.append("Settings")
                                } label: {
                                    Image(systemName: "gear")
                                        .imageScale(.large)
                                        .accessibilityLabel("Settings")
                                }
                            } else {
                                Menu(content: {
                                    if firestore.myUserProfile.safeFollowing.contains(profile.id) {
                                        Button (action: {
                                            firestore.unfollowUser(profile.id) { success in
                                                if success {
                                                    profile.followers?.removeAll(where: { $0 == firestore.myUserProfile.id })
                                                }
                                            }
                                            
                                        }, label: {
                                            Text("Unfollow \(profile.name)")
                                        })
                                    } else {
                                        Button (action: {
                                            firestore.followUser(profile.id) { success in
                                                if success {
                                                    profile.followers?.append(firestore.myUserProfile.id)
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
//                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            
            .alert(isPresented: self.$unfriendAlert) {
                Alert(title: Text("Unfriend"),
                      message: Text("Are you sure you want to unfriend \(profile.name)?"),
                      primaryButton: .destructive(Text("Unfriend")) {
                    data.unfriendUser(currentUserID: data.userInfo!.id, friendID: profile.id) { error in
                        if let error = error {
                            //print("Error unfriending user: \(error.localizedDescription)")
                        } else {
                            
                            //print("Successfully unfriended user.")
                            if !navigationPath.isEmpty {  // Ensure there is something to pop
                                navigationPath.removeLast()
                            }
                        }
                    }
                }, secondaryButton: .cancel()
                )
            }
            if photoExpanded {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                    .onTapGesture {
                        collapseImage()
                    }
            }
        }
        .animation(
            .spring(response: 0.45, dampingFraction: 0.86),
            value: photoExpanded
        )
    }
    
    func toggleImage() {
        withAnimation {
            photoExpanded.toggle()
        }
    }

    func collapseImage() {
        withAnimation {
            photoExpanded = false
        }
    }
    
    func loadUser() async {
//        isLoading = true
//        
//        defer { isLoading = false }
        
        //            let likedFestivals = [Festival]() /*try await social.fetchFavoritedFestivals(festivalIDs: Array(profile.safeFestivalFavorites.keys))*/
        do {
            let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: profile.safeStarredFestivalsList)
            let split = festivalVM.splitFestivals(likedFestivals)
            
            
            let followers = await firestore.users(from: profile.safeFollowers)
            let following = await firestore.users(from: profile.safeFollowing)
            
            await MainActor.run {
                self.attendedFestivals = split.attended
                self.upcomingFestivals = split.upcoming
                self.followers = followers
                self.following = following
            }
        } catch {
            print("loadUser failed:", error)
        }
    }
    
    
    func refreshUserProfile() async {
        do {
            // 1. re-fetch latest profile from Firestore
            let updatedProfile = try await firestore.fetchUserProfile(userID: profile.id)
            

            // 2. update local profile first
            await MainActor.run {
                self.profile = updatedProfile
                firestore.usersByID[profile.id] = updatedProfile
            }

            // 3. then load dependent data
            await loadUser()

        } catch {
            print("Failed to refresh profile:", error)
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
//                    //print("UPDATING USER'S FOLLOWERS")
//                    followers = try await social.fetchUsers(from: profile.safeFollowers)
//                }
//                
//                isLoading = false
//                
//            } catch {
//                //print("Error:", error)
//                isLoading = false
//            }
//        }
//    }
    
    var UserHeaderSection: some View {
        HStack() {
            Spacer().frame(width: 150)
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
//        .padding(.bottom, 20)
//        .padding(.trailing, 20)
        .frame(height: 130)
        
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
                    UserNumber(number: isLoading ? profile.safeStarredFestivalsList.count : (upcomingFestivals.count + attendedFestivals.count),
                               text: "Festivals",
                               isSelected: selectedSection == .festivals
                    )
                }

                Button {
                    switchTab(.following)
                } label: {
                    UserNumber(number: isLoading ? profile.safeFollowing.count : following.count,
                               text: "Following",
                               isSelected: selectedSection == .following)
                }

                Button {
                    switchTab(.followers)
                } label: {
                    UserNumber(number: isLoading ? profile.safeFollowers.count : followers.count,
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
        ScrollView {
            VStack {
                if upcomingFestivals.isEmpty && attendedFestivals.isEmpty {
                    Spacer()
                    Group {
                        if/* let id = profile.id,*/ profile.id == firestore.getUserID() {
                            Text("You have no saved festivals yet.")
                        } else {
                            Text("\(profile.name) has no saved festivals yet.")
                            
                        }
                    }
                    .foregroundStyle(.black)
                    Spacer()
                } else {
//                    let userArtistDict = getUserArtistDict(festivals: (upcomingFestivals + attendedFestivals))
                    ScrollView {
                        FestivalsListed(navigationPath: $navigationPath, festivalList: upcomingFestivals, title: "Upcoming", largeText: true, collapsable: true, profile: profile.id == firestore.getUserID() ? nil : profile)
                        FestivalsListed(navigationPath: $navigationPath, festivalList: attendedFestivals, title: "Attended", collapsable: true, showList: upcomingFestivals.isEmpty, profile: profile.id == firestore.getUserID() ? nil : profile)
                    }
                    .padding(.top, LIST_PADDING)
                }
            }
        }
        .refreshable {
            await refreshUserProfile()
        }
    }
    
//    func getUserArtistDict(festivals: [Festival]) -> [UUID : [Artist]] {
//        var userArtistDict = [UUID : [Artist]]()
//        for festival in festivals {
//            let festivalFavoritesList = festival.artistList.filter({ profile.safeFavoriteArtistsList.contains($0.id) })
//            if !festivalFavoritesList.isEmpty {
//                userArtistDict[festival.id] = festivalFavoritesList
//            }
//        }
//        return userArtistDict
//    }
    
    
    
    var FollowingView: some View {
        ScrollView {
            VStack {
                if following.isEmpty {
                    Spacer()
                    Group {
                        if/* let id = profile.id,*/ profile.id == firestore.getUserID() {
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
        .refreshable {
            await refreshUserProfile()
        }
    }
    
    var FollowersView: some View {
        ScrollView {
            VStack {
                if followers.isEmpty {
                    Spacer()
                    Group {
                        if /*let id = profile.id,*/ profile.id == firestore.getUserID() {
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
        .refreshable {
            await refreshUserProfile()
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
//                    .font(.system(size: 17))
                    .font(.headline)
                    .fontWeight(.bold)
                Text(text)
                    .font(.caption)
            }
            .padding(.vertical, 10)
            .frame(width: width, height: 57)
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






