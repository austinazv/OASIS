//
//  MyFestivalsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI

struct ExploreFestivalsPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @StateObject private var explore = ExploreViewModel()
    
    @State private var navigationPath = NavigationPath()
    
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                //                ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Text("Explore")
                            .font(.title)
                            .bold()
                        Spacer()
                        //                            NavigationLink(value: "New Event") {
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .contentShape(Rectangle())
                        
                        //                            }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                    Divider()
                    ZStack {
                        Color(red: 235/255, green: 230/255, blue: 245/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                        if explore.isLoading {
                            Spacer()
                            ProgressView()
                                .foregroundStyle(.black)
                            Spacer()
                        } else {
                            ScrollView {
                                FestivalsListed(navigationPath: $navigationPath, festivalList: explore.festivals, title: "Verified", collapsable: true)
                            }
                            .padding(.top, 5)
                            .refreshable {
                                explore.fetchVerifiedFestivals()
                            }
                        }
                    }
                    
                }
                .navigationDestination(for: DataSet.Festival.self) { festival in
                    FestivalPage(navigationPath: $navigationPath, /*festivalVM: festivalVM,*/ currentFestival: festival)
                        .environmentObject(festivalVM)
                }
                .navigationDestination(for: FestivalViewModel.FestivalNavTarget.self) { navTarget in
                    if navTarget.draftView {
                        NewEventPage(festival: navTarget.festival, /*festivalCreator: festivalVM,*/ /*festivalList: $festivalDrafts, */navigationPath: $navigationPath)
                            .environmentObject(festivalVM)
                    } else {
                        FestivalPage(navigationPath: $navigationPath, /*festivalVM: festivalVM,*/ currentFestival: navTarget.festival, previewView: navTarget.previewView)
                            .environmentObject(festivalVM)
                    }
                }
                .navigationDestination(for: DataSet.ArtistListStruct.self) { page in
                    //                        ArtistList(currDict: data.list, titleText: data.title, sortType: .alpha, subsectionLen: 1)
                    ArtistList(navigationPath: $navigationPath, titleText: page.titleText, artistList: page.list)
                        .environmentObject(festivalVM)
                }
                .navigationDestination(for: DataSet.ArtistPageStruct.self) { page in
                    ArtistPage(currentArtist: page.artist,
                               shuffleLable: page.shuffleTitle,
                               shuffleList: page.shuffleList,
                               navigationPath: $navigationPath
                    )
                    .environmentObject(festivalVM)
                }
                
                
                
                
                //                    .navigationDestination(for: DataSet.ArtistListStruct.self) { page in
                ////                        ArtistList(currDict: data.list, titleText: data.title, sortType: .alpha, subsectionLen: 1)
                //                        ArtistList(navigationPath: $navigationPath, currList: page.list, titleText: page.titleText, currentFestival: page.festival)
                //                    }
                //                    .navigationDestination(for: DataSet.ArtistPageStruct.self) { page in
                //                        ArtistPage(currentArtist: page.artist,
                //                                   shuffleLable: page.shuffleTitle,
                //                                   shuffleList: page.shuffleList,
                //                                   navigationPath: $navigationPath
                //                        )
                //                    }
                //                    .navigationDestination(for: DataSet.artistNEW.self) { artist in
                //                        ArtistPage(currentArtist: artist, includeFavorites: true)
                //                    }
                .navigationDestination(for: String.self) { value in
                    switch(value) {
                    case "Settings":
                        FestivalSettingsPage(navigationPath: $navigationPath)
                    case "FestivalView":
                        FestivalPage(navigationPath: $navigationPath/*, festivalVM: festivalVM*/)
                            .environmentObject(festivalVM)
                    case "Favorites":
                        ArtistList(navigationPath: $navigationPath, titleText: "Favorites", artistList: festivalVM.getFavorites())
                            .environmentObject(festivalVM)
                    case "New Event":
                        //                            print(festivalList)
                        NewEventPage(festival: DataSet.Festival.newFestival(), /*festivalCreator: festivalVM,*/ navigationPath: $navigationPath)
                            .environmentObject(festivalVM)
                        //                        case "Shuffle All":
                        //                            ArtistPage(currentArtist: data.shuffleArtistNEW(currentList: festival.), includeFavorites: true)
                    default:
                        SettingsPage()
                    }
                }
            }
        }
        .onAppear() {
            if !explore.isLoading {
                print("updating...")
                explore.fetchVerifiedFestivals()
            }
//            print(firestore.isLoggedIn())
        }
    }
    
    
}
