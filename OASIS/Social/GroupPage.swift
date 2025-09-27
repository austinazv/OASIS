//
//  FriendPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/23/25.
//

import SwiftUI

struct GroupPage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    var group: DataSet.SocialGroup
    
    @State var favoriteDict: [String : [String]]?
//    @State var artistList: [DataSet.artist]?
    
    @State var groupPhotos = [String : UIImage]()
    
    @State var unfriendAlert = false
    @State var isLoading = true
    
    @State var showFriendSheet: Bool = false
    
    @State var chosenMember: DataSet.FriendProfile?
    
    var body: some View {
        Group {
//            if isLoading {
//                ProgressView()
//                Text("Loading Group")
//            } else {
//                ZStack {
//                    VStack {
//                        HStack {
//                            if let localPath = group.photo, let image = UIImage(contentsOfFile: localPath) {
//                                Image(uiImage: image)
//                                    .resizable()
//                                    .scaledToFill()
//                                    .frame(width: 110, height: 110, alignment: .center)
//                                    .clipShape(Circle())
//                            } else {
//                                Image("Default Group Profile Picture")
//                                    .resizable()
//                                    .frame(width: 110, height: 110, alignment: .center)
//                                    .clipShape(Circle())
//                            }
//                            VStack {
//                                Text(group.name)
//                                    .multilineTextAlignment(.center)
////                                ShareLink(item: URL(string: group.inviteLink)!) {
////                                    Label("", systemImage: "square.and.arrow.up.circle")
////                                }
////                                .padding(.top, 4)
//                            }
//                            .font(Font.system(size: 25))
//                            .padding(.leading, 20)
//                        }
//                        .padding(.horizontal, 20)
////                        let favList = artistList!
////                        if !favList.isEmpty {
////                            ArtistList(currDict: [String(group.name + "'s Favorites") : favList as [DataSet.artist]],
////                                          titleText: String(group.name + "'s Favorites"),
//////                                          favorites: false,
//////                                          friendList: true,
////                                          groupFavorites: group.favoritesDict,
////                                          groupPhotos: self.groupPhotos,
////                                          sortType: .alpha,
////                                          subsectionLen: data.getSortLables(sort: .alpha).count)
////                            .environmentObject(data)
////                        } else {
////                            Text("Nobody in this group has any Starred Artist yet.")
////                                .multilineTextAlignment(.center)
////                                .padding(.top, 20)
////                            Spacer()
////                        }
//                    }
////                    if showFriendSheet {
////                        Color.black
////                            .opacity(0.3)
////                            .ignoresSafeArea()
////                        FriendsListSheet
////                    }
//                }
//            }
        }
//        .sheet(isPresented: $showFriendSheet) {
//            FriendsListSheet
//        }
        .sheet(isPresented: $showFriendSheet) {
            FriendsListSheet
        }
        .onAppear() {
//            self.favoriteDict = data.addMyFavorites(groupFavorites: group.favoritesDict)
//            var unsortedList = Array<DataSet.artist>()
//            for key in favoriteDict!.keys {
//                if let artist = data.getArtist(artistID: key) {
//                    unsortedList.append(artist)
//                }
//            }
//            self.artistList = unsortedList
//            
//            for m in group.members {
//                if let localPath = m.profilePic, let image = UIImage(contentsOfFile: localPath) {
//                    groupPhotos[m.id] = image
//                }
//            }
//            
//            isLoading = false
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    ShareButton
                    FriendsListButton
                    SettingsMenu
                }
            }
        }
        .alert(isPresented: self.$unfriendAlert) {
            Alert(title: Text("Leave Group"),
                  message: Text("Are you sure you want to leave \n\(group.name)?"),
                  primaryButton: .destructive(Text("Leave")) {
                data.leaveGroup(groupID: group.id) { success in
                    if !success {
                        print("Error leaving group")
                    } else {
                        print("Successfully left group.")
                            navigationPath.removeLast()
                    }
                }
            }, secondaryButton: .cancel()
            )
        }
    }
    
    var ShareButton: some View {
        ShareLink(item: URL(string: group.inviteLink)!) {
            Label("", systemImage: "square.and.arrow.up")
        }
        .offset(x: CGFloat(-4), y: CGFloat(-2))
    }
    
    var FriendsListButton: some View {
        Group {
            Image(systemName: "person.2.fill")
                .foregroundStyle(Color.blue)
                .onTapGesture {
                    self.showFriendSheet.toggle()
                }
        }
        .offset(x: 1)
    }
    
    var FriendsListSheet: some View {
        //        ZStack {
        VStack {
            Text("\(group.name) Members")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(10)
            List {
                ForEach(group.members, id: \.self) { member in
                    HStack {
                        if let image = groupPhotos[member.id] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image("Default Profile Picture")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        }
                        Text(member.name)
                            .foregroundColor(.primary)
                        Spacer()
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundStyle(.white)
                        }
                        .frame(width: 60, height: 40)
                        .padding(.horizontal, 20)
                        .shadow(radius: 6)
                        .onTapGesture {
                            data.addFriend(friendID: member.id) { success in
                                print(success)
                            }
                        }
                        
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.showFriendSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            navigationPath.append(member)
                        }
                        
                    }
                    
                }
            }
        }
    }
 
//    var AddFriendButton: some View {
        
        
//        Button (action: {
//            print("pressed")
//        }, label: {
//            ZStack(alignment: .center) {
//                RoundedRectangle(cornerRadius: 5)
//                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                Image(systemName: "person.fill.badge.plus")
//                    .foregroundStyle(.white)
//            }
//            .frame(width: 60, height: 30)
//        })
        
//    }

    
    var SettingsMenu: some View {
        Group {
            Menu(content: {
                Button (action: {
                    unfriendAlert = true
                }, label: {
                    HStack {
                        Spacer()
                        Text("❌ Leave Group")
                            
                    }.foregroundStyle(Color.red)
                })
                
            }, label: {
                Image(systemName: "gear")
                .foregroundStyle(Color.blue)
            })
        }
    }
    
    
}

//#Preview {
//    FriendPage()
//}
