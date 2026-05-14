//
//  ArtistPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/15/25.
//

import Foundation
import SwiftUI
import UIKit

struct ArtistPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var tags: TagViewModel
    //    @EnvironmentObject var spotify: SpotifyViewModel
    
    @State var currentArtist: Artist
    
    //    @State var shuffle: Bool = false
    @State var shuffleLable: String? = nil
    @State var shuffleList: Array<Artist>
    
    @Binding var navigationPath: NavigationPath
    
    @State var currentFestival: Festival
    
    //    @State var includeFavorites: Bool
    
    @State var showArtistTagSheet: Bool = false
    
    
    
    var body: some View {
        VStack {
            ArtistTitleBar
            List {
                ArtistPageSection
                //                ArtistPlaylistSection
                //                LatestProjectSection
                //                ArtistSpotifySection
                //                UpcomingAlbumSection
                //                AllAlbumsSection
                ArtistTagSection
                RelatedArtistsSection
                ArtistGenresSection
                FestivalInfoSection
            }
            //            .background(RoundedRectangle(cornerRadius: 5)
            //                .foregroundStyle(Color(currentArtist.photo.averageColor!)))
            
            
        }
        .sheet(isPresented: $showArtistTagSheet) {
            ArtistTagSheet
            
        }
        .onAppear() {
            if latestProject == nil {
                getLatestProject()
            }
            //            //print("Current Artist Tag List: \(currentArtist.artistTags)")
            //            if let festival = festivalVM.currentFestival {
            //                currentFestival = festival
            //
            //            } else {
            //                navigationPath.removeLast()
            //            }
        }
        .onChange(of: currentArtist.id) { _ in
            getLatestProject()
        }
        //        .onChange(of: currentArtist) { _ in
        //            getLatestProject()
        //        }
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    let dislikedArtists = tags.getDNSTArtists(currList: currentFestival.artistList)
                    if let randomArtist = festivalVM.shuffleArtist(currentList: shuffleList, currentArtist: currentArtist, secondWeekend: currentFestival.secondWeekend, dislikedArtists: dislikedArtists) {
                        currentArtist = randomArtist
                    }
                    //                        currentArtist.favorability = data.getFavorability(artistID: currentArtist.id)
                }, label: {
                    HStack {
                        HStack {
                            if shuffleLable != nil {
                                Text(shuffleLable!)
                            }
                            Image(systemName: "shuffle")
                            //                                    .foregroundStyle(Color.blue)
                        }
                    }
                })
            })
        
    }
    
    func getDayInfo(day: Int) -> String {
        var dayStr = ""
        if day < 0 {
            dayStr = data.getSortLables(sort: .day).last!
        } else {
            dayStr = data.getSortLables(sort: .day)[day]
        }
        return String("Day: " + dayStr)
    }
    
    func getGenreList() -> String {
        var genres = ""
        for (i,g) in currentArtist.genres.enumerated() {
            genres += g
            if i != currentArtist.genres.count - 1 {
                genres += ", "
            }
        }
        if genres.count == 1 {
            return String("Genre: " + genres)
        }
        return String("Genres: " + genres)
    }
    
    var ArtistTitleBar: some View {
        Group {
            ZStack(alignment: .top) {
                //                Color(.gray)
                //                    .ignoresSafeArea()
                VStack(alignment: .leading) {
                    HStack {
                        if let url = spotifyArtistURL(from: currentArtist.id) {
                            Link(destination: url, label: {
                                ArtistImage(imageURL: currentArtist.imageURL, frame: 120)
                            })
                        }
                        VStack {
                            HStack {
                                Text(currentArtist.name)
                                    .multilineTextAlignment(.center)
                                    .font(Font.system(size: 22))
                                    .bold()
                                //                                Button(action: {
                                //                                    self.artistInfoPopup = true
                                //                                }, label: {
                                //                                    ZStack {
                                //                                        Rectangle()
                                //                                        //                                            .scaledToFit()
                                //                                            .frame(width: 20, height: 60)
                                //                                            .opacity(0)
                                //                                        Image(systemName: "info.circle")
                                //                                            .imageScale(.large)
                                //                                    }
                                //                                })
                                
                            }
                            .foregroundStyle(Color("BW Color Switch"))
                            .padding(.bottom, 5)
                            HStack {
                                ShareLink(item: getArtistShareLink()) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                            .shadow(radius: 3)
                                        
                                        Image(systemName: "square.and.arrow.up.circle")
                                            .imageScale(.large)
                                            .foregroundStyle(.blue)
                                    }
                                    .padding([.leading, .trailing], 5)
                                }
                                Button(action: {
                                    tags.heartPressed(currentArtist.id)
                                    firestore.myUserProfile.favoriteArtistsList = tags.myFavorites
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                            .shadow(radius: 3)
                                        
                                        Image(systemName: "heart.circle")
                                            .imageScale(.large)
                                            .foregroundStyle(tags.isArtistFavorited(currentArtist.id) ? Color.red : Color.gray)
                                    }
                                    .padding([.leading, .trailing], 2)
                                })
                                
                                Button(action: {
                                    showArtistTagSheet = true
                                }, label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 28, height: 28)
                                            .shadow(radius: 3)
                                        
                                        Image(systemName: "tag.circle")
                                            .imageScale(.large)
                                            .foregroundStyle(Color.blue)
                                    }
                                    .padding([.leading, .trailing], 5)
                                })
                                
                                
                                //                                Menu(content: {
                                //                                    if !tags.isDNSTSelected(currentArtist.id) {
                                ////                                    if !currentArtist.artistTags.contains(tags.DONOTSUGGESTTAG.id) {
                                ////                                    if tags.artistTagDictionary[currentArtist.id]?.contains(tags.DONOTSUGGESTTAG.id) {
                                //                                        Button (action: {
                                //                                            tags.addDNST(currentArtist.id)
                                ////                                            doNotSuggestPressed()
                                //                                            //                                        festivalVM.dislikeButtonPressed(currentArtist.id)
                                //                                            //                                        sortType = .alpha
                                //                                        }, label: {
                                //                                            HStack {
                                //                                                Text("Do Not Suggest")
                                //                                                Spacer()
                                //                                                Image(systemName: "nosign")
                                //                                            }
                                ////                                            .foregroundStyle(festivalVM.dislikeList.contains(currentArtist.id) ? Color.red : Color.gray)
                                //                                        })
                                //                                    }
                                //                                    Button (action: {
                                //                                        showArtistTagSheet = true
                                ////                                        festivalVM.dislikeButtonPressed(currentArtist.id)
                                ////                                        sortType = .alpha
                                //                                    }, label: {
                                //                                        HStack {
                                ////                                            if currentArtist.artistTags.isEmpty {
                                //                                            if tags.doesArtistHaveTags(currentArtist.id) {
                                //                                                Text("Edit Tags")
                                //                                                Spacer()
                                //                                                Image(systemName: "pencil.circle")
                                //                                            } else {
                                //                                                Text("Add Tags")
                                //                                                Spacer()
                                //                                                Image(systemName: "plus.circle")
                                //                                            }
                                //                                        }
                                //                                    })
                                //
                                //                                }, label: {
                                //                                    Group {
                                //                                        Image(systemName: "ellipsis.circle")
                                ////                                        Image(systemName: "tag.circle")
                                //                                            .imageScale(.large)
                                //                                            .foregroundStyle(Color.gray)
                                //                                            .padding([.leading, .trailing], 5)
                                //                                    }
                                //                                })
                            }
                            .font(Font.system(size: 26))
                            //                            .shadow(radius: 2)
                            //                            .padding(10)
                            
                            //                        .listRowBackground(Color(hue: 0.76, saturation: 0.2, brightness: 0.85))
                        }
                        //                    .background(RoundedRectangle(cornerRadius: 20)
                        //                        .foregroundStyle(Color.gray))
                        .padding(10)
                    }
                    .padding(.horizontal, 10)
                    
                }
            }
            .padding(.bottom, 10)
        }
    }
    
    
    func getArtistShareLink() -> String {
        return "https://oasis-austinzv.web.app/share/festival/\(currentFestival.id)/artist/\(currentArtist.id)"
    }
    
    //    func doNotSuggestPressed() {
    //        if let index = currentArtist.artistTags.firstIndex(of: tags.DONOTSUGGESTTAG.id) {
    //            currentArtist.artistTags.remove(at: index)
    //        } else {
    //            currentArtist.artistTags.insert(tags.DONOTSUGGESTTAG.id, at: 0)
    //        }
    //    }
    
    
    //    var ArtistSpotifySection: some View {
    //        Group {
    //            Section() {
    //
    //                Link(destination: currentArtist.artistPlaylist, label: {
    //                    HStack {
    //                        //                        Image(.spotify)
    //                        //                            .resizable()
    //                        //                            .frame(width: 20, height: 20, alignment: .center)
    //                        Text(String("This is... " + currentArtist.name)).italic()
    //                        Spacer()
    //                        Image(systemName: "chevron.right")
    //                    }
    //                })
    //                .foregroundStyle(Color.black)
    //
    //            }
    ////            Section(header: Text("Playlist")) {
    //
    ////            }
    //
    //        }
    //
    //    }
    
    //    var ArtistName: some View {
    //        let nameArr = currentArtist.name.components(separatedBy: " ")
    //
    //        return Group {
    //
    //        }
    //    }
    //
    //    func getNameArray() {
    //        let artistName = currentArtist.name.components(separatedBy: " ")
    //        var nameArr = <String>()
    //        for str in artistName {
    //
    //        }
    //    }
    
    //    func getWordAmount(name: String) -> Int {
    //        var amt = 1 + name.reduce(0) { $1 == " " ? $0 + 1 : $0 }
    //        //print(amt)
    //        return amt
    //    }
    
    
    
    var ArtistTagSection: some View {
        Group {
            //            let artistTags = tags.getTagsFromIDs(currentArtist.artistTags)
            let artistTags = tags.getArtistTags(artistID: currentArtist.id)
            if !artistTags.isEmpty {
                Section(header:
                            HStack {
                    Image(systemName: "tag")
                    Text("My Tags")
                }) {
                    FlowLayout(spacing: 8) {
                        //                        Text("Genres:")
                        //                            .padding(.vertical, INFO_PADDING)
                        ForEach(artistTags, id: \.id) { tag in
                            //                            if let tag = tags.getTag(tagID) {
                            Button {
                                //                                    let tagList = festivalVM.getTagList(tag: tag, currList: currentFestival.artistList)
                                let tagList = tags.getArtistList(tag.id, currentList: currentFestival.artistList)
                                navigationPath.append(ArtistListStruct(titleText: tag.name, festival: currentFestival, list: tagList))
                                //                                //print("TAG: \(tag.name)")
                                //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currentFestival.artistList)
                                //                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currentFestival, list: genreList))
                            } label: {
                                HStack {
                                    //                                    if let symbol = tag.symbol { Image(systemName: symbol) }
                                    //                                    else { Image(systemName: "questionmark.square") }
                                    Image(systemName: tag.symbol)
                                    Text(tag.name)
                                    Image(systemName: "chevron.right").foregroundStyle(.black)
                                }
                                .foregroundStyle(COLOR_SPECTRUM_ARRAY[tag.color])
                                .padding(INFO_PADDING)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("BW Color Switch Reverse"))
                                        .shadow(color: .black, radius: 1, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.black, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            //                            }
                            //                            .onTapGesture {
                            //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                            //                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                            //                            }
                        }
                    }
                    
                    
                    
                    //                    HStack {
                    //                        WrappingHStack {
                    //                            Text("Genres: ")
                    //                            ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                    //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                    //                                let genreText = genre + (genre == currentArtist.genres.max() ? "" : ", ")
                    ////                                HStack {
                    //                                    Text(genreText)
                    ////                                }
                    //                                    .foregroundStyle(.blue)
                    //                                    .underline()
                    //                                    .onTapGesture() {
                    //                                        navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                    //                                    }
                    //                                if genre != currentArtist.genres.max() {
                    //                                    Text(" ")
                    //                                }
                    //                                //                                if genre != genres.max() {
                    //                                ////
                    //                                //                                }
                    //                            }
                    //                        }
                    //                    }
                    //                }
                }
            }
        }
    }
    
    //    var ArtistSpotifySection: some View {
    //        Group {
    //            Section(header: Text("Pages")) {
    ////                Link(destination: currentArtist.artistPage, label: {
    //                    HStack {
    //                        Image(systemName: "info.circle")
    //                        Text(String("Artist Page"))/*.bold()*/
    //                        Spacer()
    //                        Image("Spotify Image Black")
    //                            .resizable()
    //                            .frame(width: 22, height: 22, alignment: .center)
    //                        Image(systemName: "chevron.right")
    //                    }
    ////                })
    //                .foregroundStyle(Color("BW Color Switch"))
    ////                if currentArtist.artistPlaylist != nil {
    ////                    Link(destination: currentArtist.artistPlaylist!, label: {
    ////                        HStack {
    ////                            Image(systemName: "music.note.list")
    ////                            Text(String(("This is... ") + currentArtist.name))
    ////                            Spacer()
    ////                            Image("Spotify Image Black")
    ////                                .resizable()
    ////                                .frame(width: 22, height: 22, alignment: .center)
    ////                            Image(systemName: "chevron.right")
    ////                        }
    ////                    })
    ////                    .foregroundStyle(Color("BW Color Switch"))
    ////                }
    //            }
    //        }
    //
    //    }
    
    var ArtistPageSection: some View {
        Group {
            if let url = spotifyArtistURL(from: currentArtist.id) {
                Section {
                    //                    if let url = spotifyArtistURL(from: currentArtist.id) {
                    //                Section {
                    Link(destination: url, label: {
                        HStack {
                            //                            Text(currentArtist.name)
                            Text("")
                            HStack {
                                Image("Spotify Full Logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 25, alignment: .center)
                                //                                        .offset(x: -5)
                                Text("Page")
                            }
                            Spacer()
                            Image("Spotify Image Black")
                                .resizable()
                                .frame(width: 22, height: 22, alignment: .center)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    })
                    //                        .listRowSeparator(.visible, edges: .all)
                    //                        .listRowInsets(EdgeInsets())
                    //                        .padding(.)
                    //                }
                    //                    }
                    if let project = latestProject, let projectURL = URL(string: project.external_urls.spotify) {
                        Link(destination: projectURL, label: {
                            HStack {
                                Text("")
                                if let projectImage = project.images.first {
                                    ArtistImage(imageURL: projectImage.url, frame: 40)
                                }
                                VStack{
                                    HStack {
                                        Text(project.name).bold()
                                        Spacer()
                                    }
                                    HStack {
                                        Text("Released \(formatReleaseDate(project.release_date))")
                                            .foregroundStyle(Color.gray)
                                            .italic()
                                        Spacer()
                                    }
                                }
                                Spacer()
                                Image("Spotify Image Black")
                                    .resizable()
                                    .frame(width: 22, height: 22, alignment: .center)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(Color("BW Color Switch"))
                        })
                    }
                }
            }
        }
    }
    
    func spotifyArtistURL(from id: String) -> URL? {
        return URL(string: "https://open.spotify.com/artist/\(id)")
    }
    
    
    
    @State var artistPlaylist: SpotifyViewModel.Playlist?
    @State var playlistLoading: Bool = false
    
    var ArtistPlaylistSection: some View {
        Group {
            if let playlist = artistPlaylist, let playlistURL = URL(string: playlist.external_urls.spotify) {
                Section(header: HStack {
                    Image(systemName: "music.note.list")
                    Text("Artist Playlist") }
                ) {
                    Link(destination: playlistURL, label: {
                        HStack {
                            if let playlistImage = playlist.images?.first {
                                ArtistImage(imageURL: playlistImage.url, frame: 40)
                            }
                            VStack{
                                HStack {
                                    Text(playlist.name).bold()
                                    Spacer()
                                }
                                //                                HStack {
                                //                                    Text("Released \(project.release_date)")
                                //                                        .foregroundStyle(Color.gray)
                                //                                        .italic()
                                //                                    Spacer()
                                //                                }
                            }
                            Spacer()
                            Image("Spotify Image Black")
                                .resizable()
                                .frame(width: 22, height: 22, alignment: .center)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    })
                }
            } else if playlistLoading {
                Section(header: HStack {
                    Image(systemName: "music.note.list")
                    Text("Artist Playlist") }
                ) {
                    ProgressView()
                }
            }
        }
    }
    
    private func getArtistPlaylist() {
        artistPlaylist = nil
        playlistLoading = true
        spotify.fetchArtistThisIsPlaylist(artistName: currentArtist.name) { playlist in
            if let playlist = playlist {
                artistPlaylist = playlist
            }
        }
        playlistLoading = false
    }
    
    
    
    @State var latestProject: SpotifyViewModel.SpotifyAlbum?
    @State var albumLoading: Bool = false
    
    var LatestProjectSection: some View {
        Group {
            if let project = latestProject, let projectURL = URL(string: project.external_urls.spotify) {
                Section(header: HStack {
                    Image(systemName: "opticaldisc")
                    Text("Latest Album") }
                ) {
                    Link(destination: projectURL, label: {
                        HStack {
                            if let projectImage = project.images.first {
                                ArtistImage(imageURL: projectImage.url, frame: 40)
                            }
                            VStack{
                                HStack {
                                    Text(project.name).bold()
                                    Spacer()
                                }
                                HStack {
                                    Text("Released \(formatReleaseDate(project.release_date))")
                                        .foregroundStyle(Color.gray)
                                        .italic()
                                    Spacer()
                                }
                            }
                            Spacer()
                            Image("Spotify Image Black")
                                .resizable()
                                .frame(width: 22, height: 22, alignment: .center)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    })
                }
            } else if albumLoading {
                Section(header: HStack {
                    Image(systemName: "opticaldisc")
                    Text("Latest Album") }
                ) {
                    ProgressView()
                        .foregroundStyle(.black)
                }
            }
        }
    }
    
    private func formatReleaseDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .long  // "August 29, 2025"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        } else {
            return dateString // fallback if parsing fails
        }
    }
    
    private func getLatestProject() {
        latestProject = nil
        albumLoading = true
        spotify.fetchArtistLatestAlbum(artistID: currentArtist.id) { album in
            if let album = album {
                latestProject = album
            }
            albumLoading = false
        }
    }
    
    //    var AllAlbumsSection: some View {
    //        Group {
    //            if currentArtist.albums.count > 0 {
    //                Section(header: Text("Albums")) {
    ////                    ForEach(Array(zip(data.getAlbumList(artist: currentArtist).indices, data.getAlbumList(artist: currentArtist))), id: \.0) { i, album in
    //                    ForEach(data.getAlbumList(artist: currentArtist)) { album in
    //                        Link(destination: album.URLs.first!, label: {
    //                            HStack{
    //                                Text(album.name).bold()
    //                                Text(" • ")
    //                                Text(String(album.year))
    //                                    .foregroundStyle(Color.gray)
    //                                Spacer()
    //                                Image("Spotify Image Black")
    //                                    .resizable()
    //                                    .frame(width: 22, height: 22, alignment: .center)
    //                                Image(systemName: "chevron.right")
    //                            }
    //                        })
    //                        .foregroundStyle(Color("BW Color Switch"))
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    var RelatedArtistsSection: some View {
        Group {
            //            if let currFest = festivalVM.currentFestival {
            let relatedArists = data.getRelatedArtists(currentArtist: currentArtist, currentList: currentFestival.artistList)
            if relatedArists.count > 0 {
                //                    Section {
                Section(header:
                            HStack {
                    Image(systemName: "person.2")
                    Text("Similar \(currentFestival.name) Artists")
                }) {
                    ScrollView(.horizontal) {
                        LazyHStack {
                            HStack {
                                ForEach(relatedArists) { artist in
                                    NavigationLink(destination: ArtistPage(currentArtist: artist, shuffleLable: "All Artists", shuffleList: currentFestival.artistList, navigationPath: $navigationPath, currentFestival: currentFestival)) {
                                        VStack {
                                            ArtistImage(imageURL: artist.imageURL, frame: 100)
                                                .padding(5)
                                            
                                            Text(artist.name)
                                                .font(.system(size: 15))
                                                .frame(maxWidth: 100)
                                        }
                                        .padding(5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 15)
                                                .fill(Color("BW Color Switch Reverse"))
                                                .shadow(color: .black, radius: 2, x: 0, y: 2)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 15)
                                                .stroke(.black, lineWidth: 2)
                                        )
                                    }
                                    .foregroundStyle(Color("BW Color Switch"))
                                    .padding(.horizontal, 5)
                                }
                            }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            //            }
        }
        
        
    }
    
    var ArtistGenresSection: some View {
        Group {
            if !currentArtist.genres.isEmpty {
                Section(header:
                            HStack {
                    Image(systemName: "music.note.list")
                    Text("Artist Genres")
                }) {
                    FlowLayout(spacing: 8) {
                        //                        Text("Genres:")
                        //                            .padding(.vertical, INFO_PADDING)
                        ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                            Button {
                                let genreList = festivalVM.getGenreList(genre: genre, currList: currentFestival.artistList)
                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currentFestival, list: genreList))
                            } label: {
                                HStack {
                                    Text(genre)
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundStyle(Color("OASIS Dark Orange"))
                                .padding(INFO_PADDING)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color("BW Color Switch Reverse"))
                                        .shadow(color: .black, radius: 1, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.black, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            //                            .onTapGesture {
                            //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                            //                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                            //                            }
                        }
                    }
                    
                    
                    
                    //                    HStack {
                    //                        WrappingHStack {
                    //                            Text("Genres: ")
                    //                            ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                    //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                    //                                let genreText = genre + (genre == currentArtist.genres.max() ? "" : ", ")
                    ////                                HStack {
                    //                                    Text(genreText)
                    ////                                }
                    //                                    .foregroundStyle(.blue)
                    //                                    .underline()
                    //                                    .onTapGesture() {
                    //                                        navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                    //                                    }
                    //                                if genre != currentArtist.genres.max() {
                    //                                    Text(" ")
                    //                                }
                    //                                //                                if genre != genres.max() {
                    //                                ////
                    //                                //                                }
                    //                            }
                    //                        }
                    //                    }
                    //                }
                }
            }
        }
    }
    
    var ArtistGenres: some View {
        Group {
            //            if let currFest = festivalVM.currentFestival {
            if !currentArtist.genres.isEmpty {
                FlowLayout(spacing: 8) {
                    //                        Text("Genres:")
                    //                            .padding(.vertical, INFO_PADDING)
                    ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                        Button {
                            let genreList = festivalVM.getGenreList(genre: genre, currList: currentFestival.artistList)
                            navigationPath.append(ArtistListStruct(titleText: genre, festival: currentFestival, list: genreList))
                        } label: {
                            HStack {
                                Text(genre)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                            .padding(INFO_PADDING)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("BW Color Switch Reverse"))
                                    .shadow(color: .black, radius: 1, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.black, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        //                            .onTapGesture {
                        //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                        //                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                        //                            }
                    }
                }
                
                
                
                //                    HStack {
                //                        WrappingHStack {
                //                            Text("Genres: ")
                //                            ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                //                                let genreText = genre + (genre == currentArtist.genres.max() ? "" : ", ")
                ////                                HStack {
                //                                    Text(genreText)
                ////                                }
                //                                    .foregroundStyle(.blue)
                //                                    .underline()
                //                                    .onTapGesture() {
                //                                        navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                //                                    }
                //                                if genre != currentArtist.genres.max() {
                //                                    Text(" ")
                //                                }
                //                                //                                if genre != genres.max() {
                //                                ////
                //                                //                                }
                //                            }
                //                        }
                //                    }
                //                }
            }
        }
    }
    
    var FestivalInfoSection: some View {
        Group {
            Section(header:
                        HStack {
                Image(systemName: "info.circle")
                Text("\(currentFestival.name) Info")
            }) {
                ArtistDay
                ArtistStage
                ArtistTier
                //                ArtistGenres
            }
        }
    }
    
    let INFO_PADDING: CGFloat = 8
    
    var ArtistDay: some View {
        Group {
            //            if let currFest = festivalVM.currentFestival {
            FlowLayout(spacing: 8) {
                Text("Day:")
                    .padding(.vertical, INFO_PADDING)
                if currentArtist.day == data.NA_TITLE_BLOCK {
                    Text("Unannounced")
                        .padding(.vertical, INFO_PADDING)
                } else {
                    Button {
                        let dayList = festivalVM.getDayList(currArtist: currentArtist, currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
                        navigationPath.append(ArtistListStruct(titleText: currentArtist.day, festival: currentFestival, list: dayList)
                        )
                    } label: {
                        HStack {
                            Text(currentArtist.day)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("OASIS Dark Orange"))
                        .padding(INFO_PADDING)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("BW Color Switch Reverse"))
                                .shadow(color: .black, radius: 1, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.black, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    if currentFestival.secondWeekend && currentArtist.weekend != "Both" {
                        Button {
                            let weekendList = festivalVM.getWeekendList(weekend: currentArtist.weekend, currList: currentFestival.artistList)
                            navigationPath.append(ArtistListStruct(titleText: currentArtist.weekend, festival: currentFestival, list: weekendList))
                        } label: {
                            HStack {
                                Text(currentArtist.weekend)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                            .padding(INFO_PADDING)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("BW Color Switch Reverse"))
                                    .shadow(color: .black, radius: 1, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.black, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            
            
            
            
            //                HStack {
            //                    Text("Day: ")
            //                    if currentArtist.day == data.NA_TITLE_BLOCK {
            //                        Text("Unannounced")
            //                    } else {
            //                        let dayList = festivalVM.getDayList(currArtist: currentArtist, currList: currFest.artistList, secondWeekend: currFest.secondWeekend)
            ////                        NavigationLink(value: ArtistListStruct(titleText: currentArtist.day, festival: currFest, list: dayList)) {
            //                            Text(currentArtist.day)
            //                                .foregroundStyle(.blue)
            //                                .underline()
            //                                .onTapGesture() {
            //                                    navigationPath.append(ArtistListStruct(titleText: currentArtist.day, festival: currFest, list: dayList))
            //                                }
            ////                        }
            //                    }
            ////                    Spacer()
            ////                    Divider()
            //                    if currFest.secondWeekend && currentArtist.weekend != "Both" {
            ////                        Text("Weekend: ")
            ////                            .padding(.leading, 2)
            //                        let weekendList = festivalVM.getWeekendList(weekend: currentArtist.weekend, currList: currFest.artistList)
            //                            Text("(\(currentArtist.weekend))")
            //                                .foregroundStyle(.blue)
            //                                .underline()
            //                                .onTapGesture() {
            //                                    navigationPath.append(ArtistListStruct(titleText: currentArtist.weekend, festival: currFest, list: weekendList))
            //                                }
            ////                        }
            //                    }
            //                    Spacer()
            //                }
            //            }
        }
    }
    
    var ArtistStage: some View {
        Group {
            //            if let currFest = festivalVM.currentFestival {
            if festivalVM.listHasStages(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend) {
                FlowLayout(spacing: 8) {
                    Text("Stage:")
                        .padding(.vertical, INFO_PADDING)
                    if currentArtist.stage == data.NA_TITLE_BLOCK {
                        Text("Unannounced")
                            .padding(.vertical, INFO_PADDING)
                    } else {
                        Button {
                            let stageList = festivalVM.getStageList(stage: currentArtist.stage, currList: currentFestival.artistList)
                            navigationPath.append(ArtistListStruct(titleText: currentArtist.stage, festival: currentFestival, list: stageList))
                        } label: {
                            HStack {
                                Text(currentArtist.stage)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                            .padding(INFO_PADDING)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color("BW Color Switch Reverse"))
                                    .shadow(color: .black, radius: 1, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(.black, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        //                            .onTapGesture {
                        //                                let stageList = festivalVM.getStageList(stage: currentArtist.stage, currList: currFest.artistList)
                        //                                navigationPath.append(ArtistListStruct(titleText: currentArtist.stage, festival: currFest, list: stageList))
                        //                            }
                    }
                }
                
                //                    HStack {
                //                        Text("Stage: ")
                //                        if currentArtist.stage == data.NA_TITLE_BLOCK {
                //                            Text("Unannounced")
                //                        } else {
                //                            let stageList = festivalVM.getStageList(stage: currentArtist.stage, currList: currFest.artistList)
                //                            Text(currentArtist.stage)
                //                                .foregroundStyle(.blue)
                //                                .underline()
                //                                .onTapGesture() {
                //                                    navigationPath.append(ArtistListStruct(titleText: currentArtist.stage, festival: currFest, list: stageList))
                //                                }
                //                            //                        }
                //                        }
                //                    }
            }
            //            }
        }
    }
    
    var ArtistTier: some View {
        Group {
            //            if let currFest = festivalVM.currentFestival {
            if currentArtist.tier != data.NA_TITLE_BLOCK {
                FlowLayout(spacing: 8) {
                    Text("Tier:")
                        .padding(.vertical, INFO_PADDING)
                    //                        ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                    Button {
                        let tierList = festivalVM.getTierList(tier: currentArtist.tier, currList: currentFestival.artistList)
                        navigationPath.append(ArtistListStruct(titleText: currentArtist.tier, festival: currentFestival, list: tierList))
                    } label: {
                        HStack {
                            Text(currentArtist.tier)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("OASIS Dark Orange"))
                        .padding(INFO_PADDING)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color("BW Color Switch Reverse"))
                                .shadow(color: .black, radius: 1, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.black, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    //                            .onTapGesture {
                    //                                let tierList = festivalVM.getTierList(tier: currentArtist.tier, currList: currFest.artistList)
                    //                                navigationPath.append(ArtistListStruct(titleText: currentArtist.tier, festival: currFest, list: tierList))
                    //                            }
                    //                        }
                }
                
                //                    HStack {
                //                        Text("Tier: ")
                //                        let tierList = festivalVM.getTierList(tier: currentArtist.tier, currList: currFest.artistList)
                //                        Text(currentArtist.tier)
                //                            .foregroundStyle(.blue)
                //                            .underline()
                //                            .onTapGesture() {
                //                                navigationPath.append(ArtistListStruct(titleText: currentArtist.tier, festival: currFest, list: tierList))
                //                            }
                //                    }
            }
            //            }
        }
    }
    
    @State var showAddTagSheet = false
    
    @State var selectedTags: Set<UUID> = []
    
    @State var editView = false
    
    @State var editingTag: ArtistTag?
    
    var ArtistTagSheet: some View {
        VStack {
            HStack {
                ArtistTagSheetCancelButton
                Spacer()
                ArtistTagSheetAddButton
            }
            .padding([.top, .horizontal], 25)
            Text(titleText)
                .font(.title)
                .multilineTextAlignment(.center)
                .padding([.top, .horizontal], 10)
            ScrollView {
                let sortedTags = tags.getSortedTag()
                VStack(spacing: 12) {
                    ForEach(sortedTags) { tag in
                        HStack {
                            if !editView {
                                Image(systemName: selectedTags.contains(tag.id) ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(.black)
                                    .imageScale(.large)
                            } else if tag != tags.DONOTSUGGESTTAG {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(.blue)
                                    .imageScale(.medium)
                            }
                            Spacer()
                            Group {
                                //                            ZStack(alignment: .trailing) {
                                Text(tag.name)/*.padding(.trailing, 50)*/
                                Image(systemName: tag.symbol)
                                    .imageScale(.large)
                            }
                            .foregroundStyle((editView && tag.id == tags.DONOTSUGGESTTAG.id) ? Color.gray : COLOR_SPECTRUM_ARRAY[tag.color])
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 12)
                        .onTapGesture {
                            if !editView {
                                if selectedTags.contains(tag.id) {
                                    selectedTags.remove(tag.id)
                                } else {
                                    selectedTags.insert(tag.id)
                                }
                            } else if tag != tags.DONOTSUGGESTTAG {
                                editingTag = tag
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    showAddTagSheet = true
                                }
                            }
                        }
                        if let lastTag = sortedTags.last, tag != lastTag { Divider() }
                    }
                    
                    //                    .padding(/*.vertical,*/ 15)
                }
                .padding(.vertical, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.black, lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .padding(.vertical, 10)
                HStack {
                    if !editView {
                        Spacer()
                        Button {
                            editingTag = ArtistTag()
                            DispatchQueue.main.async {
                                showAddTagSheet = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add Tag")
                            }
                            .foregroundStyle(.blue)
                        }
                        //                        Spacer()
                        Divider().padding(.horizontal, 10)
                        //                        Spacer()
                        Button {
                            editView = true
                        } label: {
                            HStack {
                                Image(systemName: "pencil.circle")
                                Text("Edit Tags")
                            }
                            .foregroundStyle(.blue)
                        }
                        Spacer()
                    } else {
                        Button {
                            editView = false
                        } label: {
                            HStack {
                                //                                Image(systemName: "pencil.circle")
                                Text("Done Editing")
                            }
                            .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedTags = Set(tags.getArtistTagIDs(artistID: currentArtist.id))
            //            for tagID in currentArtist.artistTags {
            //            selectedTags.removeAll()
            //            for tagID in tags.getArtistTagIDs(artistID: currentArtist.id) {
            //                selectedTags.insert(tagID)
            //            }
        }
        //        .onChange(of: tags.myTags) { newTagList in
        //            selectedTags.removeAll()
        //            for tag in currentArtist.artistTags {
        //                selectedTags.insert(tag.id)
        //            }
        //        }
        .sheet(item: $editingTag) { tag in
            NewTagSheet(editingTag: tag)
        }
        //        .sheet(isPresented: $showAddTagSheet) {
        //
        //
        //        }
    }
    
    var titleText: AttributedString {
        let protectedName = currentArtist.name.replacingOccurrences(
            of: " ",
            with: "\u{00A0}"
        )
        
        var text = AttributedString("Add Tags to\u{200B} \(protectedName)")
        
        if let range = text.range(of: protectedName) {
            text[range].font = .title.italic()
        }
        
        return text
    }
    
    var ArtistTagSheetCancelButton: some View {
        Button {
            showArtistTagSheet = false
        } label: {
            Text("Cancel")
                .foregroundStyle(.red)
        }
    }
    
    var ArtistTagSheetAddButton: some View {
        Button {
            tags.setTags(artistID: currentArtist.id, tagIDs: selectedTags)
            showArtistTagSheet = false
        } label: {
            Text("Save")
            //                .foregroundStyle(newTag.name.isEmpty ? .gray : .blue)
        }
        //        .disabled(newTag.name.isEmpty)
    }
}
    







struct NewTagSheet: View {
    @EnvironmentObject var data: DataSet
//    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
//    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var tags: TagViewModel
    
    @State var editingTag: ArtistTag
    
    @Environment(\.dismiss) private var dismiss
    
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        showSymbolPicker = false
                        showColorPicker = false
                    }
                    
                    nameFocused = false
                }
            VStack {
                HStack {
                    NewTagSheetCancelButton
                    Spacer()
                    NewTagSheetAddButton
                }
                .padding([.top, .horizontal], 25)
                //            .padding(.horizontal, 25)
                Spacer()
                NewTagCreator
                Spacer()
                DeleteButton
                
                //            NewTagCreator
                //            CustomSymbolPickerField()
            }
        }
//        .onAppear() {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.editingTag = editingTag
//            }
//        }
    }
    
    var NewTagSheetCancelButton: some View {
        Button {
            dismiss()
//            showAddTagSheet = false
        } label: {
            Text("Cancel")
                .foregroundStyle(.red)
        }
    }
    
    var NewTagSheetAddButton: some View {
        Button {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tags.addTag(editingTag)
            dismiss()
            
//            showAddTagSheet = false
                
        } label: {
            Text(tags.myTags.contains(where: {$0.id == editingTag.id}) ? "Save" : "Add")
                .foregroundStyle(editingTag.name.isEmpty ? .gray : .blue)
        }
        .disabled(editingTag.name.isEmpty)
    }
    
    @State var deleteAlert = false
    
    var DeleteButton: some View {
        HStack {
            Spacer()
            if tags.myTags.contains(where: { $0.id == editingTag.id }) {
                Button(action: {
                    deleteAlert = true
//                    tags.myTags.remove(at: index)
//                    showAddTagSheet = false
                }, label: {
                    Text("Delete Tag")
                })
                .padding(30)
                .frame(width: 250, height: 40)
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                
            }
            Spacer()
        }
        .alert(isPresented: self.$deleteAlert) {
            Alert(title: Text("Delete Tag?"),
                  message: Text("Doing so will remove this tag for all artists"),
                  primaryButton: .destructive(Text("Delete")) {
                tags.removeTag(editingTag)
                dismiss()
//                showAddTagSheet = false
//                if festivalVM.isNewFestival(oldVersion) {
//                    festivalVM.deleteEvent(id: oldVersion.id)
//                } else {
//                    draft.newFestival = oldVersion
//                }
//                navigationPath.removeLast()
            }, secondaryButton: .cancel())
        }
    }
    
//    @State private var selectedSymbol = "flame"
//    @State private var selectedColor = 0
//    @State private var text = ""
    
    
    
    @State private var showSymbolPicker = false
    @State private var showColorPicker = false
    
    let symbols = [
        "flame", "sparkles", "hand.thumbsup", "hand.thumbsdown",
        "magnifyingglass", "bookmark", "exclamationmark", "questionmark",
        "party.popper", "figure.socialdance", "rainbow", "music.microphone",
        "wineglass", "leaf", "snowflake", "paw//print"
    ]
    
    let symbolColumns = Array(
        repeating: GridItem(.fixed(SYMBOLGRIDSIZE), spacing: 0),
        count: 4
    )
    
    let colorColumns = Array(
        repeating: GridItem(.fixed(COLORGRIDSIZE), spacing: 0),
        count: 4
    )
    
    @FocusState var nameFocused: Bool
    
    var NewTagCreator: some View {
        GeometryReader { geo in
            
            ZStack(alignment: .topLeading) {
//                Rectangle()
//                        .fill(Color.clear)
//                        .contentShape(Rectangle())
//                        .ignoresSafeArea()
//                        .onTapGesture {
//                            withAnimation(.spring()) {
//                                showSymbolPicker = false
//                                showColorPicker = false
//                            }
//                            
//                            nameFocused = false
//                        }
                
                // MAIN CONTENT
                VStack(alignment: .leading) {
                    
                    HStack(spacing: 0) {
                        Button {
                            withAnimation(.spring()) {
                                showSymbolPicker.toggle()
                                showColorPicker = false
                            }
                            DispatchQueue.main.async {
                                nameFocused = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: editingTag.symbol)
                                    .id(editingTag.id)
                                    .font(.system(size: 24))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .frame(width: 80)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        TextField("New Tag Name*", text: $editingTag.name)
                            .padding(.horizontal, 12)
                            .focused($nameFocused)
                        
                        Divider()
                        
                        Button {
                            withAnimation(.spring()) {
                                showColorPicker.toggle()
                                showSymbolPicker = false
                            }
                            DispatchQueue.main.async {
                                nameFocused = false
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill()
                                    .foregroundStyle(COLOR_SPECTRUM_ARRAY[editingTag.color])
                                    .frame(width: 20, height: 20)
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .frame(width: 80)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                    }
                    .frame(height: 65)
                    .background(
                        Capsule()
                            .stroke(.black, lineWidth: 2)
                    )
                    
                    Spacer()
                }
                
                // FLOATING PICKER
                if showSymbolPicker {
                    
                    // dismiss layer
                    //                    Color.black.opacity(0.001)
                    //                        .ignoresSafeArea()
                    //                        .onTapGesture {
                    //                            withAnimation(.spring()) {
                    //                                showSymbolPicker = false
                    //                            }
                    //                        }
                    
                    // popup positioned independently
                    LazyVGrid(columns: symbolColumns, spacing: 0) {
                        
                        ForEach(symbols, id: \.self) { symbol in
                            Button {
                                editingTag.symbol = symbol
                                
                                withAnimation(.spring()) {
                                    showSymbolPicker = false
                                }
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(editingTag.symbol == symbol ? .blue : .black)
                                    .frame(width: SYMBOLGRIDSIZE, height: SYMBOLGRIDSIZE)
                            }
                            .buttonStyle(.plain)
                            .background(Color.white)
                            .overlay(
                                Rectangle()
                                    .stroke(.black, lineWidth: 1)
                            )
                        }
                    }
                    .fixedSize() // ← IMPORTANT
                    .background(Color.white)
                    //                        .overlay(
                    //                            Rectangle()
                    //                                .stroke(.black, lineWidth: 2)
                    //                        )
                    .position(
                        x: 175,
                        y: 30
                    )
                    .zIndex(1000)
                    .transition(.opacity.combined(with: .scale))
                } else if showColorPicker {
                    
                    // dismiss layer
                    //                    Color.black.opacity(0.001)
                    //                        .ignoresSafeArea()
                    //                        .onTapGesture {
                    //                            withAnimation(.spring()) {
                    //                                showColorPicker = false
                    //                            }
                    //                        }
                    
                    // popup positioned independently
                    LazyVGrid(columns: colorColumns, spacing: 8) {
                        
                        ForEach(Array(COLOR_SPECTRUM_ARRAY.prefix(12).enumerated()), id: \.offset) { index, color in
                            Button {
                                editingTag.color = index
                                
                                withAnimation(.spring()) {
                                    showColorPicker = false
                                }
                            } label: {
                                if index == editingTag.color {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 30, height: 30)
                                        .overlay(
                                            Circle()
                                                .fill(color)
                                                .frame(width: 25, height: 25)
                                        )
                                } else {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 25, height: 25)
                                }
                                
                                //                                Image(systemName: symbol)
                                //                                    .font(.system(size: 20))
                                //                                    .foregroundStyle(selectedSymbol == symbol ? .blue : .black)
                                //                                    .frame(width: SYMBOLGRIDSIZE, height: SYMBOLGRIDSIZE)
                            }
                            .buttonStyle(.plain)
                            .background(Color.white)
                            //                            .overlay(
                            //                                Rectangle()
                            //                                    .stroke(.black, lineWidth: 1)
                            //                            )
                        }
                    }
                    .padding(.vertical, 8)
                    .fixedSize() // ← IMPORTANT
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(.black, lineWidth: 2)
                        
                    )
                    .position(
                        x: 200,
                        y: 30
                    )
                    .zIndex(1000)
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .frame(height: 120)
        .padding(.horizontal, 20)
        .onChange(of: nameFocused) { newFocus in
            if newFocus {
                showColorPicker = false
                showSymbolPicker = false
            }
        }
//        .onAppear {
//            editingTag = ArtistTag()
//        }
    }
        
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

//struct ArtistImage: View {
//    @EnvironmentObject var data: DataSet
//    
//    let artistID: String
//    let imageURL: String
//    
//    @State private var image: UIImage?
//    
//    var body: some View {
//        Group {
//            if let image {
//                Image(uiImage: image)
//                    .resizable()
//            } else {
//                Image(systemName: "person.crop.circle.fill")
//                    .resizable()
//            }
//        }
//        .onChange(of: artistID) { _ in
//            loadImage()
//        }
//        .onChange(of: imageURL) { _ in
//            loadImage()
//        }
//        .onAppear() {
//            loadImage()
//        }
//    }
//    
//    private func loadImage() {
//        Task {
//            image = await data.loadArtistImage(artistID: artistID, imageURL: imageURL)
//        }
//    }
//}

struct ArtistImage: View {
    let imageURL: String
    let frame: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame, height: frame)
                    .clipShape(Rectangle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: frame, height: frame)
                    .onAppear { loadImage() }
            }
        }
        .onChange(of: imageURL) { _ in
            image = nil
        }
    }

    private func loadImage() {
        // 1. Cached?
        if let cached = ImageCache.shared.getCachedImage(for: imageURL) {
            image = cached
            return
        }

        // 2. Remote fetch
        guard let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
//                ImageCache.shared.cacheImage(data, for: imageURL)
                DispatchQueue.main.async {
                    self.image = img
                }
            }
        }.resume()
    }
}


struct WrappingHStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                // Move to next line
                x = 0
                y += lineHeight
                lineHeight = 0
            }
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0
//        let maxWidth = bounds.width

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                // New line
                x = bounds.minX
                y += lineHeight
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width
            lineHeight = max(lineHeight, size.height)
        }
    }
}



//struct CustomSymbolPickerField: View {
//    @Binding var newTag: ArtistTag
//    
//    @State private var selectedSymbol = "flame"
//    @State private var selectedColor = 0
//    @State private var text = ""
//    
//    @State private var showSymbolPicker = false
//    @State private var showColorPicker = false
//    
//    let symbols = [
//        "flame", "sparkles", "hand.thumbsup", "hand.thumbsdown",
//        "magnifyingglass", "bookmark", "exclamationmark", "questionmark",
//        "party.popper", "figure.socialdance", "rainbow", "music.microphone",
//        "wineglass", "leaf", "snowflake", "paw//print"
//    ]
//    
//    
//    //figure.socialdance, powersleep, moon.fill, rainbow, wineglass
//    
//    //    let symbols = [
//    //        "start", "flame.fill", "mappin.circle.fill",
//    //        "hand.thumbsdown.fill", "questionmark",
//    //        "exclamationmark", "headphones",
//    //        "party.popper", "bolt.fill"
//    //    ]
//    
//    
//    
//    let symbolColumns = Array(
//        repeating: GridItem(.fixed(SYMBOLGRIDSIZE), spacing: 0),
//        count: 4
//    )
//    
//    let colorColumns = Array(
//        repeating: GridItem(.fixed(COLORGRIDSIZE), spacing: 0),
//        count: 4
//    )
//    
//    @FocusState var nameFocused: Bool
//    
//    var body: some View {
//        GeometryReader { geo in
//            
//            ZStack(alignment: .topLeading) {
//                
//                // MAIN CONTENT
//                VStack(alignment: .leading) {
//                    
//                    HStack(spacing: 0) {
//                        
//                        Button {
//                            withAnimation(.spring()) {
//                                showSymbolPicker.toggle()
//                                showColorPicker = false
//                            }
//                        } label: {
//                            HStack(spacing: 8) {
//                                Image(systemName: selectedSymbol)
//                                    .font(.system(size: 24))
//                                
//                                Image(systemName: "chevron.up.chevron.down")
//                                    .font(.system(size: 12))
//                            }
//                            .frame(width: 80)
//                        }
//                        .buttonStyle(.plain)
//                        
//                        Divider()
//                        
//                        TextField("New Tag Name", text: $text)
//                            .padding(.horizontal, 12)
//                            .focused($nameFocused)
//                        
//                        Divider()
//                        
//                        Button {
//                            withAnimation(.spring()) {
//                                showColorPicker.toggle()
//                                showSymbolPicker = false
//                            }
//                        } label: {
//                            HStack(spacing: 8) {
//                                Circle()
//                                    .fill()
//                                    .foregroundStyle(COLOR_SPECTRUM_ARRAY[selectedColor])
//                                    .frame(width: 20, height: 20)
//                                
//                                Image(systemName: "chevron.up.chevron.down")
//                                    .font(.system(size: 12))
//                            }
//                            .frame(width: 80)
//                        }
//                        .buttonStyle(.plain)
//                    }
//                    .frame(height: 65)
//                    .background(
//                        Capsule()
//                            .stroke(.black, lineWidth: 2)
//                    )
//                    
//                    Spacer()
//                }
//                
//                // FLOATING PICKER
//                if showSymbolPicker {
//                    
//                    // dismiss layer
//                    //                    Color.black.opacity(0.001)
//                    //                        .ignoresSafeArea()
//                    //                        .onTapGesture {
//                    //                            withAnimation(.spring()) {
//                    //                                showSymbolPicker = false
//                    //                            }
//                    //                        }
//                    
//                    // popup positioned independently
//                    LazyVGrid(columns: symbolColumns, spacing: 0) {
//                        
//                        ForEach(symbols, id: \.self) { symbol in
//                            Button {
//                                selectedSymbol = symbol
//                                
//                                withAnimation(.spring()) {
//                                    showSymbolPicker = false
//                                }
//                            } label: {
//                                Image(systemName: symbol)
//                                    .font(.system(size: 20))
//                                    .foregroundStyle(selectedSymbol == symbol ? .blue : .black)
//                                    .frame(width: SYMBOLGRIDSIZE, height: SYMBOLGRIDSIZE)
//                            }
//                            .buttonStyle(.plain)
//                            .background(Color.white)
//                            .overlay(
//                                Rectangle()
//                                    .stroke(.black, lineWidth: 1)
//                            )
//                        }
//                    }
//                    .fixedSize() // ← IMPORTANT
//                    .background(Color.white)
//                    //                        .overlay(
//                    //                            Rectangle()
//                    //                                .stroke(.black, lineWidth: 2)
//                    //                        )
//                    .position(
//                        x: 175,
//                        y: 30
//                    )
//                    .zIndex(1000)
//                    .transition(.opacity.combined(with: .scale))
//                } else if showColorPicker {
//                    
//                    // dismiss layer
//                    //                    Color.black.opacity(0.001)
//                    //                        .ignoresSafeArea()
//                    //                        .onTapGesture {
//                    //                            withAnimation(.spring()) {
//                    //                                showColorPicker = false
//                    //                            }
//                    //                        }
//                    
//                    // popup positioned independently
//                    LazyVGrid(columns: colorColumns, spacing: 8) {
//                        
//                        ForEach(Array(COLOR_SPECTRUM_ARRAY.enumerated()), id: \.offset) { index, color in
//                            Button {
//                                selectedColor = index
//                                
//                                withAnimation(.spring()) {
//                                    showColorPicker = false
//                                }
//                            } label: {
//                                if index == selectedColor {
//                                    Circle()
//                                        .stroke(Color.black, lineWidth: 2)
//                                        .frame(width: 30, height: 30)
//                                        .overlay(
//                                            Circle()
//                                                .fill(color)
//                                                .frame(width: 25, height: 25)
//                                        )
//                                } else {
//                                    Circle()
//                                        .fill(color)
//                                        .frame(width: 25, height: 25)
//                                }
//                                
//                                //                                Image(systemName: symbol)
//                                //                                    .font(.system(size: 20))
//                                //                                    .foregroundStyle(selectedSymbol == symbol ? .blue : .black)
//                                //                                    .frame(width: SYMBOLGRIDSIZE, height: SYMBOLGRIDSIZE)
//                            }
//                            .buttonStyle(.plain)
//                            .background(Color.white)
//                            //                            .overlay(
//                            //                                Rectangle()
//                            //                                    .stroke(.black, lineWidth: 1)
//                            //                            )
//                        }
//                    }
//                    .padding(.vertical, 8)
//                    .fixedSize() // ← IMPORTANT
//                    .background(Color.white)
//                    .overlay(
//                        Rectangle()
//                            .stroke(.black, lineWidth: 2)
//                        
//                    )
//                    .position(
//                        x: 200,
//                        y: 30
//                    )
//                    .zIndex(1000)
//                    .transition(.opacity.combined(with: .scale))
//                }
//            }
//        }
//        .frame(height: 120)
//        .padding(.horizontal, 20)
//        .onChange(of: nameFocused) { newFocus in
//            if newFocus {
//                showColorPicker = false
//                showSymbolPicker = false
//            }
//        }
//    }
//}

//struct SymbolGridPicker: View {
//    let symbols = [
//        "star", "heart", "bolt", "flame",
//        "leaf", "moon", "sun.max", "cloud",
//        "paperplane", "bell", "tag", "bookmark",
//        "music.note", "mic", "camera", "gamecontroller",
//        "sparkles", "hare", "tortoise", "globe"
//    ]
//    
//    @Binding var selectedSymbol: String?
//
//    private let columns = Array(
//        repeating: GridItem(.flexible(), spacing: 12),
//        count: 4
//    )
//
//    var body: some View {
//        LazyVGrid(columns: columns, spacing: 12) {
//            ForEach(symbols, id: \.self) { symbol in
//                Image(systemName: symbol)
//                    .font(.system(size: 22))
//                    .frame(maxWidth: .infinity, minHeight: 44)
//                    .padding(8)
//                    .background(
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(selectedSymbol == symbol ? Color.blue.opacity(0.2) : Color.clear)
//                    )
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(selectedSymbol == symbol ? Color.blue : Color.gray.opacity(0.3))
//                    )
//                    .onTapGesture {
//                        selectedSymbol = symbol
//                    }
//            }
//        }
//        .padding()
//    }
//}
let SYMBOLGRIDSIZE: CGFloat = 50
let COLORGRIDSIZE: CGFloat = 40

let COLOR_SPECTRUM_ARRAY: [Color] = [
    .red,
    .orange,
    .yellow,
    .green,
    .mint,
//    .teal,
    .cyan,
    .blue,
    .indigo,
    .purple,
    .pink,
    .brown,
    .gray,
    .black
]


//#Preview {
//    ArtistPage(currentArtist: Data"Lady Gaga")
//}
