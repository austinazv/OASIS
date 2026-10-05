//
//  AddMultipleArtistPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 8/30/26.
//

import SwiftUI

struct AddMultipleArtistsPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @State var artistList: [Artist]
    
//    @State var newArtist: Artist
    @State var artistImage: UIImage?
    
    @Binding var newFestival: Festival
    
    @Binding var showArtistSearchPage: Bool
    
    @State var isLoading = true
    
    @State var isGenreLoading = true
    
    var lastEditedArtist: Artist?
    
    @State private var groupWeekend: String = ""
    @State private var originalGroupWeekend: String = ""
    
    @State private var groupDay: String = ""
    @State private var originalGroupDay: String = ""
    
    @State private var groupTier: String = ""
    @State private var originalGroupTier: String = ""
    
    @State private var groupStage: String = ""
    @State private var originalGroupStage: String = ""
    
    @State private var groupGenres: [String]?
    @State private var originalGroupGenres: [String] = []
    
    @State private var showUpdateAlert: Bool = false
    
    @Binding var selectMultiple: Bool
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                VStack(spacing: 0) {
                    NavigationButtons
                    
//                    TitleBar
                    Form {
                        ArtistImages
                        ArtistWeekend
                        ArtistDay
                        ArtistTier
                        ArtistStage
                        ArtistGenres
                        DeleteButton
                    }
                }
            }
        }
        .onAppear() {
            for artist in artistList {
                if newFestival.secondWeekend {
                    if groupWeekend == "" {
                        groupWeekend = artist.weekend
                    } else if artist.weekend != groupWeekend {
                        groupWeekend = "Various"
                    }
                }
                
                if groupDay == "" {
                    groupDay = artist.day
                } else if artist.day != groupDay {
                    groupDay = "Various"
                }
                
                if groupTier == "" {
                    groupTier = artist.tier
                } else if artist.tier != groupTier {
                    groupTier = "Various"
                }
                
                if groupStage == "" {
                    groupStage = artist.stage
                } else if artist.stage != groupStage {
                    groupStage = "Various"
                }
                
                if groupStage == "" {
                    groupStage = artist.stage
                } else if artist.stage != groupStage {
                    groupStage = "Various"
                }
                
                if groupGenres == nil {
                    groupGenres = artist.genres
                } else {
                    groupGenres = groupGenres?.filter { artist.genres.contains($0) }
                }
            }
            
            originalGroupWeekend = groupWeekend
            originalGroupDay = groupDay
            originalGroupTier = groupTier
            originalGroupStage = groupStage
            groupGenres = groupGenres ?? []
            originalGroupGenres = groupGenres!
            
//            if artistImage == nil {
//                Task {
//                    artistImage = await data.loadArtistImage(artistID: newArtist.id, imageURL: newArtist.imageURL)
//                }
//            }
//            if !newFestival.artistList.contains(where: {$0.id == newArtist.id}) {
//                if let lastArtist = lastEditedArtist {
//                    newArtist.weekend = lastArtist.weekend
//                    newArtist.day = lastArtist.day
//                    newArtist.stage = lastArtist.stage
//                    newArtist.tier = lastArtist.tier
//                }
//                isGenreLoading = true
//                var genreList = newArtist.genres.map { $0.capitalized }
//                fetchGenresFromLastFM(artistName: newArtist.name) { genres in
//                    for genre in genres.map({ $0.capitalized }) {
//                        if !genreList.contains(genre) {
//                            genreList.append(genre)
//                        }
//                    }
//                    genreList.removeAll(where: {
//                        $0.contains("Seen Live") ||
//                        $0.contains("Vocalists") ||
//                        $0.contains("Better") ||
//                        $0.contains("My Top") ||
//                        $0.contains("Lidarr") ||
//                        $0.contains("Batch") ||
//                        $0.contains("Spotify") ||
//                        $0.contains(newArtist.name)
//                    })
//                    if genreList.contains("Hip Hop") {
//                        genreList.removeAll(where: { $0 == "Hip Hop" })
//                        if !genreList.contains("Hip-Hop") {
//                            genreList.append("Hip-Hop")
//                        }
//                    }
//                    if genreList.contains("Edm") {
//                        genreList.removeAll(where: { $0 == "Edm" })
//                        genreList.append("EDM")
//                    }
//                    if genreList.contains("Rnb") {
//                        genreList.removeAll(where: { $0 == "Rnb" })
//                        genreList.append("R&B")
//                    }
//                    if genreList.contains("Usa") {
//                        genreList.removeAll(where: { $0 == "Usa" })
//                        genreList.append("USA")
//                    }
//                    newArtist.genres = genreList
//                    isGenreLoading = false
//                    
//                    //                newArtist.genres.append(contentsOf: genres)
//                    //                newArtist.genres = newArtist.genres.map { $0.capitalized }
//                    //                for genre in genres {
//                    //                    newArtist.genres.append(genre.capitalized)
//                    //                }
//                }
//                isLoading = false
//            } else {
                isLoading = false
                isGenreLoading = false
//            }
            
        }
        
    }
    
    
    
    var NavigationButtons: some View {
        Group {
            HStack {
                Button(action: {
                    showArtistSearchPage = false
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                })
                Spacer()
                Group {
                    if haveChangesBeenMade() {
                        Button(action: {
                            showUpdateAlert = true
                        }, label: {
                            Group {
                                Text("Update")
                            }
                            .foregroundStyle(.oasisBlue)
                        })
                    } else {
                        Button(action: {
                            showArtistSearchPage = false
                        }, label: {
                            Group {
                                Text("Done")
                            }
                            .foregroundStyle(.oasisBlue)
                        })
                    }
                    
                    
                    
//                    if let oldArtist = newFestival.artistList.first(where: { $0.id == newArtist.id }) {
//                        if newArtist == oldArtist {
//                            Button(action: {
//                                showArtistSearchPage = false
//                            }, label: {
//                                Group {
//                                    Text("Done")
//                                }
//                                .foregroundStyle(.blue)
//                            })
//                        } else {
//                            Button(action: {
//                                showUpdateAlert = true
//                            }, label: {
//                                Group {
//                                    Text("Update \(artistList.count) Artists")
//                                }
//                                .foregroundStyle(.oasisDarkOrange)
//                            })
//                        }
////                        .disabled(newArtist == oldArtist)
//                    } else {
//                        Button(action: {
//                            addArtist()
//                            showArtistSearchPage = false
//                        }, label: {
//                            Group {
//                                Text("Add Artist")
//                            }
//                            .foregroundStyle(isGenreLoading ? .gray : .blue)
//                        })
//                        .disabled(isGenreLoading)
//                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            Divider()
        }
        .alert(isPresented: $showUpdateAlert) {
            return Alert(title: Text("Update \(artistList.count) Artists?"),
//                         message: Text("Are you sure you want to leave without saving?"),
                         primaryButton: .default(Text("Update")) {
                updateMultipleArtists()
            }, secondaryButton: .cancel()
            )
        }
    }
    
    func haveChangesBeenMade() -> Bool {
        if groupWeekend != originalGroupWeekend { return true }
        if groupDay != originalGroupDay { return true }
        if groupTier != originalGroupTier{ return true }
        if groupStage != originalGroupStage { return true }
        if groupGenres != originalGroupGenres { return true }
        return false
    }
    
    func updateMultipleArtists() {
        if groupStage == "+ Add Stage" {
            if stageName.isEmpty {
                groupStage = originalGroupStage
            } else {
                addStage()
            }
        }
        
        let genresToAdd = groupGenres!.filter { !originalGroupGenres.contains($0) }
        let genresToRemove = originalGroupGenres.filter { !groupGenres!.contains($0) }
        
        for artist in artistList {
            var updatedArtist = artist
            if groupWeekend != originalGroupWeekend {
                updatedArtist.weekend = groupWeekend
            }
            if groupDay != originalGroupDay {
                updatedArtist.day = groupDay
            }
            if groupTier != originalGroupTier {
                updatedArtist.tier = groupTier
            }
            if groupStage != originalGroupStage {
                updatedArtist.stage = groupStage
            }
            if groupGenres! != originalGroupGenres {
                for genre in genresToAdd where !artist.genres.contains(genre) {
                    updatedArtist.genres.append(genre)
                }
                updatedArtist.genres.removeAll { genresToRemove.contains($0) }
            }
            updatedArtist.modifyDate = Date()
            
            if let index = newFestival.artistList.firstIndex(where: { $0.id == updatedArtist.id }) {
                newFestival.artistList[index] = updatedArtist
            } else {
                newFestival.artistList.append(updatedArtist)
            }
        }
        
        selectMultiple = false
        showArtistSearchPage = false
    }
    
//    func addArtist() {
//        if newArtist.stage == "+ Add Stage" {
//            if stageName.isEmpty {
//                newArtist.stage = data.NA_TITLE_BLOCK
//            } else {
//                addStage()
//            }
//        }
//        
//        newArtist.modifyDate = Date()
//        
//        if let index = newFestival.artistList.firstIndex(where: { $0.name == newArtist.name }) {
////            DispatchQueue.main.asyncAfter(deadline: .now() + (wait ? 0.1 : 0.0)) {
//                newFestival.artistList[index] = newArtist
////                newFestival.artistList.append(newArtist)
////            }
////            newFestival.artistList.remove(at: index)
//        } else  {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                newFestival.artistList.append(newArtist)
//            }
//            if let image = artistImage {
//                do {
//                    let savedURL = try data.saveImageToDisk(image: image, artistID: newArtist.id)
//                    print("Saved image at:", savedURL.path)
//                } catch {
////                    print("Failed to save image:", error)
//                }
//            }
//        }
//        
//    }
    
    var ArtistImages: some View {
        Section(header: Text("Editing Mutliple Artists:")) {
            ScrollView(.horizontal) {
                LazyHStack {
//                    HStack {
                    ForEach(artistList.sorted(by: { $0.name < $1.name })) { artist in
                            //                        NavigationLink(destination: ArtistPage(currentArtist: artist, shuffleLable: "All Artists", shuffleList: currentFestival.artistList, navigationPath: $navigationPath, currentFestival: currentFestival)) {
                            Group {
                                VStack {
                                    ArtistImage(imageURL: artist.imageURL, frame: 60)
                                        .padding(5)
                                    
                                    Text(artist.name)
                                        .font(.system(size: 15))
                                        .frame(maxWidth: 100)
                                        .lineLimit(1)
                                }
                                .padding(5)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color("BW Color Switch Reverse"))
                                        .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.oasisDarkPurpleUninverted, lineWidth: 2)
                                )
                                .frame(width: 85)
                            }
                            .foregroundStyle(Color("BW Color Switch"))
                            .padding(.horizontal, 2)
                        }
//                    }
                }
                .padding(.vertical, 3)
            }
            .padding(.horizontal, 10)
//            .padding(.vertical, 5)
        }
    }
    
//    var TitleBar: some View {
//        VStack {
//            HStack(spacing: 20) {
//                Group {
//                    if let url = spotifyArtistURL(from: newArtist.id) {
//                        Link(destination: url, label: {
//                            ArtistImage(imageURL: newArtist.imageURL, frame: 90)
//                        })
//                    }
//                }
//                Text(newArtist.name)
//                    .font(.headline)
//            }
////            .padding(.vertical, 2)
//            .contentShape(Rectangle())
//        }
//    }
    
    func spotifyArtistURL(from id: String) -> URL? {
        return URL(string: "https://open.spotify.com/artist/\(id)")
    }
    
    var ArtistWeekend: some View {
        Group {
            if newFestival.secondWeekend {
                Section {
                    Picker("Weekend", selection: $groupWeekend) {
                        if originalGroupWeekend == "Various" { Text("Various").italic().tag("Various") }
                        Text("Both").tag("Both")
                        Text("Weekend 1").tag("Weekend 1")
                        Text("Weekend 2").tag("Weekend 2")
                    }
                    .pickerStyle(.menu)
                    .tint(groupWeekend == originalGroupWeekend ? .oasisBlue : .oasisDarkOrange)
//                    HStack {
//                        Text("Weekend")
//                        Spacer()
//                        Menu {
//                            Picker("Weekend", selection: $newArtist.weekend) {
//                                Text("Both").tag("Both")
//                                Text("Weekend 1").tag("Weekend 1")
//                                Text("Weekend 2").tag("Weekend 2")
//                            }
//                            .labelsHidden()
//                            .pickerStyle(InlinePickerStyle())
//                        } label:  {
//                            HStack {
//                                Text(newArtist.weekend)
//                                Image(systemName: "chevron.up.chevron.down")
//                            }
//                            .foregroundStyle(Color("OASIS Dark Orange"))
//                        }
//                    }
                }
            }
        }
    }
    
    var ArtistDay: some View {
        Group {
            if !Calendar.current.isDate(newFestival.startDate, inSameDayAs: newFestival.endDate) {
                Section {
                    Picker("Day", selection: $groupDay) {
                        if originalGroupDay == "Various" { Text("Various").italic().tag("Various") }
                        
                        Text("-- N/A --").tag("-- N/A --")

                        ForEach(formattedDateStrings, id: \.self) { dateString in
                            Text(dateString)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(groupDay == originalGroupDay ? .oasisBlue : .oasisDarkOrange)
//                    HStack {
//                        Text("Day")
//                        Spacer()
//                        Menu {
//                            Picker("Day", selection: $newArtist.day) {
//                                Text("-- N/A --").tag("-- N/A --")
//                                ForEach(formattedDateStrings, id: \.self) { dateString in
//                                    Text(dateString)
//                                }
//                            }
//                            .labelsHidden()
//                            .pickerStyle(InlinePickerStyle())
//                        } label:  {
//                            HStack {
//                                Text(newArtist.day)
//                                Image(systemName: "chevron.up.chevron.down")
//                            }
//                            .frame(minWidth: 120, alignment: .trailing)
//                            .foregroundStyle(Color("OASIS Dark Orange"))
//                        }
//                    }
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE (MMMM d)"
            return formatter
        }()

    private var formattedDateStrings: [String] {
        var dates: [String] = []
        var currentDate = Calendar.current.startOfDay(for: newFestival.startDate)
        let finalDate = Calendar.current.startOfDay(for: newFestival.endDate)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE" // full day name, e.g. "Friday"

        while currentDate <= finalDate {
            dates.append(dayFormatter.string(from: currentDate))
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }
    
    
    
    @State var stageName = ""
    @FocusState var stageNameFocused: Bool
    
    var ArtistStage: some View {
        Group {
            Section {
                VStack {
//                    HStack {

                        Picker("Stage", selection: $groupStage) {
                            if originalGroupStage == "Various" { Text("Various").italic().tag("Various") }
                            
                            Text("-- N/A --").tag("-- N/A --")

                            ForEach(newFestival.stageList.sorted(), id: \.self) { stage in
                                Text(stage).tag(stage)
                            }

                            Text("+ Add Stage").tag("+ Add Stage")
                        }
                        .pickerStyle(.menu)
                        .tint(groupStage == originalGroupStage ? .oasisBlue : .oasisDarkOrange)
//                    }
//                    HStack {
//                        Text("Stage")
//                        Spacer()
//                        Menu {
//                            Picker("Stage", selection: $newArtist.stage) {
//                                Text("-- N/A --").tag("-- N/A --")
//                                ForEach(newFestival.stageList.sorted(), id: \.self) { stage in
//                                    Text(stage).tag(stage)
//                                }
//                                Text("+ Add Stage").tag("+ Add Stage")
//                            }
//                            .labelsHidden()
//                            .pickerStyle(InlinePickerStyle())
//                        } label:  {
//                            HStack {
//                                Text(newArtist.stage)
//                                Image(systemName: "chevron.up.chevron.down")
//                            }
//                            .fixedSize()
//                            .foregroundStyle(Color("OASIS Dark Orange"))
//                        }
//
//                    }
//                    .padding(.horizontal, 5)
                    if groupStage == "+ Add Stage" {
                        Divider()
                        HStack {
                            ZStack {
                                TextField("Add Stage", text: $stageName)
                                    .padding(5)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(5)
                                    .autocapitalization(.words)
                                    .frame(height: FRAME_HEIGHT)
                                    .submitLabel(.return)
                                    .focused($stageNameFocused)
                                    .onSubmit {
                                        addStage()
                                    }
                                if !stageName.isEmpty {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "xmark.circle")
                                            .padding(.horizontal, 10)
                                            .foregroundStyle(.gray)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                stageName = ""
                                            }
                                    }
                                }
                            }
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundStyle(stageName == "" ? Color.gray : Color.blue /*Color("OASIS Dark Orange")*/)
                                .frame(width: FRAME_HEIGHT)
                                .onTapGesture {
                                    addStage()
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        
                    }
                }
            }
//            }
        }
    }
    
    let FRAME_HEIGHT = 40.0
    
    
    private func addStage() {
        stageNameFocused = false
        guard !stageName.isEmpty else { return }
        if !newFestival.stageList.contains(stageName) {
            newFestival.stageList.append(stageName)
        }
        groupStage = stageName
//        newArtist.stage = stageName
        stageName = ""
    }
    
    var ArtistTier: some View {
        Group {
            Section {
                Picker("Tier", selection: $groupTier) {
                    if originalGroupTier == "Various" { Text("Various").italic().tag("Various") }
                    
                    Text("-- N/A --").tag("-- N/A --")

                    ForEach(data.tierLables, id: \.self) { tier in
                        Text(tier).tag(tier)
                    }
                }
                .pickerStyle(.menu)
                .tint(groupTier == originalGroupTier ? .oasisBlue : .oasisDarkOrange)
//                HStack {
//                    Text("Tier")
//                    Spacer()
//                    Menu {
//                        Picker("Tier", selection: $newArtist.tier) {
//                            Text("-- N/A --").tag("-- N/A --")
//                            ForEach(data.tierLables, id: \.self) { tier in
//                                Text(tier).tag(tier)
//                            }
//                        }
//                        .labelsHidden()
//                        .pickerStyle(InlinePickerStyle())
//                    } label:  {
//                        HStack {
//                            Text(newArtist.tier)
//                            Image(systemName: "chevron.up.chevron.down")
//                        }
//                        .foregroundStyle(Color("OASIS Dark Orange"))
//                    }
//
//                }
            }
//            }
        }
    }
    
    @State var genreName = ""
    @FocusState var genreNameFocused: Bool
    
    var ArtistGenres: some View {
        Group {
            Section (header: Text("Shared Genres")) {
//                if isGenreLoading {
//                    ProgressView()
//                } else {
                    VStack {
                        if let groupGenresList = groupGenres {
                            if !groupGenresList.isEmpty {
                                FlowLayout(spacing: 8) {
                                    ForEach(groupGenresList.sorted(), id: \.self) { genre in
                                        HStack {
                                            Text(genre)
                                                .foregroundStyle(originalGroupGenres.contains(genre) ? .oasisBlue : .oasisDarkOrange)
                                            Image(systemName: "x.circle")
                                        }
                                        .padding(6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                            //                                    .stroke(Color("OASIS Dark Orange"), lineWidth: 1)
                                                .stroke(.oasisDarkPurple, lineWidth: 1)
                                                .foregroundStyle(.white)
                                        )
                                        .onTapGesture {
                                            if let originalIndex = groupGenres!.firstIndex(of: genre) {
                                                groupGenres!.remove(at: originalIndex)
                                            }
                                        }
                                    }
                                }
                                Divider()
                            }
                        }
                        HStack {
                            ZStack {
                                TextField("Add Genre for \(artistList.count) Artists", text: $genreName)
                                    .padding(5)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(5)
                                    .autocapitalization(.words)
                                    .frame(height: FRAME_HEIGHT)
                                    .submitLabel(.return)
                                    .focused($genreNameFocused)
                                    .onSubmit {
                                        addGenre()
                                    }
                                if !genreName.isEmpty {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "xmark.circle")
                                            .padding(.horizontal, 10)
                                            .foregroundStyle(.gray)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                genreName = ""
                                            }
                                    }
                                }
                            }
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .foregroundStyle(stageName == "" ? Color.gray : Color.blue /*Color("OASIS Dark Orange")*/)
                                .frame(width: FRAME_HEIGHT)
                                .onTapGesture {
                                    addGenre()
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                }
//            }
//            }
        }
    }
    
    //TODO: EDIT
    private func addGenre() {
        genreNameFocused = !genreName.isEmpty
        guard !genreName.isEmpty else { return }
        if !groupGenres!.contains(genreName) {
            groupGenres!.append(genreName)
        }
//        if !newArtist.genres.contains(genreName) {
//            newArtist.genres.append(genreName)
//        }
        genreName = ""
    }
    
    func fetchGenresFromLastFM(artistName: String, completion: @escaping ([String]) -> Void) {
        let apiKey = "a7bbef8bb52f8d29d337c85ddb589722"
        let encodedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlStr = "https://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=\(encodedArtist)&api_key=\(apiKey)&format=json"

        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
//                print("❌ Last.fm error: \(error?.localizedDescription ?? "Unknown")")
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let artist = json["artist"] as? [String: Any],
                   let tags = artist["tags"] as? [String: Any],
                   let tagArray = tags["tag"] as? [[String: Any]] {
                    let genres = tagArray.compactMap { $0["name"] as? String }
//                    print("🎯 Last.fm genres for \(artistName): \(genres)")
                    completion(genres)
                } else {
//                    print("⚠️ No genres found on Last.fm")
                    completion([])
                }
            } catch {
//                print("❌ JSON parse error from Last.fm: \(error)")
                completion([])
            }
        }.resume()
    }
    
    @State private var showDeleteAlert: Bool = false
    
    //TODO: FIX
    var DeleteButton: some View {
        Group {
//            if let index = newFestival.artistList.firstIndex(where: { $0.id == newArtist.id }) {
                Section {
                    HStack {
                        Spacer()
                        
                        Button(action: {
//                            newFestival.artistList.remove(at: index)
                            showDeleteAlert = true
                        }, label: {
                            Text("Remove Artists")
                        })
                        .frame(width: 250, height: 40)
                        .background(Color.red)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        
                        Spacer()
                    }
                }
                .listRowBackground(Color(uiColor: .systemGroupedBackground))
//            }
        }
        .alert(isPresented: $showDeleteAlert) {
            return Alert(title: Text("Remove \(artistList.count) Artists?"),
//                         message: Text("Are you sure you want to leave without saving?"),
                         primaryButton: .destructive(Text("Remove")) {
                removeMultipleArtists()
//                updateMultipleArtists()
            }, secondaryButton: .cancel()
            )
        }
    }
    
    func removeMultipleArtists() {
        for artist in artistList {
            if let index = newFestival.artistList.firstIndex(where: { $0.id == artist.id }) {
                newFestival.artistList.remove(at: index)
            }
        }
        showArtistSearchPage = false
    }
    
//   func fetchAccessTokenAndArtistInfo() {
//       fetchClientCredentialsToken { token in
//            guard let token = token else {
//                print("No valid token available")
//                return
//            }
//            fetchFullArtistInfo(id: artistID, accessToken: token) { result in
//                DispatchQueue.main.async {
//                    self.newArtist = result
//                    print(newArtist)
//                    self.isLoading = false
//                }
//            }
//        }
//    }
//
//
//
//    func fetchFullArtistInfo(id: String, accessToken: String, completion: @escaping (DataSet.artistNEW?) -> Void) {
//        print("ID: \(id)")
//        guard let url = URL(string: "https://api.spotify.com/v1/artists/\(id)") else {
//            print("❌ Invalid URL")
//            completion(nil)
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("", forHTTPHeaderField: "Accept-Language")
//
//        URLSession.shared.dataTask(with: request) { data, _, error in
//            guard let data = data, error == nil else {
//                print(error.debugDescription)
//                completion(nil)
//                return
//            }
//
//            struct SpotifyArtistDetail: Decodable {
//                let id: String
//                let name: String
//                let genres: [String]
//                let images: [ImageInfo]
//
//                struct ImageInfo: Decodable {
//                    let url: String
//                }
//            }
//
//            print(String(data: data, encoding: .utf8) ?? "No response string")
//            if let artist = try? JSONDecoder().decode(SpotifyArtistDetail.self, from: data),
//               let imageUrl = URL(string: artist.images.first?.url ?? "") {
//
//                URLSession.shared.dataTask(with: imageUrl) { imgData, _, _ in
//                    guard let imgData = imgData,
//                          let uiImage = UIImage(data: imgData) else {
//                        completion(nil)
//                        return
//                    }
//
//                    let result = DataSet.artistNEW(
//                        id: artist.id,
//                        name: artist.name,
//                        genres: artist.genres,
//                        photo: uiImage
//                    )
//                    print("🟡 Raw JSON:")
//                    print(String(data: data, encoding: .utf8) ?? "Unable to decode JSON")
////                    print("ARTIST RESULT: \(result)")
//
//                    completion(result)
//                }.resume()
//            } else {
//                print("UH OH")
//                completion(nil)
//            }
//        }.resume()
//    }
//
//    func fetchClientCredentialsToken(completion: @escaping (String?) -> Void) {
//        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
//        var request = URLRequest(url: tokenURL)
//        request.httpMethod = "POST"
//        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
//
//        let credentials = "\(SpotifyAuth.clientID):\(SpotifyAuth.clientSecret)"
//        let encodedCredentials = Data(credentials.utf8).base64EncodedString()
//        request.setValue("Basic \(encodedCredentials)", forHTTPHeaderField: "Authorization")
//
//        // ✅ This is where you use it
//        let bodyParams = "grant_type=client_credentials"
//        request.httpBody = bodyParams.data(using: .utf8)
//
//        URLSession.shared.dataTask(with: request) { data, _, error in
//            guard let data = data, error == nil else {
//                print("❌ Error fetching token")
//                completion(nil)
//                return
//            }
//
//            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
//               let accessToken = json["access_token"] as? String {
//                completion(accessToken)
//            } else {
//                completion(nil)
//            }
//        }.resume()
//    }
    
    
}

//#Preview {
//    ArtistSearchPage()
//}
