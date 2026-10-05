//
//  OASISApp.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/14/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseCore
import UserNotifications
import FirebaseAuth
import FirebaseAppCheck
import FirebaseMessaging


@main
struct OASISApp: App {
    @StateObject var data = DataSet(name: "AZV31")
    @StateObject var spotify = SpotifyViewModel(name: "AZV30")
    @StateObject var firestore = FirestoreViewModel(name: "AZV31")
    @StateObject var festivalVM = FestivalViewModel(name: "Austin31")
    @StateObject var social = SocialViewModel()
    @StateObject var explore = ExploreViewModel()
    @StateObject var tags = TagViewModel(name: "Austin30")
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var deepLinkManager = DeepLinkManager.shared
    
    @State private var userLoggedIn: Bool = false
    @State private var userHasName: Bool = false
    @State private var userSelectedFestivals: Bool = false
    
    @State private var logInSuccess: Bool = false
    
    @State private var errorAlert: Bool = false
    @State private var pendingRequest: DataSet.Request?
    @State private var showRequestSheet = false
    
    @State private var groupRequest = false

    // Shared namespace for morphing the “O” and the title between screens
//    @Namespace private var oasisNamespace
    
    @State var explorePath = NavigationPath()
    @State var socialPath = NavigationPath()
    @State var myFestivalsPath = NavigationPath()
    @State var createPath = NavigationPath()
    @State var myProfilePath = NavigationPath()
    
    @State private var selectedTab = 0
    
    @State var URLLoading = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content (behind while loading)
                Group {
                    
//                    if firestore.isLoggedIn || firestore.userWithoutSignIn {
//                        if spotify.isLoggedIn {
                            NavigationBottomBarView(explorePath: $explorePath, socialPath: $socialPath, myFestivalsPath: $myFestivalsPath, createPath: $createPath, myProfilePath: $myProfilePath, selectedTab: $selectedTab)
                                .environmentObject(data)
                                .environmentObject(spotify)
                                .environmentObject(firestore)
                                .environmentObject(festivalVM)
                                .environmentObject(social)
                                .environmentObject(explore)
                                .environmentObject(tags)
//                        } else {
//                            SpotifyConnectPage()
//                                .environmentObject(data)
//                                .environmentObject(spotify)
//                                .environmentObject(firestore)
//                                .environmentObject(festivalVM)
//                                .environmentObject(social)
//                                .environmentObject(explore)
//                        }
//                    } else {
//                        LogInPage()
//                            .environmentObject(data)
//                            .environmentObject(spotify)
//                            .environmentObject(firestore)
//                            .environmentObject(festivalVM)
//                            .environmentObject(social)
//                            .environmentObject(explore)
//                            .environmentObject(tags)
//                    }
                    if URLLoading {
                        ProgressView()
                    }
                }
                // Provide the shared namespace to all children so titles can match geometry
//                .environment(\.oasisNamespace, oasisNamespace)
                .opacity(spotify.isLoading ? 0 : 1)
                .animation(.easeInOut(duration: 0.45), value: spotify.isLoading)
                
                // Loading layer on top
                if spotify.isLoading {
//                    GeometryReader { geo in
                        VStack(alignment: .center, spacing: 0) {
                            Spacer().frame(height: 170)
                            OASISLoadingScreen(/*namespace: oasisNamespace*/).fixedSize()/*.border(.green)*/
                            Text("EXPLORE THE LINE-UP").kerning(6).font(.system(size: 12)).offset(y: -8).foregroundStyle(.oasisDarkPurple)
                            Spacer()/*.frame(height: geo.size.height * 0.72)*/
                            Text("By Austin Zambito-Valente").padding(20).italic().font(.system(size: 12)).foregroundStyle(.oasisDarkPurple)
                        }
                        .animation(.easeInOut(duration: 1.35), value: spotify.isLoading)
//                    }
                    
                }
            }
            // Request sheet for invites/auth
            .sheet(isPresented: $showRequestSheet, content: {
                Group {
                    if Auth.auth().currentUser != nil {
                        if let request = pendingRequest {
                            if groupRequest {
                                GroupRequestSheet(request: request, showRequestSheet: $showRequestSheet)
                                    .id(request.id)
                                    .environmentObject(social)
                                    .environmentObject(firestore)
                            } else {
                                FriendRequestSheet(request: request, showRequestSheet: $showRequestSheet)
                                    .id(request.id)
                                    .environmentObject(firestore)
                            }
                        } else {
                            Text("Loading...")
                        }
                    } else {
                        PhoneAuthPage(/*loggedIn: $loggedIn*/).environmentObject(data)
                    }
                }
            })
            .onChange(of: pendingRequest) { _ , newValue in
                if newValue != nil {
                    self.showRequestSheet = true
                }
            }
            .onOpenURL { url in
                handleURL(url)
            }
            .onReceive(deepLinkManager.$pendingURL.compactMap { $0 }) { url in
                print("URL DEEPLINK RECIEVED")
                handleURL(url)
            }
            .alert(isPresented: $logInSuccess) {
                Alert(title: Text("Successfully Signed In to Spotify"),
                             dismissButton: .default(Text("OK")))
            }
//            .onAppear {
//                try? Auth.auth().signOut()
//            }
        }
    }
    
    func handleURL(_ url: URL) {
        print("Received URL: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            self.errorAlert = true
            return
        }
        
        let pathComponents = url.pathComponents
        
        if url.absoluteString.contains("spotify") {
            print("Spotify URL: \(url)")
            handleSpotifyURL(components)
            return
        }
        
        // Handle: /share/festival/{festivalID}
        if pathComponents.count >= 4,
           pathComponents[1] == "share",
           pathComponents[2] == "festival" {
            print(url)
            let festivalID = pathComponents[3]
            let makePlaylist = pathComponents.count >= 5 &&
                               pathComponents[4] == "makePlaylist"
            
            URLLoading = true
            Task { @MainActor in
                defer { URLLoading = false }
                
                while spotify.isLoading {
                    try? await Task.sleep(for: .milliseconds(100))
                }
                
                do {
                    var festival = Festival.newFestival()
                    if let myFestival = festivalVM.myFestivals.first(where:  { $0.id.uuidString == festivalID }) {
                        festival = myFestival
//                                if !myFestivals.contains(festival)
                        myFestivalsPath = NavigationPath()
                        selectedTab = 0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if makePlaylist {
                                myFestivalsPath.append(FestivalPlaylistLink(festival: festival))
                            } else {
                                myFestivalsPath.append(festival)
                            }
                        }
                    } else {
                        //                            if festivalVM.myFestivals.contains(where: { $0.id == festivalID }) {
                        festival = try await explore.fetchFestival(with: festivalID)
                        festivalVM.currentFestival = festival
                        
                        explorePath = NavigationPath()
                        selectedTab = 1
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            explorePath.append(festival)
                        }
                    }
                    
                    if pathComponents.count >= 6,
                       pathComponents[4] == "artist" {
                        let artistID = pathComponents[5]
                        if let artist = festivalVM.getArtistFromID(artistID: artistID, festival: festival) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if festivalVM.myFestivals.contains(where:  { $0.id.uuidString == festivalID }) {
                                    myFestivalsPath.append(ArtistPageStruct(artist: artist, festival: festival,
                                                                                shuffleTitle: "All Artists",
                                                                                shuffleList: festival.artistList))
                                } else {
                                    explorePath.append(ArtistPageStruct(artist: artist, festival: festival,
                                                                        shuffleTitle: "All Artists",
                                                                        shuffleList: festival.artistList))
                                }
                            }
                        }
                    }
                    
                    
                } catch {
//                            print("Failed to fetch festival:", error.localizedDescription)
                }
            }
            
//                    if pathComponents.count >= 6,
//                       pathComponents[4] == "artist" {
//
//                        let artistID = pathComponents[5]
//                        Task {
//                            do {
//                                if let artist = festivalVM.getArtistFromID(artistID: <#T##String#>, festival: <#T##DataSet.Festival#>)
////                                let festival = try await explore.fetchFestival(with: festivalID)
////                                selectedTab = 1
////                                festivalVM.currentFestival = festival
//                                explorePath.append("FestivalView")
//                            } catch {
//                                print("Failed to fetch festival:", error.localizedDescription)
//                            }
//                        }
//
//
//
//                        print("Artist ID: \(artistID)")
//                    }
            
            return
        }
        
        if pathComponents.count >= 2, pathComponents[1] == "share" {
            if firestore.phoneConnected {
                showRequestSheet = true
                handleInviteLink(url)
                return
            } else {
                socialPath = NavigationPath()
                selectedTab = 2
            }
        }
    }
    
    
    
    func handleSpotifyURL(_ components: URLComponents) {
        guard let queryItems = components.queryItems else {
            self.errorAlert = true
            return
        }

        for item in queryItems {
            if item.name == "code", let authCode = item.value {
                print("Spotify Authorization Code: \(authCode)")
                spotify.exchangeCodeForToken(authCode)
            }
        }
        withAnimation(.easeInOut(duration: 0.45)) {
            self.logInSuccess = true
            spotify.isLoggedIn = true
        }
    }
    
    func handleInviteLink(_ url: URL) {
        if url.absoluteString.contains("/friend/") {
            self.groupRequest = false
            handleFriendInviteLink(url)
        } else if url.absoluteString.contains("/group/") {
            self.groupRequest = true
            handleGroupInviteLink(url)
        }
    }
    
    func handleFriendInviteLink(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if let senderUUID = components?.queryItems?.first(where: { $0.name == "user" })?.value {
            print("Sender ID: \(senderUUID)")
            
            let db = Firestore.firestore()
            db.collection("users").document(senderUUID).getDocument { document, error in
                if let error = error {
                    print("Error fetching sender profile: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    let senderName = document.data()?["name"] as? String ?? "Unknown"
                    let senderProfilePic = document.data()?["profileImageURL"] as? String
                    DispatchQueue.main.async {
                        self.pendingRequest = DataSet.Request(
                            id: senderUUID,
                            name: senderName,
                            photo: senderProfilePic
                        )
                    }
                    
                } else {
                    print("Sender profile not found")
                }
            }
        } else {
            print("No friend ID found in URL")
        }
    }
    
    func handleGroupInviteLink(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if let groupUUID = components?.queryItems?.first(where: { $0.name == "group" })?.value {
            print("Group ID: \(groupUUID)")
            
            let db = Firestore.firestore()
            db.collection("groups").document(groupUUID).getDocument { document, error in
                if let error = error {
                    print("Error fetching group profile: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    let groupName = document.data()?["name"] as? String ?? "Unknown"
                    let groupProfilePic = document.data()?["photo"] as? String
                    let groupMembers = document.data()?["members"] as? [String]
                    DispatchQueue.main.async {
                        self.pendingRequest = DataSet.Request(
                            id: groupUUID,
                            name: groupName,
                            photo: groupProfilePic,
                            groupMembers: groupMembers
                        )
                    }
                    
                } else {
                    print("Group profile not found")
                }
            }
        } else {
            print("No group ID found in URL")
        }
    }
    
    func acceptFriendRequest(senderUUID: String) {
        data.addFriend(friendID: senderUUID) { _ in
            showRequestSheet = false
        }
    }
    
    func acceptGroupRequest(groupUUID: String) {
        guard let currentUser = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let currentUserID = currentUser.uid

        let userRef = db.collection("users").document(currentUserID)
        let groupRef = db.collection("groups").document(groupUUID)

        groupRef.updateData(["members": FieldValue.arrayUnion([currentUserID])])
        userRef.updateData(["groups": FieldValue.arrayUnion([groupUUID])])
        
        showRequestSheet = false
    }

    func rejectRequest(senderUUID: String) {
        showRequestSheet = false
    }
}

class AppDelegate: NSObject,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        
        UNUserNotificationCenter.current().delegate = self
        
        Messaging.messaging().delegate = self


        //        UNUserNotificationCenter.current().delegate = self
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
//            if granted {
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            } else {
//                print("❌ Push notifications permission not granted")
//            }
//        }
        
        return true
    }
    
    // APNs registration succeeded
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Existing Firebase Auth APNs handling
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)

        // Firebase Messaging APNs handling
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

        // FCM token received or refreshed
        func messaging(
            _ messaging: Messaging,
            didReceiveRegistrationToken fcmToken: String?
        ) {
            guard let fcmToken else { return }

            print("FCM token:", fcmToken)
            
            NotificationManager.shared.saveFCMToken(fcmToken)

            // Next: save this token to the signed-in user's Firestore document.
        }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        
        completionHandler(.newData)
    }

//    func application(_ application: UIApplication,
//                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
//    }
//
//    func application(_ application: UIApplication,
//                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
//    }
    
    func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse,
            withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        if let urlString = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: urlString) {
            DispatchQueue.main.async {
                DeepLinkManager.shared.pendingURL = url
            }
        }
        completionHandler()
    }
}

struct FriendRequestSheet:  View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    let request: DataSet.Request
    
    @Binding var showRequestSheet: Bool
    
    var body: some View {
        Group {
            ZStack {
                LinearGradient(
                        gradient: Gradient(colors: [
                            Color("OASIS Dark Orange"),
                            Color("OASIS Light Orange"),
                            Color("OASIS Light Blue"),
                            Color("OASIS Dark Blue")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                .ignoresSafeArea()
//                .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                VStack {
                    Spacer().frame(height: 30)
                    Text(request.name)
                        .font(Font.system(size: 30))
                        .multilineTextAlignment(.center)
                        .padding()
                    SocialImage(imageURL: request.photo, name: request.name, id: request.id, frame: 140)
                    //                    .padding(.bottom, 10)
                    HStack {
                        Button(action: {
                            showRequestSheet = false
                        }, label: {
                            Text("Cancel")
                                .frame(width: 120, height: 40)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                        })
                        .padding(.horizontal, 10)
                        Button(action: {
                            firestore.followUser(request.id) { success in
                                print("Follow is a \(success)")
                            }
                        }, label: {
                            Text("Follow")
                                .frame(width: 120, height: 40)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                        })
                        .padding(.horizontal, 10)
                    }
                    
                    Spacer()
                    
                }
            }
        }
    }
}

struct GroupRequestSheet:  View {
    @EnvironmentObject var social: SocialViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    
    let request: DataSet.Request
    
    @Binding var showRequestSheet: Bool
    
    @State var members = Array<UserProfile>()
    @State var isMembersLoading = true
    
    @State private var dummyPath = NavigationPath()
    
    var body: some View {
        Group {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("OASIS Dark Orange"),
                        Color("OASIS Light Orange"),
                        Color("OASIS Light Blue"),
                        Color("OASIS Dark Blue")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack {
                    Spacer().frame(height: 30)
                    Text(request.name)
                        .font(Font.system(size: 30))
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    //                Group {
                    SocialImage(imageURL: request.photo, name: request.name, id: request.id, frame: 130)
                        .padding(5)
                    
                    //                }
                    //                .padding(10)
                    //                Text(request.name)
                    //                    .font(Font.system(size: 25))
                    ////                    .padding()
                    //                    .multilineTextAlignment(.center)
                    //                    .padding(.bottom, 5)
                    //                if !members.isEmpty {
                    VStack {
                        if let memberIDs = request.groupMembers, !memberIDs.isEmpty {
                            Group {
                                HStack {
                                    Text("Members:")
                                    Spacer()
                                }
                                .padding(.leading, 10)
                                if isMembersLoading {
                                    ProgressView()
                                } else {
                                    ProfilesListed(navigationPath: $dummyPath, profiles: members, maxHeight: 225, allowNavigation: false)
                                    //                                .padding(.top, LIST_PADDING)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            
                            
                            
                            
                            //                        Group {
                            //                            if isMembersLoading {
                            //                                ProgressView()
                            //                            } else {
                            //                                if members.count > 4 {
                            //                                    ScrollView(.horizontal) {
                            //                                        LazyHStack {
                            //                                            ForEach(Array(members.sorted(by: { $0.name < $1.name }))) { member in
                            //                                                SocialImage(imageURL: member.profilePic, name: member.name, frame: 45)
                            //                                                    .padding(.horizontal, 3)
                            //                                            }
                            //                                        }
                            //                                    }
                            //                                } else {
                            //                                    HStack {
                            //                                        ForEach(Array(members.sorted(by: { $0.name < $1.name }))) { member in
                            //                                            SocialImage(imageURL: member.profilePic, name: member.name, frame: 45)
                            //                                                .padding(.horizontal, 3)
                            //                                        }
                            //                                    }
                            //                                }
                            //                            }
                            //                        }
                            //                        .padding(5)
                            //                        .frame(width: 270, height: 65)
                            //                        //                    .background(
                            //                        //                        RoundedRectangle(cornerRadius: 15)
                            //                        //                            .fill(Color("BW Color Switch Reverse"))
                            //                        //                            .shadow(color: .black, radius: 2, x: 0, y: 2)
                            //                        //                    )
                            //                        .overlay(
                            //                            RoundedRectangle(cornerRadius: 10)
                            //                                .stroke(.black, lineWidth: 1)
                            //                        )
                        }
                    }
                    .padding(.vertical, 5)
                    HStack {
                        Button(action: {
                            showRequestSheet = false
                        }, label: {
                            Text("Cancel")
                                .frame(width: 120, height: 40)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                        })
                        .padding(.horizontal, 10)
                        Button(action: {
                            Task { @MainActor in
                                defer { showRequestSheet = false }
                                
//                                do {
                                    firestore.joinGroup(groupID: request.id) { success in
                                        print("Joined group: \(success)")
                                    }
//                                    try await firestore.joinGroup(groupID: request.id)
//                                } catch {
//                                    print("Failed to join group:", error)
//                                }
                            }
                            //                        social.joinGroup(groupID: request.id)
                            //                        onAccept(request.id)
                        }, label: {
                            Text("Join Group")
                                .frame(width: 120, height: 40)
                                .background(Color.green)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                        })
                        .padding(.horizontal, 10)
                    }
                    .padding()
                    Spacer()
                    
                }
            }
            .onAppear() {
                isMembersLoading = true
                Task {
                    defer { isMembersLoading = false }
                    if let memberIDs = request.groupMembers {
                        members = await firestore.users(from: memberIDs)
                    }
                }
//                if let memberIDs = request.groupMembers {
//                    Task {
//                        do {
//                            members = try await social.fetchUsers(from: memberIDs)
//                            isMembersLoading = false
//                            //
//                        } catch {
//                            print("Error:", error)
//                            isMembersLoading = false
//                        }
//                    }
//                } else {
//                    isMembersLoading = false
//                }
            }
        }
    }
}

extension View {
    func withAppNavigationDestinations(navigationPath: Binding<NavigationPath>,
                                       festivalVM: FestivalViewModel,
                                       selectedTab: Binding<Int>
    ) -> some View {
        self
            .navigationDestination(for: UserProfile.self) { profile in
                ProfilePage(navigationPath: navigationPath, profile: profile, selectedTab: selectedTab)
            }
            .navigationDestination(for: Festival.self) { festival in
                FestivalPage(navigationPath: navigationPath, currentFestival: festival, selectedTab: selectedTab)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: FestivalPlaylistLink.self) { festivalPlaylistLink in
                FestivalPage(navigationPath: navigationPath, currentFestival: festivalPlaylistLink.festival, selectedTab: selectedTab, createPlaylistSheet: true)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: FestivalViewModel.FestivalNavTarget.self) { navTarget in
                if navTarget.draftView {
                    NewEventPage(festival: navTarget.festival, navigationPath: navigationPath, selectedTab: selectedTab)
                        .environmentObject(festivalVM)
                } else {
                    FestivalPage(navigationPath: navigationPath, currentFestival: navTarget.festival, previewView: navTarget.previewView, selectedTab: navTarget.selectedTab)
                        .environmentObject(festivalVM)
                }
            }
            .navigationDestination(for: ArtistListStruct.self) { page in
                ArtistList(navigationPath: navigationPath,
                           titleText: page.titleText,
                           currentFestival: page.festival,
                           artistList: page.list,
                           groupFavs: page.groupFavs,
                           sortType: page.groupFavs == nil ? .alpha : .group
                )
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: ArtistPageStruct.self) { page in
                ArtistPage(currentArtist: page.artist,
                           shuffleLable: page.shuffleTitle,
                           shuffleList: page.shuffleList,
                           navigationPath: navigationPath,
                           currentFestival: page.festival)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: SocialGroup.self) { group in
                GroupPage(navigationPath: navigationPath, group: group, selectedTab: selectedTab)
//                ProfilePage(navigationPath: navigationPath, profile: profile)
            }
            .navigationDestination(for: String.self) { value in
                switch value {
                case "Settings":
                    SettingsHomePage(navigationPath: navigationPath)
                case "Edit Profile":
                    AccountEditPage(navigationPath: navigationPath)
                case "Spotify Account":
                    SpotifyAccount()
                case "About Page":
                    AboutPage()
                case "Festival Settings":
                    FestivalSettingsPage(navigationPath: navigationPath)
//                case "Favorites":
//                    ArtistList(navigationPath: navigationPath, titleText: "Favorites", artistList: festivalVM.getFavorites())
//                        .environmentObject(festivalVM)
//                case "FestivalView":
//                    FestivalPage(navigationPath: navigationPath)
//                        .environmentObject(festivalVM)
                case "New Event":
                    NewEventPage(festival: Festival.newFestival(), navigationPath: navigationPath, selectedTab: selectedTab)
                        .environmentObject(festivalVM)
                default:
                    SettingsPageOLD()
                }
            }
    }
}


final class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()

    @Published var pendingURL: URL?
}

