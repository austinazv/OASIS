////
////  ContentView.swift
////  OASIS
////
////  Created by Austin Zambito-Valente on 1/14/25.
////
//
//import SwiftUI
//import Firebase
//import FirebaseFirestore
//import FirebaseAuth
//import FirebaseStorage
//
//struct HomePage: View {
//    @EnvironmentObject var data: DataSet
//    
//    @State private var navigationPath = NavigationPath()
//    
//    @State var spotifyLogInOut: Bool = false
//    
//    @State private var isLoading: Bool = false
//    @State private var isLoadingInit: Bool = true
//    @State private var isLoggedInSpotify: Bool = false
//    
//    @State private var logOutSuccess: Bool = false
//    
//    @State private var userLoggedIn: Bool = false
//    @State private var userHasName: Bool = false
//    @State private var userSelectedFestivals: Bool = false
//    
//    var body: some View {
//        Group {
//            
//            if isLoadingInit {
//                ProgressView()
//            } else {
//                HomeScreen
//            }
////                if self.userLoggedIn {
////                    if self.userHasName {
////                        if self.userSelectedFestivals {
////                            HomeScreen
////                        } else {
////                            HomeScreen
////                            //                        FestivalPickerPage()
////                        }
////                    } else {
////                        AccountSetUpPage().environmentObject(data)
////                    }
////                } else {
////                    AuthPage().environmentObject(data)
////                }
////            }
//        }
//        .onAppear() {
//            self.checkUserBools()
//        }
//        
//    }
//    
//    var HomeScreen: some View {
//        Group {
//            NavigationStack(path: $navigationPath) {
//                ZStack(alignment: .center) {
////                    VStack {
////                        HStack {
////                            Spacer()
////                            Button(action: {
////                                spotifyLogInOut.toggle()
////                            }, label: {
////                                ZStack {
////                                    Circle()
////                                        .foregroundStyle(Color("BW Color Switch Reverse"))
////                                        .shadow(radius: 5)
////                                    Image("Spotify Image Green")
////                                        .resizable()
////                                        .shadow(radius: 0)
////                                }
////                                .frame(width: 40, height: 40)
////                                
////                            })
////                            
////                            
////                            .padding(25)
////                        }
////                        Spacer()
////                    }
//                    VStack {
////                        VStack {
////                            Text("OASIS")
////                                .foregroundStyle(Color("OASIS Light Blue"))
////                                .kerning(20)
////                                .font(Font.system(size: 60))
////                                .scaledToFill()
////                                .minimumScaleFactor(0.7)
////                                .lineLimit(1)
////                                .padding(.vertical, 10)
////                            Text("EXPLORE MUSIC FESTIVALS")
////                                .italic()
////                                .foregroundStyle(Color("BW Color Switch"))
////                                .font(Font.system(size: 15))
////                                .tracking(5)
////                                .scaledToFill()
////                                .minimumScaleFactor(0.7)
////                                .lineLimit(1)
////                                .opacity(0.8)
////                        }
////                        .padding(.vertical, 35)
//                        VStack {
//                            Divider().frame(height: 4)
//                            NavigationLink(value: "discover") {
//                                ZStack {
//                                    Rectangle()
//                                        .frame(height: BUTTONHEIGHT)
//                                        .opacity(0)
//                                    HStack{
//                                        Text("Discover")
//                                        Image(systemName: "waveform.badge.magnifyingglass")
//                                            .imageScale(.large)
//                                    }
//                                }
//                                .font(Font.system(size: 20))
//    //                            .padding(5)
//                            }
//                            Divider().frame(height: 4)
//
//                            NavigationLink(value: "social") {
//                                ZStack {
//                                    Rectangle().frame(height: BUTTONHEIGHT).opacity(0)
//                                    HStack{
//                                        Text("Social")
//                                        Image(systemName: "person.2.fill")
//                                            .imageScale(.large)
//                                    }
//                                    .font(Font.system(size: 20))
//                                    //                                        .padding(5)
//                                }
//                            }
//                            .frame(height: BUTTONHEIGHT, alignment: .center)
//                            Divider().frame(height: 4)
//                            NavigationLink(value: "starred") {
//                                ZStack {
//                                    Rectangle()
//                                        .frame(height: BUTTONHEIGHT)
//                                        .opacity(0)
//                                    HStack{
//                                        Text("Starred")
//                                        Image(systemName: "star.fill")
//                                            .imageScale(.medium)
//                                            .foregroundStyle(.yellow)
//                                    }
//                                    .font(Font.system(size: 20))
//    //                                .padding(5)
//                                }
//                            }
//                            .frame(height: BUTTONHEIGHT, alignment: .center)
//                            Divider().frame(height: 4)
//                        }
//                        
//                    }
//                    .foregroundStyle(Color("BW Color Switch"))
//                    .foregroundStyle(Color("BW Color Switch"))
//                    if spotifyLogInOut {
//                        Color.black.opacity(0.2)
//                            .ignoresSafeArea()
//                            .onTapGesture {
//                                spotifyLogInOut = false
//                            }
//                        Group {
//                            RoundedRectangle(cornerRadius: 10)
//                                .shadow(radius: 10)
//                                .frame(width: 220, height: 180)
//                                .foregroundStyle(Color("BW Color Switch"))
//                            VStack {
//                                Image("Spotify Full Logo")
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(height: 40, alignment: .center)
//                                Group {
//                                    if self.isLoggedInSpotify {
//                                        Button(action: {
//    //                                        checkUserLoginStatus()
//                                            isLoading = true
//                                            data.revokeSpotifyAccessToken() { success in
//                                                if success {
//                                                    print("Success!")
//                                                    self.isLoading = false
//                                                    self.spotifyLogInOut = false
//                                                    self.isLoggedInSpotify = false
//                                                    self.logOutSuccess = true
//                                                } else {
//                                                    self.isLoading = false
//                                                    self.spotifyLogInOut = false
//                                                }
//                                                
//                                            }
//                                        }, label: {
//                                            Text("Log Out")
//                                                .frame(width: 120, height: 50)
//                                                .background(.red)
//                                                .foregroundStyle(.black)
//                                                .cornerRadius(30)
//                                                .shadow(radius: 5)
//                                                .font(Font.system(size: 18))
//                                            
//                                        })
//                                    } else {
//                                        Button(action: {
//    //                                        checkUserLoginStatus()
//                                            self.spotifyLogInOut = false
//                                            data.openSpotifyLogin()
//                                            self.checkUserLoginStatus()
//                                        }, label: {
//                                            Text("Log In")
//                                                .frame(width: 120, height: 50)
//                                                .background(Color("Spotify Color Green"))
//                                                .foregroundStyle(.black)
//                                                .cornerRadius(30)
//                                                .shadow(radius: 5)
//                                                .font(Font.system(size: 18))
//                                            
//                                        })
//                                    }
//                                }
//                                .padding(.top, 20)
//                            }
//                        }
//                        .onAppear() {
//                            checkUserLoginStatus()
//                        }
//                        .offset(y: 80)
//                    }
//                    if isLoading {
//                        ProgressView()
//                    }
//                }
//                .alert(isPresented: $logOutSuccess) {
//                    Alert(title: Text("Successfully Logged Out"),
//                                 dismissButton: .default(Text("OK")))
//                }
//                .onAppear() {
//                    self.checkUserLoginStatus()
//                }
////                .navigationDestination(for: String.self) { value in
////                    switch(value) {
////                    case "settings":
////                        SettingsPage().environmentObject(data)
////                    case "discover":
////                        DiscoverPageNew().environmentObject(data)
//////                    case "Artist List":
//////                        ArtistList(currDict: data.getArtistDict(sort: .alpha), titleText: "All Artists", sortType: .alpha, subsectionLen: data.getSortLables(sort: .alpha).count).environmentObject(data)
//////                    case "Shuffle All":
//////                        ArtistPage(currentArtist: data.shuffleArtist(includeFavorites: false), shuffle: true, shuffleLable: "", includeFavorites: false).environmentObject(data)
////                    case "social":
////                        if let user = Auth.auth().currentUser {
////                            if let profile = data.userInfo {
////                                if profile.name == "" {
////                                    AccountSetUpPage().environmentObject(data)
////                                } else {
////                                    SocialPage(navigationPath: $navigationPath, userID: user.uid).environmentObject(data)
////                                }
////                            } else {
////                                VStack {
////                                    ProgressView()
////                                    Text("Loading Profile...")
////                                }
////                                .onAppear {
////                                    data.fetchUserProfile(userID: user.uid) { _ in }
////                                }
////                            }
////                        } else {
////                            AuthPage().environmentObject(data)
////                        }
////                    case "group":
////                        GroupSetUpPage(navigationPath: $navigationPath).environmentObject(data)
//////                    case "starred":
//////                        ArtistList(currDict: data.getArtistDict(favorites: true, sort: .day), titleText: "Starred", sortType: .day, subsectionLen: data.getSortLables(sort: .day).count).environmentObject(data)
////                    default:
////                        ProgressView()
////                    }
////                }
////                .navigationDestination(for: DataSet.FriendProfile.self) { friend in
////                    FriendPage(navigationPath: $navigationPath, profile: friend).environmentObject(data)
////                }
////                .navigationDestination(for: DataSet.UserProfile.self) { profile in
////                    MyProfilePage(navigationPath: $navigationPath, profile: profile).environmentObject(data)
////                }
////                .navigationDestination(for: DataSet.SocialGroup.self) { group in
////                    GroupPage(navigationPath: $navigationPath, group: group).environmentObject(data)
////                }
//            }
//            .toolbar(.hidden)
//        }
//    }
//    
//    func checkUserBools() {
//        if Auth.auth().currentUser != nil {
//            self.userLoggedIn = true
//            self.data.checkIfUserHasName() { hasName in
//                self.userHasName = hasName
//                self.isLoadingInit = false
//            }
//        } else {
//            self.userLoggedIn = false
//            self.isLoadingInit = false
//        }
////        print(self.userLoggedIn)
//    }
//    
//    
//    
//    func checkUserLoginStatus() {
//        data.isUserLoggedIn { loggedIn in
//            DispatchQueue.main.async {
//                self.isLoggedInSpotify = loggedIn
//                print(self.isLoggedInSpotify)
//            }
//        }
//    }
//    
//    let BUTTONHEIGHT: CGFloat = 35
//}
//
