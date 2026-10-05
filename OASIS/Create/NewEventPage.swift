//
//  NewEventPage.swift
//  OASISOASIS
//
//  Created by Austin Zambito-Valente on 6/5/25.
//

import SwiftUI
import MapKit
import PhotosUI
import PDFKit
import QuickLook
import FirebaseFunctions

struct NewEventPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @EnvironmentObject var festivalVM: FestivalViewModel
    @StateObject var draft: NewEventPageViewModel
    
//    @Binding var festivalList: Array<DataSet.festival>
    @Binding var navigationPath: NavigationPath
    
//    @State private var draft.newFestival = DataSet.festival()
    
   
    
    @State var uploadingFestival: Bool = false
    
    @State private var hasBeenEdited: Bool = false
    
    let FRAME_HEIGHT = 40.0
    
    @State var oldVersion: Festival
    
    @State var lastEditedArtist: Artist?
    
    @State var showPublishWithNotificationSheet: Bool = false
    @State var showLogInSheet: Bool = false
    
    @Binding var selectedTab: Int
    
//    init(festivalCreator: FestivalViewModel) {
//        self.festivalCreator = festivalCreator
////        _draft = StateObject(wrappedValue: NewEventPageViewModel(festivalCreator: festivalCreator))
//    }
    
    init(festival: Festival, /*festivalCreator: FestivalViewModel,*/ navigationPath: Binding<NavigationPath>, selectedTab: Binding<Int>) {
        _navigationPath = navigationPath
        _draft = StateObject(wrappedValue: NewEventPageViewModel(festival: festival))
        oldVersion = festival
        _selectedTab = selectedTab
    }
    
    @State var discardChangesAlert: Bool = false
    
    var body: some View {
        //        Group {
        ZStack {
            VStack {
                //                ScrollViewReader { proxy in
                Form {
                    EventName
                    EventDates
                    EventLocation
                    EventArtists
                    EventStages
                    if let uid = firestore.getUserID(), uid == "zrayyA8BieWLLpuqgJo5g1sBGYw1" {
                        //                        if let uid = firestore.getUserID(), uid == "zrayyA8BieWLLpuqgJo5g1sBGYw2" {
                        EventLogo
                        EventPoster
                        EventWebsite
                    }
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
        .photosPicker(
            isPresented: $showLogoPicker,
            selection: $logoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .photosPicker(
            isPresented: $showPosterPicker,
            selection: $posterItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .quickLookPreview($posterURL)
        //        }
        .toolbar(.hidden, for: .tabBar)
        .scrollDismissesKeyboard(.immediately)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    Button (action: {
                        //                        if hasBeenEdited {
                        if draft.newFestival == oldVersion {
                            navigationPath.removeLast()
                        } else {
                            discardChangesAlert = true
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
                        navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: draft.newFestival, draftView: false, previewView: true, selectedTab: $selectedTab))
                    }, label: {
                        Text("Preview")
                        Image(systemName: "eyes")
                    })
                    if draft.newFestival.published {
                        Button (action: {
                            Task {
                                await saveLocally()
                            }
                            //                            festivalVM.saveDraft(draft.newFestival)
                            //                            navigationPath.removeLast()
                        }, label: {
                            HStack {
                                Text("Save As Draft")
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                            }
                        })
                        if firestore.phoneConnected {
                            Button (action: {
                                Task {
                                    defer { uploadingFestival = false }
                                    await savePublically()
                                }
                            }, label: {
                                Text("Publish Updates")
                                Image(systemName: "globe")
                            })
                            Button (action: {
                                showPublishWithNotificationSheet = true
                            }, label: {
                                Text("Publish & Notify")
                                Image(systemName: "bell")
                            })
                        } else {
                            Button (action: {
                                showLogInSheet = true
                            }, label: {
                                Text("Sign In To Publish")
                                Image(systemName: "person.crop.circle")
                            })
                        }
                    } else {
                        Button (action: {
                            Task {
                                await saveLocally()
                            }
                        }, label: {
                            HStack {
                                Text("Save Privately")
                                Image(systemName: "lock")
                            }
                        })
                        if firestore.phoneConnected {
                            Button (action: {
                                uploadingFestival = true
                                festivalVM.uploadFestival(draft.newFestival) { result in
                                    switch result {
                                    case .success():
                                        ////print("Festival uploaded with merge successfully!")
                                        uploadingFestival = false
                                        navigationPath.removeLast()
                                    case .failure(let error):
                                        print("Upload failed:", error)
                                        uploadingFestival = false
                                    }
                                }
                            }, label: {
                                Text("Publish")
                                Image(systemName: "globe")
                            })
                            Button (action: {
                                showPublishWithNotificationSheet = true
                            }, label: {
                                Text("Publish & Notify")
                                Image(systemName: "bell")
                            })
                        } else {
                            Button (action: {
                                showLogInSheet = true
                            }, label: {
                                Text("Sign In To Publish")
                                Image(systemName: "person.crop.circle")
                            })
                        }
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
            if !festivalVM.isNewFestival(draft.newFestival) {
                singleDayEvent = festivalVM.isSameDay(draft.newFestival.startDate, draft.newFestival.endDate)
            }
            
            //            if let logoPath = draft.newFestival.logoPath {
            //                FestivalViewModel.loadFestivalImage(path: logoPath) { logo in
            //                    if let logo = logo {
            //                        //                , let logo = festivalVM.loadFestivalImage(filePath: logoPath) {
            //                        selectedImage = logo
            //                    }
            //                }
            //            }
            
        }
        .sheet(isPresented: $showArtistSearchPage) {
            if let artist = selectedArtist {
                AddArtistPage(/*navigationPath: $navigationPath, */newArtist: artist, artistImage: artistImages[artist.id], newFestival: $draft.newFestival, showArtistSearchPage: $showArtistSearchPage, lastEditedArtist: lastEditedArtist)
            }
        }
        .sheet(isPresented: $showPublishWithNotificationSheet) {
            PublishWithNotificationsSheet
        }
        .sheet(isPresented: $showLogInSheet) {
//            LogInPage(signInText: true)
            AccountSetUpPage(showSheet: $showLogInSheet)
        }
        .alert(isPresented: $discardChangesAlert) {
            return Alert(title: Text("Discard Changes?"),
                         message: Text("Are you sure you want to leave without saving?"),
                         primaryButton: .destructive(Text("Discard Changes")) {
                if festivalVM.isNewFestival(oldVersion) {
                    festivalVM.deleteEvent(id: oldVersion.id)
                } else {
                    draft.newFestival = oldVersion
                }
                navigationPath.removeLast()
            }, secondaryButton: .cancel()
            )
        }
        
        //        .photosPicker(
        //            isPresented: Binding(
        //                get: { activePicker != nil },
        //                set: { _ in }
        //            ),
        //            selection: $selectedItem,
        //            matching: .images
        //        )
        //        .onChange(of: selectedItem) { newItem in
        //            guard let newItem else { return }
        //
        //            switch activePicker {
        //            case .logo:
        //                Task {
        //                    if let data = try? await newItem.loadTransferable(type: Data.self),
        //                       let uiImage = UIImage(data: data) {
        //                        selectedLogo = uiImage
        //                    }
        //
        //                    activePicker = nil
        //                    selectedItem = nil
        //                }
        //
        //            case .poster:
        //                // Handle poster
        //                activePicker = nil
        //                selectedItem = nil
        //
        //            case nil:
        //                break
        //            }
        //        }
        .onChange(of: draft.newFestival) { _, newVersion in
            festivalVM.saveDraft(newVersion)
        }
        
    }

    func saveLocally() async {
        if let imageToUpload = selectedLogo,
           let logoPath = festivalVM.saveImageForFestival(imageToUpload, festivalID: draft.newFestival.id, previousPath: draft.newFestival.logoPath) {
            draft.newFestival.logoPath = logoPath
        } else if logoDeleted {
            festivalVM.removeImageForFestival(previousPath: draft.newFestival.logoPath)
            draft.newFestival.logoPath = nil
        }
        navigationPath.removeLast()
    }
    
    func savePublically() async {
        uploadingFestival = true
        if let oldPath = oldVersion.logoPath,
           logoDeleted,
           oldPath.hasPrefix("http") {   // ✅ only delete remote images
            _ = await firestore.deleteImageAsync(imageURL: oldPath)
        }
        if logoDeleted {
            draft.newFestival.logoPath = nil
        }
        
        festivalVM.uploadFestival(draft.newFestival) { result in
            switch result {
            case .success():
//                //print("Festival uploaded with merge successfully!")
//                                        uploadingFestival = false
                navigationPath.removeLast()
            case .failure(let error):
                print("Upload failed:", error)
//                                        uploadingFestival = false
            }
        }
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
                                    nameFocused = true
                                }
                        }
                    }
                }
                
            }
            .onAppear() {
                if draft.newFestival.name == "Unnamed Festival" { draft.newFestival.name = "" }
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
                    Toggle(isOn: $singleDayEvent, label: { Text("Single Day Event") }).padding(.vertical, 1).tint(.oasisDarkBlue)
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
                                in: draft.newFestival.startDate...(
                                    Calendar.current.date(
                                        byAdding: .day,
                                        value: 6,
                                        to: draft.newFestival.startDate
                                    ) ?? draft.newFestival.startDate
                                ),
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
            .onChange(of: singleDayEvent) {
                draft.newFestival.endDate = draft.newFestival.startDate
                draft.newFestival.secondWeekend = false
                festivalVM.setSettings(currentFestival: draft.newFestival)
                dismissKeyboard()
            }
            .onChange(of: draft.newFestival.startDate) { _, newDate in
                let maxEndDate = Calendar.current.date(
                    byAdding: .day,
                    value: 6,
                    to: newDate
                ) ?? newDate
                
                if singleDayEvent {
                    draft.newFestival.endDate = newDate
                } else if draft.newFestival.endDate < newDate {
                    draft.newFestival.endDate = newDate
                } else if draft.newFestival.endDate > maxEndDate {
                    draft.newFestival.endDate = maxEndDate
                }
                
                festivalVM.setSettings(currentFestival: draft.newFestival)
            }
            .onChange(of: draft.newFestival.endDate) {
                festivalVM.setSettings(currentFestival: draft.newFestival)
            }
            
//            .onChange(of: draft.newFestival) { _ in
//                if !hasBeenEdited {
//                    hasBeenEdited = true
//                }
//            }
            
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
                                            urlTextFocused = true
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
        .onChange(of: urlText) { _, text in
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
                            .onChange(of: query) { _, newQuery in
                                searchService.update(query: newQuery)
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
                                            locationFocused = true
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
                                        .stroke(.oasisDarkPurple, lineWidth: 1)
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
                                            stageNameFocused = true
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
    @State private var artistSearchResults: [Artist] = []
    @State var artistImages: [String : UIImage] = [:]
    @State private var selectedArtist: Artist? = nil
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
                            .foregroundStyle(Color("OASIS Dark Orange"))
//                            .contentShape(Rectangle())
//                            .onTapGesture() {
//                                navigationPath.append(ArtistEditingList(navigationPath: $navigationPath, newFestival: $draft.newFestival))
//                            }
                            NavigationLink {
                                ArtistEditingList(navigationPath: $navigationPath, newFestival: $draft.newFestival)
                                //                            ArtistEditingList(artistDict: ["Allu Artists" : draft.newFestival.artistList])
                            } label: {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        
                        Divider()
                    }
                    ZStack(alignment: .topLeading) {
                        HStack {
                            ZStack {
                                TextField("Add Artist", text: $artistSearchText)
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
                                                artistSearchFocused = true
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
                                            ArtistImage(imageURL: artist.imageURL, frame: 50)
                                            //                                            ArtistAsyncImage(imageURL: artist.imageURL)
//                                            Group {
//                                                if let image = artistImages[artist.id] {
//                                                    Image(uiImage: image)
//                                                        .resizable()
//                                                        .aspectRatio(contentMode: .fill)
//
//                                                    //                                                        .clipShape(Circle())
//                                                } else {
//                                                    ProgressView()
//                                                }
//                                            }
//                                            .frame(width: 50, height: 50)
                                            Text(artist.name)
                                            Spacer()
                                            Group {
                                                if draft.newFestival.artistList.contains(where: { $0.id == artist.id }) {
                                                    Image(systemName: "pencil.circle")
                                                        .foregroundStyle(Color(.oasisDarkOrange))
                                                } else {
                                                    Image(systemName: "plus.circle")
                                                        .foregroundStyle(Color.blue)
                                                }
                                            }
                                            .imageScale(.large)
                                            .padding(.trailing, 6)
                                        }
                                        .padding(6)
                                        .contentShape(Rectangle())
                                        .onTapGesture() {
                                            if let artistInListIndex = draft.newFestival.artistList.firstIndex(where: { $0.id == artist.id }) {
                                                selectedArtist = draft.newFestival.artistList[artistInListIndex]
                                            } else {
                                                selectedArtist = artist
                                            }
                                            //                                            ////print(artist.id)
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                            //
//                                                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                                                                            showArtistSearchPage = true
//                                                                                        }
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
        .onChange(of: artistSearchResults) { _, searchResults in
            Task {
                for artist in searchResults {
                    if let image = await data.loadArtistImage(artistID: artist.id, imageURL: artist.imageURL) {
                        artistImages[artist.id] = image
                    }
                }
            }
        }
        .onChange(of: selectedArtist) { _, newArtist in
            if newArtist != nil {
                showArtistSearchPage = true
            }
        }
        .onChange(of: showArtistSearchPage) { _, bool in
            if !bool {
                selectedArtist = nil
            }
        }
        .onChange(of: artistSearchText) { _, newValue in
            artistSearchResults.removeAll()
            debounceCancellable?.cancel()
            
            guard !newValue.isEmpty else { return }

            let workItem = DispatchWorkItem {
                fetchAccessTokenAndSearch()
            }
            debounceCancellable = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
        }
        .onChange(of: draft.newFestival.artistList) { _, newList in
            artistSearchText = ""
            artistSearchResults.removeAll()
            let sorted = festivalVM.sortDateModified(currList: newList)[""]!
            lastEditedArtist = sorted.first
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
        spotify.getAppLevelSpotifyToken { token in
            guard let token = token else {
                ////print("No valid token available")
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
                //////print("Error fetching artists: \(error?.localizedDescription ?? "Unknown error")")
                artistSearchIsLoading = false
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(SpotifyViewModel.SpotifySearchResponse.self, from: data)
                let artistsRaw = decoded.artists.items
                
                var results: [Artist] = []
                
                for artist in artistsRaw {
                    let imageUrlString = artist.images.first?.url ?? ""
                    ////print("ARTIST ID: \(artist.id)")
                    
                    let newArtist = Artist(
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
                ////print("Failed to decode response: \(error)")
                artistSearchIsLoading = false
            }
        }.resume()
    }

//    func loadImage(for artist: Artist, completion: @escaping (UIImage?) -> Void) {
//        if let cached = ImageCache.shared.get(for: artist.imageURL) {
//            completion(cached)
//            return
//        }
//
//        // Download the image
//        guard let url = URL(string: artist.imageURL) else {
//            completion(nil)
//            return
//        }
//
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            guard let data = data,
//                  let image = UIImage(data: data) else {
//                completion(nil)
//                return
//            }
//
//            ImageCache.shared.set(image, for: artist.imageURL)
//            completion(image)
//        }.resume()
//    }
    
    
    
    
    
//    @State private var showPhotoPicker = false
//    @State private var selectedItem: PhotosPickerItem?
//    @State var selectedImage: UIImage?
//    
//    @State var logoDeleted = false

    @State private var showPosterPicker = false
    @State private var posterItem: PhotosPickerItem?
//    @State private var selectedPoster: UIImage?
    @State private var selectedPoster: PDFDocument?
    @State private var posterURL: URL?
    
    @State var posterDeleted = false
    
    var EventPoster: some View {
        Group {
            Section(header: Text("Poster")) {
//                let showingPoster = (selectedPoster != nil || (draft.newFestival.posterPath != nil && !posterDeleted))
                Group {
                    if draft.newFestival.posterPath != nil {
                        HStack {
                            Spacer()
                            Text("Show Poster")
                                .foregroundStyle(Color.blue)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    firestore.loadPoster(festivalID: draft.newFestival.id, festivalName: draft.newFestival.name) { result in
                                        switch result {
                                        case .success(let url):
                                            DispatchQueue.main.async {
                                                posterURL = url
                                            }

                                        case .failure(let error):
                                            print(error)
                                        }
                                    }
                                }
                            Spacer()
                            Divider()
                                .frame(height: 25)
                            //                                .padding(.horizontal, 15)
                            Spacer()
                            Text("Remove Poster")
                                .foregroundStyle(Color.red)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    draft.newFestival.posterPath = nil
//                                    posterItem = nil
//                                    selectedPoster = nil
//                                    posterDeleted = true
                                }
                            Spacer()
                        }
                        
                        
                    } else {
                        HStack {
//                            Image(systemName: "plus.circle")
                            Text("Add Poster")
                        }
                            .foregroundStyle(Color.blue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showPosterPicker = true
                            }
                    }
                }
                .frame(height: 20)
            }
        }
        .onChange(of: posterItem) { _, newItem in
            guard let newItem else { return }

            Task {
                guard
                    let data = try? await newItem.loadTransferable(type: Data.self),
                    let image = UIImage(data: data)
                else { return }

                firestore.uploadPoster(image: image, festival: draft.newFestival) { result in
                    switch result {
                    case .success(let updatedFestival):
                        DispatchQueue.main.async {
                            draft.newFestival = updatedFestival
                            posterItem = nil
                        }

                    case .failure(let error):
                        print("Poster upload failed:", error)
                    }
                }
            }
        }
//        .onChange(of: posterItem) { _, newItem in
//            if newItem != nil {
//                Task {
//                    guard let newItem,
//                          let data = try? await newItem.loadTransferable(type: Data.self),
//                          let image = UIImage(data: data)
//                    else { return }
//                    
//                    let url = FileManager.default.urls(
//                        for: .documentDirectory,
//                        in: .userDomainMask
//                    )[0]
//                    .appendingPathComponent("\(draft.newFestival.name) Poster.jpg")
//                    
//                    do {
//                        if let jpegData = image.jpegData(compressionQuality: 0.9) {
//                            try jpegData.write(to: url)
//                            draft.newFestival.posterPath = url.path
//                            posterItem = nil
//                            //                        posterURL = url
//                        }
//                    } catch {
//                        print("Failed writing image:", error)
//                    }
//                }
//            }
//        }
        
//        .onChange(of: posterItem) { newItem in
//            Task {
//                guard let newItem,
//                      let imageData = try? await newItem.loadTransferable(type: Data.self),
//                      let image = UIImage(data: imageData)
//                else { return }
//
//                let renderer = UIGraphicsPDFRenderer(
//                    bounds: CGRect(origin: .zero, size: image.size)
//                )
//
//                let pdfData = renderer.pdfData { context in
//                    context.beginPage()
//                    image.draw(in: CGRect(origin: .zero, size: image.size))
//                }
//
//                selectedPoster = PDFDocument(data: pdfData)
//            }
//        }
//        .onChange(of: posterItem) { newItem in
//            Task {
//                guard let newItem,
//                      let data = try? await newItem.loadTransferable(type: Data.self),
//                      let uiImage = UIImage(data: data)
//                else { return }
//
//                selectedPoster = uiImage
//            }
//        }
//        .onChange(of: selectedLogoItem) { newItem in
//            Task {
//                if let selectedLogoItem, let data = try? await selectedLogoItem.loadTransferable(type: Data.self),
//                   let uiImage = UIImage(data: data) {
//                    selectedImage = uiImage
//                }
//            }
//        }
//        .onChange(of: selectedImage) { newLogo in
//            if let logo = newLogo {
//                Task {
//                    if let path = festivalVM.saveImageForFestival(logo, festivalID: draft.newFestival.id) {
//                        draft.newFestival.logoPath = path
//                    }
//                }
//            } else {
//                draft.newFestival.logoPath = nil
//            }
//        }
    }
    
    
    
    
    
    
    
    
    
//    @State private var showLogoPhotoPicker = false
//    @State private var selectedItem: PhotosPickerItem?
//    @State var selectedLogo: UIImage?
    
    @State private var showLogoPicker = false
    @State private var logoItem: PhotosPickerItem?
    @State private var selectedLogo: UIImage?
    
    @State var logoDeleted = false
    
    var EventLogo: some View {
        Group {
            Section(header: Text("Logo")) {
                let showingLogo = (selectedLogo != nil || (draft.newFestival.logoPath != nil && !logoDeleted))
                VStack {
                    if let selectedLogo {
                        InvertInDarkModeImage(image: selectedLogo, frame: 60, invert: true)
//                        ZStack {
//                            Image(uiImage: selectedLogo)
//                                .resizable()
//                                .scaledToFit()
//                                .frame(maxHeight: 60, alignment: .center)
                                .padding(5)
//                        }
//                        .frame(maxHeight: 60)
                        Divider()
                        //                        .clipShape(Circle())
                    } else if !logoDeleted {
                        if let logoPath = draft.newFestival.logoPath {
                            FestivalLogoView(logoPath: logoPath, title: draft.newFestival.name, frame: 60)
                                .padding(5)
                            Divider()
                        }
                    }
                    HStack {
                        if showingLogo {
                            Spacer()
                        }
                        Text(showingLogo ? "Change Logo" : "Add Logo")
                            .foregroundStyle(Color.blue)
                            .frame(height: 20)
                            .contentShape(Rectangle())
                            .onTapGesture {
//                                activePicker = .logo
                                showLogoPicker = true
                            }
                        if showingLogo {
                            Spacer()
                            Divider()
                                .frame(height: 25)
//                                .padding(.horizontal, 15)
                            Spacer()
                            Text("Remove Logo")
                                .foregroundStyle(Color.red)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    logoItem = nil
                                    selectedLogo = nil
                                    logoDeleted = true
                                }
//                                .padding(.leading, 20)
                                .padding(.vertical, 5)
                        }
                        Spacer()
                    }
                }
            }
        }
        
        .onChange(of: logoItem) { _, newItem in
            Task {
                guard let newItem,
                      let data = try? await newItem.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data)
                else { return }

                selectedLogo = uiImage
            }
        }
        
//        .onChange(of: selectedImage) { newLogo in
//            if let logo = newLogo {
//                Task {
//                    if let path = festivalVM.saveImageForFestival(logo, festivalID: draft.newFestival.id) {
//                        draft.newFestival.logoPath = path
//                    }
//                }
//            } else {
//                draft.newFestival.logoPath = nil
//            }
//        }
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
    
    
    
    
    
    
    
    
    
    
    var PublishWithNotificationsSheet: some View {
        VStack {
            NavigationButtons
            Text("Publish With Notifications").font(.title2).padding()
            ScrollView {
                TitleText
                MessageText
                NotifyOtherFestivals
                //            Spacer()
            }
        }
        .onChange(of: selectedFestivals) { _, newSet in
            print("FESTIVALS TO NOTIFY: \(newSet)")
        }
    }
    
    var NavigationButtons: some View {
        Group {
            HStack {
                Button(action: {
                    showPublishWithNotificationSheet = false
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                })
                Spacer()
                Button(action: {
                    
                        Task {
                            defer {
                                uploadingFestival = false
                                showPublishWithNotificationSheet = false
                            }
                            await savePublically()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
                                firestore.sendFestivalNotification(festivalID: draft.newFestival.id,
                                                                   title: title,
                                                                   body: message,
                                                                   festivalsToNotify: selectedFestivals)
                            }
                        }
//                        testPushNotification()
//                    }
                    
                }, label: {
                    Group {
                        Text("Publish")
                    }
//                    .foregroundStyle(isGenreLoading ? .gray : .blue)
                })
//                .disabled(isGenreLoading)
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            Divider()
        }
    }
    
    @State private var title = ""
    let MAX_TITLE_COUNT = 30
    
    
    var TitleText: some View {
        HStack(spacing: 0) {
            Text("Title: ").bold()
            Text(title)
            Spacer()
        }
        .font(.system(size: 17))
        .padding(.vertical, 4)
        .padding(.horizontal, 24)
        .onAppear {
            let festNameAndYear = festivalVM.getFestiTitleWithYear(name: draft.newFestival.name, startDate: draft.newFestival.startDate)
            if draft.newFestival.published {
                title = "\(festNameAndYear) Updates!"
            } else {
                title = "\(festNameAndYear) Lineup Released!"
            }
        }
    }
    
    
    var TitleTextEditable: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Text("Title")
                    .font(.system(size: 17))
                Spacer()
            }
            .padding(.horizontal, 4)
            
            TextField("Name", text: $title)
//                .frame(height: 40)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: title) {
                    if title.count > MAX_TITLE_COUNT {
                        title = String(message.prefix(MAX_TITLE_COUNT))
                    }
                }
                
            HStack {
                let charCountRemaining = MAX_TITLE_COUNT - title.count
                Spacer()
                Text("\(charCountRemaining)")
                    .foregroundStyle(charCountRemaining == 0 ? .red : .gray)
            }
            .padding(.horizontal, 4)
            
        }
        .padding(.horizontal, 20)
    }
    
    
    @State private var message = ""
    let MAX_MESSAGE_COUNT = 80
    
    @FocusState private var messageFocused: Bool
    
    var MessageText: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Text("Message:")
                    .font(.system(size: 17))
                    .bold()
                Spacer()
            }
            .padding(.horizontal, 4)
            
            ZStack(alignment: .topLeading) {
                DismissOnReturnTextEditor(
                    text: $message,
                    isFocused: $messageFocused
                )
                .frame(height: 60)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onChange(of: message) {
                    if message.count > MAX_MESSAGE_COUNT {
                        message = String(message.prefix(MAX_MESSAGE_COUNT))
                    }
                }
//                TextEditor(text: $message)
////                    .submitLabel(.done)
//                    .frame(height: 60)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .clipShape(RoundedRectangle(cornerRadius: 12))
//                    .onChange(of: message) {
//                        if message.count > MAX_MESSAGE_COUNT {
//                            message = String(message.prefix(MAX_MESSAGE_COUNT))
//                        }
//                    }
//                    .focused($messageFocused)
//                    .toolbar {
//                        ToolbarItemGroup(placement: .keyboard) {
//                            Spacer()
//
//                            Button {
//                                messageFocused = false
//                            } label: {
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    }
                if message.isEmpty {
                    Group {
                        if draft.newFestival.published {
                            Text("Describe Your Updates")
                        }
//                        else {
//                            Text("Promo")
//                        }
                    }
                    .foregroundStyle(.gray)
                    .opacity(0.9)
                    .padding(25)
                }
            }
            
            HStack {
                let charCountRemaining = MAX_MESSAGE_COUNT - message.count
                Spacer()
                Text("\(charCountRemaining)")
                    .foregroundStyle(charCountRemaining == 0 ? .red : .gray)
            }
            .padding(.horizontal, 4)
            
        }
        .padding(.horizontal, 20)
        .onAppear {
            if draft.newFestival.published {
                message = ""
            } else {
                message = getMessageText()
            }
            
        }
    }
    
    func getMessageText() -> String {
        let tierLabels = ["Headliner", "First Tier", "Second Tier", "Third+ Tier"]
        
        let dayOrder: [String: Int] = [
            "Tuesday": 0,
            "Wednesday": 1,
            "Thursday": 2,
            "Friday": 3,
            "Saturday": 4,
            "Sunday": 5,
            "Monday": 6
        ]
        
        func parseDay(_ str: String) -> (dayIndex: Int, weekendIndex: Int) {
            let components = str.components(separatedBy: " (")
            let dayName = components.first?.trimmingCharacters(in: .whitespaces) ?? ""
            let dayIndex = dayOrder[dayName] ?? Int.max
            
            var weekendIndex = 0
            
            if str.contains("Weekend 1") {
                weekendIndex = 1
            } else if str.contains("Weekend 2") {
                weekendIndex = 2
            }
            
            return (dayIndex, weekendIndex)
        }
        
        func compareDays(_ artist1: Artist, _ artist2: Artist) -> Bool {
            let d1 = parseDay(artist1.day)
            let d2 = parseDay(artist2.day)
            
            if d1.weekendIndex != d2.weekendIndex {
                return d1.weekendIndex < d2.weekendIndex
            }
            
            if d1.dayIndex != d2.dayIndex {
                return d1.dayIndex < d2.dayIndex
            }
            
            return artist1.name.localizedCaseInsensitiveCompare(artist2.name) == .orderedAscending
        }
        
        // First sort everything by tier.
        let tierSorted = draft.newFestival.artistList.sorted {
            let tier1 = tierLabels.firstIndex(of: $0.tier) ?? tierLabels.count
            let tier2 = tierLabels.firstIndex(of: $1.tier) ?? tierLabels.count
            
            return tier1 != tier2
                ? tier1 < tier2
                : $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
        
        // Build the final list, prioritizing different days within each tier.
        var sortedArtists: [Artist] = []
        
        for tier in tierLabels + ["-- N/A --"] {
            let artistsInTier = tierSorted.filter { $0.tier == tier }
            
            var remaining = artistsInTier
            
            while !remaining.isEmpty {
                // Prefer an artist whose day hasn't already been used in this tier.
                let usedDays = Set(sortedArtists
                    .filter { $0.tier == tier }
                    .map { $0.day })
                
                let differentDayArtist = remaining
                    .filter { !usedDays.contains($0.day) }
                    .sorted(by: compareDays)
                    .first
                
                if let artist = differentDayArtist {
                    sortedArtists.append(artist)
                    remaining.removeAll { $0.id == artist.id }
                } else {
                    // All remaining artists share a day, so sort alphabetically.
                    sortedArtists.append(contentsOf: remaining.sorted {
                        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    })
                    break
                }
            }
        }
        
        let topArtists = Array(sortedArtists.prefix(3))
        let names = topArtists.map { $0.name }
        
        switch names.count {
        case 0:
            return ""
        case 1:
            return "\(names[0]), and more!"
        case 2:
            return "\(names[0]), \(names[1]), and more!"
        default:
            return "\(names[0]), \(names[1]), \(names[2]), and more!"
        }
    }
    
    
    
    
    
    @State var selectedFestivals = Set<UUID>()
    
    @State var myFestivals: [Festival] = []
    @State var myFestivalsLoading = false
    
    var NotifyOtherFestivals: some View {
        Group {
            SelectedFestivals(festivalList: myFestivals, selectedFestivals: $selectedFestivals, title: "Notify Your Other Festivals:", fontSize: 17, isLoading: myFestivalsLoading)
                .padding(8)
        }
        .task {
            myFestivalsLoading = true
            defer { myFestivalsLoading = false }

            do {
                myFestivals = try await firestore.getMyFestivals()
                    .filter { $0.id != draft.newFestival.id }
                    .sorted {
                        if $0.startDate == $1.startDate {
                            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                        }
                        return $0.startDate > $1.startDate
                    }
            } catch {
                print("Error fetching my festivals: \(error)")
            }
        }
    }
    
    
    
    func testPushNotification() {
        Functions.functions()
            .httpsCallable("testPushNotification")
            .call { result, error in
                if let error {
                    print("❌ Push test failed:", error.localizedDescription)
                    return
                }

                print("✅ Push test response:", result?.data ?? "nil")
            }
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
//                ////print("Error fetching artists: \(error?.localizedDescription ?? "Unknown error")")
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
//                            ////print("Failed to load image for artist \(artist.name)")
//                            return
//                        }
//                        ////print("ARTIST ID: \(artist.id)")
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
//                ////print("Failed to decode response: \(error)")
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
        ////print("Search failed: \(error.localizedDescription)")
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

//class ImageCache: ObservableObject {
//    static let shared = ImageCache()
//    
//    private init() {}
//    
//    private var cache: [String: UIImage] = [:]
//    
//    func get(for url: String) -> UIImage? {
//        return cache[url]
//    }
//    
//    func set(_ image: UIImage, for url: String) {
//        cache[url] = image
//    }
//}


//#Preview {
//    NewEventPage()
//}



//TO ADD TO ON APPEAR:

struct DismissOnReturnTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.font = .preferredFont(forTextStyle: .body)
        textView.backgroundColor = .white
        textView.returnKeyType = .done

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }

//        if isFocused.wrappedValue && !textView.isFirstResponder {
//            textView.becomeFirstResponder()
//        } else if !isFocused.wrappedValue && textView.isFirstResponder {
//            textView.resignFirstResponder()
//        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: DismissOnReturnTextEditor

        init(_ parent: DismissOnReturnTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText text: String
        ) -> Bool {

            if text == "\n" {
                parent.isFocused.wrappedValue = false
                textView.resignFirstResponder()
                return false
            }

            return true
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = false
        }
    }
}
