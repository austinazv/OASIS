//
//  GroupPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/15/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct SocialPage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    @State var profile: DataSet.UserProfile?
    @State private var isProfileLoaded = false
    
    let userID: String

    var body: some View {
        Form {
            GroupSection
            FriendSection
            
        }
        
        .onChange(of: profile) { newProfile in
            if newProfile != nil {
                isProfileLoaded = true
            }
        }
        .onAppear {
            if profile == nil {
                if data.userInfo == nil {
                    data.fetchUserProfile(userID: userID) { success in
                        DispatchQueue.main.async {
                            //                            isProfileLoaded = success // Update state when the profile is ready
                            if success {
                                self.profile = data.userInfo
                            } else {
                                //                                    dismiss()
                            }
                        }
                    }
                } else {
                    self.profile = data.userInfo
                }
            } else {
                isProfileLoaded = true
            }
        }
        
        .navigationTitle("Social")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isProfileLoaded, let userProfile = profile {
                    NavigationLink(value: userProfile) {
//
//                    NavigationLink(destination: MyProfilePage(/*loggedIn: $loggedIn, */profile: userProfile).environmentObject(data)) {
                        HStack {
                            Text("My Profile")
                            Image(systemName: "chevron.right")
                        }
                        //                        if let profilePic = viewModel.userInfo.profilePic, let url = URL(string: profilePic) {
                        //                            AsyncImage(url: url) { image in
                        //                                image
                        //                                    .resizable()
                        //                                    .scaledToFill()
                        //                            } placeholder: {
                        //                                ProgressView()
                        //                            }
                        //                            .frame(width: 20, height: 20)
                        //                            .clipShape(Circle())
                        //                        } else {
                        //                            Image("Default Profile Picture")
                        //                                .resizable()
                        //                                .frame(width: 30, height: 30, alignment: .center)
                        //                                .clipShape(Circle())
                        //                        }
                    }
                }
            }
        }
    }
    
    var GroupSection: some View {
        Group {
            Section(header: Group {
                HStack {
                    Text("My Groups")
                    NavigationLink(value: "group") {
                        Image(systemName: "plus.circle")
                    }
                }
                .font(.headline)
            }) {
                Group {
                    if !isProfileLoaded {
                        ProgressView()
                    } else if profile!.groups.isEmpty {
                        Text("No Groups Yet")
                    } else {
                        List(profile!.groups) { group in
                            NavigationLink(value: group) {
                                HStack {
                                    if let localPath = group.photo , let image = UIImage(contentsOfFile: localPath) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                    } else {
                                        Image("Default Group Profile Picture")
                                            .resizable()
                                            .frame(width: 40, height: 40, alignment: .center)
                                            .clipShape(Circle())
                                    }
                                    Text(group.name)
                                }
                            }
                            
                        }
                    }
                }
            }
            .padding(.horizontal, 0)
        }
    }
    
    var FriendSection: some View {
        Group {
            Section(header: Group {
                HStack {
                    Text("My Friends")
                    ShareLink(item: data.getInviteLink()) {
                        Label("", systemImage: "plus.circle")
                    }
                }
                .font(.headline)
            }) {
                Group {
                    if !isProfileLoaded {
                        ProgressView()
                    } else if profile!.friends.isEmpty {
                        Text("No Friends Yet")
                    } else {
                        List(profile!.friends) { friend in
                            NavigationLink(value: friend) {
                                if let localPath = friend.profilePic, let image = UIImage(contentsOfFile: localPath) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    Image("Default Profile Picture")
                                        .resizable()
                                        .frame(width: 40, height: 40, alignment: .center)
                                        .clipShape(Circle())
                                }
                                Text(friend.name)
                            }
                        }
                        
                    }
                }
            }
        }
    }
    
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
