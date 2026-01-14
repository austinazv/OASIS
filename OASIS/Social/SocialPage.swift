//
//  GroupPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/15/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import Contacts
import CryptoKit

struct SocialPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @StateObject var social = SocialViewModel()
    
    
    @State private var navigationPath = NavigationPath()
    
    @State var isLoadingFriends = false
    @State var friends = Array<UserProfile>()
    
    @State var isLoadingGroups = false
    @State var groups = Array<SocialGroup>()
    
//    @State var profile: DataSet.UserProfile?
//    @State private var isProfileLoaded = false
    
//    let userID: String

    var body: some View {
        if firestore.phoneConnected {
            SocialPageBody
        } else {
            AccountSetUpPage()
        }
    }
    
    var SocialPageBody: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Social")
                            .font(.title)
                            .bold()
                        Spacer()
                        SocialButton
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                    Divider()
                    ZStack {
//                        Color(.oasisDarkOrange)
                        Color(red: 235/255, green: 230/255, blue: 245/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
//                        if explore.isLoading {
//                            Spacer()
//                            ProgressView()
//                                .foregroundStyle(.black)
//                            Spacer()
//                        } else {
                            VStack {
                                GroupsListed
                                FriendsListed
                                Spacer()
                            }
                            .padding(.top, 5)
//                            .refreshable {
//                                explore.fetchVerifiedFestivals()
//                            }
//                        }
                    }
                    
                }
                .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
            }
        }
    }
    
    
    
    var SocialButton: some View {
        Group {
            Menu(content: {
                Button (action: {
                    showAddFriendsSheet = true
                }, label: {
                    Text("Find People")
                    Image(systemName: "person.2.fill")
                })
                Button (action: {
                    //TODO: Group stuff
                    showGroupSheet = true
                }, label: {
                    Text("New Group")
                    Image(systemName: "person.3.fill")
                })
            }, label: {
                Image(systemName: "person.2.fill")
                    .imageScale(.large)
                    .foregroundStyle(.blue)
            })
        }
        
    }
    
    @State var showAddFriendsSheet = false
    
    var FriendsListed: some View {
        Group {
            VStack {
                HStack {
                    Text("Following")
                    Button(action: { showAddFriendsSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top], 10)
                .foregroundStyle(.black)
                .bold()
                VStack {
                    if isLoadingFriends {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(10)
                        .border(Color.gray, width: 2)
                        .padding([.leading, .trailing, .bottom], 10)
                    } else {
                        if !friends.isEmpty {
                            ProfilesListed(navigationPath: $navigationPath, profiles: friends)
                        } else {
//                            Button(action: { showAddFriendsSheet = true }) {
                                HStack {
                                    Spacer()
//                                    Image(systemName: "plus.circle.fill")
                                    Text("You are not following anyone yet.")
                                    Spacer()
                                }
                                .foregroundStyle(.black)
                                .frame(height: 60)
                                .background(Color.white)
                                .contentShape(Rectangle())
                                .cornerRadius(10)
                                .border(Color.gray, width: 2)
                                .padding([.leading, .trailing, .bottom], 10)
//                            }
                        }
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showAddFriendsSheet) {
            AddFriendsSheet
        }
        .onAppear {
            loadFriends()
            loadGroups()
        }
        .onChange(of: showAddFriendsSheet) { newValue in
            if !newValue {
                loadFriends()
            }
        }
        .onChange(of: navigationPath) { _ in
            showAddFriendsSheet = false
        }
    }
    
    func loadFriends() {
        if friends.isEmpty { isLoadingFriends = true }
        Task {
            do {
                friends = try await social.fetchUsers(from: firestore.myUserProfile.safeFollowing)
                isLoadingFriends = false
                
            } catch {
                print("Error:", error)
                isLoadingFriends = false
            }
        }
    }
    
    func loadGroups() {
        if groups.isEmpty { isLoadingGroups = true }
        Task {
            do {
                groups = try await social.fetchGroups(from: firestore.myUserProfile.safegroups)
                isLoadingGroups = false
                
            } catch {
                print("Error:", error)
                isLoadingGroups = false
            }
        }
    }
    
//    struct AddFriendsSheet: View {
//        @EnvironmentObject var social: SocialViewModel
//        @EnvironmentObject var festivalVM: FestivalViewModel
        
//        @State private var navigationPath = NavigationPath()
        
        @StateObject private var contactsManager = ContactsManager()
        @State private var showingDeniedAlert = false
        
        var AddFriendsSheet: some View {
            NavigationStack(path: $navigationPath) {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Connect on OASIS")
                            .font(.title)
                            .fontWeight(.bold)
                            .padding(5)
                        ShareLink(item: social.getInviteLink()) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Send My Invite Link")
                            }
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            //                    .padding(10)
                        }
                        if contactsManager.permissionGranted {
                            ContactsListed
                        } else {
                            Button(action: {
                                contactsManager.requestAccess()
                            }, label: {
                                HStack {
                                    Image(systemName: "text.book.closed.fill")
                                    Text("Connect Contacts")
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(.oasisDarkBlue)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                                //                        .padding(10)
                            })
                        }
                    }
                    .padding()
                }
                .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
                .alert("Contacts Access Denied",
                       isPresented: $showingDeniedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Please enable Contacts access in Settings to find friends.")
                }
                .onChange(of: contactsManager.permissionGranted) { granted in
                    if granted {
                        Task { await contactsManager.loadContactsIfNeeded() }
                    } else {
                        showingDeniedAlert = true
                    }
                }
                .onAppear {
                    Task {
                        await contactsManager.loadFriendsFromContacts()
                        print(contactsManager.matchedFriends)
                    }
                }
            }
        }
        
        var ContactsListed: some View {
            Group {
                VStack {
                    HStack {
                        Text("Contacts on OASIS")
                            .bold()
                        Spacer()
                        Button(action: {
                            Task {
                                await contactsManager.loadFriendsFromContacts(forceRefresh: true)
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .padding(.horizontal, 12)
                    if contactsManager.isLoadingFriends {
                        HStack {
                            ProgressView()
                            Text("Connecting Contacts...")
                                .italic()
                        }
                    } else {
                        ProfilesListed(navigationPath: $navigationPath, profiles: contactsManager.matchedFriends)
                    }
                }
                .padding(.top, 10)
            }
        }
//    }
    
    
    @State var showGroupSheet = false
    
    var GroupsListed: some View {
        Group {
            VStack {
                HStack {
                    Text("Groups")
                    Button(action: { showGroupSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
                .padding([.horizontal, .top], 10)
                .foregroundStyle(.black)
                .bold()
                VStack {
                    if isLoadingGroups {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(10)
                        .border(Color.gray, width: 2)
                        .padding([.leading, .trailing, .bottom], 10)
                    } else {
                        if !groups.isEmpty {
                            GroupsList(navigationPath: $navigationPath, groups: groups)
                            //                        ForEach(social.groups) { group in
                            ////                            EmptyView()
                            //                            HStack {
                            //                                SocialImage(imageURL: group.photo, name: group.name, frame: 40)
                            //                                Text(group.name)
                            //                            }
                            //                            .contentShape(Rectangle())
                            //                            .padding(.horizontal, 10)
                            //                            .onTapGesture() {
                            ////                                //TODO: NavPath to GroupPage
                            //////                                 navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView))
                            //                            }
                            ////                            Divider()
                            //                        }
                        } else {
                            //                        Button(action: { showGroupSheet = true }) {
                            HStack {
                                Spacer()
                                //                                Image(systemName: "plus.circle.fill")
                                Text("You do not have any groups yet.")
                                Spacer()
                            }
                            .foregroundStyle(.black)
                            .frame(height: 60)
                            .background(Color.white)
                            .contentShape(Rectangle())
                            .cornerRadius(10)
                            .border(Color.gray, width: 2)
                            .padding([.leading, .trailing, .bottom], 10)
                            //                            .background()
                        }
                        //                        .onTapGesture() {
                        //                            //TODO: New group
                        //                            showGroupSheet = true
                        //                        }
                    }
                    
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .sheet(isPresented: $showGroupSheet) {
            NewGroupSheet
//            GroupSetUpPage(navigationPath: $navigationPath)
        }
    }
    
    
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var setupDone = false
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State var createdGroup: DataSet.SocialGroup?
    
    @State var errorAlert: Bool = false
    
    var NewGroupSheet: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create New Group")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(5)
                
                ZStack(alignment: .center) {
                    if let selectedImage {
                        ZStack (alignment: .topTrailing) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130, alignment: .center)
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
                    } else {
                        Image("Default Group Profile Picture")
                            .resizable()
                            .frame(width: 130, height: 130, alignment: .center)
                            .clipShape(Circle())
                        Text("Upload Image").foregroundStyle(Color.black)
                    }
                }
                //                    if selectedImage != nil {
                //                        Button {
                //                            withAnimation {
                //                                selectedImage = nil
                //                                selectedItem = nil
                //                            }
                //                        } label: {
                //                            Image(systemName: "xmark")
                //                                .font(.system(size: 10, weight: .bold))
                //                                .foregroundColor(.white)
                //                                .padding(6)
                //                                .background(Color.black.opacity(0.85))
                //                                .clipShape(Circle())
                //                                .overlay(
                //                                    Circle().stroke(Color.white, lineWidth: 1)
                //                                )
                //                        }
                //                        // Position slightly outside the 130x130 circle visually
                //                        .offset(x: 6, y: -6)
                //                        .accessibilityLabel("Remove photo")
                //                    }
                //                }
                .shadow(radius: 4)
                .onTapGesture {
                    showPhotoPicker = true
                }
                ZStack {
                    TextField("Group Name", text: $groupName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
                    if !groupName.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .padding(.horizontal, 10)
                                .foregroundStyle(.gray)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    groupName = ""
                                }
                        }
                    }
                }
                
                
                
                Button(action: addGroup) {
                    Text("Create")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(groupName.isEmpty ? Color.gray : .blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(groupName.isEmpty || isLoading)
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
        .onChange(of: errorAlert) { newValue in
            if newValue == false {
                navigationPath.removeLast()
            }
            //                print("🔄 pendingFriendRequest updated: \(String(describing: newValue))")
        }
        .onAppear() {
            groupName = ""
            selectedItem = nil
            selectedImage = nil
        }
    }
    
    func addGroup() {
        Task {
            do {
                let newGroup = try await firestore.createGroup(
                    name: groupName,
                    photo: nil
                )
//                fire
                print("Created group:", newGroup.id)
            } catch {
                print("Failed to create group:", error)
            }
        }
        
//        if let myID = firestore.getUserID() {
//            var newGroup = SocialGroup(id: UUID().uuidString, ownerID: myID, name: groupName, members: [firestore.myUserProfile.id!], festivals: [])
//            firestore.createGroup(group: newGroup)
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("FFF8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("GGG8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("HHH8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("III8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("JJJ8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("LLL8gsIB5WgFBrHY6ruBTM5s0sR3") }
////            if Int.random(in: 0..<2) == 0 { newGroup.members.append("MMM8gsIB5WgFBrHY6ruBTM5s0sR3") }
//            
//            social.groups.append(newGroup)
//            navigationPath.append(newGroup)
//        }
        showGroupSheet = false
    }
    
    func placeholder() {
        print("TODO")
    }
    
    
    
    
//    var FriendSection: some View {
//        Group {
//            Section(header: Group {
//                HStack {
//                    Text("My Friends")
//                    ShareLink(item: data.getInviteLink()) {
//                        Label("", systemImage: "plus.circle")
//                    }
//                }
//                .font(.headline)
//            }) {
//                Group {
//                    if !isProfileLoaded {
//                        ProgressView()
//                    } else if profile!.friends.isEmpty {
//                        Text("No Friends Yet")
//                    } else {
//                        List(profile!.friends) { friend in
//                            NavigationLink(value: friend) {
//                                if let localPath = friend.profilePic, let image = UIImage(contentsOfFile: localPath) {
//                                    Image(uiImage: image)
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(width: 40, height: 40)
//                                        .clipShape(Circle())
//                                } else {
//                                    Image("Default Profile Picture")
//                                        .resizable()
//                                        .frame(width: 40, height: 40, alignment: .center)
//                                        .clipShape(Circle())
//                                }
//                                Text(friend.name)
//                            }
//                        }
//                        
//                    }
//                }
//            }
//        }
//    }
    
//    func sortFriends(friends: Array<DataSet.FriendProfile>) -> Array<DataSet.FriendProfile> {
//        var friendsSorted = friends
//        return friendsSorted.sorted(by: {
//            
//        })
//    }
}

//#Preview {
//    GroupPage()
//}

//        Form {
//            GroupSection
//            FriendSection
//
//        }
//
//        .onChange(of: profile) { newProfile in
//            if newProfile != nil {
//                isProfileLoaded = true
//            }
//        }
//        .onAppear {
//            if profile == nil {
//                if data.userInfo == nil {
//                    data.fetchUserProfile(userID: userID) { success in
//                        DispatchQueue.main.async {
//                            //                            isProfileLoaded = success // Update state when the profile is ready
//                            if success {
//                                self.profile = data.userInfo
//                            } else {
//                                //                                    dismiss()
//                            }
//                        }
//                    }
//                } else {
//                    self.profile = data.userInfo
//                }
//            } else {
//                isProfileLoaded = true
//            }
//        }
//
//        .navigationTitle("Social")
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                if isProfileLoaded, let userProfile = profile {
//                    NavigationLink(value: userProfile) {
////
////                    NavigationLink(destination: MyProfilePage(/*loggedIn: $loggedIn, */profile: userProfile).environmentObject(data)) {
//                        HStack {
//                            Text("My Profile")
//                            Image(systemName: "chevron.right")
//                        }
//                        //                        if let profilePic = viewModel.userInfo.profilePic, let url = URL(string: profilePic) {
//                        //                            AsyncImage(url: url) { image in
//                        //                                image
//                        //                                    .resizable()
//                        //                                    .scaledToFill()
//                        //                            } placeholder: {
//                        //                                ProgressView()
//                        //                            }
//                        //                            .frame(width: 20, height: 20)
//                        //                            .clipShape(Circle())
//                        //                        } else {
//                        //                            Image("Default Profile Picture")
//                        //                                .resizable()
//                        //                                .frame(width: 30, height: 30, alignment: .center)
//                        //                                .clipShape(Circle())
//                        //                        }
//                    }
//                }
//            }
//        }

struct SocialImage: View {
    let imageURL: String?
    let name: String
    let frame: CGFloat
    
    var fallback: some View {
        BlankProfileImage(name: name, frame: frame)
    }
    
    var body: some View {
        Group {
            if let imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: frame, height: frame)
                            .clipShape(Circle())
                    } else {
                        fallback
                    }
                }
            } else {
                fallback
            }
        }
        .overlay(
            Circle()
                .stroke(.black, lineWidth: 1)
                .frame(width: frame, height: frame)
        )
    }
}


struct BlankProfileImage: View {
    let name: String
//    let id: String
    let frame: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .frame(width: frame, height: frame)
                .foregroundStyle(colorFromString(name))
            Group {
                if let letter = name.first {
                    Text(String(letter))
                } else {
                    Text("?")
                }
            }
            .font(.system(size: frame * 0.5))
            .foregroundStyle(.black)
        }
    }
    
    func colorFromString(_ string: String) -> Color {
        var hash: UInt64 = 0

        for scalar in string.unicodeScalars {
            hash = hash &* 31 &+ UInt64(scalar.value)
        }

        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6
        let brightness = 0.85

        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}


struct ProfilesListed: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    @State var profiles: [UserProfile]

    var maxHeight: CGFloat = 300
    
    var allowNavigation = true

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let sortedProfiles = profiles.sorted(by: { $0.name < $1.name })
                
                ForEach(sortedProfiles.indices, id: \.self) { index in
                    let profile = sortedProfiles[index]
                    HStack {
                        SocialImage(imageURL: profile.profilePic, name: profile.name, frame: 50)
                        Text(profile.name)
                            .foregroundStyle(.black)
                        Spacer()
                        if firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                            if allowNavigation {
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.black)
                            }
                        } else {
                            FollowButtonShort(profile: profile, allowNavigation: allowNavigation)
                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        if allowNavigation {
                            navigationPath.append(profile)
                        }
                    }

                    if index < sortedProfiles.count - 1 {
                        Divider()
                    }
                }

            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(Color.white)
        .frame(maxHeight: maxHeight) // <- caps the height; scrolls after this
        .cornerRadius(10)
        .border(Color.gray, width: 2)
        .padding(.horizontal, 10)
    }
    
    
}

struct FollowButtonShort: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    var profile: UserProfile
    
    var allowNavigation: Bool
    
    var body: some View {
        Group {
            if let profileID = profile.id {
                if profileID != firestore.getUserID() {
                    Button {
                        firestore.followUser(profileID)
                    } label: {
                        Group {
                            if firestore.followUnfollowLoadingArray.contains(profileID) {
                                ProgressView()
                            } else {
                                HStack {
                                    Image(systemName: "person.fill.badge.plus")
                                }
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.blue)
                        )
                        .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                } else {
                    if allowNavigation {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.black)
                    }
                }
            }
        }
    }
}

struct ProfileButton: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    let profile: UserProfile
    
    var body: some View {
        if let profileID = profile.id, profileID != firestore.getUserID() {
            button(for: profileID)
        }
    }
    
    @ViewBuilder
    private func button(for profileID: String) -> some View {
        if firestore.myUserProfile.safeFollowing.contains(profileID) {
            FollowButtonLong(
                profileID: profileID,
                text: "Following",
//                symbol: "person.fill.xmark",
                color: .gray,
                shadow: 0
            ) {
//                firestore.unfollowUser(profileID)
            }
        } else if firestore.myUserProfile.safeFollowers.contains(profileID) {
            FollowButtonLong(
                profileID: profileID,
                text: "Follow Back",
                color: .blue
            ) {
                firestore.followUser(profileID)
            }
        } else {
            FollowButtonLong(
                profileID: profileID,
                text: "Follow",
                symbol: "person.fill.badge.plus",
                color: .blue
            ) {
                firestore.followUser(profileID)
            }
        }
    }
}

struct ShareGroupButton: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    let profile: UserProfile
    
    var body: some View {
        if let profileID = profile.id, profileID != firestore.getUserID() {
            button(for: profileID)
        }
    }
    
    @ViewBuilder
    private func button(for profileID: String) -> some View {
        if firestore.myUserProfile.safeFollowing.contains(profileID) {
            FollowButtonLong(
                profileID: profileID,
                text: "Following",
//                symbol: "person.fill.xmark",
                color: .gray,
                shadow: 0
            ) {
//                firestore.unfollowUser(profileID)
            }
        } else if firestore.myUserProfile.safeFollowers.contains(profileID) {
            FollowButtonLong(
                profileID: profileID,
                text: "Follow Back",
                color: .blue
            ) {
                firestore.followUser(profileID)
            }
        } else {
            FollowButtonLong(
                profileID: profileID,
                text: "Follow",
                symbol: "person.fill.badge.plus",
                color: .blue
            ) {
                firestore.followUser(profileID)
            }
        }
    }
}


struct FollowButtonLong: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    let profileID: String
    let text: String
    let symbol: String?
    let color: Color
    let shadow: CGFloat
    let action: () -> Void
    
    private var isLoading: Bool {
        firestore.followUnfollowLoadingArray.contains(profileID)
    }
    
    init(
        profileID: String,
        text: String,
        symbol: String? = nil,
        color: Color,
        shadow: CGFloat = 5,
        action: @escaping () -> Void
    ) {
        self.profileID = profileID
        self.text = text
        self.symbol = symbol
        self.color = color
        self.shadow = shadow
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    HStack(spacing: 6) {
                        Text(text)
                        if let symbol {
                            Image(systemName: symbol)
                        }
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(width: 135, height: 35)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(color)
            )
            .shadow(radius: shadow)
        }
        .buttonStyle(.plain)
        .padding(0)
        .disabled(isLoading)
    }
}


struct GroupsList: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    var groups: [SocialGroup]

    var maxHeight: CGFloat = 300

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                let sortedGroups = groups.sorted(by: { $0.name < $1.name })
                
                ForEach(sortedGroups.indices, id: \.self) { index in
                    let group = sortedGroups[index]
                    HStack {
                        SocialImage(imageURL: group.photo, name: group.name, frame: 50)
//                        VStack(alignment: .leading, spacing: 5) {
                            Text(group.name)
//                                .bold()
//                                .font(.title)
                                .foregroundStyle(.black)
//                                .padding(.leading, 10)
                            
//                        }
                        Spacer()
                        GroupMemberPhotos(memberIDs: group.members)
//                        if firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.black)
//                        } else {
//                            FollowButtonShort(profile: profile)
//                        }
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 10)
                    .onTapGesture {
                        navigationPath.append(group)
                    }

                    if index < sortedGroups.count - 1 {
                        Divider()
                    }
                }

            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .background(Color.white)
        .frame(maxHeight: maxHeight) // <- caps the height; scrolls after this
        .cornerRadius(10)
        .border(Color.gray, width: 2)
        .padding(.horizontal, 10)
    }
}

struct GroupMemberPhotos: View {
    @EnvironmentObject var social: SocialViewModel
    
    @State var isLoading = false
    
    var memberIDs: Array<String>
    @State var members: Array<UserProfile> = []
    
    var photoWidth: CGFloat = 30
    let OFFSET_WIDTH = -20
    
    var body: some View {
        ZStack {
            let membersSorted = members.sorted(by: { $0.name < $1.name })
            if members.count > 3 {
                Group {
                    SocialImage(imageURL: membersSorted[0].profilePic, name: membersSorted[0].name, frame: photoWidth)
                        .offset(x: CGFloat(OFFSET_WIDTH*2))
                    SocialImage(imageURL: membersSorted[1].profilePic, name: membersSorted[1].name, frame: photoWidth)
                        .offset(x: CGFloat(OFFSET_WIDTH))
                    Circle()
                        .fill(Color.white)
                        .frame(width: photoWidth, height: photoWidth)
                        .overlay(
                            Circle().stroke(Color.black, lineWidth: 1)
                        )
                    Text("+\(members.count - 2)")
                        .font(.subheadline)
                }
            } else {
                ForEach(Array(membersSorted.enumerated()), id: \.element.id) { index, profile in
//                    let offset = CGFloat((members.count - (index + 1)) * 15.0)
                    SocialImage(imageURL: profile.profilePic, name: profile.name, frame: photoWidth)
//                        .offset(x: CGFloat(index * 15))
                        .offset(x: CGFloat((members.count - (index + 1)) * OFFSET_WIDTH))
                        .zIndex(Double(index))
//
                }
            }
//            .offset(x: -5)
        }
        .onAppear() {
            isLoading = true
            
            Task {
                do {
                    if !memberIDs.isEmpty {
                        members = try await social.fetchUsers(from: memberIDs)
                    }
                    isLoading = false
    //
                } catch {
                    print("Error:", error)
                    isLoading = false
                }
            }
        }
    }
}


//struct AddFriendsSheet: View {
//    @EnvironmentObject var social: SocialViewModel
//    @EnvironmentObject var festivalVM: FestivalViewModel
//    
//    @State private var navigationPath = NavigationPath()
//    
//    @StateObject private var contactsManager = ContactsManager()
//    @State private var showingDeniedAlert = false
//    
//    var body: some View {
//        NavigationStack(path: $navigationPath) {
//            ScrollView {
//                VStack(spacing: 20) {
//                    Text("Add Friends")
//                        .font(.title)
//                        .fontWeight(.bold)
//                    ShareLink(item: social.getInviteLink()) {
//                        HStack {
//                            Image(systemName: "square.and.arrow.up")
//                            Text("Send My Invite Link")
//                        }
//                        .frame(height: 60)
//                        .frame(maxWidth: .infinity)
//                        .background(.blue)
//                        .foregroundStyle(.white)
//                        .cornerRadius(10)
//                        .shadow(radius: 5)
//                        //                    .padding(10)
//                    }
//                    if contactsManager.permissionGranted {
//                        ContactsListed
//                    } else {
//                        Button(action: {
//                            contactsManager.requestAccess()
//                        }, label: {
//                            HStack {
//                                Image(systemName: "text.book.closed.fill")
//                                Text("Connect Contacts")
//                            }
//                            .frame(height: 60)
//                            .frame(maxWidth: .infinity)
//                            .background(.oasisDarkBlue)
//                            .foregroundStyle(.white)
//                            .cornerRadius(10)
//                            .shadow(radius: 5)
//                            //                        .padding(10)
//                        })
//                    }
//                }
//                .padding()
//            }
//            .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
//            .alert("Contacts Access Denied",
//                   isPresented: $showingDeniedAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text("Please enable Contacts access in Settings to find friends.")
//            }
//            .onChange(of: contactsManager.permissionGranted) { granted in
//                if granted {
//                    Task { await contactsManager.loadContactsIfNeeded() }
//                } else {
//                    showingDeniedAlert = true
//                }
//            }
//            .onAppear {
//                Task {
//                    await contactsManager.loadFriendsFromContacts()
//                    print(contactsManager.matchedFriends)
//                }
//            }
//        }
//    }
//    
//    var ContactsListed: some View {
//        Group {
//            VStack {
//                HStack {
//                    Text("Contacts on OASIS")
//                        .bold()
//                    Spacer()
//                    Button(action: {
//                        Task {
//                            await contactsManager.loadFriendsFromContacts(forceRefresh: true)
//                        }
//                    }) {
//                        Image(systemName: "arrow.clockwise")
//                    }
//                }
//                .padding(.horizontal, 12)
//                if contactsManager.isLoadingFriends {
//                    HStack {
//                        ProgressView()
//                        Text("Connecting Contacts...")
//                            .italic()
//                    }
//                } else {
//                    ProfilesListed(navigationPath: $navigationPath, profiles: contactsManager.matchedFriends)
//                }
//            }
//            .padding(.top, 10)
//        }
//    }
//}



@MainActor
class ContactsManager: ObservableObject {
    @Published var permissionGranted = false
    @Published var uploadComplete = false
    @Published var contacts: [String] = []
    @Published var hashedContacts: [String] = []
    @Published var isLoaded = false
    @Published var matchedFriends: [UserProfile] = []
    @Published var isLoadingFriends = false

    private let store = CNContactStore()
    private let db = Firestore.firestore()
    
    // Keys for UserDefaults
    private let uploadKey = "contactsUploaded"
    private let hashCacheKey = "hashedContactsCache"
    private let cachedMatchedIDsKey = "cachedMatchedFriendIDs"

    init() {
        // Check contacts permission
        let status = CNContactStore.authorizationStatus(for: .contacts)
        permissionGranted = (status == .authorized)
        
        // Check if contacts were already uploaded
        uploadComplete = UserDefaults.standard.bool(forKey: uploadKey)
        
        // Load cached hashes if available
        if let cached = UserDefaults.standard.array(forKey: hashCacheKey) as? [String], !cached.isEmpty {
            self.hashedContacts = cached
            self.isLoaded = true
        }
        
        // 4️⃣ Cached matched friend IDs (do NOT fetch yet)
            if let cachedIDs = UserDefaults.standard.stringArray(forKey: cachedMatchedIDsKey),
               !cachedIDs.isEmpty {
                print("📦 Found \(cachedIDs.count) cached matched friend IDs")
            }
    }

    // MARK: - Request Access

    func requestAccess() {
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                self.permissionGranted = granted
                if granted {
                    Task {
                        await self.loadContactsIfNeeded()
                        await self.handleFirstTimeUploadIfNeeded()
                    }
                }
            }
        }
    }

    // MARK: - Load Contacts for UI (normalized)

    func loadContactsIfNeeded() async {
        guard permissionGranted else { return }
        guard !isLoaded else { return }

        isLoaded = true

        // Fetch & normalize
        let numbers = await fetchContacts()
        contacts = numbers
        
        // Hash and cache
        hashedContacts = Array(Set(numbers.map(hashPhoneNumber)))
        UserDefaults.standard.set(hashedContacts, forKey: hashCacheKey)
        print("📥 Contacts loaded: \(contacts.count), hashed: \(hashedContacts.count)")
    }

    // MARK: - Upload Once

    func handleFirstTimeUploadIfNeeded() async {
        guard permissionGranted, !uploadComplete else { return }

        if hashedContacts.isEmpty {
            let numbers = await fetchContacts()
            contacts = numbers
            hashedContacts = Array(Set(numbers.map(hashPhoneNumber)))
            UserDefaults.standard.set(hashedContacts, forKey: hashCacheKey)
        }

        await uploadContacts(hashedContacts)
        uploadComplete = true
        UserDefaults.standard.set(true, forKey: uploadKey)
    }

    private func fetchContacts() async -> [String] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var results: [String] = []

                let request = CNContactFetchRequest(
                    keysToFetch: [CNContactPhoneNumbersKey as CNKeyDescriptor]
                )

                do {
                    try self.store.enumerateContacts(with: request) { contact, _ in
                        for labeled in contact.phoneNumbers {
                            if let normalized = self.normalizePhoneNumber(
                                labeled.value.stringValue
                            ) {
                                results.append(normalized)
                            }
                        }
                    }
                } catch {
                    print("❌ Contact fetch failed:", error)
                }

                continuation.resume(returning: results)
            }
        }
    }

    // MARK: - Normalize + Hash

    private func normalizePhoneNumber(_ number: String) -> String? {
        // Keep only digits
        var digits = number.components(
            separatedBy: CharacterSet.decimalDigits.inverted
        ).joined()

        // Remove leading US country code
        if digits.count == 11, digits.hasPrefix("1") {
            digits.removeFirst()
        }

        // Must be exactly 10 digits
        guard digits.count == 10 else {
            return nil
        }

        return digits
    }


    private func hashPhoneNumber(_ number: String) -> String {
        let data = Data(number.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Upload to Firestore

    private func uploadContacts(_ hashes: [String]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = db.collection("users").document(uid)

        do {
            try await doc.setData(["contacts": hashes], merge: true)
            print("✅ Uploaded \(hashes.count) contacts")
        } catch {
            print("❌ Upload failed:", error)
        }
    }
    
    func fetchFriendsFromContacts(hashedContacts: [String]) async -> [UserProfile] {

        guard !hashedContacts.isEmpty else { return [] }

        let db = Firestore.firestore()
        var matchedUsers: [UserProfile] = []

        let chunks = hashedContacts.chunked(into: 10)

        for chunk in chunks {
            do {
                let snapshot = try await db.collection("users")
                    .whereField("phoneHash", in: chunk)
                    .getDocuments()

                for doc in snapshot.documents {
                    if let user = try? doc.data(as: UserProfile.self) {
                        matchedUsers.append(user)
                    }
                }
            } catch {
                print("❌ Error fetching friends:", error)
            }
        }

        return matchedUsers
    }

    func loadFriendsFromContacts(forceRefresh: Bool = false) async {
        guard permissionGranted else {
            print("⚠️ Contacts permission not granted")
            return
        }

        let cachedIDs = loadCachedMatchedFriendIDs()

        // 1️⃣ Restore from cache if allowed
        if !forceRefresh, !cachedIDs.isEmpty {
            print("📦 Using cached matched friend IDs")
            await restoreCachedFriends(from: cachedIDs)
            return
        }

        isLoadingFriends = true

        // 2️⃣ Ensure hashes exist
        if hashedContacts.isEmpty {
            print("📥 No hashes — fetching contacts")

            let numbers = await fetchContacts()
            contacts = numbers
            hashedContacts = Array(Set(numbers.map(hashPhoneNumber)))
            UserDefaults.standard.set(hashedContacts, forKey: hashCacheKey)
        }

        guard !hashedContacts.isEmpty else {
            isLoadingFriends = false
            return
        }

        // 3️⃣ Query Firestore
        let friends = await fetchFriendsFromContacts(
            hashedContacts: hashedContacts
        )

        let myUID = Auth.auth().currentUser?.uid
        let filtered = friends.filter { $0.id != myUID }

        matchedFriends = filtered
        saveMatchedFriendIDs(filtered.compactMap(\.id))

        isLoadingFriends = false
        print("🎉 Found \(filtered.count) friends")
    }


    
    private func saveMatchedFriendIDs(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: cachedMatchedIDsKey)
    }

    private func loadCachedMatchedFriendIDs() -> [String] {
        UserDefaults.standard.stringArray(forKey: cachedMatchedIDsKey) ?? []
    }
    
    func restoreCachedFriends(from ids: [String]) async {
        guard !ids.isEmpty else { return }

        isLoadingFriends = true
        print("📦 Restoring \(ids.count) cached friends")

        var users: [UserProfile] = []

        for id in ids {
            if let doc = try? await db.collection("users").document(id).getDocument(),
               let user = try? doc.data(as: UserProfile.self) {
                users.append(user)
            }
        }

        matchedFriends = users
        isLoadingFriends = false
    }



}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}




