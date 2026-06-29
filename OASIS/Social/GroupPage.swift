//
//  FriendPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/23/25.
//

import SwiftUI
import PhotosUI

struct GroupPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var social: SocialViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State var group: SocialGroup
    
    @State var unfriendAlert = false
    @State var isLoading = false
    
//    @State var likedFestivals = Array<DataSet.Festival>()
    
    @State var upcomingFestivals = Array<Festival>()
    @State var attendedFestivals = Array<Festival>()
    
    @State var members = Array<UserProfile>()
    
    @State var showEditGroupSheet: Bool = false
    
    @State private var photoExpanded = false
    
    var body: some View {
//        NavigationStack(path: $navigationPath) {
        ZStack(alignment: photoExpanded ? .center : .topLeading) {
            SocialImage(imageURL: group.photo, name: group.name, frame: photoExpanded ? 320 : 110)
                .shadow(radius: photoExpanded ? 20 : 0)
                .padding(.leading, photoExpanded ? 0 : 40)
                .onTapGesture {
                    if group.photo != nil {
                        toggleImage()
                    }
                }
                .zIndex(2)
            VStack(spacing: 0) {
                GroupHeaderSection
                GroupInfoSection
                if isLoading {
                    Spacer()
                    ProgressView()
                        .foregroundStyle(.black)
                    Spacer()
                } else {
                    ZStack {
                        switch selectedSection {
                        case .festivals:
                            //                            ScrollView {
                            FestivalsView
//                        }
                                .transition(pageSlideTransition)

                        case .members:
//                            ScrollView {
                                MembersView
//                            }
                                .transition(pageSlideTransition)

//                        case .following:
//                            ScrollView { FollowingView }
//                                .transition(pageSlideTransition)
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: selectedSection)

//                    FestivalsView
                }
                Spacer()
            }
            .background(Color(.white))
            .task {
                isLoading = true
                defer { isLoading = false }

                do {
                    try await loadGroup()
                } catch {
                    print(error)
                }
            }
            .onChange(of: group.members) { _, newMemberIDs in
                Task {
                    members = await firestore.users(from: newMemberIDs)
                }
            }
            .onChange(of: group.festivals) { _, newFestivalIDs in
                Task {
                    let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: newFestivalIDs)
                    let split = festivalVM.splitFestivals(likedFestivals)
                    attendedFestivals = split.attended
                    upcomingFestivals = split.upcoming
//                    members = await firestore.users(from: newMemberIDs)
                }
            }
            .sheet(isPresented: $showEditGroupSheet) {
                EditGroupSheet(showEditGroupSheet: $showEditGroupSheet, currentGroup: $group)
            }
//            .onChange(of: firestore.profileDidChange) { bool in
//                if bool {
//                    loadUser()
//                    firestore.profileDidChange = false
//                }
//            }
            .toolbar {

                ToolbarItem(placement: .principal) {
                    OASISTitle(fontSize: 30, kerning: 2)
//                    Group {
                    
//                        if let id = profile.id, id == firestore.getUserID() {
//                            Text("My Profile")
//                        } else {
                            //                                Text("\(profile.name)'s Profile")
                            
//                        }
//                    }
//                    .foregroundStyle(.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu(content: {
                        if let myID = firestore.getUserID(), myID == group.ownerID {
                            Button (action: { showEditGroupSheet = true }) {
                                Text("Edit Group")
                            }
                        }
                        if firestore.myUserProfile.safeGroups.contains(group.id!) {
                            Button (action: leaveGroup) {
                                Text("Leave Group")
                            }
                        } else {
                            Button (action: joinGroup) {
                                Text("Join Group")
                            }
                        }
                    }, label: {
                        Group {
                            Image(systemName: "gear")
                        }
                    })
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
        
        //TODO: GROUP ALERT
//            .alert(isPresented: self.$unfriendAlert) {
//                Alert(title: Text("Unfriend"),
//                      message: Text("Are you sure you want to unfriend \(profile.name)?"),
//                      primaryButton: .destructive(Text("Unfriend")) {
//                    data.unfriendUser(currentUserID: data.userInfo!.id!, friendID: profile.id!) { error in
//                        if let error = error {
//                            print("Error unfriending user: \(error.localizedDescription)")
//                        } else {
//                            
//                            print("Successfully unfriended user.")
//                            if !navigationPath.isEmpty {  // Ensure there is something to pop
//                                navigationPath.removeLast()
//                            }
//                        }
//                    }
//                }, secondaryButton: .cancel()
//                )
//            }
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
    
    func joinGroup() {
        firestore.joinGroup(groupID: group.id!) { success in

            if success {
                group.members.append(firestore.getUserID()!)
                firestore.myUserProfile.groups?.append(group.id!)
            }
        }
    }
    
    func leaveGroup() {
        firestore.leaveGroup(groupID: group.id!) { success in

            if success {
                group.members.removeAll(where: { $0 == firestore.getUserID()! })
                firestore.myUserProfile.groups?.removeAll(where: { $0 == group.id! })
                firestore.mySocialGroups.removeAll(where: { $0.id == group.id! })
                navigationPath.removeLast()
            }
        }
    }
    
    @MainActor
    func loadGroup() async throws {
        let likedFestivals = try await social.fetchFavoritedFestivals(
            festivalIDs: group.festivals
        )

        let split = festivalVM.splitFestivals(likedFestivals)
        attendedFestivals = split.attended
        upcomingFestivals = split.upcoming

        members = await firestore.users(from: group.members)
    }
    
    func loadUser() {
        isLoading = true
        
        Task {
            do {
//                profile = (try? await firestore.fetchUserProfile(userID: profile.id!)) ?? profile
//                
//                // ✅ 1. Fetch festivals
                if !group.festivals.isEmpty {
                    let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: group.festivals)
                    
                    let split = festivalVM.splitFestivals(likedFestivals)
                    attendedFestivals = split.attended
                    upcomingFestivals = split.upcoming
                }
                
                // ✅ 2. Fetch members
//                if !group.members.isEmpty {
//                    members = try await social.fetchUsers(from: group.members)
//                }
//                
//                // ✅ 3. Fetch followers
//                if !profile.safeFollowers.isEmpty  {
//                    followers = try await social.fetchUsers(from: profile.safeFollowers)
//                }
//                
                isLoading = false
//                
            } catch {
//                print("Error:", error)
                isLoading = false
            }
        }
    }
    
    var GroupHeaderSection: some View {
            HStack {
                Spacer().frame(width: 150)
                Spacer()
                VStack {
                    Text(group.name)
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .font(Font.system(size: 25))
                    GroupSocialButton
//                    ProfileButton(profile: profile)
                    
                    //                if profile.id! != firestore.getUserID() && !firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                    //                    FollowButtonLong(profile: profile/*, longView: true*/)
                    //                }
                }
                Spacer()
                
            }
            .frame(height: 130)
            //        .padding(.top, 20)
//            .padding(.bottom, 20)
        
    }
    
    var GroupSocialButton: some View {
        Group {
            if let myID = firestore.getUserID(), group.members.contains(myID) {
                ShareLink(item: shareGroupURL()) {
                    HStack {
                        Text("Invite Friends")
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                }
            } else {
                Button (action: joinGroup) {
                    HStack {
                        Text("Join Group")
                        Image(systemName: "person.3.fill")
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .frame(width: 160, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(.blue)
        )
        .shadow(radius: 5)
        .buttonStyle(.plain)
        .padding(0)
    }
    
    func shareGroupURL() -> URL {
        let inviteLink = URL(string: "https://oasis-austinzv.web.app/share/group/?group=\(group.id!)")!
        return inviteLink
    }
    
    @State private var selectedSection: SectionType = .festivals
    @State private var previousSection: SectionType = .festivals
    @State private var slideDirection: SlideDirection = .forward

    
    var GroupInfoSection: some View {
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
                    UserNumber(number: group.festivals.count,
                               text: "Festivals",
                               isSelected: selectedSection == .festivals,
                               width: 160
                    )
                }

                Button {
                    switchTab(.members)
                } label: {
                    UserNumber(number: group.members.count,
                               text: "Members",
                               isSelected: selectedSection == .members,
                               width: 160
                    )
                }

//                Button {
//                    switchTab(.followers)
//                } label: {
//                    UserNumber(number: profile.safeFollowers.count,
//                               text: "Followers",
//                               isSelected: selectedSection == .followers)
//                }
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
        case members = 1
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
    
    @State var showAddFestivalToGroupSheet: Bool = false
    
    var FestivalsView: some View {
        VStack {
            if upcomingFestivals.isEmpty && attendedFestivals.isEmpty {
                Spacer()
                Group {
                    Text("Your group has no connected festivals yet.")
                        .foregroundStyle(.black)
                    Button(action: {
                        showAddFestivalToGroupSheet = true
//                        selectedTab = 1
                    }) {
                        HStack {
                            Text("Connect festivals")
                            Image(systemName: "plus.circle")
                        }
                    }
                    .italic()
                    .padding(.top, 8)
//                    Text("There are no festivals connected to this group yet.")
                }
                Spacer()
            } else {
                ScrollView {
                    Group {
                        if !upcomingFestivals.isEmpty {
                            FestivalsListed(navigationPath: $navigationPath, festivalList: upcomingFestivals, title: "Upcoming", collapsable: true, socialGroup: group)
                            Button(action: {
                                showAddFestivalToGroupSheet = true
                            }) {
                                HStack {
                                    if firestore.myUserProfile.id == group.ownerID {
                                        Text("Edit connected festivals")
                                        Image(systemName: "pencil.circle")
                                    } else {
                                        Text("Connect more festivals")
                                        Image(systemName: "plus.circle")
                                    }
                                }
                            }
                            .italic()
                            .padding(.top, 8)
                        } else {
                            VStack {
                                Text("No Upcoming Festivals!")
                                    .foregroundStyle(.black)
                                Button(action: {
                                    showAddFestivalToGroupSheet = true
                                }) {
                                    HStack {
                                        Text("Connect more festivals")
                                        Image(systemName: "plus.circle")
                                    }
                                }
                                .italic()
                                .padding(.top, 8)
                            }
                            .padding(.vertical, 40)
                            
                            Divider()
                                .padding(.bottom, 8)
                        }
                        FestivalsListed(navigationPath: $navigationPath, festivalList: attendedFestivals, title: "Attended", collapsable: true, showList: upcomingFestivals.isEmpty, reversed: true, socialGroup: group)
                    }
                    .padding(.top, LIST_PADDING)
                }
                .refreshable {
                    do {
                        try await loadGroup()
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFestivalToGroupSheet) {
            AddFestivalsToGroupSheet(group: $group, showAddFestivalToGroupSheet: $showAddFestivalToGroupSheet)
        }
    }
    
    var MembersView: some View {
        ScrollView {
            VStack {
                if members.isEmpty {
                    Spacer()
                    Text("There are no current members.")
                        .foregroundStyle(.black)
                    Spacer()
                } else {
                    ProfilesListed(navigationPath: $navigationPath, profiles: members, maxHeight: 370, topUser: group.ownerID)
                        .padding(.top, LIST_PADDING)
                        .fixedSize(horizontal: false, vertical: true)
                    
                }
            }
        }
        .refreshable {
            do {
                try await loadGroup()
            } catch {
                print(error)
            }
        }
    }
    
//    var FollowersView: some View {
//        VStack {
//            if followers.isEmpty {
//                Spacer()
//                Group {
//                    if let id = profile.id, id == firestore.getUserID() {
//                        Text("You have no followers yet.")
//                    } else {
//                        Text("\(profile.name) has no followers yet.")
//                    }
//                }
//                .foregroundStyle(.black)
//                Spacer()
//            } else {
//                ProfilesListed(navigationPath: $navigationPath, profiles: followers)
//                    .padding(.top, LIST_PADDING)
//            }
//        }
//    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    @EnvironmentObject var data: DataSet
//    
//    @Binding var navigationPath: NavigationPath
//    
//    var group: DataSet.SocialGroup
//    
//    @State var favoriteDict: [String : [String]]?
////    @State var artistList: [DataSet.artist]?
//    
//    @State var groupPhotos = [String : UIImage]()
//    
//    @State var unfriendAlert = false
//    @State var isLoading = true
//    
//    @State var showFriendSheet: Bool = false
//    
//    @State var chosenMember: DataSet.FriendProfileOLD?
//    
//    var body: some View {
//        Group {
////            if isLoading {
////                ProgressView()
////                Text("Loading Group")
////            } else {
////                ZStack {
////                    VStack {
////                        HStack {
////                            if let localPath = group.photo, let image = UIImage(contentsOfFile: localPath) {
////                                Image(uiImage: image)
////                                    .resizable()
////                                    .scaledToFill()
////                                    .frame(width: 110, height: 110, alignment: .center)
////                                    .clipShape(Circle())
////                            } else {
////                                Image("Default Group Profile Picture")
////                                    .resizable()
////                                    .frame(width: 110, height: 110, alignment: .center)
////                                    .clipShape(Circle())
////                            }
////                            VStack {
////                                Text(group.name)
////                                    .multilineTextAlignment(.center)
//////                                ShareLink(item: URL(string: group.inviteLink)!) {
//////                                    Label("", systemImage: "square.and.arrow.up.circle")
//////                                }
//////                                .padding(.top, 4)
////                            }
////                            .font(Font.system(size: 25))
////                            .padding(.leading, 20)
////                        }
////                        .padding(.horizontal, 20)
//////                        let favList = artistList!
//////                        if !favList.isEmpty {
//////                            ArtistList(currDict: [String(group.name + "'s Favorites") : favList as [DataSet.artist]],
//////                                          titleText: String(group.name + "'s Favorites"),
////////                                          favorites: false,
////////                                          friendList: true,
//////                                          groupFavorites: group.favoritesDict,
//////                                          groupPhotos: self.groupPhotos,
//////                                          sortType: .alpha,
//////                                          subsectionLen: data.getSortLables(sort: .alpha).count)
//////                            .environmentObject(data)
//////                        } else {
//////                            Text("Nobody in this group has any Starred Artist yet.")
//////                                .multilineTextAlignment(.center)
//////                                .padding(.top, 20)
//////                            Spacer()
//////                        }
////                    }
//////                    if showFriendSheet {
//////                        Color.black
//////                            .opacity(0.3)
//////                            .ignoresSafeArea()
//////                        FriendsListSheet
//////                    }
////                }
////            }
//        }
////        .sheet(isPresented: $showFriendSheet) {
////            FriendsListSheet
////        }
//        .sheet(isPresented: $showFriendSheet) {
//            FriendsListSheet
//        }
//        .onAppear() {
////            self.favoriteDict = data.addMyFavorites(groupFavorites: group.favoritesDict)
////            var unsortedList = Array<DataSet.artist>()
////            for key in favoriteDict!.keys {
////                if let artist = data.getArtist(artistID: key) {
////                    unsortedList.append(artist)
////                }
////            }
////            self.artistList = unsortedList
////            
////            for m in group.members {
////                if let localPath = m.profilePic, let image = UIImage(contentsOfFile: localPath) {
////                    groupPhotos[m.id] = image
////                }
////            }
////            
////            isLoading = false
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .topBarTrailing) {
//                HStack {
//                    ShareButton
//                    FriendsListButton
//                    SettingsMenu
//                }
//            }
//        }
//        .alert(isPresented: self.$unfriendAlert) {
//            Alert(title: Text("Leave Group"),
//                  message: Text("Are you sure you want to leave \n\(group.name)?"),
//                  primaryButton: .destructive(Text("Leave")) {
//                data.leaveGroup(groupID: group.id) { success in
//                    if !success {
//                        print("Error leaving group")
//                    } else {
//                        print("Successfully left group.")
//                            navigationPath.removeLast()
//                    }
//                }
//            }, secondaryButton: .cancel()
//            )
//        }
//    }
//    
//    var ShareButton: some View {
//        ShareLink(item: URL(string: group.inviteLink)!) {
//            Label("", systemImage: "square.and.arrow.up")
//        }
//        .offset(x: CGFloat(-4), y: CGFloat(-2))
//    }
//    
//    var FriendsListButton: some View {
//        Group {
//            Image(systemName: "person.2.fill")
//                .foregroundStyle(Color.blue)
//                .onTapGesture {
//                    self.showFriendSheet.toggle()
//                }
//        }
//        .offset(x: 1)
//    }
//    
//    var FriendsListSheet: some View {
//        //        ZStack {
//        VStack {
//            Text("\(group.name) Members")
//                .font(.title)
//                .multilineTextAlignment(.center)
//                .padding(10)
//            List {
//                ForEach(group.members, id: \.self) { member in
//                    HStack {
//                        if let image = groupPhotos[member.id] {
//                            Image(uiImage: image)
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 60, height: 60)
//                                .clipShape(Circle())
//                        } else {
//                            Image("Default Profile Picture")
//                                .resizable()
//                                .scaledToFill()
//                                .frame(width: 60, height: 60)
//                                .clipShape(Circle())
//                        }
//                        Text(member.name)
//                            .foregroundColor(.primary)
//                        Spacer()
//                        ZStack(alignment: .center) {
//                            RoundedRectangle(cornerRadius: 5)
//                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                            Image(systemName: "person.fill.badge.plus")
//                                .foregroundStyle(.white)
//                        }
//                        .frame(width: 60, height: 40)
//                        .padding(.horizontal, 20)
//                        .shadow(radius: 6)
//                        .onTapGesture {
//                            data.addFriend(friendID: member.id) { success in
//                                print(success)
//                            }
//                        }
//                        
//                    }
//                    .contentShape(Rectangle())
//                    .onTapGesture {
//                        self.showFriendSheet = false
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                            navigationPath.append(member)
//                        }
//                        
//                    }
//                    
//                }
//            }
//        }
//    }
// 
////    var AddFriendButton: some View {
//        
//        
////        Button (action: {
////            print("pressed")
////        }, label: {
////            ZStack(alignment: .center) {
////                RoundedRectangle(cornerRadius: 5)
////                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
////                Image(systemName: "person.fill.badge.plus")
////                    .foregroundStyle(.white)
////            }
////            .frame(width: 60, height: 30)
////        })
//        
////    }
//
//    
//    var SettingsMenu: some View {
//        Group {
//            Menu(content: {
//                Button (action: {
//                    unfriendAlert = true
//                }, label: {
//                    HStack {
//                        Spacer()
//                        Text("❌ Leave Group")
//                            
//                    }.foregroundStyle(Color.red)
//                })
//                
//            }, label: {
//                Image(systemName: "gear")
//                .foregroundStyle(Color.blue)
//            })
//        }
//    }
    
    
    
    
}

struct EditGroupSheet: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var showEditGroupSheet: Bool
    @Binding var currentGroup: SocialGroup
    
    @State var groupNameText: String = ""
    @State private var isLoading = false
    @State private var setupDone = false
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State var createdGroup: DataSet.SocialGroup?
//    @State private var editedPhotoURL: String?
    
    @State var errorAlert: Bool = false
    
    @State private var didRemovePhoto = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Edit Group Details")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(5)
                
                ZStack(alignment: .center) {
                    if let selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())

                            Button {
                                withAnimation {
                                    self.selectedImage = nil
                                    selectedItem = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }

                    } else if let urlString = currentGroup.photo,
                              !didRemovePhoto,
                              let url = URL(string: urlString) {

                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image("Default Group Profile Picture")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())

                            Button {
                                withAnimation {
                                    selectedImage = nil
                                    selectedItem = nil
                                    didRemovePhoto = true
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }

                    } else {
                        ZStack {
                            Image("Default Group Profile Picture")
                                .resizable()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())

                            Text("Upload Image")
                                .foregroundStyle(Color.black)
                        }
                    }
                }
                .shadow(radius: 4)
                .onTapGesture {
                    showPhotoPicker = true
                }

                ZStack {
                    TextField("Group Name", text: $groupNameText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
                    if !groupNameText.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .padding(.horizontal, 10)
                                .foregroundStyle(.gray)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    groupNameText = ""
                                }
                        }
                    }
                }
                HStack {
                    Button(action: { showEditGroupSheet = false }) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    //                .disabled(groupNameText.isEmpty || isLoading)
                    
                    Button(action: editGroup) {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Save")
                            }
                        }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(groupNameText.isEmpty ? Color.gray : .green)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                    .disabled(groupNameText.isEmpty || isLoading)
                }
            }
        }
        .padding()
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                // Retrieve the image from the PhotosPickerItem
                if let selectedItem, let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .alert(isPresented: $errorAlert) {
            Alert(
                title: Text("Something went wrong"),
                message: Text("Please try again later"),
                dismissButton: .default(Text("Ok"))
            )
        }
        .onAppear() {
            groupNameText = currentGroup.name
            
        }
    }
    
    func editGroup() {
        Task {
            isLoading = true
            do {
                let groupID = currentGroup.id!
                var finalPhotoURL: String? = currentGroup.photo

                // 1️⃣ Photo changed
                if let selectedImage {
                    let path = "groupImages/\(groupID).jpg"

                    finalPhotoURL = await withCheckedContinuation { continuation in
                        firestore.uploadGroupImageToFirebase(
                            image: selectedImage,
                            path: path
                        ) { url in
                            continuation.resume(returning: url)
                        }
                    }
                }

                // 2️⃣ Photo deleted
                if didRemovePhoto {
                    try await firestore.deleteGroupImage(groupID: groupID)
                    finalPhotoURL = nil
                }

                // 3️⃣ Update Firestore doc
                try await firestore.updateGroup(
                    groupID: groupID,
                    name: groupNameText,
                    photoURL: finalPhotoURL
                )

                // 4️⃣ Update local state
                currentGroup.name = groupNameText
                currentGroup.photo = finalPhotoURL
                
                if let index = firestore.mySocialGroups.firstIndex(where: { $0.id == $currentGroup.id! }) {
                    firestore.mySocialGroups[index] = currentGroup
                } else {
                    firestore.mySocialGroups.append(currentGroup)
                }

                showEditGroupSheet = false

            } catch {
//                print("❌ Failed to edit group:", error)
                errorAlert = true
            }

            isLoading = false
        }
    }
}




struct AddFestivalsToGroupSheet: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
//    @State var navigationPath = NavigationPath()
    @Binding var group: SocialGroup
    
    @Binding var showAddFestivalToGroupSheet: Bool
    
    @State var selectedFestivals: Set<UUID> = []
    @State var removedFestivals: Set<UUID> = []
    
    @State var popupMessage: String?
    
    @State var showErrorAlert = false
    
    var body: some View {
        VStack {
            //            NavigationStack(path: $navigationPath) {
            NavigationButtons
            (Text("Connect festivals to \"") + Text(group.name).bold() + Text("\""))
            //                Text("Add \(festival.name) To Your Groups")
                .font(.title3)
                .padding(.vertical)
            
            let allFestivals = festivalVM.myFestivals
            let upcomingFestivals = festivalVM.splitFestivals(allFestivals).upcoming
            let unconnectedFestivals = Array(upcomingFestivals.filter({ !group.festivals.contains($0.id.uuidString) }))
            let connectedFestivals = allFestivals.filter({ group.festivals.contains($0.id.uuidString) })
            
            ScrollView {
                if !unconnectedFestivals.isEmpty {
                    VStack(spacing: 4) {
                        HStack {
                            Text("My Upcoming Festivals:")
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(unconnectedFestivals.enumerated()), id: \.element.id) { index, festival in
                                //                                let festival = unconnectedFestivals[index]
                                HStack {
                                    FestivalLogoView(logoPath: festival.logoPath, title: festival.name, frame: 35.0)
                                    //                                    SocialImage(imageURL: group.photo, name: group.name, frame: 50)
                                    //                                    Text(festival.name)
                                    //                                        .foregroundStyle(.black)
                                    Spacer()
                                    //                                    GroupMemberPhotos(memberIDs: group.members)
                                    Image(systemName: selectedFestivals.contains(festival.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(Color("OASIS Dark Orange"))
                                        .imageScale(.large)
                                        .padding(.leading, 20)
                                    
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 10)
                                .onTapGesture {
                                    if selectedFestivals.contains(festival.id) {
                                        selectedFestivals.remove(festival.id)
                                    } else {
                                        selectedFestivals.insert(festival.id)
                                    }
                                }
                                if index < unconnectedFestivals.count - 1 {
                                    Divider()
                                }
                            }
                            
                        }
                        .background(Color.bwColorSwitchReverse)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 10)
                }
                Text("Favorite festivals to have them appear here.").italic().padding(4)
                
                if !connectedFestivals.isEmpty {
                    VStack(spacing: 4) {
                        HStack {
                            if firestore.myUserProfile.id == group.ownerID {
                                Text("Remove:").foregroundStyle(.red)
                            } else {
                                Text("Already Connected:")
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        VStack(spacing: 0) {
                            ForEach(Array(connectedFestivals.enumerated()), id: \.element.id) { index, festival in
                                HStack {
                                    FestivalLogoView(logoPath: festival.logoPath, title: festival.name, frame: 35.0)
                                    Spacer()
                                    if firestore.myUserProfile.id == group.ownerID {
                                        Image(systemName: removedFestivals.contains(festival.id) ? "minus.square.fill" : "square")
                                            .foregroundColor(.red)
                                            .imageScale(.large)
                                            .padding(.leading, 20)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 10)
                                .onTapGesture {
                                    if firestore.myUserProfile.id == group.ownerID {
                                        if removedFestivals.contains(festival.id) {
                                            removedFestivals.remove(festival.id)
                                        } else {
                                            removedFestivals.insert(festival.id)
                                        }
                                    } else {
                                        popupMessage = "Only the festival owner can remove festivals."
                                    }
                                }
                                //                        .onTapGesture {
                                //                            if selectedGroups.contains(group.id!) {
                                //                                selectedGroups.remove(group.id!)
                                //                            } else {
                                //                                selectedGroups.insert(group.id!)
                                //                            }
                                //                        }
                                if index < connectedFestivals.count - 1 {
                                    Divider()
                                }
                            }
                            
                        }
                        .background(Color.bwColorSwitchReverse)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                        
                    }
                    .padding(10)
                    //                    .padding(.vertical, 20)
                }
            }
            //            }
        }
        .overlay(alignment: .bottom) {
            if let message = popupMessage {
                MessagePopUp(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                //                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: popupMessage)
        .onChange(of: popupMessage) { _, newValue in
            guard newValue != nil else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    popupMessage = nil
                }
            }
        }
        .alert(isPresented: self.$removeFestivalsAlert) {
            Alert(title: Text("Disconnect Festivals?"),
                  message: Text("Are you sure you want to disconnect\n\(removedFestivals.count) \(removedFestivals.count == 1 ? "festival" : "festivals") from \(group.name)?"),
                  primaryButton: .destructive(Text("Disconnect")) {
                removeFestivals()
                if !selectedFestivals.isEmpty {
                    addFestivals()
                } else {
                    showAddFestivalToGroupSheet = false
                }
            }, secondaryButton: .cancel()
            )
        }
//        .alert(isPresented: self.$showErrorAlert) {
//            Alert(title: Text("Error"),
//                  message: Text("Please try again later."),
//                  dismissButton: .default(Text("Ok"))
//            )
//        }
        //        .onAppear() {
        //            groupSelection = Array(repeating: false, count: firestore.mySocialGroups.count)
        //        }
    }
    
    @State var removeFestivalsAlert = false
    
    var NavigationButtons: some View {
        VStack {
            HStack {
                Button(action: {
                    showAddFestivalToGroupSheet = false
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                })
                Spacer()
                if !removedFestivals.isEmpty {
                    Button(action: {
                        removeFestivalsAlert = true
                    }, label: {
                        Text("Save").foregroundStyle(.blue)
                    })
                } else {
                    Button(action: {
                        addFestivals()
                    }, label: {
                        Text("Add")
                        .foregroundStyle(selectedFestivals.isEmpty ? .gray : .blue)
                    })
                    .disabled(selectedFestivals.isEmpty)
                }
                //                        .disabled(newArtist == oldArtist)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
//            Divider()
        }
    }
    
    func addFestivals() {
//        firestore.addFestivalsToGroup(groupID: group.id!, festivalIDs: Array(selectedFestivals.map(\.uuidString)))
        Task {
            let success = await firestore.addFestivalsToGroup(groupID: group.id!, festivalIDs: Array(selectedFestivals.map(\.uuidString)))
            if success {
                group.festivals.append(contentsOf: selectedFestivals.map(\.uuidString))
                showAddFestivalToGroupSheet = false
            } else {
                showErrorAlert = true
            }
        }
    }
    
    func removeFestivals() {
//        firestore.addFestivalsToGroup(groupID: group.id!, festivalIDs: Array(selectedFestivals.map(\.uuidString)))
        Task {
            let success = await firestore.removeFestivalsFromGroup(groupID: group.id!, festivalIDs: Array(removedFestivals.map(\.uuidString)))
            if success {
                let removedIDs = Set(removedFestivals.map(\.uuidString))
                group.festivals.removeAll { removedIDs.contains($0) }
//                showAddFestivalToGroupSheet = false
            } else {
                showErrorAlert = true
            }
        }
    }
}

//#Preview {
//    FriendPage()
//}
