//
//  ArtistEditingList.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/4/25.
//

import SwiftUI

struct ArtistEditingList: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @Binding var newFestival: DataSet.Festival
    
    
    @State var artistDict: [String : Array<DataSet.Artist>] = [:]
    @State var viewSubsection = Array<Bool>()
    @State var reverse = false
    
    @State var sortType: DataSet.sortType = .addDate
    
    @State var showArtistSearchPage = false
    @State private var selectedArtist: DataSet.Artist? = nil
//    @State private var
    
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        List {
//            ScrollView {
            if searchText.isEmpty {
                ForEach(Array(data.getDictKeysSorted(currDict: artistDict, sort: sortType).enumerated()), id: \.element) { i, section in
                    if let artistArray = artistDict[section] {
                        if !artistArray.isEmpty /*&& (sortType != .genre || artistArray.count > 1)*/  {
                            if sortType != .alpha {
                                Group {
                                    if sortType == .addDate || sortType == .modifyDate {
                                        HStack {
                                            Text(reverse ? "Most Recent Last" : "Most Recent First")
                                            Image(systemName: "arrow.up.arrow.down")
                                            Spacer()
                                        }
                                        .onTapGesture(perform: {
                                            reverse.toggle()
                                            artistDict = festivalVM.reverseArtistDict(currDict: artistDict)
                                        })
                                    } else {
                                        HStack {
                                            Text(section)
                                            Image(systemName: viewSubsection[i] ? "chevron.up" : "chevron.down")
                                            Spacer()
                                        }
                                        .onTapGesture(perform: {
                                            viewSubsection[i] = !viewSubsection[i]
                                        })
                                    }
                                }
//                                .padding(.horizontal, 20)
                                .padding(.bottom, 3)
                                .padding(.top, 0)
                                .font(.headline)
                                .listRowBackground(Color("Same As Background"))
                                
//                                .listRowBackground(Color)
                            }
                            if viewSubsection[i] {
                                    ForEach(artistArray, id: \.self) { artist in
                                        HStack {
                                            ArtistImage(imageURL: artist.imageURL, frame: 40)
                                            Text(artist.name)
                                            Spacer()
                                            Image(systemName: "square.and.pencil")
                                                .imageScale(.large)
                                                .foregroundStyle(Color("OASIS Dark Orange"))
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture() {
                                            selectedArtist = artist
                                        }
                                    }
                                    .onDelete(perform: delete)
//                                }
                            }
                        }
                    }
                }
            } else {
                SearchResults
            }
        }
        .onAppear() {
            artistDict = festivalVM.getArtistDict(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
        }
        .sheet(isPresented: $showArtistSearchPage) {
            if let artist = selectedArtist {
                AddArtistPage(newArtist: artist, newFestival: $newFestival, showArtistSearchPage: $showArtistSearchPage)
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
                artistDict = festivalVM.getArtistDict(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
            }
        }
        .onChange(of: sortType) { newSort in
            artistDict = festivalVM.getArtistDict(currList: newFestival.artistList, sort: newSort, secondWeekend: newFestival.secondWeekend)
            viewSubsection = Array(repeating: true, count: artistDict.keys.count)
            reverse = false
        }
        .navigationBarItems(trailing: HStack {
            SortMenu(sortType: $sortType, currList: newFestival.artistList, secondWeekend: newFestival.secondWeekend, editing: true)
        })
        .navigationTitle("\(newFestival.name) Artist List")
        .searchable(text: $searchText)
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let artistID = artistDict["All Artists"]![index].id
            newFestival.artistList.removeAll { $0.id == artistID }
        }
        artistDict = festivalVM.getArtistDict(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
    }
    
    var SearchResults: some View {
        Group {
//            List {
                let searchList = searchArtists()
                if !searchList.isEmpty {
//                    Divider().padding(.horizontal, 20)
//                    ScrollView {
                        ForEach(searchList, id: \.self) { artist in
                            HStack(alignment: .center) {
                                ArtistImage(imageURL: artist.imageURL, frame: 40)
                                Text(artist.name)
                                Spacer()
                                Image(systemName: "square.and.pencil")
                                    .imageScale(.large)
                                    .foregroundStyle(Color("OASIS Dark Orange"))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture() {
                                selectedArtist = artist
                            }
                        }
                        .onDelete(perform: delete)
//                    }
                } else {
                    Text("No Results")
                        .font(.subheadline)
                }
//            }
        }
    }
    
    
    func searchArtists() -> Array<DataSet.Artist> {
        var artistSearchList = Array<DataSet.Artist>()
        for a in newFestival.artistList {
            if a.name.lowercased().starts(with: searchText.lowercased()) || a.name.lowercased().contains(String(" " + searchText.lowercased())) {
                artistSearchList.append(a)
                artistSearchList.sort {
                    $0.name.lowercased() < $1.name.lowercased()
                }
            }
        }
        return artistSearchList
    }
    
    
//    var SortMenuOLD: some View {
//        Group {
//            let dayBool = festi.listHasDays(currList: newFestival.artistList)
//            let genreBool = data.listHasGenres(currList: newFestival.artistList)
//            let stageBool = data.listHasStages(currList: newFestival.artistList)
//            let tierBool = data.listHasTiers(currList: newFestival.artistList)
//            
//            
//            //            if dayBool || genreBool || stageBool || tierBool {
//            Menu(content: {
//                //View by Alphabetically
//                Button (action: {
//                    sortType = .alpha
//                    artistDict = data.getArtistDictFromListNEW(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
//                    viewSubsection = Array(repeating: true, count: artistDict.keys.count)
//                }, label: {
//                    HStack {
//                        Text("Sort Alphabetically")
//                        if sortType == .alpha {
//                            Spacer()
//                            Image(systemName: "checkmark")
//                        }
//                    }
//                })
//                
//                //View by Day
//                if dayBool {
//                    Button (action: {
//                        sortType = .day
//                        artistDict = data.getArtistDictFromListNEW(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
//                        viewSubsection = Array(repeating: true, count: artistDict.keys.count)
//                    }, label: {
//                        HStack {
//                            Text("Sort by Day")
//                            if sortType == .day {
//                                Spacer()
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    })
//                }
//                
//                //View by Genre
//                if genreBool {
//                    Button (action: {
//                        sortType = .genre
//                        artistDict = data.getArtistDictFromListNEW(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
//                        viewSubsection = Array(repeating: true, count: artistDict.keys.count)
//                    }, label: {
//                        HStack {
//                            Text("Sort by Genre")
//                            if sortType == .genre {
//                                Spacer()
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    })
//                }
//                
//                //View by Stage
//                if stageBool {
//                    Button (action: {
//                        sortType = .stage
//                        artistDict = data.getArtistDictFromListNEW(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
//                        viewSubsection = Array(repeating: true, count: artistDict.keys.count)
//                    }, label: {
//                        HStack {
//                            Text("Sort by Stage")
//                            if sortType == .stage {
//                                Spacer()
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    })
//                }
//                
//                //View by Tier
//                if tierBool {
//                    Button (action: {
//                        sortType = .billing
//                        artistDict = data.getArtistDictFromListNEW(currList: newFestival.artistList, sort: sortType, secondWeekend: newFestival.secondWeekend)
//                        viewSubsection = Array(repeating: true, count: artistDict.keys.count)
//                    }, label: {
//                        HStack {
//                            Text("Sort by Tier")
//                            if sortType == .billing {
//                                Spacer()
//                                Image(systemName: "checkmark")
//                            }
//                        }
//                    })
//                }
//            }, label: {
//                Group {
//                    Image(systemName: "list.bullet")
//                }
//            })
//        }
//    }
}

//#Preview {
//    ArtistEditingList()
//}
