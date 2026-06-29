//
//  TagCreationPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/31/25.
//

import SwiftUI

struct NewTagSheet: View {
    @EnvironmentObject var data: DataSet
//    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
//    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var tags: TagViewModel
    
    @State var editingTag: ArtistTag
    @Binding var binding: ArtistTag?
    
    let currentFestival: Festival
    
    @Binding var selectedTags: Set<UUID>
    
//    @Environment(\.dismiss) private var dismiss
//    @Binding var showSheet: Bool
    
    @State var navigationPath = NavigationPath()

    
    var body: some View {
        Group {
            NavigationStack(path: $navigationPath) {
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
                .onAppear {
                    nameFocused = true
                    //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    //                self.editingTag = editingTag
                    //            }
                }
                .navigationDestination(for: String.self) { value in
                    switch value {
                    default:
                        AddArtistsToTagSheet(navigationPath: $navigationPath, currentFestival: currentFestival, currentTag: editingTag, binding: $binding)
                    }
                }
            }
        }
        
    }
    
    var NewTagSheetCancelButton: some View {
        Button {
            binding = nil
//            dismiss()
//            showSheet = false
//            showAddTagSheet = false
        } label: {
            Text("Cancel")
                .foregroundStyle(.red)
        }
        .contentShape(Rectangle())
    }
    
    var NewTagSheetAddButton: some View {
        Group {
            if tags.tagAlreadyExists(tagID: editingTag.id, festivalID: currentFestival.id) {
                Button {
                    tags.addTag(tag: editingTag, festivalID: currentFestival.id)
                    selectedTags.insert(editingTag.id)
                    binding = nil
                } label: {
                    Text("Save")
                }
                .contentShape(Rectangle())
            } else {
                Button {
                    navigationPath.append("Next")
                } label: {
                    Text("Next")
                }
                .contentShape(Rectangle())
            }
        }
        .foregroundStyle(editingTag.name.isEmpty ? .gray : .blue)
        .disabled(editingTag.name.isEmpty)
        
        
//        Button {
//            tags.addTag(tag: editingTag, festivalID: currentFestival.id)
////            if selectedTags != nil {
//                selectedTags.insert(editingTag.id)
//                dismiss()
////            } else {
////                
////            }
//            
//            
////            showAddTagSheet = false
//                
//        } label: {
////            let tagAlreadyExists = tags.tagAlreadyExists(tagID: editingTag.id, festivalID: currentFestival.id)
//            Group {
////                if selectedTags != nil {
//                    Text(tags.tagAlreadyExists(tagID: editingTag.id, festivalID: currentFestival.id) ? "Save" : "Add")
////                } else {
////                    Text("Next")
////                }
//            }
//                .foregroundStyle(editingTag.name.isEmpty ? .gray : .blue)
//        }
        
    }
    
    @State var deleteAlert = false
    
    var DeleteButton: some View {
        HStack {
            Spacer()
            if tags.tagAlreadyExists(tagID: editingTag.id, festivalID: currentFestival.id) {
//            if tags.festivalTags[currentFestival.id]?.keys.contains(editingTag.id) {
//            if tags.myTags.contains(where: { $0.id == editingTag.id }) {
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
                tags.removeTag(tag: editingTag, festivalID: currentFestival.id)
                binding = nil
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
        "wineglass", "leaf", "snowflake", "headphones"
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
                            .autocapitalization(.words)
                        
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
        .onChange(of: nameFocused) { _, newFocus in
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









struct AddArtistsToTagSheet: View {
    
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var tags: TagViewModel
    
    @Binding var navigationPath: NavigationPath
    
    let currentFestival: Festival
    
    @State var artistDict: [String : Array<Artist>] = [:]
//    @State var viewSubsection = Array<Bool>()
//    @State var reverse = false
    
    @State var sortType: DataSet.sortType = .alpha
    
    
    
//    @State var showArtistSearchPage = false
//    @State private var selectedArtist: Artist? = nil
//    @State private var
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    @State var selectedArtists = Set<String>()
    
    var titleText: String? = ""
    
//    @State var sectionBools = [String : Bool]()
//    @State var artistBools = [String : Bool]()
    @State var showSections = [String : Bool]()
    
//    @Environment(\.dismiss) private var dismiss
    var currentTag: ArtistTag
    @Binding var binding: ArtistTag?
    
    var body: some View {
        Group {
            if currentFestival.artistList.isEmpty {
                HStack {
                    Spacer()
                    Text("Artist List is empty.")
                    Spacer()
                }
            } else {
                if searchText.isEmpty {
                    Form {
                        Section(header: HStack(spacing: 0) {
                            Text("Add ")
                            HStack(spacing: 4) {
                                Image(systemName: currentTag.symbol)
                                Text(currentTag.name)
                            }
                            .foregroundStyle(COLOR_SPECTRUM_ARRAY[currentTag.color])
                            Text(" to Artists")
                            Spacer()
                            SortMenu(sortType: $sortType, currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend, editing: false)
                        }) {
                            ForEach(Array(data.getDictKeysSorted(currDict: artistDict, sort: sortType).enumerated()), id: \.element) { i, section in
                                //            ForEach(Array(data.getSortLables(sort: sortType).enumerated()), id: \.element) { i, section in
                                if let artistList = artistDict[section] {
                                    HStack {
                                        Button(action: {
                                            self.toggleSection(section: section, sectionList: artistList)
                                        }, label: {
                                            HStack {
//                                                Image(systemName: sectionBools[section] == true ? "checkmark.square.fill" : "square")
                                                Image(systemName: checkSection(sectionList: artistList) ? "checkmark.square.fill" : "square")
                                                    .foregroundColor(Color("OASIS Dark Orange"))
                                                    .imageScale(.large)
                                                Group {
                                                    if sortType == .alpha {
                                                        if let text = titleText { Text("All \(text) Artists") }
                                                        else { Text("All Artists") }
                                                    } else {
                                                        Text(section)
                                                    }
                                                }
                                                .foregroundStyle(Color("BW Color Switch"))
                                                Spacer()
                                            }
                                        })
                                        Spacer()
                                        Image(systemName: "chevron.down").rotationEffect(showSections[section]! ? Angle(degrees: 180) : Angle(degrees: 0))
                                        //                        Image(systemName: showSections[section]! ? "chevron.up" : "chevron.down")
                                            .onTapGesture(perform: {
                                                withAnimation {
                                                    showSections[section]!.toggle()
                                                }
                                            })
                                    }
                                    if showSections[section]! {
                                        ForEach(Array(artistList.enumerated()), id: \.element) { j, artist in
                                            HStack {
                                                Button(action: {
                                                    if selectedArtists.contains(artist.id) {
                                                        selectedArtists.remove(artist.id)
                                                    } else {
                                                        selectedArtists.insert(artist.id)
                                                    }
                                                    //                                    print(artist)
                                                    //                                    print(artistBools)
//                                                    artistBools[artist.id]!.toggle()
                                                    //                                    print(artistBools)
                                                    
                                                    //                                artistBools[artist.id] = !artistBools[artist.id]
                                                }, label: {
                                                    Image(systemName: selectedArtists.contains(artist.id) ? "checkmark.square.fill" : "square")
                                                        .foregroundColor(Color("OASIS Light Orange"))
                                                        .imageScale(.large)
                                                })
//                                                ArtistImage(imageURL: artist.imageURL, frame: 30)
                                                Text(artist.name)
                                            }
                                        }
                                        .padding(.leading, 25)
                                    }
                                }
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                tags.addTag(tag: currentTag, festivalID: currentFestival.id)
                                tags.addArtistsToTag(tagID: currentTag.id, artistIDs: selectedArtists)
//                                dismiss()
                                binding = nil
                            } label: {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                            
//                            .background(.blue)
                        }
                    }
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
//                    EmptyView()
//                    Section(header: Group {
//                        HStack {
//                            Text("Add TAG to Artists").bold()
//                            Spacer()
//                            SortMenu(sortType: $sortType, currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend, editing: false)
//                        }
//                        .padding(.horizontal)
////                    }) {
//                    Form {
//                        ForEach(Array(data.getDictKeysSorted(currDict: artistDict, sort: sortType).enumerated()), id: \.element) { i, section in
//                            if let artistArray = artistDict[section] {
//                                if !artistArray.isEmpty /*&& (sortType != .genre || artistArray.count > 1)*/  {
//                                    
//                                    //                                    EmptyView()
//                                    Section(header: Group {
//                                        if sortType != .alpha {
//                                            HStack {
//                                                Text(section)
//                                                Image(systemName: "chevron.down").rotationEffect(viewSubsection[i] ? Angle(degrees: 180) : Angle(degrees: 0))
//                                                Spacer()
//                                            }
//                                            .contentShape(Rectangle())
//                                            .onTapGesture(perform: {
//                                                withAnimation {
//                                                    viewSubsection[i] = !viewSubsection[i]
//                                                }
//                                            })
//                                        }
//                                    }) {
//                                        //                                .padding(.horizontal, 20)
//                                        //                                        .padding(.bottom, 3)
//                                        //                                        .padding(.top, 0)
//                                        //                                        .font(.headline)
//                                        //                                    .listRowBackground(Color("Same As Background"))
//                                        //                                    }
//                                        if viewSubsection[i] {
//                                            ForEach(artistArray, id: \.self) { artist in
//                                                HStack {
//                                                    ArtistImage(imageURL: artist.imageURL, frame: 40)
//                                                    Text(artist.name)
//                                                    Spacer()
//                                                    Image(systemName: selectedArtists.contains(artist.id) ? "checkmark.square.fill" : "square")
//                                                        .foregroundColor(Color("OASIS Dark Orange"))
//                                                        .imageScale(.large)
//                                                }
//                                                .contentShape(Rectangle())
//                                                .onTapGesture() {
//                                                    if selectedArtists.contains(artist.id) {
//                                                        selectedArtists.remove(artist.id)
//                                                    } else {
//                                                        selectedArtists.insert(artist.id)
//                                                    }
//                                                }
//                                            }
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .toolbar {
//                        ToolbarItem(placement: .topBarTrailing) {
//                            Button {
//                                dismiss()
//                            } label: {
//                                Image(systemName: "checkmark")
//                            }
//                            .foregroundStyle(.blue)
////                            .background(.blue)
//                        }
//                    }
                } else {
                    SearchResults
                }
            }
        }
        .onAppear() {

            artistDict = festivalVM.getArtistDict(currList: currentFestival.artistList, sort: sortType, secondWeekend: currentFestival.secondWeekend, checkSettingsBool: false)
//            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
            initializeCheckBoxes()
//            print(navigationPath)
        }
//        .sheet(isPresented: $showArtistSearchPage) {
//            if let artist = selectedArtist {
//                AddArtistPage(newArtist: artist, newFestival: $newFestival, showArtistSearchPage: $showArtistSearchPage)
//            }
//        }
//        .onChange(of: selectedArtist) { newArtist in
//            if newArtist != nil {
//                showArtistSearchPage = true
//            }
//        }
//        .onChange(of: showArtistSearchPage) { bool in
//            if !bool {
//                selectedArtist = nil
//                artistDict = festivalVM.getArtistDict(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend, checkSettingsBool: false)
//            }
//        }
        .onChange(of: sortType) { _, newSort in
            artistDict = festivalVM.getArtistDict(currList: currentFestival.artistList, sort: newSort, secondWeekend: currentFestival.secondWeekend, checkSettingsBool: false)
//            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
            changeSectionBool()
//            reverse = false
        }
        
//        .toolba
//        .onChange(of: newFestival.artistList) { newList in
//            print("CHANGING")
//            if newList.isEmpty { navigationPath.removeLast() }
//        }
//        .navigationBarItems(trailing:
//                                HStack {
//            SortMenu(sortType: $sortType, currList: newFestival.artistList, secondWeekend: newFestival.secondWeekend, editing: true)
//        })
//        .navigationTitle("Add tag to Artists")
//        .searchable(text: $searchText)
        .if(!currentFestival.artistList.isEmpty) {
            $0.searchable(text: $searchText)
        }
    }
    
    func initializeCheckBoxes() {
        for (key, _) in artistDict {
//            sectionBools[key] = false
            showSections[key]  = true
            selectedArtists = Set<String>()
//            for artist in list {
//                artistBools[artist.id] = false
//            }
        }
    }
    
    func toggleSection(section: String, sectionList: Array<Artist>) {
        if checkSection(sectionList: sectionList) {
            selectedArtists.subtract(sectionList.map(\.id))
            
        } else {
            selectedArtists.formUnion(sectionList.map(\.id))
        }
        
        
        
//        let boolValue = !checkSection(sectionList: sectionList)
////        sectionBools[section] = boolValue
//        
//        for artist in artistDict[section]! {
//            artistBools[artist.id]! = boolValue
//        }
    }
    
    func checkSection(sectionList: Array<Artist>) -> Bool {
        for artist in sectionList {
            if !selectedArtists.contains(artist.id) {
                return false
            }
        }
        return true
    }
    
//    func anyArtistChecked() -> Bool {
//        for (_, bool) in artistBools {
//            if bool {
//                return true
//            }
//        }
//        return false
//    }
    
    func changeSectionBool() {
//        sectionBools.removeAll()
        showSections.removeAll()
        let lables = artistDict.keys
//        let lables = data.getSortLables(sort: sortType)
        for lable in lables {
//            sectionBools[lable] = isSubsectionChecked(section: lable)
            showSections[lable] = true
        }
    }
    
//    func isSubsectionChecked(section: String) -> Bool {
//        if let subsectionList = artistDict[section] {
//            for artist in subsectionList {
//                if artistBools[artist.id]! {
//                    return true
//                }
//            }
//        }
//        return false
//    }
    
    var SearchResults: some View {
        Group {
            //            List {
            let searchList = searchArtists()
            if !searchList.isEmpty {
                //                    Divider().padding(.horizontal, 20)
                //                    ScrollView {
                Form {
                    ForEach(searchList, id: \.self) { artist in
                        HStack {
                            Button(action: {
                                if selectedArtists.contains(artist.id) {
                                    selectedArtists.remove(artist.id)
                                } else {
                                    selectedArtists.insert(artist.id)
                                }
                            }, label: {
                                Image(systemName: selectedArtists.contains(artist.id) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(Color("OASIS Light Orange"))
                                    .imageScale(.large)
                            })
                            Text(artist.name)
                        }
                    }
                }
            } else {
                Text("No Results")
                    .font(.subheadline)
            }
            //            }
        }
    }
    
    func searchArtists() -> Array<Artist> {
        var artistSearchList = Array<Artist>()
        for a in currentFestival.artistList {
            if a.name.lowercased().starts(with: searchText.lowercased()) || a.name.lowercased().contains(String(" " + searchText.lowercased())) {
                artistSearchList.append(a)
                artistSearchList.sort {
                    $0.name.lowercased() < $1.name.lowercased()
                }
            }
        }
        return artistSearchList
    }
}

