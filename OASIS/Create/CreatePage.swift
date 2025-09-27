//
//  CreatePage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 6/30/25.
//

import SwiftUI
import FirebaseAuth

struct CreatePage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @State private var navigationPath = NavigationPath()
    
    @State var selectedFestival: DataSet.Festival?
    
    @State var festivalDrafts: Array<DataSet.Festival> = []
    @State var festivalsPublished: Array<DataSet.Festival>
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
//                ScrollView {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Create")
                                .font(.title)
                                .bold()
                            Spacer()
//                            NavigationLink(value: "New Event") {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundStyle(.blue)
//                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        navigationPath.append("New Event")
//                                        let newFestival = DataSet.festival()
//                                        festivalCreator.addToDrafts(newFestival)
//                                        navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: newFestival, draftView: true))
//                                        navigationPath.append("New Event")
//                                        navigationPath.append(NewEventPage(festivalCreator: festivalCreator, navigationPath: $navigationPath))
                                    }
                                
//                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 20)
                        .padding(.bottom, 5)
                        Divider()
                        ZStack {
                            Color(red: 230/255, green: 240/255, blue: 255/255)
                                .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                            Group {
                                if !(festivalVM.festivalDrafts.isEmpty && festivalVM.publishedFestivals.isEmpty) {
                                    ScrollView {
                                        FestivalsListed(navigationPath: $navigationPath, festivalList: festivalVM.festivalDrafts, title: "Drafts", collapsable: true, draftView: true)
                                        FestivalsListed(navigationPath: $navigationPath, festivalList: festivalVM.publishedFestivals, title: "Published", collapsable: true)
                                    }
                                } else {
                                    VStack {
                                        Text("No Created Festivals Yet!")
                                        Button(action: {
                                            navigationPath.append("New Event")
//                                            let newFestival = DataSet.festival()
//                                            festivalCreator.addToDrafts(newFestival)
//                                            navigationPath.append(FestivalViewModel.FestivalNavTarget(draftView: true))
                                        }) {
                                            HStack {
                                                Text("Create New")
                                                Image(systemName: "chevron.right")
                                            }
                                        }
                                        .italic()
                                        .padding(8)
                                    }
                                }
                            }
                            .padding(.top, 5)
                        }
                        //                    HStack {
                        //                        Text("Create")
                        //                            .font(Font.system(size: 40))
                        //                            .padding(.bottom, 5)
                        //                        Image(systemName: "wrench.and.screwdriver.fill")
                        //                            .imageScale(.large)
//                                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        //                    }
                        //                    Divider()
                        
                        //                    ZStack {
                        //                        Color(red: 220/255, green: 225/255, blue: 230/255)
                        //                            .edgesIgnoringSafeArea([.leading, .trailing])
                        //                        ScrollView {
                        //                            NavigationLink(value: "New Event") {
                        //                                HStack {
                        //                                    Text("New Event")
                        //                                    Image(systemName: "plus.circle.fill")
                        //                                }
                        //                                .foregroundStyle(Color("OASIS Dark Orange"))
                        //
                        //                                .background(
                        //                                    RoundedRectangle(cornerRadius: 20)
                        //                                        .frame(width: 200, height: 50)
                        //                                        .foregroundStyle(.white)
                        //                                )
                        //                                .frame(width: 200, height: 50)
                        //                                .contentShape(Rectangle())
                        //                                .padding(5)
                        //                            }
//                                                    FestivalsListed(festivalList: festivalDrafts, title: "Drafts")
//                                                    FestivalsListed(festivalList: festivalsPublished, title: "Published")
                        //                        }
                        //                        .padding(.top, 10)
                        //                    }
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
//                    .navigationDestination(for: DataSet.artistNEW.self) { artist in
//                        ArtistPage(currentArtist: artist, includeFavorites: true)
//                    }
                    .navigationDestination(for: String.self) { value in
                        switch(value) {
                        case "Settings":
                            SettingsPage()
                        case "Favorites":
                            ArtistList(navigationPath: $navigationPath, titleText: "Favorites", artistList: festivalVM.getFavorites())
                                .environmentObject(festivalVM)
                        case "FestivalView":
                            FestivalPage(navigationPath: $navigationPath/*, festivalVM: festivalVM*/)
                                .environmentObject(festivalVM)
                        case "New Event":
                            NewEventPage(festival: DataSet.Festival.newFestival(), /*festivalCreator: festivalVM,*/ navigationPath: $navigationPath)
                                .environmentObject(festivalVM)
                        default:
                            SettingsPage()
                        }
                    }
                    .onAppear() {
                    }
//                }
                
            }
        }
//        .toolbar(/*selectedFestival == nil ? .hidden : */.visible)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    if !navigationPath.isEmpty {
//                        navigationPath.removeLast()
//                    }
//                }) {
//                    HStack {
//                        Image(systemName: "chevron.left")
//                        Text("Back")
//                    }
//                }
//            }
//        }
        .onAppear {

        }
    }
    
    
    
    func sortedFestivals(festivalList: Array<DataSet.Festival>) -> Array<DataSet.Festival> {
        let sortedFestivals = festivalList.sorted {
            if $0.startDate == $1.startDate {
                if $0.endDate == $1.endDate {
                    return $0.name < $1.name
                }
                return $0.endDate < $1.endDate
            }
            return $0.startDate < $1.startDate
//            ($0.dates.first ?? Date.distantFuture) < ($1.dates.first ?? Date.distantFuture)
        }
        return sortedFestivals
    }
    
    func getDates(startDate: Date, endDate: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        // Case: same day
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: startDate)
        }

        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)

        formatter.dateFormat = "MMMM d"
        let startString = formatter.string(from: startDate)

        if startMonth == endMonth {
            // Same month: "April 11 - 13"
            formatter.dateFormat = "d"
            let endDay = formatter.string(from: endDate)
            return "\(startString) - \(endDay)"
        } else {
            // Different months: "June 30 - July 3"
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        }
    }
    
    func cleanMemory() {
        for (i, fest) in festivalVM.festivalDrafts.enumerated() {
            for (j, artist) in fest.artistList.enumerated(){
                if artist.day.contains("Thursday") { festivalVM.festivalDrafts[i].artistList[j].day = "Thursday" }
                else if artist.day.contains("Friday") { festivalVM.festivalDrafts[i].artistList[j].day = "Friday" }
                else if artist.day.contains("Saturday") { festivalVM.festivalDrafts[i].artistList[j].day = "Saturday" }
                else if artist.day.contains("Sunday") { festivalVM.festivalDrafts[i].artistList[j].day = "Sunday" }
            }
        }
    }
    
    
    
    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.festivalsPublished = []
    }
}
