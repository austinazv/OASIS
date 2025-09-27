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
//    @EnvironmentObject var spotify: SpotifyViewModel
    
    @State var currentArtist: DataSet.Artist
    
//    @State var shuffle: Bool = false
    @State var shuffleLable: String? = nil
    @State var shuffleList: Array<DataSet.Artist>
    
    @Binding var navigationPath: NavigationPath
    
    @State var currentFestival = DataSet.Festival.newFestival()
    
//    @State var includeFavorites: Bool
    
    @State var artistInfoPopup: Bool = false
    
    var body: some View {
        VStack {
            ArtistTitleBar
            List {
                ArtistPageSection
                //                ArtistPlaylistSection
                LatestProjectSection
                //                ArtistSpotifySection
                //                UpcomingAlbumSection
                //                AllAlbumsSection
                RelatedArtistsSection
                ArtistInfoSection
            }
            //            .background(RoundedRectangle(cornerRadius: 5)
            //                .foregroundStyle(Color(currentArtist.photo.averageColor!)))
            
            
        }
        .onAppear() {
            if let festival = festivalVM.currentFestival {
                currentFestival = festival
                if latestProject == nil {
                    getLatestProject()
                }
            } else {
                navigationPath.removeLast()
            }
        }
        .onChange(of: currentArtist) { _ in
            getLatestProject()
        }
        .navigationBarItems(
            trailing: HStack {
                Button(action: {
                    if let randomArtist = festivalVM.shuffleArtist(currentList: shuffleList, currentArtist: currentArtist, secondWeekend: currentFestival.secondWeekend) {
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
                VStack(alignment: .leading) {
                    HStack {
                        ArtistImage(imageURL: currentArtist.imageURL, frame: 120)
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
//                                ShareLink(item: currentArtist.artistPage) {
                                    Label("", systemImage: "square.and.arrow.up.circle")
//                                }
                                .imageScale(.large)
                                .foregroundStyle(.gray)
                                .padding([.leading, .trailing], 5)
                                Button(action: {
                                    festivalVM.dislikeButtonPressed(currentArtist.id)
//                                    currentArtist.favorability = data.setFavorability(liking: -1, artist: currentArtist)
                                }, label: {
                                    Image(systemName: "x.circle")
                                        .imageScale(.large)
                                        .foregroundStyle(festivalVM.dislikeList.contains(currentArtist.id) ? Color.red : Color.gray)
//                                        .foregroundStyle(currentArtist.favorability == -1 ? Color.red : Color.gray)
                                        .padding([.leading, .trailing], 5)
                                })
                                Button(action: {
                                    festivalVM.favoriteButtonPressed(currentArtist.id)
                                }, label: {
                                    Image(systemName: "heart.circle")
                                        .imageScale(.large)
                                        .foregroundStyle(festivalVM.favoriteList.contains(currentArtist.id) ? Color.red : Color.gray)
                                        .padding([.leading, .trailing], 5)
                                })
                            }
                            .font(Font.system(size: 24))
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
//        print(amt)
//        return amt
//    }
    
    
    
    var ArtistTagSection: some View {
        Group {
            Divider()
            HStack {
                Text("Tags:")
                Image(systemName: "plus.circle")
                Spacer()
            }
            .padding(.top, 3)
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
                    Link(destination: url, label: {
                        HStack {
//                            Text(currentArtist.name)
                            Image("Spotify Full Logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 25, alignment: .center)
                            Text("Page")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    })
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
            if let currFest = festivalVM.currentFestival {
                let relatedArists = data.getRelatedArtists(currentArtist: currentArtist, currentList: currFest.artistList)
                if relatedArists.count > 0 {
//                    Section {
                    Section(header:
                                HStack {
                        Image(systemName: "person.2")
                        Text("Similar Artists")
                    }) {
                        ScrollView(.horizontal) {
                            LazyHStack {
                                HStack {
                                    ForEach(relatedArists) { artist in
                                        NavigationLink(destination: ArtistPage(currentArtist: artist, shuffleList: shuffleList, navigationPath: $navigationPath)) {
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
            }
        }
       
        
    }
    
    var ArtistInfoSection: some View {
        Group {
            Section(header:
                        HStack {
                Image(systemName: "info.circle")
                Text("Artist Info")
            }) {
                ArtistDay
                ArtistStage
                ArtistTier
                ArtistGenres
            }
        }
    }
    
    var ArtistDay: some View {
        Group {
            if let currFest = festivalVM.currentFestival {
                HStack {
                    Text("Day: ")
                    if currentArtist.day == data.NA_TITLE_BLOCK {
                        Text("Unannounced")
                    } else {
                        let dayList = festivalVM.getDayList(currArtist: currentArtist, currList: currFest.artistList, secondWeekend: currFest.secondWeekend)
//                        NavigationLink(value: DataSet.ArtistListStruct(titleText: currentArtist.day, festival: currFest, list: dayList)) {
                            Text(currentArtist.day)
                                .foregroundStyle(.blue)
                                .underline()
                                .onTapGesture() {
                                    navigationPath.append(DataSet.ArtistListStruct(titleText: currentArtist.day, festival: currFest, list: dayList))
                                }
//                        }
                    }
//                    Spacer()
//                    Divider()
                    if currFest.secondWeekend && currentArtist.weekend != "Both" {
//                        Text("Weekend: ")
//                            .padding(.leading, 2)
                        let weekendList = festivalVM.getWeekendList(weekend: currentArtist.weekend, currList: currFest.artistList)
                            Text("(\(currentArtist.weekend))")
                                .foregroundStyle(.blue)
                                .underline()
                                .onTapGesture() {
                                    navigationPath.append(DataSet.ArtistListStruct(titleText: currentArtist.weekend, festival: currFest, list: weekendList))
                                }
//                        }
                    }
                    Spacer()
                }
            }
        }
    }
    
    var ArtistStage: some View {
        Group {
            if let currFest = festivalVM.currentFestival {
                if festivalVM.listHasStages(currList: currFest.artistList, secondWeekend: currFest.secondWeekend) {
                    HStack {
                        Text("Stage: ")
                        if currentArtist.stage == data.NA_TITLE_BLOCK {
                            Text("Unannounced")
                        } else {
                            let stageList = festivalVM.getStageList(stage: currentArtist.stage, currList: currFest.artistList)
                            Text(currentArtist.stage)
                                .foregroundStyle(.blue)
                                .underline()
                                .onTapGesture() {
                                    navigationPath.append(DataSet.ArtistListStruct(titleText: currentArtist.stage, festival: currFest, list: stageList))
                                }
                            //                        }
                        }
                    }
                }
            }
        }
    }
    
    var ArtistTier: some View {
        Group {
            if let currFest = festivalVM.currentFestival {
                if currentArtist.tier != data.NA_TITLE_BLOCK {
                    HStack {
                        Text("Tier: ")
                        let tierList = festivalVM.getTierList(tier: currentArtist.tier, currList: currFest.artistList)
                        Text(currentArtist.tier)
                            .foregroundStyle(.blue)
                            .underline()
                            .onTapGesture() {
                                navigationPath.append(DataSet.ArtistListStruct(titleText: currentArtist.tier, festival: currFest, list: tierList))
                            }
                    }
                }
            }
        }
    }
    
    var ArtistGenres: some View {
        Group {
            if let currFest = festivalVM.currentFestival {
                if !currentArtist.genres.isEmpty {
                    HStack {
                        WrappingHStack {
                            Text("Genres: ")
                            ForEach(currentArtist.genres.sorted(), id: \.self) { genre in
                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                                let genreText = genre + (genre == currentArtist.genres.max() ? "" : ", ")
//                                HStack {
                                    Text(genreText)
//                                }
                                    .foregroundStyle(.blue)
                                    .underline()
                                    .onTapGesture() {
                                        navigationPath.append(DataSet.ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                                    }
                                if genre != currentArtist.genres.max() {
                                    Text(" ")
                                }
                                //                                if genre != genres.max() {
                                ////
                                //                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    
//    var BackButton : some View {
//        Button(action: {
//            self.presentationMode.wrappedValue.dismiss()
//        }) {
//            HStack {
//                Image(systemName: "chevron.left")
//                Text("Back")
//            }
//        }
//    }
        
        
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
    
    var body: some View {
        if let url = URL(string: imageURL) {
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
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                case .failure(_):
                    // If it fails
                    Image(systemName: "person.crop.circle.fill.badge.exclam")
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
        let maxWidth = bounds.width

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


//#Preview {
//    ArtistPage(currentArtist: Data"Lady Gaga")
//}
