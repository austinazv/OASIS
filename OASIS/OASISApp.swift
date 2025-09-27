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
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @State private var userLoggedIn: Bool = false
    @State private var userHasName: Bool = false
    @State private var userSelectedFestivals: Bool = false
    
    @State private var logInSuccess: Bool = false
    
    @State private var errorAlert: Bool = false
    @State private var pendingRequest: DataSet.Request?
    @State private var showRequestSheet = false
    
    @State private var groupRequest = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                NavigationBottomBarView()
                    .environmentObject(data)
                    .environmentObject(spotify)
                    .environmentObject(firestore)
                    .environmentObject(festivalVM)
                //TODO: ADD IN HERE!
            }
            .sheet(isPresented: $showRequestSheet, content: {
                Group {
                    if Auth.auth().currentUser != nil {
                        if let request = pendingRequest {
                            FriendRequestSheet(request: request, onAccept: groupRequest ? acceptGroupRequest : acceptFriendRequest, onReject: rejectRequest, groupRequest: groupRequest)
                        } else {
                            Text("Loading...")
                        }
                    } else {
                        AuthPage(/*loggedIn: $loggedIn*/).environmentObject(data)
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
        self.logInSuccess = true
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
            // Use the extracted groupId
            print("Group ID: \(groupUUID)")
            
            
            
            let db = Firestore.firestore()
            db.collection("groups").document(groupUUID).getDocument { document, error in
                if let error = error {
                    print("Error fetching group profile: \(error.localizedDescription)")
                    return
                }
                
                if let document = document, document.exists {
                    let groupName = document.data()?["groupName"] as? String ?? "Unknown"
                    let senderProfilePic = document.data()?["groupPhotoURL"] as? String
                    DispatchQueue.main.async {
                        self.pendingRequest = DataSet.Request(
                            id: groupUUID,
                            name: groupName,
                            photo: senderProfilePic
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

        // Add user to group's member list
        groupRef.updateData(["members": FieldValue.arrayUnion([currentUserID])])

        // Add group to user's groups list
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

        // Request push notification permissions
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
    
    // ✅ Handle receiving remote notifications and pass them to FirebaseAuth
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
        completionHandler(.newData)
    }

    // ✅ Handle successful push notification registration
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    }

    // ✅ Handle failed push notification registration
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

//class AppState: ObservableObject {
//    @Published var createPlaylist: Bool = false
//}

struct FriendRequestSheet:  View {
    let request: DataSet.Request
    let onAccept: (String) -> Void
    let onReject: (String) -> Void
    let groupRequest: Bool
    
    var body: some View {
        Group {
            VStack {
                Text(groupRequest ? "New Group Request" : "New Friend Request")
                    .font(Font.system(size: 30))
                    .multilineTextAlignment(.center)
                    .padding()
                Group {
                    if let profilePic = request.photo, let url = URL(string: profilePic) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                    } else {
                        Image("Default Profile Picture")
                            .resizable()
                            .frame(width: 130, height: 130, alignment: .center)
                            .clipShape(Circle())
                    }
                }
                .padding(10)
                Text(request.name)
                    .font(Font.system(size: 25))
                    .padding()
                    .multilineTextAlignment(.center)
                HStack {
                    Button(action: {
                        onReject(request.id)
                    }, label: {
                        Text("Reject")
                            .frame(width: 100, height: 40)
                            .background(Color.red)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        
                    })
                    .padding(.horizontal, 10)
                    Button(action: {
                        onAccept(request.id)
                    }, label: {
                        Text("Accept")
                            .frame(width: 100, height: 40)
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

//struct FriendRequestSheetWrapper: View {
//    @EnvironmentObject var data: DataSet
//    @Binding var loggedIn: Bool
//    @State var request: DataSet.FriendProfile
//    
//    @Binding var showFriendRequestSheet: Bool
//    
//    var body: some View {
//        if loggedIn {
//            FriendRequestSheet(request: request, onAccept: acceptFriendRequest, onReject: rejectFriendRequest)
////            if let request = pendingFriendRequest {
////                
////            } else {
////                Text("Loading...")
////            }
//        } else {
//            AuthPage(loggedIn: $loggedIn)
//        }
//    }
//    
//    
//}
