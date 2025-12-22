//
//  FriendPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/23/25.
//

import SwiftUI

struct ProfilePage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    var profile: DataSet.FriendProfile
    
    @State var unfriendAlert = false
    
    var body: some View {
        VStack {
            HStack {
                if let localPath = profile.profilePic, let image = UIImage(contentsOfFile: localPath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110, alignment: .center)
                        .clipShape(Circle())
                    //                    AsyncImage(url: url) { image in
                    //                        image
                    //                            .resizable()
                    //                            .scaledToFill()
                    //                    } placeholder: {
                    //                        ProgressView()
                } else {
                    Image("Default Profile Picture")
                        .resizable()
                        .frame(width: 110, height: 110, alignment: .center)
                        .clipShape(Circle())
                }
                Text(profile.name)
                    .multilineTextAlignment(.center)
                    .font(Font.system(size: 25))
                
            }
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button (action: {
                        unfriendAlert = true
                    }, label: {
                        HStack {
                            Spacer()
                            Text("❌ Unfriend")
                                
                        }.foregroundStyle(Color.red)
                    })
                    
                }, label: {
                    Image(systemName: "gear")
                    .foregroundStyle(Color.blue)
                })
            }
        }
        .alert(isPresented: self.$unfriendAlert) {
            Alert(title: Text("Unfriend"),
                  message: Text("Are you sure you want to unfriend \(profile.name)?"),
                  primaryButton: .destructive(Text("Unfriend")) {
                data.unfriendUser(currentUserID: data.userInfo!.id, friendID: profile.id) { error in
                    if let error = error {
                            print("Error unfriending user: \(error.localizedDescription)")
                    } else {
                        
                        print("Successfully unfriended user.")
                        if !navigationPath.isEmpty {  // Ensure there is something to pop
                            navigationPath.removeLast()
                        }
                    }
                }
            }, secondaryButton: .cancel()
            )
        }
    }
}

//#Preview {
//    FriendPage()
//}


struct SocialImage: View {
    let imageURL: String?
    let frame: CGFloat
    
    var body: some View {
        if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // While loading
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .frame(width: frame, height: frame)
                case .success(let image):
                    // When successfully loaded
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: frame, height: frame)
                        .clipShape(Circle())
                case .failure(_):
                    // If it fails
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: frame, height: frame)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            // If imageURL is not a valid URL
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: frame, height: frame)
        }
    }
}
