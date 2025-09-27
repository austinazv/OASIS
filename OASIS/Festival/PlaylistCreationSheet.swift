//
//  PlaylistCreationSheet.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 3/18/25.
//

import SwiftUI

struct PlaylistCreationSheet: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @Environment(\.dismiss) var dismiss
    
    @State var isLoading: Bool = false
    
    @State private var playlistName = ""
    @State private var isPublic: Bool = true
    
    @State var artistList: Array<DataSet.Artist>
    @State var artistDict = [String : Array<DataSet.Artist>]()
    @State var sortType: DataSet.sortType = .alpha
    
    @State var sectionBools = [String : Bool]()
    @State var artistBools = [String : Bool]()
    @State var showSections = [String : Bool]()
    
    @State var currentFestival = DataSet.Festival.newFestival()
    
    @Binding var playlistCreatedAlert: Bool
    
    @State var arrayLength = 0
//    @State private var progress: Float = 0.0
    
    @State private var progressText = "Adding songs..."
    
    var body: some View {
        ZStack {
            VStack {
                CreateButtons
                Title
                Form {
                    PlaylistNameSection
                    PrivacySection
                    ArtistChecklist
                }
            }
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                VStack {
                    Text(progressText)
                        .padding(.top, 10)
                        .shadow(radius: 0)
//                    if data.progress < 1 {
                        ProgressBarView(progress: $spotify.progress)
                            .frame(width: 200, height: 20)
                            .padding()
//                    } else {
//                        ProgressView()
//                            .progressViewStyle(CircularProgressViewStyle(tint: .black))
//                            .foregroundStyle(Color.black)
//                    }
                }
                .shadow(radius: 5)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
                
            }
            
        }
        .onAppear() {
            if let currFest = festivalVM.currentFestival {
                currentFestival = currFest
                artistDict = festivalVM.getArtistDict(currList: artistList, sort: sortType, secondWeekend: currentFestival.secondWeekend)
            } else {
                dismiss()
            }
            initializeCheckBoxes()
//            changeSectionBool()
        }
        .onChange(of: sortType) { newSort in
            artistDict = festivalVM.getArtistDict(currList: artistList, sort: newSort, secondWeekend: currentFestival.secondWeekend)
            self.changeSectionBool()
//            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
        }
//        .alert(isPresented: self.$playlistCreatedAlert) {
//            Alert(title: Text("Playlist Created!"),
//                  primaryButton: .default(Text("Ok")),
//                  secondaryButton: .default(Text("Go to playlist")) {
//                if let URL = data.getPlaylistURL() {
//                    UIApplication.shared.open(URL)
//                }
//            })
//        }
    }
    
    
    //TODO: Incorperate
//    init(artistDict: [String : Array<DataSet.artist>], sortType: DataSet.sortType, playlistCreatedAlert: Binding<Bool>) {
//        self.artistDict = artistDict
//        self.sortType = sortType
//        self._playlistCreatedAlert = playlistCreatedAlert
//        
//        _showSections = State(initialValue: Dictionary(uniqueKeysWithValues: artistDict.keys.map { ($0, true) }))
//        _sectionBools = State(initialValue: Dictionary(uniqueKeysWithValues: artistDict.keys.map { ($0, false) }))
//        
//        _artistBools = State(initialValue: Dictionary(
//                uniqueKeysWithValues: artistDict.flatMap { (_, artists) in
//                    artists.map { ($0.id, false) }
//                }
//            ))
//    }
    
    func initializeCheckBoxes() {
        for (key, list) in artistDict {
            sectionBools[key] = false
            showSections[key]  = true
            for artist in list {
                artistBools[artist.id] = false
            }
        }
    }
    
    var Title: some View {
        HStack {
            Text("Create")
            Image("Spotify Full Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 30, alignment: .center)
            Text("Playlist")
        }
        .bold()
        .font(.headline)
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
    
    var CreateButtons: some View {
        HStack {
            Button(action: {
                dismiss()
            }, label: {
                Text("Cancel")
                .foregroundStyle(.red)
            })
            Spacer()
            Button(action: {
                makePlaylist()
            }, label: {
                Text("Create")
                    .foregroundStyle(anyArtistChecked() ? Color("Spotify Color Green") : .gray)
            })
            .disabled(!anyArtistChecked())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    var PlaylistNameSection: some View {
        Section(header: Text("Playlist Name")) {
            HStack {
                TextField("My \(currentFestival.name) Playlist", text: $playlistName)
                    .autocapitalization(.words)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .frame(height: 30)
            
            .padding(.horizontal, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    var PrivacySection: some View {
        Section(header: Text("Privacy")) {
            Picker("Weekend", selection: $isPublic) {
                Text("Public").tag(true)
                Text("Private").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    var ArtistChecklist: some View {
        Section(header: HStack {
            Text("Artist List")
            Spacer()
            SortMenu(sortType: $sortType, currList: artistList, secondWeekend: currentFestival.secondWeekend)
        }) {
            ForEach(Array(data.getDictKeysSorted(currDict: artistDict, sort: sortType).enumerated()), id: \.element) { i, section in
//            ForEach(Array(data.getSortLables(sort: sortType).enumerated()), id: \.element) { i, section in
                if let artistList = artistDict[section] {
                    HStack {
                        Button(action: {
                            self.toggleSection(section: section)
                        }, label: {
                            HStack {
                                Image(systemName: sectionBools[section] == true ? "checkmark.square.fill" : "square")
                                    .foregroundColor(Color("OASIS Dark Orange"))
                                    .imageScale(.large)
                                Text(section)
                                    .foregroundStyle(Color("BW Color Switch"))
                                Spacer()
                            }
                        })
                        Spacer()
                        Image(systemName: showSections[section]! ? "chevron.up" : "chevron.down")
                            .onTapGesture(perform: {
                                showSections[section]!.toggle()
                            })
                    }
                    if showSections[section]! {
                        ForEach(Array(artistList.enumerated()), id: \.element) { j, artist in
                            HStack {
                                Button(action: {
                                    print(artist)
                                    print(artistBools)
                                    artistBools[artist.id]!.toggle()
                                    print(artistBools)
                                    
                                    //                                artistBools[artist.id] = !artistBools[artist.id]
                                }, label: {
                                    Image(systemName: artistBools[artist.id] == true ? "checkmark.square.fill" : "square")
                                        .foregroundColor(Color("OASIS Light Orange"))
                                        .imageScale(.large)
                                })
                                Text(artist.name)
                            }
                        }
                        .padding(.leading, 25)
                    }
                }
            }
        }
    }
    
//    var SortMenu: some View {
//        Group {
//            Menu(content: {
//                //View by Alphabetically
//                Button (action: {
//                    sortType = .alpha
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType, secondWeekend: true)
////                    artistDict = data.updateArtistDict(currDict: artistDict)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: false, sort: sortType)
//                    self.changeSectionBool()
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
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType, secondWeekend: true)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: false, sort: sortType)
//                    self.changeSectionBool()
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
//                    artistDict = data.getArtistDictFromListNEW(currList: artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: false, sort: sortType)
//                    self.changeSectionBool()
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
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: false, sort: sortType)
//                    self.changeSectionBool()
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
////                    artistDict = data.getArtistDict(currDict: artistDict, favorites: false, sort: sortType)
//                    self.changeSectionBool()
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
//                Image(systemName: "list.bullet")
//                    .foregroundStyle(Color.blue)
//            })
//            
//        }
//    }
    
    func toggleSection(section: String) {
        let boolValue = !sectionBools[section]!
        sectionBools[section] = boolValue
        
        for artist in artistDict[section]! {
            artistBools[artist.id]! = boolValue
        }
    }
    
    func anyArtistChecked() -> Bool {
        for (_, bool) in artistBools {
            if bool {
                return true
            }
        }
        return false
    }
    
    func makePlaylist() {
        self.isLoading = true
        var playlistList = Array<String>()
        for (artistID, bool) in artistBools {
            if bool {
                playlistList.append(artistID)
            }
        }
        var name = self.playlistName
        if name == "" {
            name = "My Coachella 2025 Playlist"
        }
        print(playlistList.count)
//        self.startProgress(arrayLen: playlistList.count)
        spotify.makeNewSpotifyPlaylist(artistList: playlistList, playlistName: name, isPublic: self.isPublic) { playlistID in
            self.arrayLength = playlistList.count
            DispatchQueue.main.async {
                if let playlistID = playlistID {
                    self.isLoading = false
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.playlistCreatedAlert = true
                    }
                    print("🎉 Playlist successfully created: https://open.spotify.com/playlist/\(playlistID)")
                } else {
                    self.isLoading = false
//                    self.errorAlert = true
                    print("❌ Playlist creation failed")
                }
            }
        }
    }
    
    
    func startProgress(arrayLen: Int) {
        // Calculate the total time based on the array length
        var totalTime = Double(arrayLen) * 2
        if arrayLen < 50 {
            totalTime = Double(arrayLen) / 5
        }
        data.progress = 0.0
        let step = 1.0 / Float(totalTime)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            DispatchQueue.main.async {
                if data.progress + step < 1.0 {
                    data.progress += step
                } else {
                    progressText = "Finalizing..."
                    data.progress = 1.0
                    timer.invalidate()
                }
            }
        }
        
        // Run the timer in the current run loop
        RunLoop.current.add(timer, forMode: .common)
    }
    
    func changeSectionBool() {
        sectionBools.removeAll()
        showSections.removeAll()
        let lables = artistDict.keys
//        let lables = data.getSortLables(sort: sortType)
        for lable in lables {
            sectionBools[lable] = isSubsectionChecked(section: lable)
            showSections[lable] = true
        }
    }
    
    func isSubsectionChecked(section: String) -> Bool {
        if let subsectionList = artistDict[section] {
            for artist in subsectionList {
                if artistBools[artist.id]! {
                    return true
                }
            }
        }
        return false
    }
    
    
}

struct ProgressBarView: View {
    @Binding var progress: Float
    
    var body: some View {
        ProgressView(value: progress, total: 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
//            .padding()
//            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white).shadow(radius: 5))
            .onTapGesture {
                print(progress)
            }
    }
}

//#Preview {
//    PlaylistCreationSheet()
//}
