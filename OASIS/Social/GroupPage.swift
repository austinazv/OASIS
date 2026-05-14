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
                loadGroup()
            }
            .onChange(of: group.members) { newMemberIDs in
                Task {
                    members = await firestore.users(from: newMemberIDs)
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
//        }
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
    
    func loadGroup() {
        isLoading = true
        
        Task {
            defer { isLoading = false }
            
            let likedFestivals = try await social.fetchFavoritedFestivals(festivalIDs: group.festivals)
            let split = festivalVM.splitFestivals(likedFestivals)
            attendedFestivals = split.attended
            upcomingFestivals = split.upcoming
            
//            followers = await firestore.users(from: profile.safeFollowers)
            members = await firestore.users(from: group.members)
        }
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
    
    var UserHeaderSection: some View {
            HStack {
                SocialImage(imageURL: group.photo, name: group.name, frame: 110)
                    .padding(.leading, 40)
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
            //        .padding(.top, 20)
            .padding(.bottom, 20)
        
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
    
    var FestivalsView: some View {
        VStack {
            if upcomingFestivals.isEmpty && attendedFestivals.isEmpty {
                Spacer()
                Group {
                    Text("This group has no connected festivals yet.")
//                    Text("There are no festivals connected to this group yet.")
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
    
    var MembersView: some View {
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
        .onChange(of: selectedItem) { newItem in
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

//#Preview {
//    FriendPage()
//}
