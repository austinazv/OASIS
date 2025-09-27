//
//  NewEventPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 6/5/25.
//

import SwiftUI
import MapKit
import PhotosUI

struct NewEventPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var spotify: SpotifyViewModel
    
    @EnvironmentObject var festivalVM: FestivalViewModel
    @StateObject var draft: NewEventPageViewModel
    
//    @Binding var festivalList: Array<DataSet.festival>
    @Binding var navigationPath: NavigationPath
    
//    @State private var draft.newFestival = DataSet.festival()
    
   
    
    @State var uploadingFestival: Bool = false
    
    @State private var hasBeenEdited: Bool = false
    
    let FRAME_HEIGHT = 40.0
    
//    init(festivalCreator: FestivalViewModel) {
//        self.festivalCreator = festivalCreator
////        _draft = StateObject(wrappedValue: NewEventPageViewModel(festivalCreator: festivalCreator))
//    }
    
    init(festival: DataSet.Festival, /*festivalCreator: FestivalViewModel,*/ navigationPath: Binding<NavigationPath>) {
        _navigationPath = navigationPath
        _draft = StateObject(wrappedValue: NewEventPageViewModel(festival: festival))
    }
    
    @State var discardChangesAlert: Bool = false
    
    
    var body: some View {
        Group {
            ZStack {
                VStack {
                    //                ScrollViewReader { proxy in
                    Form {
                        EventName
                        EventDates
                        EventLocation
                        EventArtists
                        EventStages
                        EventLogo
                        EventWebsite
                        DeleteButton
                        //                    Section {
                        //                        Spacer()
                        //                            .frame(height: 200)
                        //                    }
                        //                    .listRowBackground(Color("Same As Background"))
                    }
                    //                }
                    //                .frame(height: 1000)
                }
                if uploadingFestival {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: 40, height: 40, alignment: .center)
                        .foregroundStyle(.gray)
                        .opacity(0.5)
                    ProgressView()
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    Button (action: {
                        if hasBeenEdited {
                            discardChangesAlert = true
                        } else {
                            navigationPath.removeLast()
                        }
                    }, label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    })
                }
                .foregroundStyle(.blue)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu(content: {
                    Button (action: {
                        dismissKeyboard()
                        festivalVM.currentFestival = draft.newFestival
                        navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: draft.newFestival, draftView: false, previewView: true))
                    }, label: {
                        Text("Preview")
                        Image(systemName: "eyes")
                    })
                    if draft.newFestival.published {
//                        Button (action: {
//                            festivalVM.saveDraft(draft.newFestival)
//                            navigationPath.removeLast()
//                        }, label: {
//                            HStack {
//                                Text("Save As Draft")
//                                Image(systemName: "checkmark.seal")
//                            }
//                        })
                        Button (action: {
                            uploadingFestival = true
                            festivalVM.uploadFestival(draft.newFestival) { result in
                                switch result {
                                case .success():
                                    print("Festival uploaded with merge successfully!")
                                    uploadingFestival = false
                                    navigationPath.removeLast()
                                case .failure(let error):
                                    print("Upload failed:", error)
                                    uploadingFestival = false
                                }
                            }
                        }, label: {
                            Text("Publish Updates")
                            Image(systemName: "globe")
                        })
                    } else {
                        Button (action: {
                            festivalVM.saveDraft(draft.newFestival)
                            navigationPath.removeLast()
                        }, label: {
                            HStack {
                                Text("Save Draft")
                                Image(systemName: "checkmark.seal")
                            }
                        })
                        Button (action: {
                            uploadingFestival = true
                            festivalVM.uploadFestival(draft.newFestival) { result in
                                switch result {
                                case .success():
                                    print("Festival uploaded with merge successfully!")
                                    uploadingFestival = false
                                    navigationPath.removeLast()
                                case .failure(let error):
                                    print("Uxpload failed:", error)
                                    uploadingFestival = false
                                }
                            }
                        }, label: {
                            Text("Publish")
                            Image(systemName: "globe")
                        })
                    }
                    
                }, label: {
                    HStack {
                        Text("Save")
                    }
                })
                .foregroundStyle(draft.newFestival.name == "" ? .gray : .blue)
                .disabled(draft.newFestival.name == "")
            }
            ToolbarItem(placement: .principal) {
                Text(draft.newFestival.name == "" ? "New Event" : draft.newFestival.name)
                    .font(.headline)
            }
        }
        .onAppear() {
            if let logoPath = draft.newFestival.logoPath {
                FestivalViewModel.loadFestivalImage(path: logoPath) { logo in
                    if let logo = logo {
                        //                , let logo = festivalVM.loadFestivalImage(filePath: logoPath) {
                        selectedImage = logo
                    }
                }
            }
            if !festivalVM.isNewFestival(draft.newFestival) {
                singleDayEvent = festivalVM.isSameDay(draft.newFestival.startDate, draft.newFestival.endDate)
            }
        }
        .sheet(isPresented: $showArtistSearchPage) {
            if let artist = selectedArtist {
                AddArtistPage(newArtist: artist, artistImage: artistImages[artist.id], newFestival: $draft.newFestival, showArtistSearchPage: $showArtistSearchPage)
            }
        }
        .alert(isPresented: $discardChangesAlert) {
            return Alert(title: Text("Discard Changes?"),
                         message: Text("Are you sure you want to leave without saving?"),
                         primaryButton: .destructive(Text("Discard Changes")) {
                navigationPath.removeLast()
            }, secondaryButton: .cancel()
            )
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $selectedItem,
            matching: .images,
            photoLibrary: .shared()
        )
    }
    
    
    @FocusState var nameFocused: Bool
    
    var EventName: some View {
        Group {
            Section(header:
                        HStack {
                Text("Event Name")
                Text("*").foregroundStyle(.red)
            }
            ) {
                //                ClearableTextField(text: $draft.newFestival.name, placeholder: "Name")
                ZStack {
                    TextField("Name", text: $draft.newFestival.name)
                        .padding(5)
                        .background(Color(.systemGray6))
                        .cornerRadius(5)
                        .autocapitalization(.words)
                        .frame(height: FRAME_HEIGHT)
                        .focused($nameFocused)
                    if !draft.newFestival.name.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .padding(.horizontal, 10)
                                .contentShape(Rectangle())
                                .foregroundStyle(.gray)
                                .onTapGesture {
                                    draft.newFestival.name = ""
                                }
                        }
                    }
                }
                
            }
        }
    }
    
    @State private var singleDayEvent = false
    @State private var showStartDates = false
    @State private var showEndDates = false
    
    var EventDates: some View {
        Group {
            Section(header:
                        HStack {
                Text(singleDayEvent ? "Date" : "Dates")
                Text("*").foregroundStyle(.red)
            }
            ) {
                VStack {
                    Toggle(isOn: $singleDayEvent, label: { Text("Single Day Event") }).padding(.vertical, 1)
                    Divider()
                    HStack {
                        Text(getStartDateText())
                        Spacer()
                        Text("\(draft.newFestival.startDate.formatted(date: .long, time: .omitted))")
                            .foregroundStyle(Color("OASIS Dark Orange"))
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        showStartDates.toggle()
                        showEndDates = false
                        dismissKeyboard()
                    }
                    if showStartDates {
                        Divider()
                        DatePicker(
                            "Select a date",
                            selection: $draft.newFestival.startDate,
                            //                            selection: $startDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                    }
                    if !singleDayEvent {
                        Divider()
                        HStack {
                            Text(draft.newFestival.secondWeekend ? "Weekend 1 End Date:" : "End Date:")
                            Spacer()
                            Text("\(draft.newFestival.endDate.formatted(date: .long, time: .omitted))")
                                .foregroundStyle(Color("OASIS Dark Orange"))
                        }
                        .padding(.vertical, 4)
                        .onTapGesture {
                            showEndDates.toggle()
                            showStartDates = false
                            dismissKeyboard()
                        }
                        if showEndDates {
                            Divider()
                            DatePicker(
                                "Select a date",
                                selection: $draft.newFestival.endDate,
                                in: draft.newFestival.startDate...,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                        }
                        Divider()
                        HStack {
                            if draft.newFestival.secondWeekend {
                                let secondWeekendText = festivalVM.getSecondWeekendText(startDate: draft.newFestival.startDate, endDate: draft.newFestival.endDate)
                                Text("Weekend 2: \(secondWeekendText)")
                                Spacer()
                                Image(systemName: "minus.circle")
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "plus.circle")
                                Text("Add Second Weekend")
                                Spacer()
                            }
                        }
                        .foregroundStyle(.gray)
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onTapGesture() {
                            draft.newFestival.secondWeekend.toggle()
                        }
                        
                    }
                }
            }
            .onChange(of: singleDayEvent) { _ in
                draft.newFestival.endDate = draft.newFestival.startDate
                draft.newFestival.secondWeekend = false
                dismissKeyboard()
            }
            .onChange(of: draft.newFestival.startDate) { newDate in
                if singleDayEvent {
                    draft.newFestival.endDate = newDate
                } else if draft.newFestival.endDate < newDate {
                    draft.newFestival.endDate = newDate
                }
            }
            .onChange(of: draft.newFestival) { _ in
                if !hasBeenEdited {
                    hasBeenEdited = true
                }
            }
            
        }
    }
    
    func getStartDateText() -> String {
        if singleDayEvent {
            return "Date:"
        } else if draft.newFestival.secondWeekend {
            return "Weekend 1 Start Date:"
        }
        return "Start Date:"
    }
    
    @State var urlText = ""
    @FocusState var urlTextFocused: Bool
    
    var EventWebsite: some View {
        Group {
            Section(header: Text("Website")) {
                VStack {
                    HStack {
                        ZStack {
                            TextField("Enter URL", text: $urlText)
                                .padding(5)
                                .background(Color(.systemGray6))
                                .autocorrectionDisabled(true)
                                .cornerRadius(5)
                                .autocapitalization(.none)
                                .frame(height: FRAME_HEIGHT)
                                .submitLabel(.return)
                                .focused($urlTextFocused)
                            //                            .onSubmit {
                            //                                addStage()
                            //                            }
                            if !urlText.isEmpty {
                                HStack {
                                    Spacer()
                                    Image(systemName: "xmark.circle")
                                        .padding(.horizontal, 10)
                                        .foregroundStyle(.gray)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            urlText = ""
                                        }
                                }
                            }
                        }
                        if isValidURL(urlText) {
                            Image(systemName: "checkmark")
                                .imageScale(.large)
                                .foregroundStyle(Color("OASIS Dark Orange"))
                                .frame(width: FRAME_HEIGHT)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    if !urlText.isEmpty && !isValidURL(urlText) {
                        Divider()
                        HStack {
                            Image(systemName: "xmark")
                                .imageScale(.small)
//                                .foregroundStyle(.red)
//                                .frame(width: FRAME_HEIGHT)
                            Text("Please enter valid URL")
                                .italic()
                                .font(.footnote)
                            Spacer()
                        }
                        .padding(2)
                        .foregroundStyle(.gray)
                    }
                }
            }
            .onAppear() {
                if let url = draft.newFestival.website {
                    urlText = url
                }
            }
        }
        .onChange(of: urlText) { text in
            if isValidURL(text) {
                draft.newFestival.website = text
            } else {
                draft.newFestival.website = nil
            }
        }
    }
    
    func isValidURL(_ urlString: String) -> Bool {
        let commonTLDs = [".com", ".org", ".net", ".io", ".edu", ".gov", ".co", ".us", ".uk", ".dev", ".ai"]
        
        let testStrings = [
            urlString,
            "http://\(urlString)",
            "http://www.\(urlString)"
        ]
        
        for test in testStrings {
            if let url = URL(string: test),
               UIApplication.shared.canOpenURL(url),
               let host = url.host?.lowercased() {
                
                // Check if host ends with a known TLD
                for tld in commonTLDs {
                    if host.hasSuffix(tld) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    
    
    
    @StateObject private var searchService = LocationSearchService()
    @State private var query = ""
//    @State private var selectedLocation: String?
    @FocusState private var locationFocused: Bool
    
    var EventLocation: some View {
        Group {
            //            ScrollViewReader { proxy in
            Section(header: Text("Location")) {
                VStack(alignment: .leading, spacing: 8) {
                    if let selected = draft.newFestival.location {
                        HStack {
                            Group {
                                Image(systemName: "mappin")
                                Text(selected)
                            }
                            .foregroundStyle(Color("OASIS Dark Orange"))
                            Spacer()
                            Image(systemName: "x.circle")
                                .onTapGesture {
                                    draft.newFestival.location = nil
                                }
                        }
                        .padding(.vertical, 3)
                    }
                    ZStack(alignment: .topLeading) {
                        ZStack {
                            TextField(
                                draft.newFestival.location == nil ? "Enter City or State" : "Change Location",
                                text: $query
                            )
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .autocapitalization(.words)
                            .focused($locationFocused)
                            .onChange(of: query) {
                                searchService.update(query: $0)
                            }
                            if !query.isEmpty {
                                HStack {
                                    Spacer()
                                    Image(systemName: "xmark.circle")
                                        .padding(.horizontal, 10)
                                        .foregroundStyle(.gray)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            query = ""
                                            searchService.results.removeAll()
                                        }
                                }
                            }
                        }
                        if !query.isEmpty && searchService.isLoading {
                            Spacer().frame(height: 120)
                            HStack {
                                Spacer()
                                ProgressView()
                                    .frame(height: 50)
                                Spacer()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                            .padding(.horizontal)
                            .offset(y: 55)
                            .zIndex(1)
                        }
                        if !searchService.results.isEmpty {
                            Spacer().frame(height: 255)
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(searchService.results, id: \.self) { result in
                                        Button {
                                            draft.newFestival.location = result.title
                                            searchService.results = []
                                            query = ""
                                            locationFocused = false
                                        } label: {
                                            Text(result.title)
                                                .padding()
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color(.systemBackground))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                            .padding(.horizontal)
                            .offset(y: 50)
                            .zIndex(1)
                        }
                    }
                }
                .animation(.default, value: searchService.results)
            }
        }
    }


    
    
    @State var stageName = ""
    @FocusState var stageNameFocused: Bool
    
    var EventStages: some View {
        Group {
            Section(header: Text("Venue / Stages")) {
                VStack {
                    if !draft.newFestival.stageList.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(draft.newFestival.stageList.sorted(), id: \.self) { stage in
                                HStack {
                                    Text(stage)
                                        .foregroundStyle(Color("OASIS Dark Orange"))
                                    Image(systemName: "x.circle")
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(.black, lineWidth: 1)
                                        .foregroundStyle(.white)
                                )
                                .onTapGesture {
                                    removeStage(stage: stage)
                                }
                            }
                        }
                        Divider()
                    }
                    HStack {
                        ZStack {
                            TextField("Add Stage", text: $stageName)
                                .padding(5)
                                .background(Color(.systemGray6))
                                .autocorrectionDisabled(true)
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
//            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        }
    }
    
    private func addStage() {
        stageNameFocused = !stageName.isEmpty
        guard !stageName.isEmpty else { return }
        if !draft.newFestival.stageList.contains(stageName) {
            draft.newFestival.stageList.append(stageName)
        }
        stageName = ""
    }
    
    private func removeStage(stage: String) {
        for (i, artist) in draft.newFestival.artistList.enumerated() {
            if artist.stage == stage {
                draft.newFestival.artistList[i].stage = data.NA_TITLE_BLOCK
            }
        }
        if let originalIndex = draft.newFestival.stageList.firstIndex(of: stage) {
            draft.newFestival.stageList.remove(at: originalIndex)
        }
    }
    
    
    
    
    
    @State var showArtistSearchPage = false
    @State var artistSearchText = ""
    @State private var artistSearchResults: [DataSet.Artist] = []
    @State var artistImages: [String : UIImage] = [:]
    @State private var selectedArtist: DataSet.Artist? = nil
    @FocusState var artistSearchFocused: Bool
    @State var artistSearchIsLoading = false
    @State private var debounceCancellable: DispatchWorkItem?
    
    var EventArtists: some View {
        Group {
            Section(header: Text("Performers")) {
                VStack {
                    if !draft.newFestival.artistList.isEmpty {
                        ZStack {
                            HStack {
                                Text("\(draft.newFestival.artistList.count) \(draft.newFestival.artistList.count == 1 ? "Artist" : "Artists")")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            NavigationLink {
                                ArtistEditingList(newFestival: $draft.newFestival)
                                //                            ArtistEditingList(artistDict: ["All Artists" : draft.newFestival.artistList])
                            } label: {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .foregroundStyle(Color("OASIS Dark Orange"))
                        Divider()
                    }
                    ZStack(alignment: .topLeading) {
                        HStack {
                            ZStack {
                                TextField("Search Spotify Database", text: $artistSearchText)
                                    .padding(5)
                                    .background(Color(.systemGray6))
                                    .autocorrectionDisabled(true)
                                    .cornerRadius(5)
                                    .autocapitalization(.words)
                                    .frame(height: FRAME_HEIGHT)
                                    .focused($artistSearchFocused)
                                    .submitLabel(.return)
//                                    .onSubmit {
//                                        fetchAccessTokenAndSearch()
//                                    }
                                if !artistSearchText.isEmpty {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "xmark.circle")
                                            .padding(.horizontal, 10)
                                            .foregroundStyle(.gray)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                artistSearchText = ""
                                                artistSearchResults.removeAll()
                                            }
                                    }
                                }
                            }
                            Image(systemName: "magnifyingglass")
                                .imageScale(.large)
                                .foregroundStyle(artistSearchText == "" ? Color.gray : Color.blue /*Color("OASIS Dark Orange")*/)
                                .frame(width: FRAME_HEIGHT)
                                .onTapGesture {
                                    artistSearchFocused = false
                                    fetchAccessTokenAndSearch()
                                    //                                        withAnimation {
                                    //                                            proxy.scrollTo("Artist Section", anchor: .top)
                                    //                                        }
                                }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        
                        if !artistSearchResults.isEmpty {
                            Spacer().frame(height: 270)
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    //                                ForEach(artistSearchResults, id: \.self) { result in
                                    ForEach(artistSearchResults) { artist in
                                        HStack(spacing: 12) {
                                            //                                            ArtistAsyncImage(imageURL: artist.imageURL)
                                            Group {
                                                if let image = artistImages[artist.id] {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                    
                                                    //                                                        .clipShape(Circle())
                                                } else {
                                                    ProgressView()
                                                }
                                            }
                                            .frame(width: 50, height: 50)
                                            Text(artist.name)
                                            Spacer()
                                            Image(systemName: "plus.circle")
                                                .imageScale(.large)
                                                .foregroundStyle(Color.blue)
                                        }
                                        .padding(6)
                                        .contentShape(Rectangle())
                                        .onTapGesture() {
                                            if let artistInListIndex = draft.newFestival.artistList.firstIndex(where: { $0.id == artist.id }) {
                                                selectedArtist = draft.newFestival.artistList[artistInListIndex]
                                            } else {
                                                selectedArtist = artist
                                            }
                                            //                                            print(artist.id)
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            //
                                            //                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            //                                                showArtistSearchPage = true
                                            //                                            }
                                        }
                                    }
                                }
                            }
                            .frame(maxHeight: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                            .padding(.horizontal)
                            .offset(y: 55)
                            .zIndex(1)
                        }
                        if artistSearchIsLoading {
                            Spacer().frame(height: 120)
                            HStack {
                                Spacer()
                                ProgressView()
                                    .frame(height: 50)
                                Spacer()
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemBackground))
                                    .shadow(radius: 4)
                            )
                            
                            .padding(.horizontal)
                            .offset(y: 55)
                            .zIndex(1)
                        }
                    }
                }
                .animation(.default, value: artistSearchResults)
            }
        }
        .onChange(of: artistSearchResults) { searchResults in
            Task {
                for artist in searchResults {
                    if let image = await data.loadArtistImage(artistID: artist.id, imageURL: artist.imageURL) {
                        artistImages[artist.id] = image
                    }
                }
            }
        }
        .onChange(of: selectedArtist) { newArtist in
            if newArtist != nil {
                showArtistSearchPage = true
            }
        }
        .onChange(of: showArtistSearchPage) { bool in
            if !bool {
                selectedArtist = nil
            }
        }
        .onChange(of: artistSearchText) { newValue in
            artistSearchResults.removeAll()
            debounceCancellable?.cancel()
            
            guard !newValue.isEmpty else { return }

            let workItem = DispatchWorkItem {
                fetchAccessTokenAndSearch()
            }
            debounceCancellable = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
        .onChange(of: draft.newFestival.artistList) { _ in
            artistSearchText = ""
            artistSearchResults.removeAll()
        }
        
        
    }
    
//    func loadArtistImage(from artist: DataSet.artistNEW) -> UIImage? {
//        // 1. Try loading from imagePath if it exists
//        if let path = artist.imageLocalPath {
//            let fileURL = URL(fileURLWithPath: path)
//            if let imageData = try? Data(contentsOf: fileURL),
//               let image = UIImage(data: imageData) {
//                return image
//            }
//        }
//        
//        // 2. Fallback to loading from imageURL
//        if let url = URL(string: artist.imageURL),
//           let imageData = try? Data(contentsOf: url),
//           let image = UIImage(data: imageData) {
//            return image
//        }
//        
//        // 3. If both fail, return nil
//        return nil
//    }
    
    private func fetchAccessTokenAndSearch() {
        artistSearchResults.removeAll()
        artistSearchIsLoading = true
        spotify.getValidAccessToken { token in
            guard let token = token else {
                print("No valid token available")
                return
            }
            performSearch(with: token)
        }
    }
    
    
    private func performSearch(with accessToken: String) {
        guard let encodedQuery = artistSearchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=artist&limit=5") else {
            artistSearchIsLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Optionally set loading state here
            }
            
            guard let data = data, error == nil else {
                print("Error fetching artists: \(error?.localizedDescription ?? "Unknown error")")
                artistSearchIsLoading = false
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(SpotifyViewModel.SpotifySearchResponse.self, from: data)
                let artistsRaw = decoded.artists.items
                
                var results: [DataSet.Artist] = []
                
                for artist in artistsRaw {
                    let imageUrlString = artist.images.first?.url ?? ""
                    print("ARTIST ID: \(artist.id)")
                    
                    let newArtist = DataSet.Artist(
                        id: artist.id,
                        name: artist.name,
                        genres: artist.genres,
                        imageURL: imageUrlString
                    )
                    
                    results.append(newArtist)
                }
                
                DispatchQueue.main.async {
                    self.artistSearchResults = results
                    artistSearchIsLoading = false
                }
            } catch {
                print("Failed to decode response: \(error)")
                artistSearchIsLoading = false
            }
        }.resume()
    }

    func loadImage(for artist: DataSet.Artist, completion: @escaping (UIImage?) -> Void) {
        if let cached = ImageCache.shared.get(for: artist.imageURL) {
            completion(cached)
            return
        }

        // Download the image
        guard let url = URL(string: artist.imageURL) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data) else {
                completion(nil)
                return
            }

            ImageCache.shared.set(image, for: artist.imageURL)
            completion(image)
        }.resume()
    }
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    var EventLogo: some View {
        Group {
            Section(header: Text("Logo")) {
                VStack {
                    if let selectedImage {
                        ZStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 60, alignment: .center)
                                .padding(5)
                        }
                        .frame(maxHeight: 60)
                        Divider()
                        //                        .clipShape(Circle())
                    }
                    HStack {
                        Text(selectedImage == nil ? "Add Logo" : "Change Logo")
                            .foregroundStyle(Color.blue)
                            .frame(height: 20)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showPhotoPicker = true
                            }
                        if selectedImage != nil {
                            Divider()
                                .frame(height: 25)
                                .padding(.horizontal, 15)
                            Text("Remove Logo")
                                .foregroundStyle(Color.red)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedImage = nil
                                }
//                                .padding(.leading, 20)
                                .padding(.vertical, 5)
                        }
                    }
                }
            }
        }
        
        .onChange(of: selectedItem) { newItem in
            Task {
                if let selectedItem, let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .onChange(of: selectedImage) { newLogo in
            if let logo = newLogo {
                Task {
                    if let path = festivalVM.saveImageForFestival(logo, festivalID: draft.newFestival.id) {
                        draft.newFestival.logoPath = path
                    }
                }
            } else {
                draft.newFestival.logoPath = nil
            }
        }
    }
    
    
    
    @State var showDeleteAlert = false
    
    @State var showDeleteDialog = false
    @State var showUnpublishDialog = false
    
    var DeleteButton: some View {
        Section {
            HStack() {
                Spacer()
                Group {
                    if !festivalVM.isNewFestival(draft.newFestival) {
                        if draft.newFestival.published {
                            Button(action: {
                                showUnpublishDialog = true
                            }, label: {
                                Text("Unpublish Event")
                            })
                        } else {
                            Button(action: {
                                showDeleteDialog = true
                            }, label: {
                                Text("Delete Draft")
                                //                                .frame(width: 200, height: 40)
                                //                                .background(Color.red)
                                //                                .foregroundStyle(.white)
                                //                                .cornerRadius(10)
                                //                                .shadow(radius: 5)
                            })
                        }
                    } else {
                        Button(action: {
                            navigationPath.removeLast()
                        }, label: {
                            Text("Cancel")
//                                .frame(width: 200, height: 40)
//                                .background(Color.red)
//                                .foregroundStyle(.white)
//                                .cornerRadius(10)
//                                .shadow(radius: 5)
                        })
                    }
                    
                }
                .frame(width: 200, height: 40)
                .background(Color.red)
                .foregroundStyle(.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                
                
                
//                Button(action: {
//                    if hasBeenEdited {
//                        showDeleteAlert = true
//                    } else {
//                        navigationPath.removeLast()
//                    }
//                }, label: {
//                    Text("Delete Event")
//                        .frame(width: 200, height: 40)
//                        .background(Color.red)
//                        .foregroundStyle(.white)
//                        .cornerRadius(10)
//                        .shadow(radius: 5)
//                })
                Spacer()
            }
            .confirmationDialog("Unpublish Event?",
                isPresented: $showUnpublishDialog,
                titleVisibility: .visible
            ) {
                Button("Unpublish", role: .destructive) {
                    festivalVM.unpublishAndSave(draft.newFestival) { result in
                        switch result {
                        case .success:
                            navigationPath.removeLast()
                        case .failure(let error):
                            print(error)
                            //TODO: ERROR MESSAGE
                        }
                    }
                }
                Button("Unpublish & Delete", role: .destructive) {
                    festivalVM.unpublishAndDelete(draft.newFestival) { result in
                        switch result {
                        case .success:
                            navigationPath.removeLast()
                        case .failure(let error):
                            print(error)
                            //TODO: ERROR MESSAGE
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to unpublish \(draft.newFestival.name == "" ? "Untitled Event" : draft.newFestival.name)?")
            }
            .confirmationDialog("Delete Draft?",
                isPresented: $showDeleteDialog,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    festivalVM.deleteEvent(id: draft.newFestival.id)
                    navigationPath.removeLast()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(draft.newFestival.name == "" ? "Untitled Event" : draft.newFestival.name)?")
            }
            
//            .alert(isPresented: self.$showDeleteAlert) {
//                let eventName = (draft.newFestival.name == "" ? "Untitled Event" : draft.newFestival.name)
//                if draft.newFestival.published {
//                    return Alert(title: Text("Unpublish Event?"),
//                                 message: Text("Are you sure you want to delete \(eventName)?"),
//                                 primaryButton: .destructive(Text("Delete")) {
//                        festivalVM.deleteEvent(id: draft.newFestival.id)
//                        navigationPath.removeLast()
//                    }, secondaryButton: .cancel()
//                    )
//                } else {
//                    return Alert(title: Text("Delete Event?"),
//                                 message: Text("Are you sure you want to delete \(eventName)?"),
//                                 primaryButton: .destructive(Text("Delete")) {
//                        festivalVM.deleteEvent(id: draft.newFestival.id)
//                        navigationPath.removeLast()
//                    }, secondaryButton: .cancel()
//                    )
//                }
//            }
        }
        .listRowBackground(Color("Same As Background"))
        
    }
    
    
    func dismissKeyboard() {
        nameFocused = false
        locationFocused = false
        stageNameFocused = false
        artistSearchFocused = false
        urlTextFocused = false
    }

    
    
    
//    private func performSearch(with accessToken: String) {
//        guard let encodedQuery = artistSearchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
//              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=artist&limit=5") else {
//            artistSearchIsLoading = false
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//        
////        isLoading = true
//        
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async {
////                isLoading = false
//            }
//            
//            guard let data = data, error == nil else {
//                print("Error fetching artists: \(error?.localizedDescription ?? "Unknown error")")
//                artistSearchIsLoading = false
//                return
//            }
//            
//            do {
//                let decoded = try JSONDecoder().decode(SpotifyViewModel.SpotifySearchResponse.self, from: data)
//                let artistsRaw = decoded.artists.items
//                
//                var results: [DataSet.artistNEW] = []
//                let group = DispatchGroup()
//                
//                for artist in artistsRaw {
//                    guard let imageUrlString = artist.images.first?.url,
//                          let imageUrl = URL(string: imageUrlString) else { continue }
//                    
//                    group.enter()
//                    
//                    // Download image data
//                    URLSession.shared.dataTask(with: imageUrl) { data, _, error in
//                        defer { group.leave() }
//                        
//                        guard let data = data, error == nil,
//                              let image = UIImage(data: data) else {
//                            artistSearchIsLoading = false
//                            print("Failed to load image for artist \(artist.name)")
//                            return
//                        }
//                        print("ARTIST ID: \(artist.id)")
//                        let newArtist = DataSet.artistNEW(
//                            id: artist.id,
//                            name: artist.name,
//                            genres: artist.genres,
//                            photo: image
//                        )
//                        
//                        DispatchQueue.main.async {
//                            
//                            results.append(newArtist)
//                            
//                        }
//                    }.resume()
//                }
//                
//                group.notify(queue: .main) {
//                    self.artistSearchResults = results
//                    artistSearchIsLoading = false
//                    
//                }
//            } catch {
//                
//                print("Failed to decode response: \(error)")
//                artistSearchIsLoading = false
//            }
//        }.resume()
//    }
}







struct ColorSliderPicker: View {
    @Binding var hue: Double
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: stride(from: 0.0, through: 1.0, by: 0.01).map {
                        Color(hue: $0, saturation: 1.0, brightness: 1.0)
                    }),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 10)
                .cornerRadius(5)
                
                // Slider on top
                Slider(value: $hue, in: 0...1)
                    .accentColor(.clear)
            }
            .frame(height: 44)
            .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }
            
            // Color preview box
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hue: hue, saturation: 1.0, brightness: 1.0))
                .frame(width: 44, height: 44)
                .shadow(radius: 5)
                .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }
        }
        .alignmentGuide(.firstTextBaseline) { d in d[VerticalAlignment.center] }
        .padding(.horizontal)
        .padding(.vertical, 3)
        .frame(height: 44)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: bounds.minX + currentX, y: bounds.minY + currentY),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}



class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    @Published var isLoading: Bool = false
    
    var completer: MKLocalSearchCompleter
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        self.completer.delegate = self
        self.completer.resultTypes = [.address]
    }
    
    func update(query: String) {
        isLoading = true
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
        self.isLoading = false
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed: \(error.localizedDescription)")
    }
}


struct ArtistAsyncImage: View {
    var imagePath: String?
    var imageURL: String

    var body: some View {
        Group {
            if let imagePath,
               let image = loadImageFromDisk(imagePath) {
                // Local image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                // Remote image
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 50, height: 50)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }

    // Load UIImage from disk path
    func loadImageFromDisk(_ path: String) -> UIImage? {
        let fullURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(path)
        guard let url = fullURL, FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
}

class ImageCache: ObservableObject {
    static let shared = ImageCache()
    
    private init() {}
    
    private var cache: [String: UIImage] = [:]
    
    func get(for url: String) -> UIImage? {
        return cache[url]
    }
    
    func set(_ image: UIImage, for url: String) {
        cache[url] = image
    }
}


//#Preview {
//    NewEventPage()
//}



//TO ADD TO ON APPEAR:

//draft.newFestival = DataSet.festival(id: UUID(uuidString: "80F6188F-91C2-4F42-B5E6-525FEDC9FF46")!, ownerID: "austin.zv", ownerName: "Austin", saveDate: Date(), verified: true, name: "Coachella 2025 Weekend 1", startDate: Date(), endDate: Date(), location: Optional("Indio, CA"), logoPath: nil, artistList: [DataSet.artistNEW(id: "246dkjvS1zLTtiykXe5h60", name: "Post Malone", genres: ["Hip-Hop", "Rap", "Trap", "Cloud Rap", "Pop"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebe17c0aa1714a03d62b5ce4e0", imageLocalPath: nil, day: "Sunday (April 13)", tier: "Headliner", stage: "Main Stage"), DataSet.artistNEW(id: "1HY2Jd0NmPuamShAr6KMms", name: "Lady Gaga", genres: ["Pop", "Dance", "Electronic", "Female Vocalist"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebaadc18cac8d48124357c38e6", imageLocalPath: nil, day: "Friday (April 11)", tier: "Headliner", stage: "Main Stage"), DataSet.artistNEW(id: "2qxJFvFYMEDqd7ui6kSAcq", name: "Zedd", genres: ["Electro House", "Electronic", "House", "Electro", "Dubstep"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebe28762aed82cde1178fb3873", imageLocalPath: nil, day: "Sunday (April 13)", tier: "First Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "7oPftvlwr6VrsViSDV7fJY", name: "Green Day", genres: ["Punk Rock", "Rock", "Punk", "Pop Punk", "Alternative"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb6ff0cd5ef2ecf733804984bb", imageLocalPath: nil, day: "Saturday (April 12)", tier: "Headliner", stage: "Main Stage"), DataSet.artistNEW(id: "0Y5tJX1MQlPlqiwlOH1tJY", name: "Travis Scott", genres: ["Rap", "R&B", "Hip-Hop", "Trap"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb19c2790744c792d05570bb71", imageLocalPath: nil, day: "Saturday (April 12)", tier: "Headliner", stage: "Main Stage"), DataSet.artistNEW(id: "4o4tLTIJ3eWMFerz73atcT", name: "Qveen Herby", genres: ["Pop", "Rap", "Hip-Hop", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb7d26fee545bdb0164fc0d11b", imageLocalPath: nil, day: "Saturday (April 12)", tier: "-- N/A --", stage: "Heineken House"), DataSet.artistNEW(id: "25uiPmTg16RbhZWAqwLBy5", name: "Charli xcx", genres: ["Pop", "Synthpop", "Electronic", "Electroclash"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb936885667ef44c306483c838", imageLocalPath: nil, day: "Saturday (April 12)", tier: "First Tier", stage: "Main Stage"), DataSet.artistNEW(id: "2wIVse2owClT7go1WT98tk", name: "Missy Elliott", genres: ["Hip-Hop", "Rap", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebf6691f40d906f097e9fbaa4c", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Main Stage"), DataSet.artistNEW(id: "22wbnEMDvgVIAGdFeek6ET", name: "Benson Boone", genres: ["Pop", "Pop Rock", "Rock", "Usa"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebb68234e1a673acc3d873d3e6", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Main Stage"), DataSet.artistNEW(id: "6CwfuxIqcltXDGjfZsMd9A", name: "MARINA", genres: ["Pop", "Indie Pop", "Post-Hardcore", "Polish"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb4b482c79edd367dea0258224", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "Main Stage"), DataSet.artistNEW(id: "2sSGPbdZJkaSE2AbcGOACx", name: "The Marías", genres: ["Dream Pop", "Indie Pop", "Bedroom Pop", "Indie", "Sophisti-Pop"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebaf586afa2b397f1288683a76", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "0oK5D6uPhGu4Jk2dbZfodU", name: "Thee Sacred Souls", genres: ["Soul", "Funk", "United States", "San Diego", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb1a99219498d5119b0e742b19", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "Main Stage"), DataSet.artistNEW(id: "5L1lO4eRHmJ7a0Q6csE5cT", name: "LISA", genres: ["J-Pop", "Japanese", "Pop", "Hip-Hop"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb5cd3b3af8b72e32be78571ec", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Sahara"), DataSet.artistNEW(id: "4k1ELeJKT1ISyDv8JivPpB", name: "The Prodigy", genres: ["Electronic", "Techno", "Industrial", "Dance", "Electronica"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb147841812056c247407811f3", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0YinUQ50QDB7ZxSCLyQ40k", name: "Mustard", genres: ["Rap", "Hip-Hop", "Trap", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb54406b7007a449aeaac06c44", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Sahara"), DataSet.artistNEW(id: "0w1sbtZVQoK6GzV4A4OkCv", name: "Mau P", genres: ["House", "Tech House", "Dutch", "Techno", "Electronic"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebc494c9e97f2c6ee7560db705", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Sahara"), DataSet.artistNEW(id: "2qoQgPAilErOKCwE2Y8wOG", name: "GloRilla", genres: ["Rap", "Hip-Hop", "Trap", "Memphis"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebc33cf3ad025517202d8efbc0", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "3qiHUAX7zY4Qnjx8TNUzVx", name: "Yeat", genres: ["Trap", "Rap", "Cloud Rap", "Rage", "Plugg"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebbcb7b5ea25215172d09d4e2e", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "5p9HO3XC5P3BLxJs5Mtrhm", name: "Djo", genres: ["Psychedelic Pop", "Indie Pop", "Indie Rock", "Indie", "Psychedelic"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb44cd1d78b7d37cdd5bf8aac1", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "3SozjO3Lat463tQICI9LcE", name: "Tyla", genres: ["Pop", "South Africa", "Amapiano", "Afrobeat", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eba1fca104a7abe5a7031b887d", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "7eILArMiTFTQf8SEh5fFHK", name: "Sara Landry", genres: ["Minimal Techno", "Techno", "Hard Techno", "Acid Techno", "Acid"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb71b9ccd0f00f003b3d2b5eb0", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "5y8tKLUfMvliMe8IKamR32", name: "d4vd", genres: ["Pop", "Rock", "Dream Pop", "Indie Pop", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebee632cde061121a5fe48c1d6", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0PCCGZ0wGLizHt2KZ7hhA2", name: "Artemas", genres: ["Pop", "British", "Indie", "Singer-Songwriter", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb36e8f783dc68dcb1be1003a2", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "4l1cKWYW591xnwEGxpUg3J", name: "Miike Snow", genres: ["Electronic", "Electropop", "Pop", "Synth", "Dance"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb4c4eb4999b61bca344c03a7b", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "26s8LSolLfCIY88ysQbIuT", name: "Three 6 Mafia", genres: ["Rap", "Hip-Hop", "Dirty South", "Southern Rap"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb697a2395da5148557c36af55", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "7tm9Tuc70geXOOyKhtZHIj", name: "Chris Lorenzo", genres: ["Uk Garage", "Electronic", "House", "British", "Bassline"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebf0c4eaa650f582c8062e0fd2", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0H39MdGGX6dbnnQPt6NQkZ", name: "SAINt JHN", genres: ["Hip-Hop", "Rap", "Trap", "Electronic", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb5d18141fa518f77d006d6933", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "5fi7lIgJGH3RgUpJYcffQ7", name: "4batz", genres: ["Rap", "Soul", "Hip-Hop", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebb9d7b39ae0ddaf062a2a72d2", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "28uJnu5EsrGml2tBd7y8ts", name: "Vintage Culture", genres: ["House", "Brazil", "Deep House", "Brazilian", "Techno"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebb2858408e6d69098e07329fd", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "4v6XOdonnfpdTKTRJArG7v", name: "Tink", genres: ["Hip-Hop", "Rap", "Chicago", "R&B", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb567b8d72a8c508b6271b8275", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "7zrkALJ9ayRjzysp4QYoEg", name: "Maribou State", genres: ["Electronic", "Ambient", "Future Garage", "Dubstep", "Downtempo"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb8226ea46d749763f4e650015", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "3XxNRirzbjfLdDli06zMaB", name: "Eyedress", genres: ["Electronic", "Psychedelic", "Experimental", "Indie", "Lo-Fi"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb40d9ed7871bc7e39c2eb3950", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "335TWGWGFan4vaacJzSiU8", name: "A. G. Cook", genres: ["Bubblegum Bass", "Electronic", "Pc Music", "Pop", "Hyperpop"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb46fcb25c1d37f61e5fb2a5fd", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "3BxjasMelf9pKaE4f7Y0So", name: "Chris Stussy", genres: ["Deep House", "House", "Techno", "Electronic", "Dutch"], imageURL: "https://i.scdn.co/image/ab6761610000e5eba81703becb327be560062711", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "6I8TDGeUmmLom8auKPzMdX", name: "CA7RIEL & Paco Amoroso", genres: ["Pop"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb4f038c72eedc31a43021d020", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Mojave"), DataSet.artistNEW(id: "3EIJ8wiUHbgkRCt5cpRrQv", name: "Damian Lazarus", genres: ["Minimal", "Techno", "Minimal Techno", "Electronic", "Electro"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebd3aa0fd5b5cb1beee4931445", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "43UmVQp9qZILibJ5vHq21k", name: "Austin Millz", genres: ["Electronic", "Hip-Hop", "Usa", "Instrumental Hip-Hop", "Harlem"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb9b511aaad3e1abde4294f6f8", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "67FB4n52MgexGQIG8s0yUH", name: "Lola Young", genres: ["Pop", "Indie Pop", "Soul", "My Top Songs", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb72440981cd31315dbf45d359", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "5EmEZjq8eHEC6qFnT63Lza", name: "Tinlicker", genres: ["Progressive House", "Electro House", "Progressive Trance", "Melodic Techno", "Ambient"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb5c216e4bdf9cfd19c5e969be", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "5RTLRtXjbXI2lSXc6jxlAz", name: "Ravyn Lenae", genres: ["Soul", "Neo-Soul", "Alternative Rnb", "Electronic", "R&B"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb138d70fe372dedacdca53b61", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "1jgSqmZTBltb5O2L7ErmEP", name: "Beltran", genres: ["Electronic", "House", "Brazilian", "Brazil"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb9c36062fc529e6016f9f9bba", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "1UJfZU4rQx3bJ3tGypRuAT", name: "PARISI", genres: ["Sweden"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb3e7d3077105a0d87e724548f", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "6n1t55WMsSIUFHrAL4mUsB", name: "Pete Tong", genres: ["Electronic", "House", "Progressive House", "Dance", "Bbc Radio 1"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb770142bff034f7b72d4da6f7", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "4jercY4pUhY6jB8eQjpVJV", name: "Ahmed Spins", genres: ["House", "Deep House", "Morocco", "Afro House", "EDM"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb4fc4486527b4a277e7dd7ee3", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "4Siyzg8kWayQfPQsPSl6JI", name: "Shermanology", genres: ["Curacao", "House", "Dance", "Electronic", "Dutch"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebc4882ccd70c56733e4118bb1", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "3cIXmCH7iNcslTbwrwS7zy", name: "Moon Boots", genres: ["Nu-Disco", "Electronica", "House", "Electronic", "Disco"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb5285e5b78ca9a0b93b351a1d", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0Adbm5kzcPUxFybf9fhjgG", name: "Coco & Breezy", genres: [], imageURL: "https://i.scdn.co/image/ab6761610000e5ebc8f74c728e1aeebd56990fc3", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0UKrJ4XldrkShYFCjRPhVa", name: "EREZ", genres: ["Electronic", "Alternative", "Queer", "Los Angeles", "Israeli"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb329a3a88c0ea80a739de24ae", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "-- N/A --"), DataSet.artistNEW(id: "0yeC3KlivVqaE4MGdopqvF", name: "Gabe Real", genres: [], imageURL: "https://i.scdn.co/image/ab6761610000e5eb9d535a3deee869ef26467966", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Main Stage"), DataSet.artistNEW(id: "3oKRxpszQKUjjaHz388fVA", name: "Parcels", genres: [], imageURL: "https://i.scdn.co/image/ab6761610000e5eb495b935eb2a87c4cf3395248", imageLocalPath: nil, day: "Friday (April 11)", tier: "First Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "2mG8HHQ9S9kcbjcrb5N1FE", name: "The Go-Go\'s", genres: ["New Wave", "80S", "Pop", "Rock"], imageURL: "https://i.scdn.co/image/5506a4ed9d4abd277f4eda5a92239dc68073d46d", imageLocalPath: nil, day: "Friday (April 11)", tier: "Second Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "1GQur7dDvAWhKT9u9YwBJZ", name: "Seun Kuti", genres: ["Afrobeat", "Jazz", "Nigeria", "African", "World"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebb78262dec526d591cf8e3eff", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "6L71LxY17w8Yzh1zUphpiW", name: "Egypt 80", genres: ["Afrobeat", "Guitar", "Trumpet", "Jazz", "Organ"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb68d4b08ad9d1ed9519a6836b", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "26vfb56oacqQcv9oPEAyCa", name: "Tiffany Tyson", genres: [], imageURL: "", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Outdoor Stage"), DataSet.artistNEW(id: "2Au9zIICTEr0oeV1iQrJ6X", name: "HiTech", genres: ["Ghettotech", "Footwork", "Juke", "Rap", "Trap"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb1bb067080d7127c0156a5020", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora"), DataSet.artistNEW(id: "1ga48mxYYI9RuUrWLa3voh", name: "Los Mirlos", genres: ["Cumbia", "Chicha", "Peru", "Psychedelic", "Chill906"], imageURL: "https://i.scdn.co/image/ab6761610000e5eba75bdcded3725808d12285a9", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora"), DataSet.artistNEW(id: "1ZVACPeq7ccGCoUXwtafUU", name: "KNEECAP", genres: ["Rap", "Irish", "Hip-Hop", "Ireland"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebc07b6d26c0ae6faa9a90152f", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora"), DataSet.artistNEW(id: "2SdK1QDmZIP2hk94rSaLl9", name: "TOPS", genres: ["Indie", "Indie Pop", "Pop", "Soft Rock", "Canadian"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebb389e24691a904ff0398abc9", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora"), DataSet.artistNEW(id: "4417xRt2a90h8KtmfsaWL8", name: "Vs Self", genres: ["Emo", "Screamo", "Midwest Emo", "Skramz", "American"], imageURL: "https://i.scdn.co/image/ab6761610000e5eb9f3a4da4025cc1eaa242e2c6", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora"), DataSet.artistNEW(id: "3eimPofmo9TuKJTgpM9Bcj", name: "Glixen", genres: ["Shoegaze", "Dream Pop", "Indie Rock", "Indie"], imageURL: "https://i.scdn.co/image/ab6761610000e5ebe98d4d7cf9e725dbc495bff1", imageLocalPath: nil, day: "Friday (April 11)", tier: "Third+ Tier", stage: "Sonora")], stageList: ["Main Stage", "Outdoor Stage", "Mojave", "Heineken House", "Sahara", "Sonora", "Gobi"], website: Optional("Coachella.com"), published: false)
