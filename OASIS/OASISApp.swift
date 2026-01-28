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


@main
struct OASISApp: App {
    @StateObject var data = DataSet(name: "AZV31")
    @StateObject var spotify = SpotifyViewModel(name: "AZV30")
    @StateObject var firestore = FirestoreViewModel(name: "AZV31")
    @StateObject var festivalVM = FestivalViewModel(name: "Austin30")
    @StateObject var social = SocialViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var userLoggedIn: Bool = false
    @State private var userHasName: Bool = false
    @State private var userSelectedFestivals: Bool = false
    
    @State private var logInSuccess: Bool = false
    
    @State private var errorAlert: Bool = false
    @State private var pendingRequest: DataSet.Request?
    @State private var showRequestSheet = false
    
    @State private var groupRequest = false

    // Shared namespace for morphing the “O” and the title between screens
    @Namespace private var oasisNamespace
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app content (behind while loading)
                Group {
                    if firestore.isLoggedIn {
                        if spotify.isLoggedIn {
                            NavigationBottomBarView()
                                .environmentObject(data)
                                .environmentObject(spotify)
                                .environmentObject(firestore)
                                .environmentObject(festivalVM)
                                .environmentObject(social)
                        } else {
                            SpotifyConnectPage()
                                .environmentObject(data)
                                .environmentObject(spotify)
                                .environmentObject(firestore)
                                .environmentObject(festivalVM)
                        }
                    } else {
                        LogInPage()
                            .environmentObject(data)
                            .environmentObject(spotify)
                            .environmentObject(firestore)
                            .environmentObject(festivalVM)
                    }
                }
                // Provide the shared namespace to all children so titles can match geometry
                .environment(\.oasisNamespace, oasisNamespace)
                .opacity(spotify.isLoading ? 0 : 1)
                .animation(.easeInOut(duration: 0.45), value: spotify.isLoading)
                
                // Loading layer on top
                if spotify.isLoading {
                    OASISLoadingScreen(namespace: oasisNamespace)
                        // No custom slide transition; matchedGeometryEffect will move from loading to destination.
//                        .transition(.opacity) // optional fade for the overlay itself
                        .animation(.easeInOut(duration: 1.35), value: spotify.isLoading) // 3× slower
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
            .onChange(of: pendingRequest) { newValue in
                if newValue != nil {
                    self.showRequestSheet = true
                }
            }
            .onOpenURL(perform: { url in
                print("Received URL: \(url.absoluteString)")
                    
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                    self.errorAlert = true
                    return
                }
                
                if url.absoluteString.contains("spotify") {
                    handleSpotifyURL(components)
                } else if url.absoluteString.contains("/share/") {
                    showRequestSheet = true
                    handleInviteLink(url)
                    
                } else {
                    print("Unhandled URL")
                }
            })
            .alert(isPresented: $logInSuccess) {
                Alert(title: Text("Successfully Signed In to Spotify"),
                             dismissButton: .default(Text("OK")))
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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())

        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            } else {
                print("❌ Push notifications permission not granted")
            }
        }
        
        return true
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

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
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
                    SocialImage(imageURL: request.photo, name: request.name, frame: 140)
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
                    SocialImage(imageURL: request.photo, name: request.name, frame: 130)
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
//                isMembersLoading = true
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
                                       festivalVM: FestivalViewModel) -> some View {
        self
            .navigationDestination(for: UserProfile.self) { profile in
                ProfilePage(navigationPath: navigationPath, profile: profile)
            }
            .navigationDestination(for: DataSet.Festival.self) { festival in
                FestivalPage(navigationPath: navigationPath, currentFestival: festival)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: FestivalViewModel.FestivalNavTarget.self) { navTarget in
                if navTarget.draftView {
                    NewEventPage(festival: navTarget.festival, navigationPath: navigationPath)
                        .environmentObject(festivalVM)
                } else {
                    FestivalPage(navigationPath: navigationPath, currentFestival: navTarget.festival, previewView: navTarget.previewView)
                        .environmentObject(festivalVM)
                }
            }
            .navigationDestination(for: DataSet.ArtistListStruct.self) { page in
                ArtistList(navigationPath: navigationPath, titleText: page.titleText, artistList: page.list)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: DataSet.ArtistPageStruct.self) { page in
                ArtistPage(currentArtist: page.artist,
                           shuffleLable: page.shuffleTitle,
                           shuffleList: page.shuffleList,
                           navigationPath: navigationPath)
                    .environmentObject(festivalVM)
            }
            .navigationDestination(for: SocialGroup.self) { group in
                GroupPage(navigationPath: navigationPath, group: group)
//                ProfilePage(navigationPath: navigationPath, profile: profile)
            }
            .navigationDestination(for: String.self) { value in
                switch value {
                case "Settings":
                    SettingsHomePage()
                case "Festival Settings":
                    FestivalSettingsPage(navigationPath: navigationPath)
                case "Favorites":
                    ArtistList(navigationPath: navigationPath, titleText: "Favorites", artistList: festivalVM.getFavorites())
                        .environmentObject(festivalVM)
                case "FestivalView":
                    FestivalPage(navigationPath: navigationPath)
                        .environmentObject(festivalVM)
                case "New Event":
                    NewEventPage(festival: DataSet.Festival.newFestival(), navigationPath: navigationPath)
                        .environmentObject(festivalVM)
                default:
                    SettingsPageOLD()
                }
            }
    }
}

