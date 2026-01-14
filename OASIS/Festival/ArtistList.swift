//
//  ArtistList.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/16/25.
//

import Foundation
import SwiftUI
import UIKit

struct ArtistList: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var spotify: SpotifyViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State private var isLoading = false
    @State var notLoggedInAlert: Bool = false
    @State var playlistCreatedAlert: Bool = false
    @State var errorAlert: Bool = false
    @State var createPlaylistSheet: Bool = false
    @State var playlistName = ""
    @State private var searchText: String = ""
    
    var currPlaylistID: String?
   
    var titleText: String?
//    var currentFestival: DataSet.Festival
    @State var currentFestival = DataSet.Festival.newFestival()
    
    @State var artistList: Array<DataSet.Artist>
    @State var artistDict = [String : Array<DataSet.Artist>]()
//    {
//        didSet {
//            viewSubsection = Array(repeating: true, count: data.getSortLables(sort: sortType).count)
//        }
//    }
    
    
    
    
//    var favorites: Bool
//    var friendList: Bool
    @State var groupFavorites: [String : [String]]?
    @State var groupPhotos: [String : UIImage]?
    
    
    @State var sortType: DataSet.sortType = .alpha
    @State var viewSubsection = Array<Bool>()
    
    var body: some View {
        ZStack {
            VStack {
                VStack {
                    
                    if !data.isArtistDicEmpty(currDict: artistDict) {
                        if searchText == "" {
                            VStack {
                                HStack {
                                    ShuffleButtonSection
                                    CreatePlaylistSection
                                }
                                .padding(10)
                                .frame(height: 80)
                                .shadow(radius: 5)
                                FullList
                                
                            }
                        } else {
                            SearchResults
                        }
                    }
                    
                }
//                TabView() {
//                    Tab("Search", systemImage: "magnifyingglass", role: .search) {
//                        SearchResults
//                    }
//                }
//                .toolbarRole()
                .searchable(
                        text: $searchText,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: titleText.map { "Search \($0)" } ?? "Search"
                    )
//                .searchToolbarBehavior(.)
            }
//            .if(!friendList) { view in
//                view.searchable(text: $searchText)
//            }
            if isLoading {
                VStack {
                    ProgressView("Adding songs...")
                        .padding()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .foregroundStyle(Color.black)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                        .shadow(radius: 5)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                FestivalLogoView(
                    logoPath: currentFestival.logoPath,
                    title: currentFestival.name,
                    frame: 40.0
                )
            }
        }
//        .onChange(of: groupFavorites) { newValue in
//            print("CHANGED")
//            artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType, sortDict: groupFavorites)
//            
//        }
        .onAppear() {
            if let festival = festivalVM.currentFestival {
                currentFestival = festival
                artistDict = festivalVM.getArtistDict(currList: artistList, sort: sortType, secondWeekend: currentFestival.secondWeekend)
                viewSubsection = Array(repeating: true, count: artistDict.keys.count)
            } else {
                navigationPath.removeLast()
            }
        }
//        .onChange(of: selectedItem) { newItem in
//            
//        }
        .alert(isPresented: self.$playlistCreatedAlert) {
            Alert(title: Text("Playlist Created!"),
                  primaryButton: .default(Text("Ok")),
                  secondaryButton: .default(Text("Go to playlist")) {
                if let URL = spotify.getPlaylistURL() {
                    UIApplication.shared.open(URL)
                } else {
                    self.errorAlert = true
                }
            })
        }
        .sheet(isPresented: $createPlaylistSheet) {
            PlaylistCreationSheet(artistList: artistList, playlistCreatedAlert: $playlistCreatedAlert)
//            PlaylistCreationSheet(artistDict: data.getArtistDict(currDict: artistDict, favorites: favorites, sort: .alpha), sortType: .alpha, playlistCreatedAlert: self.$playlistCreatedAlert).environmentObject(data)
        }
//        .alert(isPresented: self.$errorAlert) {
//            Alert(
//                title: Text("Something went wrong"),
//                message: Text("Please try again later"),
//                dismissButton: .default(Text("Ok"))
//            )
//        }
//        .navigationTitle(/*friendList ? Text("") : */Text(currentFestival.name))
//        .navigationTitle(Text(String(currentFestival.name + ": Artist List")))
        .toolbar {
            ToolbarItem(placement: .principal) {
                FestivalLogoView(
                    logoPath: currentFestival.logoPath,
                    title: currentFestival.name,
                    frame: 40.0
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: HStack {
            SortMenu(sortType: $sortType, currList: artistList, secondWeekend: currentFestival.secondWeekend)
        })
        .onChange(of: sortType) { newSort in
            artistDict = festivalVM.getArtistDict(currList: artistList, sort: newSort, secondWeekend: currentFestival.secondWeekend)
            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
        }
//        .if(!friendList) { view in
//            view.navigationBarItems(trailing: HStack {
//                SortMenu
//            })
//        }
    }
    
    
    
    var ShuffleButtonSection: some View {
        Group {
            //            NavigationLink(destination: ArtistPage(currentArtist: data.shuffleArtist(currentList: data.getArtistList(currDict: artistDict), includeFavorites: true), shuffle: true, shuffleList: data.getArtistList(currDict: artistDict), shuffleLable: titleText == "All Artists" ? "Random" : titleText, includeFavorites: true).environmentObject(data)) {
            //            NavigationLink(value: )
            //            Navigation
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                VStack (spacing: 3) {
                    Text("Shuffle")
                        .multilineTextAlignment(.center)
                    Image(systemName: "shuffle")
                    
                }
                .font(Font.system(size: 18))
                .bold()
                .foregroundStyle(Color.black)
            }
            //            }
            .frame(height: 70, alignment: .center)
            .padding(.trailing, 5)
            .onTapGesture {
                let currentList = data.getArtistList(currDict: artistDict)
                if let randomArtist = festivalVM.shuffleArtist(currentList: currentList, secondWeekend: currentFestival.secondWeekend) {
                    navigationPath.append(DataSet.ArtistPageStruct(artist: randomArtist,
                                                                   shuffleTitle: titleText != nil ? titleText! : "All Artists",
                                                                   shuffleList: currentList))
                }
            }
        }
//        .alert(isPresented: $data.createPlaylist) {
//            Alert(title: Text("Connection to Spotify Successful!"),
//                  message: Text("Do you want to create a starred playlist?"),
//                  primaryButton: .default(Text("Create Playlist")) {
//                self.makeStarredPlaylist(name: "")
//            }, secondaryButton: .cancel()
//            )
//        }
    }
    
    var CreatePlaylistSection: some View {
        Group {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color("Spotify Color Green"))
                VStack (spacing: 3) {
                    Text("Create Playlist")
                    Image("Spotify Image Always Black")
                        .resizable()
                        .frame(width: 24, height: 24, alignment: .center)
                }
                .font(Font.system(size: 18))
                .bold()
                .foregroundStyle(Color.black)
                
            }
            .frame(height: 70, alignment: .center)
            .onTapGesture {
                if !isLoading {
                    spotify.isUserLoggedIn { isLoggedIn in
                        DispatchQueue.main.async {
                            if isLoggedIn {
                                self.createPlaylistSheet = true
//                                self.makeStarredPlaylist(name: "")
                            } else {
                                self.notLoggedInAlert = true
                            }
                        }
                    }
                }
            }
            .padding(.leading, 5)
            
        }
        .background(Color.clear)
        .alert(isPresented: self.$playlistCreatedAlert) {
            Alert(title: Text("Playlist Created!"),
                  primaryButton: .default(Text("Ok")),
                  secondaryButton: .default(Text("Go to playlist")) {
                if let URL = spotify.getPlaylistURL() {
                    UIApplication.shared.open(URL)
                } else {
                    self.errorAlert = true
                }
            })
        }
    }
    
    func makeStarredPlaylist(playlistName: String, isPublic: Bool) {
//        isLoading = true
//        data.makeNewSpotifyPlaylist(artistList: data.getArtistList(currDict: artistDict), playlistName: "", isPublic: true) { playlistID in
//            DispatchQueue.main.async {
//                if let playlistID = playlistID {
//                    
//                    self.isLoading = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        self.playlistCreatedAlert = true
//                    }
//                    print("🎉 Playlist successfully created: https://open.spotify.com/playlist/\(playlistID)")
//                } else {
//                    self.isLoading = false
//                    self.errorAlert = true
//                    print("❌ Playlist creation failed")
//                }
//            }
//        }
    }
    
    var FullList: some View {
        Group {
            ScrollView {
                ForEach(Array(data.getDictKeysSorted(currDict: artistDict, sort: sortType).enumerated()), id: \.element) { i, section in
                    if let artistArray = artistDict[section] {
                        if !artistArray.isEmpty {
                            if sortType != .alpha {
                                HStack {
                                    Text(section)
                                    if viewSubsection[i] {
                                        Image(systemName: "chevron.up")
                                    } else {
                                        Image(systemName: "chevron.down")
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                                .font(.headline)
                                .onTapGesture(perform: {
                                    viewSubsection[i] = !viewSubsection[i]
                                })
                            }
                            if viewSubsection[i] {
//                                    if sortType != .alpha && !favorites {
//                                        ShuffleSubgroupSection(artistArray: artistArray, section: section)
//                                    }
                                Divider().padding(.horizontal, 20)
                                ForEach(artistArray, id: \.self) { artist in
                                    ArtistLink(artist: artist, shuffleList: data.getArtistList(currDict: artistDict), titleText: titleText, currentFestival: currentFestival, groupFavorites: self.groupFavorites, groupPhotos: self.groupPhotos)
                                }
                            }
//                            Section(header: Group {
//                                if friendList {
//                                    Text(titleText)
//                                } else if sortType != .alpha {
//                                    HStack {
//                                        Text(section)
//                                        if viewSubsection[i] {
//                                            Image(systemName: "chevron.up")
//                                        } else {
//                                            Image(systemName: "chevron.down")
//                                        }
//                                    }
//                                    .onTapGesture(perform: {
//                                        viewSubsection[i] = !viewSubsection[i]
//                                    })
//                                }
//                            }) {
                                
//                            }
                        }
                    }
                }
            }
        }
//        .sheet(isPresented: $createPlaylistSheet) {
//            VStack {
//                Text("Enter Playlist Name")
//                    .font(.headline)
//                TextField("Playlist Name", text: $playlistName)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                    .padding()
//                Button("Create") {
//                    makeStarredPlaylist(name: playlistName)
//                    createPlaylistSheet = false
//                }
//                .padding()
//            }
//            .padding()
//        }
    }
    
    
    var SearchResults: some View {
        Group {
            VStack {
                let searchList = searchArtists()
                if !searchList.isEmpty {
                    Divider().padding(.horizontal, 20)
                    ScrollView {
                        ForEach(searchList, id: \.self) { artist in
                            ArtistLink(artist: artist, shuffleList: artistList, titleText: titleText, currentFestival: currentFestival)
                        }
                    }
                } else {
                    Text("No Results")
                        .font(.subheadline)
                }
            }
        }
    }
    
    
    func searchArtists() -> Array<DataSet.Artist> {
        var artistSearchList = Array<DataSet.Artist>()
        for a in artistList {
            if a.name.lowercased().starts(with: searchText.lowercased()) || a.name.lowercased().contains(String(" " + searchText.lowercased())) {
                artistSearchList.append(a)
                artistSearchList.sort {
                    $0.name.lowercased() < $1.name.lowercased()
                }
            }
        }
        return artistSearchList
    }
    
//    var SortMenu: some View {
//        Group {
//            Menu(content: {
//                //View by Alphabetically
//                Button (action: {
//                    sortType = .alpha
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
////                    artistDict = data.updateArtistDict(currDict: artistDict)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType)
//                }, label: {
//                    HStack {
//                        Text("Sort Alphabetically")
//                        if sortType == .alpha {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//                //View by Day
//                Button (action: {
//                    sortType = .day
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType)
//                }, label: {
//                    HStack {
//                        Text("Sort by Day")
//                        if sortType == .day {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//                //View by Genre
//                Button (action: {
//                    sortType = .genre
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType)
//                }, label: {
//                    HStack {
//                        Text("Sort by Genre")
//                        if sortType == .genre {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//                //View by Stage
//                Button (action: {
//                    sortType = .stage
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType)
//                }, label: {
//                    HStack {
//                        Text("Sort by Stage")
//                        if sortType == .stage {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//                //View by Tier
//                Button (action: {
//                    sortType = .billing
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: favorites, sort: sortType)
//                }, label: {
//                    HStack {
//                        Text("Sort by Tier")
//                        if sortType == .billing {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//            }, label: {
//                Group {
////                    if favorites {
////                        Image(systemName: "list.star")
////                    } else {
//                        Image(systemName: "list.bullet")
////                    }
//                }
////                    .foregroundStyle(Color.blue)
//            })
            
//        }
//        .alert(isPresented: self.$notLoggedInAlert) {
//            Alert(title: Text("Connect to Spotify"),
//                  message: Text("Connect to your Spotify account to create custom playlists!"),
//                  primaryButton: .default(Text("Connect ")) {
//                spotify.openSpotifyLogin()
//            }, secondaryButton: .cancel()
//            )
//        }
//    }
    
    var NoArtistSection: some View {
        Group {
            List {
                Section {
                    HStack {
                        Spacer()
                        Text("You have no Starred Artists yet!")
                            .multilineTextAlignment(.center)
                            .italic()
                        Spacer()
                    }
                }
                Section {
                    ZStack {
                        HStack{
                            Spacer()
//                            Image(systemName: "shuffle")
//                                .imageScale(.large)
                            Text("Discover")
                            Image(systemName: "shuffle")
                                .imageScale(.large)
                            Spacer()
                        }
                        .foregroundStyle(Color.black)
                        .padding(.vertical, 10)
//                        NavigationLink(destination: ArtistPage(currentArtist: data.shuffleArtist(includeFavorites: true), shuffle: true, includeFavorites: true).environmentObject(data)) {
//                            EmptyView()
//                        }
//                        .opacity(0)
                    }
                    .listRowBackground(Color("OASISBlue"))
                }
            }
        }
    }
    
    
//    init(navigationPath: Binding<NavigationPath>, currList: Array<DataSet.Artist> /*currDict: [String : Array<DataSet.artistNEW>]*/, titleText: String? = nil, currentFestival: DataSet.Festival, /*titleText: String,*/ /*favorites: Bool = false, *//*friendList: Bool = false,*/ groupFavorites: [String : [String]]? = nil, groupPhotos: [String : UIImage]? = nil/*, sortType: DataSet.sortType, subsectionLen: Int*/) {
//        self._navigationPath = navigationPath
//        self.artistList = currList
//        self.titleText = titleText
////        self.currentFestival = currentFestival
////        self.titleText = titleText
////        self.favorites = favorites
////        self.friendList = friendList
//        self.groupFavorites = groupFavorites
//        self.groupPhotos = groupPhotos
//    }
        
        
}

//struct ArtistImage: View {
//    var image: UIImage
//    
//    var body: some View{
//        Group {
//            Image(uiImage: image)
//                .resizable()
//                .frame(width: 50, height: 50, alignment: .leading)
//                .clipShape(RoundedRectangle(cornerRadius: 2))
//        }
//    }
//}



struct ArtistLink: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    var artist: DataSet.Artist
    var shuffleList: Array<DataSet.Artist>
    var titleText: String? = nil
    var currentFestival: DataSet.Festival
//    var includeFavorites: Bool
//    var favorites: Bool
    
    var groupFavorites: [String : [String]]?
    var groupPhotos: [String : UIImage]?
    
    @State private var showOverlay: Bool = false
    
    var body: some View {
        Group {
            VStack {
                NavigationLink(value: DataSet.ArtistPageStruct(artist: artist,
                                                               shuffleTitle: titleText != nil ? titleText! : "All Artists",
//                                                               shuffleTitle: "All Artists",
                                                               shuffleList: shuffleList)) {
//                NavigationLink(destination: ArtistPage(currentArtist: artist, includeFavorites: includeFavorites).environmentObject(data)) {
                    ZStack {
                        HStack{
                            ArtistImage(imageURL: artist.imageURL, frame: 50)
                            Text(artist.name)
                            Spacer()
                            if titleText != "Favorites" && festivalVM.favoriteList.contains(artist.id) {
                                Image(systemName: "heart.fill")
                                    .imageScale(.large)
                                    .foregroundStyle(.red)
                                    .padding(.trailing, 5)
                            }
//                            if self.groupFavorites != nil {
//                                FriendPictures
//                            } else if data.getFavorability(artistID: artist.id) == 1 /*&& !favorites*/ {
//                                Image(systemName: "star.fill")
//                                    .imageScale(.large)
//                                    .foregroundStyle(Color.yellow)
//                            }
                            Image(systemName: "chevron.right")
                                .imageScale(.large)
                            
                        }
                        if showOverlay {
                            FriendPicsOverlay
                        }
                    }
                    .contentShape(Rectangle())
                }
                
                Divider()
            }
            .frame(height: 65)
            .padding(.horizontal, 20)
            .buttonStyle(PlainButtonStyle())
            .foregroundStyle(Color("BW Color Switch"))
            
            
            
            
            
//            NavigationLink(destination: ArtistPage(currentArtist: artist, includeFavorites: includeFavorites).environmentObject(data)) {
//                ArtistImage(image: artist.photo)
//                Text(artist.name)
//            }
        }
    }
    
    let FRIEND_PIC_OFFSET: CGFloat = 20

    var FriendPictures: some View {
        Group {
//            if let artistFans = data.addMyFavorites(groupFavorites: groupFavorites!)[artist.id] {
//                ZStack {
//                    if artistFans.count <= 3 {
//                        ForEach(Array(artistFans.prefix(3)).enumerated().map { $0 }, id: \.1) { index, friendID in
//                            Group {
//                                if let image = groupPhotos?[friendID] {
////                                if let localPath = groupPhotos?[friendID] ?? nil, let image = UIImage(contentsOfFile: localPath) {
//                                    Image(uiImage: image)
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(width: 30, height: 30)
//                                        .clipShape(Circle())
//                                } else {
//                                    Image("Default Profile Picture")
//                                        .resizable()
//                                        .frame(width: 30, height: 30, alignment: .center)
//                                        .clipShape(Circle())
//                                }
//                            }
//                            .offset(x: CGFloat(((min(artistFans.count, 3) - 1)-index) * -20))
//                            .padding(.leading, FRIEND_PIC_OFFSET * CGFloat(min(artistFans.count, 3) - 1))
//                        }
//                    } else {
//                        ZStack {
//                            ForEach(Array(artistFans.prefix(2)).enumerated().map { $0 }, id: \.1) { index, friendID in
//                                Group {
//                                    if let image = groupPhotos?[friendID] {
//                                        //                                if let localPath = groupPhotos?[friendID] ?? nil, let image = UIImage(contentsOfFile: localPath) {
//                                        Image(uiImage: image)
//                                            .resizable()
//                                            .scaledToFill()
//                                            .frame(width: 30, height: 30)
//                                            .clipShape(Circle())
//                                    } else {
//                                        Image("Default Profile Picture")
//                                            .resizable()
//                                            .frame(width: 30, height: 30, alignment: .center)
//                                            .clipShape(Circle())
//                                    }
//                                }
//                                .offset(x: CGFloat(((min(artistFans.count, 3)) - (index + 1)) * -20))
//                                .padding(.leading, FRIEND_PIC_OFFSET * CGFloat(min(artistFans.count, 3) - 1))
//                            }
//                            ZStack(alignment: .center) {
//                                Circle()
//                                    .frame(width: 30, height: 30, alignment: .center)
//                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                                //                                .foregroundStyle(.gray)
//                                //                        let numString = String(artistFans - 2)
//                                Text("+\(String(artistFans.count - 2))")
//                                    .offset(x: CGFloat(-2))
//                                    .bold()
//                            }
//                            .offset(x: CGFloat(20))
//                        }
//                        .onTapGesture {
//                            showOverlay.toggle()
//                        }
//                    }
//                }
//                
//            }
        }
    }
    
    var FriendPicsOverlay: some View {
        Group {
//            if let artistFans = data.addMyFavorites(groupFavorites: groupFavorites!)[artist.id] {
//                VStack(alignment: .trailing) {
//                    ZStack {
//                        ZStack {
//                            Triangle()
//                                .fill(Color.white)
//                                .frame(width: 20, height: 20)
//                        
//                                .offset(x: 75, y: 0)
//                                .shadow(radius: 0)
//                            RoundedRectangle(cornerRadius: 10)
//                                .shadow(radius: 0)
//                                .foregroundStyle(.white)
//
//                            
//                        }
//                        .compositingGroup()
//                        .shadow(radius: 5)
//                        ScrollView(.horizontal) {
//                            LazyHStack {
//                                ForEach(artistFans, id: \.self) { friendID in
//                                    VStack {
//                                        if let image = groupPhotos?[friendID] {
//                                            Image(uiImage: image)
//                                                .resizable()
//                                                .scaledToFill()
//                                                .frame(width: 40, height: 40)
//                                                .clipShape(Circle())
//                                        } else {
//                                            Image("Default Profile Picture")
//                                                .resizable()
//                                                .frame(width: 40, height: 40, alignment: .center)
//                                                .clipShape(Circle())
//                                        }
////                                        Text(data.getMemberName(memberID: friendID))
////                                            .lineLimit(1)
//                                    }
////                                    .padding(.vertical, 5)
//                                    
//                                    .frame(width: 40)
//                                }
////                                ForEach(Array(artistFans).enumerated().map { $0 }, id: \.1) { index, friendID in
//                                    
////                                }
//                            }
//                        }
//                        .padding(.horizontal, 4)
//                    }
//                    .offset(x: 5, y: 0)
//                    .frame(width: 130, height: 50, alignment: .center)
//                }
//                .onTapGesture {
//                    showOverlay.toggle()
//                }
//            }
            
        }
    }
    
}

//struct ShuffleSubgroupSection: View {
//    @EnvironmentObject var data: DataSet
//    var artistArray: Array<DataSet.artist>
//    var section: String
//    
//    var body: some View {
//        Group {
//            ZStack {
////                NavigationLink(destination: ArtistPage(currentArtist: data.shuffleArtist(currentList: artistArray, includeFavorites: true), shuffle: false, shuffleList: artistArray, shuffleLable: section, includeFavorites: true).environmentObject(data)) {
////                    EmptyView()
////                }
////                .opacity(0)
//                HStack {
//                    Spacer()
//                    Text(String("Shuffle All " + section))
//                        .italic()
//                        .multilineTextAlignment(.center)
//                                            
//                    Image(systemName: "shuffle")
//                        .imageScale(.large)
//                    Spacer()
//                }
//                .foregroundStyle(Color.black)
//                
////                                    .back
//            }
//            .listRowBackground(Color("OASISBlue"))
//        }
//    }
//}

struct SortMenu: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @Binding var sortType: DataSet.sortType
    var currList: Array<DataSet.Artist>
    var secondWeekend: Bool
//    @Binding var artistDict: [String : Array<DataSet.artistNEW>]
    
    @State var currentFestival = DataSet.Festival.newFestival()
    
    var body: some View {
        Group {
            let dayBool = festivalVM.listHasDays(currList: currList, secondWeekend: currentFestival.secondWeekend)
            let genreBool = festivalVM.listHasGenres(currList: currList, secondWeekend: currentFestival.secondWeekend)
            let stageBool = festivalVM.listHasStages(currList: currList, secondWeekend: currentFestival.secondWeekend)
            let tierBool = festivalVM.listHasTiers(currList: currList, secondWeekend: currentFestival.secondWeekend)
            
            
            //            if dayBool || genreBool || stageBool || tierBool {
            Menu(content: {
                //View by Alphabetically
                Button (action: {
                    sortType = .alpha
                }, label: {
                    HStack {
                        Text("Sort Alphabetically")
                        if sortType == .alpha {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                })
                
                //View by Day
                if dayBool {
                    Button (action: {
                        sortType = .day
                    }, label: {
                        HStack {
                            Text("Sort by Day")
                            if sortType == .day {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
                
                //View by Genre
                if genreBool {
                    Button (action: {
                        sortType = .genre
                    }, label: {
                        HStack {
                            Text("Sort by Genre")
                            if sortType == .genre {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
                
                //View by Stage
                if stageBool {
                    Button (action: {
                        sortType = .stage
                    }, label: {
                        HStack {
                            Text("Sort by Stage")
                            if sortType == .stage {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
                
                //View by Tier
                if tierBool {
                    Button (action: {
                        sortType = .billing
                    }, label: {
                        HStack {
                            Text("Sort by Tier")
                            if sortType == .billing {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    })
                }
            }, label: {
                Group {
                    Image(systemName: "list.bullet")
                }
            })
        }
        .onAppear() {
            if let festival = festivalVM.currentFestival {
                currentFestival = festival
            }
        }
//        .onChange(of: sortType) { newSort in
//            artistDict = data.getArtistDictFromListNEW(currList: currList, sort: newSort, secondWeekend: secondWeekend)
//        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}


class ImageCache {
    static let shared = ImageCache()

    private let cacheDir: URL

    private init() {
        cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("imageCache")

        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    private func localPath(for url: String) -> URL {
        let filename = url.replacingOccurrences(of: "/", with: "_")
        return cacheDir.appendingPathComponent(filename)
    }

    func getCachedImage(for url: String) -> UIImage? {
        let path = localPath(for: url)
        return UIImage(contentsOfFile: path.path)
    }

    func cacheImage(_ data: Data, for url: String) {
        let path = localPath(for: url)
        try? data.write(to: path)
    }
}
