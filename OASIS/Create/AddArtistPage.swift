//
//  ArtistSearchPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 6/16/25.
//

import SwiftUI

struct AddArtistPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
//    let artistID: String
    @State var newArtist: DataSet.Artist
    @State var artistImage: UIImage?
    
    @Binding var newFestival: DataSet.Festival
    
    @Binding var showArtistSearchPage: Bool
    
    @State var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else {
                VStack {
                    NavigationButtons
                    TitleBar
                    Form {
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
            if artistImage == nil {
                Task {
                    artistImage = await data.loadArtistImage(artistID: newArtist.id, imageURL: newArtist.imageURL)
                }
            }
            if !newFestival.artistList.contains(where: {$0.id == newArtist.id}) {
                var genreList = newArtist.genres.map { $0.capitalized }
                fetchGenresFromLastFM(artistName: newArtist.name) { genres in
                    for genre in genres.map({ $0.capitalized }) {
                        if !genreList.contains(genre) {
                            genreList.append(genre)
                        }
                    }
                    genreList.removeAll(where: {
                        $0.contains("Seen Live") ||
                        $0.contains("Vocalists") ||
                        $0.contains("Better") ||
                        $0.contains("My Top") ||
                        $0.contains(newArtist.name)
                    })
                    if genreList.contains("Hip Hop") {
                        genreList.removeAll(where: { $0 == "Hip Hop" })
                        if !genreList.contains("Hip-Hop") {
                            genreList.append("Hip-Hop")
                        }
                    }
                    if genreList.contains("Edm") {
                        genreList.removeAll(where: { $0 == "Edm" })
                        genreList.append("EDM")
                    }
                    if genreList.contains("Rnb") {
                        genreList.removeAll(where: { $0 == "Rnb" })
                        genreList.append("R&B")
                    }
                    if genreList.contains("Usa") {
                        genreList.removeAll(where: { $0 == "Usa" })
                        genreList.append("USA")
                    }
                    newArtist.genres = genreList
                    
                    //                newArtist.genres.append(contentsOf: genres)
                    //                newArtist.genres = newArtist.genres.map { $0.capitalized }
                    //                for genre in genres {
                    //                    newArtist.genres.append(genre.capitalized)
                    //                }
                }
                isLoading = false
            } else {
                isLoading = false
            }
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
                    if let oldArtist = newFestival.artistList.first(where: { $0.id == newArtist.id }) {
                        Button(action: {
                            addArtist()
                            showArtistSearchPage = false
                        }, label: {
                            Group {
                                Text("Update")
                            }
                            .foregroundStyle(newArtist == oldArtist ? .gray : .blue)
                        })
                        .disabled(newArtist == oldArtist)
                    } else {
                        Button(action: {
                            addArtist()
                            showArtistSearchPage = false
                        }, label: {
                            Group {
                                Text("Add Artist")
                            }
                            .foregroundStyle(.blue)
                        })
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            Divider()
        }
    }
    
    func addArtist() {
        if newArtist.stage == "+ Add Stage" {
            newArtist.stage = data.NA_TITLE_BLOCK
        }
        
        newArtist.modifyDate = Date()
        
        if let index = newFestival.artistList.firstIndex(where: { $0.name == newArtist.name }) {
            newFestival.artistList.remove(at: index)
        } else if let image = artistImage {
            do {
                let savedURL = try data.saveImageToDisk(image: image, artistID: newArtist.id)
                print("Saved image at:", savedURL.path)
            } catch {
                print("Failed to save image:", error)
            }
        }
        newFestival.artistList.append(newArtist)
    }
    
    
    
    var TitleBar: some View {
        VStack {
            HStack(spacing: 20) {
                //                        if let artist = newArtist {
                //TODO: Fix
                Group {
                    if let url = spotifyArtistURL(from: newArtist.id) {
                        Link(destination: url, label: {
                            ArtistImage(imageURL: newArtist.imageURL, frame: 90)
                        })
                    }
//                    if let image = artistImage {
//                        Image(uiImage: image)
//                            .resizable()
//                    } else {
//                        Image(systemName: "person.crop.circle.fill")
//                            .resizable()
//                    }
                }
//                .frame(width: 90, height: 90)
                Text(newArtist.name)
                    .font(.headline)
            }
            //                    }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
//            Text(newArtist.genres.joined(separator: ", "))
//                            .font(.subheadline)
//                            .foregroundColor(.gray)
        }
    }
    
    func spotifyArtistURL(from id: String) -> URL? {
        return URL(string: "https://open.spotify.com/artist/\(id)")
    }
    
    var ArtistWeekend: some View {
        Group {
            if newFestival.secondWeekend {
                Section {
                    HStack {
                        Text("Weekend")
                        Spacer()
                        Menu {
                            Picker("Weekend", selection: $newArtist.weekend) {
                                Text("Both").tag("Both")
                                Text("Weekend 1").tag("Weekend 1")
                                Text("Weekend 2").tag("Weekend 2")
                            }
                            .labelsHidden()
                            .pickerStyle(InlinePickerStyle())
                        } label:  {
                            HStack {
                                Text(newArtist.weekend)
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                        }
                    }
                }
            }
        }
    }
    
    var ArtistDay: some View {
        Group {
            if !Calendar.current.isDate(newFestival.startDate, inSameDayAs: newFestival.endDate) {
                Section {
                    HStack {
                        Text("Day")
                        Spacer()
                        Menu {
                            Picker("Day", selection: $newArtist.day) {
                                Text("-- N/A --").tag("-- N/A --")
                                ForEach(formattedDateStrings, id: \.self) { dateString in
                                    Text(dateString)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(InlinePickerStyle())
                        } label:  {
                            HStack {
                                Text(newArtist.day)
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                        }
                    }
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
                    HStack {
                        Text("Stage")
                        Spacer()
                        Menu {
                            Picker("Stage", selection: $newArtist.stage) {
                                Text("-- N/A --").tag("-- N/A --")
                                ForEach(newFestival.stageList.sorted(), id: \.self) { stage in
                                    Text(stage).tag(stage)
                                }
                                Text("+ Add Stage").tag("+ Add Stage")
                            }
                            .labelsHidden()
                            .pickerStyle(InlinePickerStyle())
                        } label:  {
                            HStack {
                                Text(newArtist.stage)
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                        }
                        
                    }
//                    .padding(.horizontal, 5)
                    if newArtist.stage == "+ Add Stage" {
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
        newArtist.stage = stageName
        stageName = ""
    }
    
    var ArtistTier: some View {
        Group {
            Section {
                HStack {
                    Text("Tier")
                    Spacer()
                    Menu {
                        Picker("Tier", selection: $newArtist.tier) {
                            Text("-- N/A --").tag("-- N/A --")
                            ForEach(data.tierLables, id: \.self) { tier in
                                Text(tier).tag(tier)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(InlinePickerStyle())
                    } label:  {
                        HStack {
                            Text(newArtist.tier)
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .foregroundStyle(Color("OASIS Dark Orange"))
                    }
                    
                }
            }
//            }
        }
    }
    
    @State var genreName = ""
    @FocusState var genreNameFocused: Bool
    
    var ArtistGenres: some View {
        Group {
            Section (header: Text("Genres")) {
                VStack {
                    if !newArtist.genres.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(newArtist.genres.sorted(), id: \.self) { genre in
                                HStack {
                                    Text(genre)
                                        .foregroundStyle(Color("OASIS Dark Orange"))
                                    Image(systemName: "x.circle")
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                    //                                    .stroke(Color("OASIS Dark Orange"), lineWidth: 1)
                                        .stroke(.black, lineWidth: 1)
                                        .foregroundStyle(.white)
                                )
                                .onTapGesture {
                                    if let originalIndex = newArtist.genres.firstIndex(of: genre) {
                                        newArtist.genres.remove(at: originalIndex)
                                    }
                                }
                            }
                        }
                        Divider()
                    }
                    HStack {
                        ZStack {
                            TextField("Add Genre", text: $genreName)
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
        }
    }
    
    private func addGenre() {
        genreNameFocused = !genreName.isEmpty
        guard !genreName.isEmpty else { return }
        if !newArtist.genres.contains(genreName) {
            newArtist.genres.append(genreName)
        }
        genreName = ""
    }
    
    func fetchGenresFromLastFM(artistName: String, completion: @escaping ([String]) -> Void) {
        let apiKey = "a7bbef8bb52f8d29d337c85ddb589722"  // ⬅️ replace this with your real API key
        let encodedArtist = artistName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let urlStr = "https://ws.audioscrobbler.com/2.0/?method=artist.getInfo&artist=\(encodedArtist)&api_key=\(apiKey)&format=json"

        guard let url = URL(string: urlStr) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("❌ Last.fm error: \(error?.localizedDescription ?? "Unknown")")
                completion([])
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let artist = json["artist"] as? [String: Any],
                   let tags = artist["tags"] as? [String: Any],
                   let tagArray = tags["tag"] as? [[String: Any]] {
                    let genres = tagArray.compactMap { $0["name"] as? String }
                    print("🎯 Last.fm genres for \(artistName): \(genres)")
                    completion(genres)
                } else {
                    print("⚠️ No genres found on Last.fm")
                    completion([])
                }
            } catch {
                print("❌ JSON parse error from Last.fm: \(error)")
                completion([])
            }
        }.resume()
    }
    
    var DeleteButton: some View {
        Section {
            HStack {
                Spacer()
                if let index = newFestival.artistList.firstIndex(where: { $0.id == newArtist.id }) {
                    Button(action: {
                        newFestival.artistList.remove(at: index)
                        showArtistSearchPage = false
                    }, label: {
                        Text("Remove Artist")
                    })
                    .frame(width: 250, height: 40)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                }
                Spacer()
            }
        }
        .listRowBackground(Color("Same As Background"))
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
