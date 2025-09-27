//
//  FestivalPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/21/25.
//

import SwiftUI
import UIKit
import MapKit
import EventKit
import EventKitUI

struct FestivalPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State var currentFestival = DataSet.Festival.newFestival()
    
    var previewView: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            FestivalInfoBar
            EditingBar
            ZStack {
                LinearGradient(
                        gradient: Gradient(colors: [
                            Color("OASIS Dark Orange"),
                            Color("OASIS Light Orange"),
                            Color("OASIS Light Blue"),
                            Color("OASIS Dark Blue")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                Group {
                    //                ScrollView {
                    if !festivalVM.checkSettings(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend).isEmpty {
                        ScrollView {
                            VStack {
                                FestivalOptionsBar
                                HStack {
                                    ArtistListButton
                                    ShuffleAllButton
                                }
                                FavoritesButton
                                ShuffleBySection
                                InfoSection
                                Spacer()
                            }
                        }
                    } else if !currentFestival.artistList.isEmpty {
                        VStack {
                            Spacer()
                            Text("No Artists Match Your Settings")
                            
                            NavigationLink(value: "Settings") {
                                HStack {
                                    Text("Adjust Your Settings To Explore This Festival")
                                    Image(systemName: "chevron.right")
                                }
                                .underline()
                            }
                            .italic()
                            .padding(8)
                            .foregroundStyle(.black)
                            Spacer()
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text("This Festival is Empty")
                                .italic()
                            Spacer()
                        }
                    }
                    
                    //                }
                }
                .frame(maxWidth: .infinity)
//                .background(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
//                //            .ignoresSafeArea()
//                //            .cornerRadius(0)
//                
//                .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
//                .clipped()
            }
        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbarRole(.editor)
//        .navigationBarBackButtonDisplayMode
//        .navigationBarBa
//        .navigationBarBackButtonDisplayMode(.minimal)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if !previewView {
                        if let userID = firestore.getUserID(), userID == currentFestival.ownerID {
//                        if currentFestival.ownerID == "austin.zv" {
                            NavigationLink(value: FestivalViewModel.FestivalNavTarget(festival: currentFestival, draftView: true)) {
                                Image(systemName: "pencil.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        NavigationLink(value: "Settings") {
                            Image(systemName: "gear")
                                .foregroundStyle(.blue)
                            //                            .foregroundStyle(Color.blue)
                        }
                    }
                    
                }
                .foregroundStyle(Color("OASIS Dark Orange"))
                .imageScale(.large)
                .foregroundStyle(.tint)
                //                .font(Font.system(size: 10))
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                FestivalLogoView(
                    logoPath: currentFestival.logoPath,
                    title: currentFestival.name,
                    frame: 40.0
                )
            }
        }
        .onAppear() {
            if let festival = festivalVM.currentFestival {
                print(festival)
                currentFestival = festival
            } else {
                navigationPath.removeLast()
            }
        }
    }
    
    func starPressed() {
        if let index = data.userInfoTemp.festivalList.firstIndex(where: {$0.id == currentFestival.id}) {
            data.userInfoTemp.festivalList.remove(at: index)
        } else {
            data.userInfoTemp.festivalList.append(currentFestival)
        }
//        if data.userInfoTemp.festivalList.contains(where: {$0 == currentFestival.id}) {
//
//        }
    }
    
    var EditingBar: some View {
        Group {
            if previewView || !currentFestival.published {
                HStack {
                    Spacer()
                    if previewView {
                        Text("Preview")
                    } else {
                        Text("Draft")
                    }
                    Spacer()
                }
                .padding(5)
                .italic()
                .background(.blue)
                .clipped()
                .edgesIgnoringSafeArea([.leading, .trailing])
            }
        }
    }
    
    var PreviewBar: some View {
        Group {
//            if !currentFestival.published {
                HStack {
                    Spacer()
                    Text("Draft")
//                    Image(systemName: "chevron.right")
                    Spacer()
                }
                .padding(5)
                .italic()
                .background(.blue)
                .clipped()
                .edgesIgnoringSafeArea([.leading, .trailing])
//                .onTapGesture {
//                    navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: currentFestival, draftView: true))
//                }
//            }
        }
    }
    
    var DraftBar: some View {
        Group {
//            if !currentFestival.published {
                HStack {
                    Spacer()
                    Text("Draft")
//                    Image(systemName: "chevron.right")
                    Spacer()
                }
                .padding(5)
                .italic()
                .background(.blue)
                .clipped()
                .edgesIgnoringSafeArea([.leading, .trailing])
//                .onTapGesture {
//                    navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: currentFestival, draftView: true))
//                }
//            }
        }
    }
    
    @State private var showingEventEditor = false
    @State private var eventStore = EKEventStore()
    @State private var newCalEvent: calendarEvent? = nil
    
    var FestivalInfoBar: some View {
        Group {
            HStack {
                if let location = currentFestival.location {
                    Menu(content: {
                        Button (action: {
                            openInMaps(query: location)
                        }, label: {
                            HStack {
                                Text("Search In Maps")
                                Spacer()
                                Image(systemName: "mappin")
                            }
                        })
                    }, label: {
                        Text(location)
                    })
                    Text(" | ")
                }
                Button (action: {
                    eventStore.requestAccess(to: .event) { granted, error in
                        if granted {
                            var eventTitle  = currentFestival.name
                            if currentFestival.secondWeekend { eventTitle.append(" (Weekend 1)") }
                            newCalEvent = calendarEvent(title: eventTitle, startDate: currentFestival.startDate, endDate: currentFestival.endDate)
                        } else {
                            print("Calendar access denied or error: \(error?.localizedDescription ?? "unknown")")
                        }
                    }
                }, label: {
                    Text(festivalVM.getDates(startDate: currentFestival.startDate, endDate: currentFestival.endDate))
                })
                if currentFestival.secondWeekend {
                    Text(" | ")
                    Button (action: {
                        eventStore.requestAccess(to: .event) { granted, error in
                            if granted {
                                newCalEvent = calendarEvent(title: "\(currentFestival.name) (Weekend 2)",
                                                            startDate: Calendar.current.date(byAdding: .day, value: 7, to: currentFestival.startDate)!,
                                                            endDate: Calendar.current.date(byAdding: .day, value: 7, to: currentFestival.endDate)!)
                            } else {
                                print("Calendar access denied or error: \(error?.localizedDescription ?? "unknown")")
                            }
                        }
                    }, label: {
                        Text(festivalVM.getSecondWeekendText(startDate: currentFestival.startDate, endDate: currentFestival.endDate))
                    })
                    
                }
            }
            .foregroundStyle(Color("OASIS Dark Orange"))
            .padding(.bottom, 10)
            .padding(.top, 10)
            .onChange(of: newCalEvent) { calEvent in
                if calEvent != nil {
                    showingEventEditor = true
                }
            }
            .sheet(isPresented: $showingEventEditor) {
                if let calEvent = newCalEvent {
                    EventEditView(eventStore: eventStore,
                                  title: calEvent.title,
                                  startDate: calEvent.startDate,
                                  endDate: calEvent.endDate,
                                  location: currentFestival.location,
                                  url: currentFestival.website.flatMap { URL(string: $0) }
                    )
                }
            }
        }
    }
    
    struct calendarEvent: Equatable {
        var title: String
        var startDate: Date
        var endDate: Date
    }
    
    func openInMaps(query: String) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let mapItem = response?.mapItems.first else {
                print("No results found: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            mapItem.openInMaps(launchOptions: nil)
        }
    }
    
    func createWeekend1Link() -> URL? {
        var title  = currentFestival.name
        if currentFestival.secondWeekend { title.append(" (Weekend 1)") }
        
        return createICSFile(title: title, start: currentFestival.startDate, end: currentFestival.endDate)
    }
    
    func createICSFile(title: String, start: Date, end: Date) -> URL? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd'T'HHmmss"
            formatter.timeZone = TimeZone.current

            let startString = formatter.string(from: start)
            let endString = formatter.string(from: end)

            let icsString = """
            BEGIN:VCALENDAR
            VERSION:2.0
            BEGIN:VEVENT
            DTSTART:\(startString)
            DTEND:\(endString)
            SUMMARY:\(title)
            END:VEVENT
            END:VCALENDAR
            """

            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("event.ics")
            try? icsString.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        }
    
    func openCalendarEvent(title: String, startDate: Date, endDate: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd'T'HHmmss"
        formatter.timeZone = TimeZone.current
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let icsString = """
            BEGIN:VCALENDAR
            VERSION:2.0
            BEGIN:VEVENT
            DTSTART:\(startString)
            DTEND:\(endString)
            SUMMARY:\(title)
            END:VEVENT
            END:VCALENDAR
            """
        
        // Save to temp file
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("event.ics")
        try? icsString.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Open in Calendar
        UIApplication.shared.open(fileURL)
    }
    
    var FestivalOptionsBar: some View {
        Group {
            HStack(spacing: 30) {
                ZStack {
                    Circle()
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    Image(systemName: "square.and.arrow.up")
                        .imageScale(.large)
                        .foregroundStyle(.blue)
                }
                if let url = currentFestival.website {
                    ZStack {
                        Circle()
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                            .shadow(radius: SHADOW)
                        Image(systemName: "network")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                    }
                    .onTapGesture {
                        if let URL = URL(string: toHttpWww(url)) {
                            UIApplication.shared.open(URL)
                        }
                    }
                }
                ZStack {
                    Circle()
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    Image(systemName: data.userInfoTemp.festivalList.contains(where: {$0.id == currentFestival.id}) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                        .imageScale(.large)
                        .onTapGesture() {
                            starPressed()
                        }
                }
            }
            .foregroundStyle(Color("BW Color Switch"))
            .frame(height: LARGE_BUTTON_HEIGHT/1.3)
            .padding(5)
        }
        .padding(.top, 10)
    }
    
    func toHttpWww(_ input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1) Ensure we can parse it with URL by adding "http://" if missing
        let hasScheme = trimmed.range(of: "^[a-zA-Z][a-zA-Z0-9+.-]*://", options: .regularExpression) != nil
        let parsable = hasScheme ? trimmed : "http://\(trimmed)"

        guard var components = URLComponents(string: parsable) else {
            // fallback if it's not parsable
            return "http://www.\(trimmed)"
        }

        // 2) Adjust the hostname to include "www." if needed
        if var host = components.host {
            if !host.hasPrefix("www.") {
                let dotCount = host.filter { $0 == "." }.count
                // Only prepend "www." if it's a bare domain (like coachella.com)
                if dotCount == 1 {
                    host = "www." + host
                }
            }
            components.host = host
        }

        // 3) Force scheme to http
        components.scheme = "http"

        // 4) Return the string
        return components.string ?? "http://www.\(trimmed)"
    }
    
    var FavoritesButton: some View {
        Group {
            if !festivalVM.favoriteList.isEmpty {
                NavigationLink(value: "Favorites") {
                    ZStack {
                        RoundedRectangle(cornerRadius: CORNER_RADIUS)
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                            .shadow(radius: SHADOW)
                        HStack{
                            Spacer()
                            Text("My Favorites")
                            Image(systemName: "heart.fill")
                                .imageScale(.large)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    }
                }
                .frame(height: LARGE_BUTTON_HEIGHT)
                .padding(10)
            }
        }
    }
    
    var ArtistListButton: some View {
        Group {
            if !festivalVM.checkSettings(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend).isEmpty {
                NavigationLink(value: DataSet.ArtistListStruct(festival: currentFestival, list: currentFestival.artistList)) {
                    //            NavigationLink(value: "Artist List") {
                    ZStack {
                        RoundedRectangle(cornerRadius: CORNER_RADIUS)
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                            .shadow(radius: SHADOW)
                        HStack{
                            Spacer()
                            Text("Full List")
                            Image(systemName: "list.bullet")
                                .imageScale(.large)
                            Spacer()
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    }
                }
                .frame(height: LARGE_BUTTON_HEIGHT)
                .padding(10)
            }
        }
    }
    
    var ShuffleAllButton: some View {
        Group {
            if !festivalVM.checkSettings(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend).isEmpty {
                //            NavigationLink(value: data.shuffleArtistNEW(currentList: currentFestival.artistList)!) {
                ZStack {
                    RoundedRectangle(cornerRadius: CORNER_RADIUS)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    HStack{
                        Spacer()
                        Text("Random")
                        Image(systemName: "shuffle")
                            .imageScale(.large)
                        Spacer()
                    }
                    .foregroundStyle(Color("BW Color Switch"))
                }
                //            }
                .frame(height: LARGE_BUTTON_HEIGHT)
                .padding(10)
                .onTapGesture {
                    if let randomArtist = festivalVM.shuffleArtist(currentList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend) {
                        navigationPath.append(DataSet.ArtistPageStruct(artist: randomArtist,
                                                                       shuffleTitle: "All Artists",
                                                                       shuffleList: currentFestival.artistList))
                    }
                }
            }
        }
    }
    
    @State var genreAccordian: Bool = false
    @State var dayAccordian: Bool = false
    @State var stageAccordian: Bool = false
    @State var tierAccordian: Bool = false
    
    @State var genreDict = [String : Array<DataSet.Artist>]()
    @State var dayDict = [String : Array<DataSet.Artist>]()
    @State var stageDict = [String : Array<DataSet.Artist>]()
    @State var tierDict = [String : Array<DataSet.Artist>]()
    
    
    var ShuffleBySection: some View {
        Group {
            VStack(spacing: 0) {
                if !genreDict.isEmpty {
                    SortByGenre
                }
                if dayDict.count > 1 {
                    Divider()
                    SortByDay
                }
                if !stageDict.isEmpty {
                    Divider()
                    SortByStage
                }
                if !tierDict.isEmpty {
                    Divider()
                    SortByBilling
                }
            }
            .padding(10)
            
        }
        .animation(.easeInOut, value: genreAccordian)
        .animation(.easeInOut, value: dayAccordian)
        .animation(.easeInOut, value: stageAccordian)
        .animation(.easeInOut, value: tierAccordian)
        .shadow(radius: SHADOW)
        .onAppear() {
            genreDict = festivalVM.sortGenre(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
            dayDict = festivalVM.sortDay(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
            stageDict = festivalVM.sortStage(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
            tierDict = festivalVM.sortTier(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
        }
    }
        
    
    var SortByGenre: some View {
        VStack(spacing: 0) {
            let finalSectionBool: Bool = (dayDict.count < 2 && stageDict.isEmpty && tierDict.isEmpty)
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS,
                                       bottomLeadingRadius: (finalSectionBool && !genreAccordian) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool && !genreAccordian) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: CORNER_RADIUS,
                                       style: .continuous)
                    .foregroundStyle(Color("BW Color Switch Reverse"))
//                    .shadow(radius: SHADOW)
                HStack {
                    Image(systemName: genreAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Genres")
                    Image(systemName: "theatermasks")
                    Spacer()
                    Image(systemName: genreAccordian ? "chevron.up" : "chevron.down")
                }
                .padding(.horizontal, 15)
            }
            .transaction { $0.animation = nil }
            .frame(height: SMALL_BUTTON_HEIGHT)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    genreAccordian.toggle()
                    dayAccordian = false
                    stageAccordian = false
                    tierAccordian = false
                }
            }
            if genreAccordian {
                VStack (spacing: 1) {
                    ForEach(genreDict.keys.sorted(), id: \.self) { genre in
                        NavigationLink(value: DataSet.ArtistListStruct(titleText: genre, festival: currentFestival, list: genreDict[genre]!)) {
                            ZStack {
//                                if genres.keys.sorted().last!
                                let finalCategoryBool: Bool = (finalSectionBool && genreAccordian && genre == genreDict.keys.sorted().last!)
                                UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                    .foregroundStyle(Color("BW Color Switch Reverse"))
                                HStack {
                                    Spacer()
                                    Text(genre)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                                
                            }
                            .padding(.horizontal, 20)
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 1)
                .scaleEffect(genreAccordian ? 1 : 0.95, anchor: .top)
                .opacity(genreAccordian ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: genreAccordian)
            }
        }
        .foregroundStyle(Color("BW Color Switch"))
        .shadow(radius: 0)
    }
    
    var SortByDay: some View {
        VStack(spacing: 0) {
            let firstSectionBool: Bool = genreDict.isEmpty
            let finalSectionBool: Bool = (stageDict.isEmpty && tierDict.isEmpty)
            ZStack {
                
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: (finalSectionBool && !dayAccordian) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool && !dayAccordian) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                //                    .shadow(radius: SHADOW)
                HStack {
                    Image(systemName: dayAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Days")
                    Image(systemName: "calendar")
                    Spacer()
                    Image(systemName: dayAccordian ? "chevron.up" : "chevron.down")
                }
                .padding(.horizontal, 15)
            }
            .transaction { $0.animation = nil }
            .frame(height: SMALL_BUTTON_HEIGHT)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    genreAccordian = false
                    dayAccordian.toggle()
                    stageAccordian = false
                    tierAccordian = false
                }
            }
            if dayAccordian {
                VStack (spacing: 1) {
                    ForEach(data.sortByDate(days: Array(dayDict.keys)), id: \.self) { day in
                        NavigationLink(value: DataSet.ArtistListStruct(titleText: day, festival: currentFestival, list: dayDict[day]!)) {
                            ZStack {
                                let finalCategoryBool: Bool = (finalSectionBool && dayAccordian && day == dayDict.keys.sorted().last!)
                                UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                HStack {
                                    Spacer()
                                    Text(day)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 1)
                .scaleEffect(dayAccordian ? 1 : 0.95, anchor: .top)
                .opacity(dayAccordian ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: dayAccordian)
            }
            
        }
        .foregroundStyle(Color("BW Color Switch"))
//        .transition(.opacity.combined(with: .move(edge: .top)))
        .shadow(radius: 0)
//        .padding(10)
    }
    
    var SortByStage: some View {
        VStack(spacing: 0) {
            let firstSectionBool: Bool = (genreDict.isEmpty && dayDict.count < 2)
            let finalSectionBool: Bool = tierDict.isEmpty
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: (finalSectionBool && !stageAccordian) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool && !stageAccordian) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                //                UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS, topTrailingRadius: CORNER_RADIUS, style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                //                    .shadow(radius: SHADOW)
                HStack {
                    Image(systemName: stageAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Stages")
                    Image(systemName: "map")
                    Spacer()
                    Image(systemName: stageAccordian ? "chevron.up" : "chevron.down")
                }
                .padding(.horizontal, 15)
            }
            .transaction { $0.animation = nil }
            .frame(height: SMALL_BUTTON_HEIGHT)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    genreAccordian = false
                    dayAccordian = false
                    stageAccordian.toggle()
                    tierAccordian = false
                }
            }
            //            Divider()
            if stageAccordian {
                VStack (spacing: 1) {
                    ForEach(stageDict.keys.sorted(), id: \.self) { stage in
                        NavigationLink(value: DataSet.ArtistListStruct(titleText: stage, festival: currentFestival, list: stageDict[stage]!)) {
                            ZStack {
                                let finalCategoryBool: Bool = (finalSectionBool && stageAccordian && stage == stageDict.keys.sorted().last!)
                                UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                HStack {
                                    Spacer()
                                    Text(stage)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 1)
                .scaleEffect(stageAccordian ? 1 : 0.95, anchor: .top)
                .opacity(stageAccordian ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: stageAccordian)
            }
        }
        .foregroundStyle(Color("BW Color Switch"))
//        .transition(.opacity.combined(with: .move(edge: .top)))
        .shadow(radius: 0)
//        .padding(10)
    }
    
    var SortByBilling: some View {
        VStack(spacing: 0) {
            let firstSectionBool: Bool = (genreDict.isEmpty && dayDict.count < 2 && stageDict.isEmpty)
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: tierAccordian ? 0 : CORNER_RADIUS,
                                       bottomTrailingRadius: tierAccordian ? 0 : CORNER_RADIUS,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                HStack {
                    Image(systemName: tierAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Billing")
                    Image(systemName: "list.bullet.indent")
                    Spacer()
                    Image(systemName: tierAccordian ? "chevron.up" : "chevron.down")
                }
                .padding(.horizontal, 15)
            }
            .transaction { $0.animation = nil }
            .frame(height: SMALL_BUTTON_HEIGHT)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    genreAccordian = false
                    dayAccordian = false
                    stageAccordian = false
                    tierAccordian.toggle()
                }
            }
            if tierAccordian {
                VStack (spacing: 1) {
                    ForEach(data.sortByTier(tiers: Array(tierDict.keys)), id: \.self) { tier in
                        NavigationLink(value: DataSet.ArtistListStruct(titleText: tier, festival: currentFestival, list: tierDict[tier]!)) {
                            ZStack {
                                let finalCategoryBool: Bool = (tierAccordian && tier == tierDict.keys.sorted().last!)
                                UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                HStack {
                                    Spacer()
                                    Text(tier)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                                
                            }
                            //                            }
                            .padding(.horizontal, 20)
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.vertical, 1)
                .scaleEffect(tierAccordian ? 1 : 0.95, anchor: .top)
                .opacity(tierAccordian ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: tierAccordian)
            }
        }
        .foregroundStyle(Color("BW Color Switch"))
        .shadow(radius: 0)
//        .transition(.opacity.combined(with: .move(edge: .top)))
//        .padding(10)
    }
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter
    }()
    
    
    var InfoSection: some View {
        Group {
            VStack(spacing: 5) {
                Text("Created By: \(currentFestival.ownerName)")
                Text("Last Saved: \(currentFestival.saveDate, formatter: dateFormatter)")
                    .italic()
            }
            .font(Font.system(size: 15))
            .padding(.top, 5)
            .padding(.bottom, 15)
        }
        
    }
    
    
    
    
    

//
    
    
    
    
    let LARGE_BUTTON_HEIGHT: CGFloat = 80
    let SMALL_BUTTON_HEIGHT: CGFloat = 55
    let CORNER_RADIUS: CGFloat = 10
    let SHADOW: CGFloat = 5
    

}


struct EventEditView: UIViewControllerRepresentable {
    let eventStore: EKEventStore
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let url: URL?
    let isAllDay: Bool = true

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let controller = EKEventEditViewController()
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.notes = "Creating using OASIS"
        event.location = location
        event.url = url
        
//        if isAllDay {
//            // Add one extra day so it includes the last full day
//            if let adjustedEnd = Calendar.current.date(byAdding: .day, value: 1, to: endDate) {
//                event.endDate = adjustedEnd
//            } else {
//                event.endDate = endDate
//            }
//            event.isAllDay = true
//        } else {
//            event.endDate = endDate
//            event.isAllDay = false
//        }
        
        controller.event = event
        controller.eventStore = eventStore
        controller.editViewDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: EKEventEditViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let parent: EventEditView
        init(_ parent: EventEditView) {
            self.parent = parent
        }

        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
            controller.dismiss(animated: true)
        }
    }
}



//#Preview {
//    FestivalPage()
//}
