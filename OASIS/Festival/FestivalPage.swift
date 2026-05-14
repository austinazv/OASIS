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
import PhotosUI

struct FestivalPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var tags: TagViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State var currentFestival: Festival
    
    var previewView: Bool = false
    
    @State var popupMessage: String?
    
//    var friendFavorites: FriendFavorites? = nil
    
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
                                FavoritesSection
                                MyTagSection
                                ShuffleBySection
                                WebsiteSection
                                InfoSection
                                Spacer()
                            }
                        }
                    } else if !currentFestival.artistList.isEmpty {
                        VStack {
                            Spacer()
                            Text("No Artists Match Your Settings")
                            
                            NavigationLink(value: "Festival Settings") {
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
                }
                .frame(maxWidth: .infinity)
//                if let message = popupMessage {
//                    VStack {
//                        Spacer()
//                        MessagePopUp(message: message)
//                            .transition(.move(edge: .bottom).combined(with: .opacity))
//                    }
//                }
            }
        }
        .overlay(alignment: .bottom) {
            if let message = popupMessage {
                MessagePopUp(message: message)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
//                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: popupMessage)
        .onChange(of: popupMessage) { newValue in
            guard newValue != nil else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    popupMessage = nil
                }
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
            ToolbarItem(placement: .topBarTrailing) {
//                if !previewView {
                    HStack {
                        if let userID = firestore.getUserID(), userID == currentFestival.ownerID {
                            NavigationLink(value: FestivalViewModel.FestivalNavTarget(festival: currentFestival, draftView: true)) {
                                Image(systemName: "pencil.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        NavigationLink(value: "Festival Settings") {
                            Image(systemName: "gear")
                                .foregroundStyle(.blue)
                        }
                    }
                .foregroundStyle(Color("OASIS Dark Orange"))
                .imageScale(.large)
                .foregroundStyle(.tint)
//                }
            }
        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .onAppear() {
//            popupMessage = "This is a test."
//            festivalVM.currentFestival = currentFestival
        }
//        .onAppear() {
//            if let festival = festivalVM.currentFestival {
//                currentFestival = festival
//            } else {
//                navigationPath.removeLast()
//            }
//        }
//        .onChange(of: festivalVM.currentFestival) { newFestival in
//            guard let festival = newFestival else { return }
//            if currentFestival.id == newFestival.id {
//                currentFestival = newFestival
//            }
//        }
    }
    
//    func starPressed() {
//        festivalVM.festivalStarPressed(festival: currentFestival)
//    }
    

    
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
        ZStack(alignment: .top) {
            Color.white
                    .ignoresSafeArea(edges: [.top, .leading, .trailing]) // covers status bar + nav bar area
                    .frame(height: 31)
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
                            //print("Calendar access denied or error: \(error?.localizedDescription ?? "unknown")")
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
                                //print("Calendar access denied or error: \(error?.localizedDescription ?? "unknown")")
                            }
                        }
                    }, label: {
                        Text(festivalVM.getSecondWeekendText(startDate: currentFestival.startDate, endDate: currentFestival.endDate))
                    })
                    
                }
            }
            .foregroundStyle(Color("OASIS Dark Orange"))
            .padding(.bottom, 10)
//            .padding(.top, 10)
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
                //print("No results found: \(error?.localizedDescription ?? "Unknown error")")
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
    
    @State var showAddFestivalToGroupSheet = false
    
    var FestivalOptionsBar: some View {
        Group {
            HStack(spacing: 32) {
                if currentFestival.published {
                    ShareLink(item: getFestivalLink()) {
                        ZStack {
                            Circle()
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                .shadow(radius: SHADOW)
                            Image(systemName: "square.and.arrow.up")
                                .imageScale(.large)
                                .foregroundStyle(.blue)
                                .offset(y: -3)
                        }
                    }
                    .frame(height: LARGE_BUTTON_HEIGHT/1.3)
                } else {
                    ZStack {
                        Circle()
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                            .shadow(radius: SHADOW)
                        Image(systemName: "square.and.arrow.up")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .offset(y: -3)
                    }
                    .frame(height: LARGE_BUTTON_HEIGHT/1.3)
                    .opacity(0.5)
                    .onTapGesture {
                        popupMessage = "Make this festival public to share."
                    }
                }
                    
                
                ZStack {
                    Circle()
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    Image(systemName: festivalVM.festivalIsFavorited(festivalID: currentFestival.id) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
//                        .imageScale(.large)
                        .font(.system(size: 34))
                        .onTapGesture() {
//                            let _ = festivalVM.isStarNowPressed(festival: currentFestival)
                            festivalVM.starPressed(festival: currentFestival)
                            firestore.myUserProfile.starredFestivalsList = festivalVM.myFestivals.map { $0.id.uuidString }
//                            festivalVM.isStarNowPressed(festival: <#T##Festival#>)
//                            firestore.festivalStarPressed(festivalID: currentFestival.id.uuidString, currentStar: currentStar)
                        }
                }
                .frame(height: LARGE_BUTTON_HEIGHT/1.05)
                
                
                ZStack {
                    Circle()
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    Image(systemName: "person.2.badge.plus.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 20))
                        .onTapGesture() {
                            if currentFestival.published {
                                showAddFestivalToGroupSheet = true
                            } else {
                                popupMessage = "Make this festival public to add to groups."
                            }
                        }
                }
                .frame(height: LARGE_BUTTON_HEIGHT/1.3)
                .opacity(currentFestival.published ? 1 : 0.5)
            }
            .foregroundStyle(Color("BW Color Switch"))
            .padding(5)
        }
        .padding(.top, 10)
        .sheet(isPresented: $showAddFestivalToGroupSheet) {
            AddFestivalToGroupSheet(festival: currentFestival, showAddFestivalToGroupSheet: $showAddFestivalToGroupSheet)
        }
    }
    
    func getFestivalLink() -> String {
        "https://oasis-austinzv.web.app/share/festival/\(currentFestival.id)"
    }

    
//    if let url = currentFestival.website {
//        ZStack {
//            Circle()
//                .foregroundStyle(Color("BW Color Switch Reverse"))
//                .shadow(radius: SHADOW)
//            Image(systemName: "network")
//                .imageScale(.large)
//                .foregroundStyle(.blue)
//        }
//        .onTapGesture {
//            if let URL = URL(string: toHttpWww(url)) {
//                UIApplication.shared.open(URL)
//            }
//        }
//    }
    
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
    
    var FavoritesSection: some View {
        VStack(spacing: 0) {
                MyFavoritesButton
                Divider()
                HStack(spacing: 0) {
                    FriendsFavoritesButton
                        .layoutPriority(showFriendList ? 1 : 0)
                    if !friendsFavs.isEmpty && !groupFavorites.isEmpty {
                        Divider()
                    }
                    GroupFavoritesButton
                        .layoutPriority(showGroupList ? 1 : 0)
                }
//            .background(
//                    RoundedRectangle(cornerRadius: CORNER_RADIUS)
//                        .fill(Color(.systemBackground))
//                        .shadow(radius: SHADOW)
//                )
            ShowFriendsOrGroups
        }
        .compositingGroup()
        .shadow(radius: SHADOW)
        .animation(.easeInOut, value: showFriendList)
        .padding(10)
//        .shadow(radius: SHADOW)
    }
    
//    @State var myFavorites = Array<Artist>()
    
    var MyFavoritesButton: some View {
        Group {
            let lastSectionBool: Bool = friendsFavs.isEmpty && groupFavorites.isEmpty
            let myFavorites = tags.getFavoritesList(currList: currentFestival.artistList)
            if !myFavorites.isEmpty {
                NavigationLink(value: ArtistListStruct(titleText: "My Favorites",
                                                               festival: currentFestival,
                                                               list: myFavorites)) {
//                NavigationLink(value: myFavorites) {
                    ZStack {
                        UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS,
                                               bottomLeadingRadius: lastSectionBool ? CORNER_RADIUS : 0,
                                               bottomTrailingRadius: lastSectionBool ? CORNER_RADIUS : 0,
                                               topTrailingRadius: CORNER_RADIUS,
                                               style: .continuous)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                        .shadow(radius: SHADOW)
                        HStack{
                            Spacer()
                            Text("My Favorites").bold()
                            Image(systemName: "heart.fill")
                                .imageScale(.large)
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .foregroundStyle(Color("BW Color Switch"))
                    }
                    .frame(height: LARGE_BUTTON_HEIGHT)
                }
            } else {
                ZStack {
                    UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS,
                                           bottomLeadingRadius: lastSectionBool ? CORNER_RADIUS : 0,
                                           bottomTrailingRadius: lastSectionBool ? CORNER_RADIUS : 0,
                                           topTrailingRadius: CORNER_RADIUS,
                                           style: .continuous)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                        .shadow(radius: SHADOW)
                    HStack{
                        Spacer()
                        Text("No Favorites Yet").bold()
                        Image(systemName: "heart")
                            .imageScale(.large)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .foregroundStyle(Color("BW Color Switch"))
                }
                .frame(height: SMALL_BUTTON_HEIGHT)
            }
        }
        .task {
            loadGroups()
        }
        .onChange(of: firestore.mySocialGroups) { _ in
            loadGroups()
        }
//        .onAppear {
//            if let myFavoriteIDs = firestore.myUserProfile.festivalFavorites?[currentFestival.id.uuidString] {
//                myFavorites = festivalVM.getArtistListFromID(artistIDs: myFavoriteIDs, festival: currentFestival)
//            }
//        }
//        .onChange(of: friendsFavs) { newFriends in
//            if !newFriends.isEmpty {
//                withAnimation {
//                    showFriends = true
//                }
//            } else {
//                withAnimation {
//                    showFriends = false
//                }
//            }
//        }
    }
    
    func loadGroups() {
        Task {
            isLoadingFriends = true
            defer { isLoadingFriends = false }
            
            let following = await firestore.users(from: firestore.myUserProfile.safeFollowing)
            let festivalID = currentFestival.id.uuidString
            
            let currArtistIDs = Set(currentFestival.artistList.map(\.id))
            
            let newFriendFavs: [UserProfile: [String]] = Dictionary(
                uniqueKeysWithValues: following.compactMap { user in
                    let fav = user.safeFavoriteArtistsList.filter {
                        currArtistIDs.contains($0)
                    }
                    return fav.isEmpty ? nil : (user, fav)
                }
            )
            
            var results: [GroupFestivalFavorites] = []
            
            for group in firestore.mySocialGroups where group.festivals.contains(festivalID) {

                let users = await firestore.users(from: group.members)
//                //print("USERS*********: \(users)")

                var artistToUsers: [String: Set<String>] = [:]

                for user in users {
                    //print("*************\(user.name)'s FAVORITES: \(user.safeFavoriteArtistsList)")
                    let favs = user.safeFavoriteArtistsList.filter {
                        currArtistIDs.contains($0)
                    }
                    
//                    guard
//                        let favs = user.safeFestivalFavorites[festivalID],
//                        !favs.isEmpty
//                    else { continue }

                    for artistID in favs {
                        artistToUsers[artistID, default: []].insert(user.id!)
                    }
                }

                let artistFavorites = artistToUsers.map { artistID, userSet in
                    UserFestivalFavorites(
                        artistID: artistID,
                        userIDs: Array(userSet)
                    )
                }

                if !artistFavorites.isEmpty {
                    results.append(
                        GroupFestivalFavorites(
                            group: group,
                            users: artistFavorites
                        )
                    )
                }
            }
            
            await MainActor.run {
                friendsFavs = newFriendFavs
                groupFavorites = results
//                //print("GROUP FAVS: \(groupFavorites)")
            }
        }
    }
    

    
    
    @State var isLoadingFriends = false
//    @State var showFriends = true

    @State var showFriendList = false
    @State var friendsFavs = [UserProfile : [String]]()
//    @State var groupFavorites = [[UserProfile : [String]]]()
    
    
    
    var FriendsFavoritesButton: some View {
        Group {
            if !friendsFavs.isEmpty {
//                VStack(spacing: 0) {
//                    let roundedBottomRectangle = !showFriendList/* && !showGroupList*/
                    ZStack {
                        UnevenRoundedRectangle(bottomLeadingRadius: /*!showFriendList ? */CORNER_RADIUS/* : 0*/,
                                               bottomTrailingRadius: groupFavorites.isEmpty /*&& !showFriendList*/ ? CORNER_RADIUS : 0,
                                               style: .continuous)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                        .shadow(radius: showFriendList ? 5 : 0)
                        HStack {
                            Image(systemName: showFriendList ? "chevron.up" : "chevron.down")
                            if !showGroupList {
                                Spacer()
                                Text("Friends").bold()
                                Image(systemName: "person.2.fill")
                                Spacer()
                            } else {
                                Image(systemName: "person.2.fill")
                            }
                            Image(systemName: showFriendList ? "chevron.up" : "chevron.down")
                        }
                        .padding(.horizontal, 15)
                    }
                    .foregroundStyle(Color("BW Color Switch"))
                    .transaction { $0.animation = nil }
                    .frame(height: SMALL_BUTTON_HEIGHT)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            showFriendList.toggle()
                            showGroupList = false
                            closeInfoSection()
                        }
                    }
                    .foregroundStyle(Color("BW Color Switch"))
//                    if showGroupList {
//                        Divider().padding(.leading, 40)
//                    }
//                    if showFriendList {
//                        VStack (spacing: 1) {
//                            ForEach(Array(friendsFavs.keys.sorted(by: { $0.name < $1.name }).enumerated()), id: \.element.id) { index, profile in
//                                NavigationLink(value: ArtistListStruct(titleText: "\(profile.name)'s Favorites",
//                                                                               festival: currentFestival,
//                                                                               list: festivalVM.getArtistListFromID(artistIDs: friendsFavs[profile]!, festival: currentFestival))) {
//                                    ZStack {
//                                        let lastFriendBool = (index == friendsFavs.keys.count - 1) && groupFavorites.isEmpty
//                                        UnevenRoundedRectangle(bottomLeadingRadius: lastFriendBool ? CORNER_RADIUS : 0,
//                                                               bottomTrailingRadius: lastFriendBool ? CORNER_RADIUS : 0,
//                                                               style: .continuous)
//                                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                                        HStack {
//                                            Spacer()
//                                            SocialImage(imageURL: profile.profilePic, name: profile.name, frame: 30)
//                                            Text(profile.name)
//                                            Image(systemName: "chevron.right")
//                                            Spacer()
//                                        }
//                                    }
//                                    .padding(.horizontal, 20)
//                                    .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
//                                    .buttonStyle(PlainButtonStyle())
//                                    
//                                }
//                            }
//                            
//                            //                            ForEach(data.sortByTier(tiers: Array(tierDict.keys)), id: \.self) { tier in
//                            //                                NavigationLink(value: ArtistListStruct(titleText: tier, festival: currentFestival, list: tierDict[tier]!)) {
//                            //                                    ZStack {
//                            //                                        let finalCategoryBool: Bool = (tierAccordian && tier == tierDict.keys.sorted().last!)
//                            //                                        UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
//                            //                                                               bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
//                            //                                                               style: .continuous)
//                            //                                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                            //                                        HStack {
//                            //                                            Spacer()
//                            //                                            Text(tier)
//                            //                                            Image(systemName: "chevron.right")
//                            //                                            Spacer()
//                            //                                        }
//                            //
//                            //                                    }
//                            //                                    //                            }
//                            //                                    .padding(.horizontal, 20)
//                            //                                    .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
//                            //                                    .buttonStyle(PlainButtonStyle())
//                            //                                }
//                            //                            }
//                        }
//                        .padding(.vertical, 1)
//                        .scaleEffect(showFriendList ? 1 : 0.95, anchor: .top)
//                        .opacity(showFriendList ? 1 : 0)
//                        .animation(.easeInOut(duration: 0.3), value: showFriendList)
//                    }
//                }
                
                
//                .scaleEffect(showFriends ? 1 : 0.95, anchor: .top)
//                .opacity(showFriends ? 1 : 0)
//                .animation(.easeInOut(duration: 0.3), value: showFriends)
            }
        }
    }
    
//    @State var isLoadingFriends = false
//    @State var showFriends = true
    @State var showGroupList = false
    @State var groupFavorites: [GroupFestivalFavorites] = []
    
    var GroupFavoritesButton: some View {
        Group {
            if !groupFavorites.isEmpty {
//                VStack(spacing: 0) {
//                    let bottomRoundedBool = (groupFavorites.count == 1 || !showGroupList)
//                    let roundedBottomRectangle = /*!showFriendList &&*/ !showGroupList
                    ZStack {
                        UnevenRoundedRectangle(bottomLeadingRadius: friendsFavs.isEmpty /*&& !showGroupList*/ ? CORNER_RADIUS : 0,
                                               bottomTrailingRadius: /*!showGroupList ? */CORNER_RADIUS/* : 0*/,
//                                               topTrailingRadius: 0,
                                               style: .continuous)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                        .shadow(radius: showGroupList ? 5 : 0)
                        HStack {
                            Image(systemName: showGroupList ? "chevron.up" : "chevron.down")
                            if !showFriendList {
                                Spacer()
                                Text("Groups").bold()
                                Image(systemName: "person.3.fill")
                                Spacer()
                            } else {
                                Image(systemName: "person.3.fill")
                            }
                            Image(systemName: showGroupList ? "chevron.up" : "chevron.down")
                        }
                        .padding(.horizontal, 15)
                    }
                    .transaction { $0.animation = nil }
                    .frame(height: SMALL_BUTTON_HEIGHT)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            showGroupList.toggle()
                            showFriendList = false
                            closeInfoSection()
                        }
                    }
                    .foregroundStyle(Color("BW Color Switch"))
//                    if showGroupList {
////                        Divider()
//                        Rectangle()
//                            .frame(height: 2)
//                            .foregroundStyle(.red)
//                            
//                    }
//                    if showGroupList {
//                        VStack (spacing: 1) {
////                            ForEach(Array(groupFavorites.sorted(by: { $0.group.name })))
//                            ForEach(Array(groupFavorites.sorted(by: { $0.group.name < $1.group.name }).enumerated()), id: \.offset) { index, groupFestFav in
////                                groupFestFav.
//                                NavigationLink(value: ArtistListStruct(titleText: "\(groupFestFav.group.name)'s Favorites",
//                                                                               festival: currentFestival,
//                                                                               list: festivalVM.getArtistListFromID(artistIDs: groupFestFav.users.flatMap { $0.artistIDs }, festival: currentFestival))) {
//                                    ZStack {
//                                        let lastGroupBool = (index == groupFavorites.count - 1)
//                                        UnevenRoundedRectangle(
////                                            topLeadingRadius: 0,
//                                            bottomLeadingRadius: lastGroupBool ? CORNER_RADIUS : 0,
//                                            bottomTrailingRadius: lastGroupBool ? CORNER_RADIUS : 0,
////                                            topTrailingRadius: 0,
//                                            style: .continuous)
//                                        .foregroundStyle(Color("BW Color Switch Reverse"))
//                                        HStack {
//                                            Spacer()
//                                            SocialImage(imageURL: groupFestFav.group.photo, name: groupFestFav.group.name, frame: 30)
//                                            Text(groupFestFav.group.name)
//                                            Image(systemName: "chevron.right")
//                                            Spacer()
//                                        }
//                                    }
//                                    .padding(.horizontal, 20)
//                                    .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
//                                    .buttonStyle(PlainButtonStyle())
//                                    
//                                }
//                            }
//                        }
//                        .padding(.vertical, 1)
//                        .scaleEffect(showGroupList ? 1 : 0.95, anchor: .top)
//                        .opacity(showGroupList ? 1 : 0)
//                        .animation(.easeInOut(duration: 0.3), value: showGroupList)
//                    }
//                }
                
//                .shadow(radius: showGroupList ? 5 : 0)
//                .scaleEffect(showFriends ? 1 : 0.95, anchor: .top)
//                .opacity(showFriends ? 1 : 0)
//                .animation(.easeInOut(duration: 0.3), value: showFriends)
            }
        }
    }
    
    let SIDE_BUFFER: CGFloat = 30
    
    var ShowFriendsOrGroups: some View {
        VStack(spacing: 0) {
            if showFriendList {
                VStack (spacing: 0) {
                    Divider()
                    ForEach(Array(friendsFavs.keys.sorted(by: { $0.name < $1.name }).enumerated()), id: \.element.id) { index, profile in
                        NavigationLink(value: ArtistListStruct(titleText: "\(profile.name)'s Favorites",
                                                                       festival: currentFestival,
                                                                       list: festivalVM.getArtistListFromID(artistIDs: friendsFavs[profile]!, festival: currentFestival))) {
                            ZStack {
                                let lastFriendBool = (index == friendsFavs.keys.count - 1) /*&& groupFavorites.isEmpty*/
                                UnevenRoundedRectangle(bottomLeadingRadius: lastFriendBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: lastFriendBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                //                                .shadow(radius: showFriendList ? 5 : 0)
                                HStack {
                                    Spacer()
                                    SocialImage(imageURL: profile.profilePic, name: profile.name, frame: 30)
                                    Text(profile.name)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                            }
                            
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                        if index < friendsFavs.count - 1 {
                            Divider()
                        }
                    }
                }
//                .padding(.vertical, 1)
//                .padding(.leading, groupFavorites.isEmpty ? 20 : 0)
//                .padding(.trailing, groupFavorites.isEmpty ? 20 : SIDE_BUFFER)
//                .background(
//                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: CORNER_RADIUS, bottomTrailingRadius: CORNER_RADIUS, topTrailingRadius: 0, style: .continuous)
////                        UnevenRoundedRectangle(cornerRadius: CORNER_RADIUS)
//                            .fill(Color(.systemBackground))
//                            .shadow(radius: SHADOW, x: 0, y: SHADOW)
//                    )
                .padding(.horizontal, SIDE_BUFFER)
                .scaleEffect(showFriendList ? 1 : 0.95, anchor: .top)
                .opacity(showFriendList ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showFriendList)
            } else if showGroupList {
                VStack (spacing: 0) {
                    Divider()
//                            ForEach(Array(groupFavorites.sorted(by: { $0.group.name })))
                    ForEach(Array(groupFavorites.sorted(by: { $0.group.name < $1.group.name }).enumerated()), id: \.offset) { index, groupFestFav in
                        let artistList = festivalVM.getArtistListFromID(artistIDs: groupFestFav.users.map { $0.artistID },
                                                                        festival: currentFestival)
                        
                        NavigationLink(value: ArtistListStruct(titleText: "\(groupFestFav.group.name)'s Favorites",
                                                                       festival: currentFestival,
                                                                       list: artistList,
                                                                       groupFavs: groupFestFav.users
                                                                      )) {
                            ZStack {
                                let lastGroupBool = (index == groupFavorites.count - 1)
                                UnevenRoundedRectangle(
                                    //                                            topLeadingRadius: 0,
                                    bottomLeadingRadius: lastGroupBool ? CORNER_RADIUS : 0,
                                    bottomTrailingRadius: lastGroupBool ? CORNER_RADIUS : 0,
                                    //                                            topTrailingRadius: 0,
                                    style: .continuous)
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                //                                .shadow(radius: showGroupList ? 5 : 0)
                                HStack {
                                    Spacer()
                                    SocialImage(imageURL: groupFestFav.group.photo, name: groupFestFav.group.name, frame: 30)
                                    Text(groupFestFav.group.name)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                            }
                            
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                            
                        }
                        if index < groupFavorites.count - 1 {
                            Divider()
                        }
                    }
                    
                }
//                .padding(.vertical, 1)
//                .padding(.leading, friendsFavs.isEmpty ? 20 : SIDE_BUFFER)
//                .padding(.trailing, friendsFavs.isEmpty ? 20 : 0)
                .padding(.horizontal, SIDE_BUFFER)
//                .padding(.leading, 40)
                .scaleEffect(showGroupList ? 1 : 0.95, anchor: .top)
                .opacity(showGroupList ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showGroupList)
            }
        }
        .foregroundStyle(.black)
    }
    
    func closeInfoSection() {
        genreAccordian = false
        dayAccordian = false
        stageAccordian = false
        tierAccordian = false
    }
    
    func closeFavoritesSection() {
        showFriendList = false
        showGroupList = false
    }
    
    
    var ArtistListButton: some View {
        Group {
            if !festivalVM.checkSettings(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend).isEmpty {
                NavigationLink(value: ArtistListStruct(festival: currentFestival, list: currentFestival.artistList)) {
                    //            NavigationLink(value: "Artist List") {
                    ZStack {
                        RoundedRectangle(cornerRadius: CORNER_RADIUS)
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                            .shadow(radius: SHADOW)
                        HStack{
                            Spacer()
                            Text("Full List").bold()
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
                        Text("Random").bold()
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
                    let dislikedArtists = tags.getDNSTArtists(currList: currentFestival.artistList)
                    if let randomArtist = festivalVM.shuffleArtist(currentList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend, dislikedArtists: dislikedArtists) {
                        navigationPath.append(ArtistPageStruct(artist: randomArtist, festival: currentFestival,
                                                                       shuffleTitle: "All Artists",
                                                                       shuffleList: currentFestival.artistList))
                    }
                }
            }
        }
    }
    
    
    @State var showMyTags = false
    
    var MyTagSection: some View {
        Group {
            let tagDictionary = tags.getTagDictionary(currList: currentFestival.artistList)
            if !tagDictionary.isEmpty {
                VStack(spacing: 0) {
                    //            let finalSectionBool: Bool = (dayDict.count < 2 && stageDict.isEmpty && tierDict.isEmpty)
                    ZStack {
                        RoundedRectangle(cornerRadius: CORNER_RADIUS, style: .continuous)
                        //                UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS,
                        //                                       bottomLeadingRadius: /*showMyTags ? 0 : */ CORNER_RADIUS,
                        //                                       bottomTrailingRadius: /*showMyTags ? 0 : */ CORNER_RADIUS,
                        //                                       topTrailingRadius: CORNER_RADIUS,
                        //                                       style: .continuous)
                            .foregroundStyle(Color("BW Color Switch Reverse"))
                        HStack {
                            Image(systemName: showMyTags ? "chevron.up" : "chevron.down")
                            Spacer()
                            Text("My Tags").bold()
                            Image(systemName: "tag")
                            Spacer()
                            Image(systemName: showMyTags ? "chevron.up" : "chevron.down")
                        }
                        .padding(.horizontal, 15)
                    }
                    .transaction { $0.animation = nil }
                    .frame(height: SMALL_BUTTON_HEIGHT)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            showMyTags.toggle()
                        }
                    }
                    if showMyTags {
                        VStack (spacing: 0) {
                            Divider()
                            let sortedTags = tags.sortTags(Array(tagDictionary.keys))
//                            let sortedTags = tags.getSortedTag()
                            //                    ForEach(Array(topGenresDict.keys), id: \.self) { genre in
                            ForEach(sortedTags, id: \.id) { tag in
                                let tagList = tagDictionary[tag]!
                                let finalTagBool = (tag == sortedTags.last!)
                                //                        navigationPath.append(ArtistListStruct(titleText: tag.name, festival: currentFestival, list: tagList))
                                NavigationLink(value: ArtistListStruct(titleText: tag.name, festival: currentFestival, list: tagList)) {
                                    ZStack {
                                        //                                if genres.keys.sorted().last!
                                        UnevenRoundedRectangle(topLeadingRadius: 0,
                                                               bottomLeadingRadius: finalTagBool ? CORNER_RADIUS : 0,
                                                               bottomTrailingRadius: finalTagBool ? CORNER_RADIUS : 0,
                                                               topTrailingRadius: 0,
                                                               style: .continuous)
                                        .foregroundStyle(Color("BW Color Switch Reverse"))
                                        HStack {
                                            Spacer()
                                            Group {
                                                Image(systemName: tag.symbol)
                                                Text(tag.name)
                                            }
                                            .foregroundStyle(COLOR_SPECTRUM_ARRAY[tag.color])
                                            Image(systemName: "chevron.right")
                                            Spacer()
                                        }
                                    }
                                    .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                                    .buttonStyle(PlainButtonStyle())
                                }
                                if !finalTagBool { Divider() }
                            }
                        }
                        //                .padding(.vertical, 1)
                        .padding(.horizontal, SIDE_BUFFER)
                        .scaleEffect(showMyTags ? 1 : 0.95, anchor: .top)
                        .opacity(showMyTags ? 1 : 0)
                        .animation(.easeInOut(duration: 0.3), value: showMyTags)
                    }
                }
                .foregroundStyle(Color("BW Color Switch"))
                .compositingGroup()
                .shadow(radius: SHADOW)
                .padding(10)
            }
        }
    }
    
    
    
    
    
    @State var genreAccordian: Bool = false
    @State var dayAccordian: Bool = false
    @State var stageAccordian: Bool = false
    @State var tierAccordian: Bool = false
    
    @State var topGenresDict = [String : Array<Artist>]()
    @State var allGenresDict = [String : Array<Artist>]()
    @State var dayDict = [String : Array<Artist>]()
    @State var stageDict = [String : Array<Artist>]()
    @State var tierDict = [String : Array<Artist>]()
    
    
    var ShuffleBySection: some View {
        Group {
            VStack(spacing: 0) {
                if !allGenresDict.isEmpty {
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
        .compositingGroup()
        .shadow(radius: SHADOW)
        .animation(.easeInOut, value: genreAccordian)
        .animation(.easeInOut, value: dayAccordian)
        .animation(.easeInOut, value: stageAccordian)
        .animation(.easeInOut, value: tierAccordian)
//        .shadow(radius: SHADOW)
        .shadow(radius: 0)
        .onAppear() {
            let genres = festivalVM.sortGenre(currList: currentFestival.artistList, secondWeekend: currentFestival.secondWeekend)
            topGenresDict = genres.topGenres
            allGenresDict = genres.allGenres
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
                                       bottomLeadingRadius: (finalSectionBool /*&& !genreAccordian*/) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool /*&& !genreAccordian*/) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: CORNER_RADIUS,
                                       style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                HStack {
                    Image(systemName: genreAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Genres").bold()
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
                    closeFavoritesSection()
                }
            }
            if genreAccordian {
                VStack (spacing: 0) {
                    let topGenres = Array(topGenresDict.keys)
                    if !topGenres.isEmpty {
                        Divider()
                        ForEach(topGenres, id: \.self) { genre in
                            NavigationLink(value: ArtistListStruct(titleText: genre, festival: currentFestival, list: topGenresDict[genre]!)) {
                                ZStack {
                                    //                                if genres.keys.sorted().last!
                                    Rectangle()
                                        .foregroundStyle(Color("BW Color Switch Reverse"))
                                    HStack {
                                        Spacer()
                                        Image(systemName: "flame")
                                        Text(genre)
                                        Image(systemName: "chevron.right")
                                        Spacer()
                                    }
                                }
                                .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                                .buttonStyle(PlainButtonStyle())
                            }
                            if genre != topGenres.last! { Divider() }
                        }
                    }
                    Spacer().frame(height: 3) //TODO: Fix
                    let allGenres = allGenresDict.keys.sorted()
                    ForEach(allGenres, id: \.self) { genre in
                        NavigationLink(value: ArtistListStruct(titleText: genre, festival: currentFestival, list: allGenresDict[genre]!)) {
                            ZStack {
                                //                                if genres.keys.sorted().last!
                                let finalCategoryBool: Bool = (finalSectionBool && genreAccordian && genre == allGenresDict.keys.sorted().last!)
                                UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                       style: .continuous)
                                .foregroundStyle(Color("BW Color Switch Reverse"))
                                HStack {
                                    Spacer()
                                    if topGenresDict[genre] != nil { Image(systemName: "flame") }
                                    Text(genre)
                                    Image(systemName: "chevron.right")
                                    Spacer()
                                }
                                
                            }
                            //                                .padding(.horizontal, 20)
                            .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                            .buttonStyle(PlainButtonStyle())
                        }
                        if genre != allGenres.last! { Divider() }
                    }
                    
                }
//                .padding(.vertical, 1)
                .padding(.horizontal, SIDE_BUFFER)
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
            let firstSectionBool: Bool = allGenresDict.isEmpty
            let finalSectionBool: Bool = (stageDict.isEmpty && tierDict.isEmpty)
            ZStack {
                
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: (finalSectionBool /*&& !dayAccordian*/) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool /*&& !dayAccordian*/) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                //                    .shadow(radius: SHADOW)
                HStack {
                    Image(systemName: dayAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Days").bold()
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
                    closeFavoritesSection()
                }
            }
            if dayAccordian {
                VStack (spacing: 0) {
                    let sortedDays = data.sortByDate(days: Array(dayDict.keys))
                    if !sortedDays.isEmpty {
                        Divider()
                        ForEach(sortedDays.indices, id: \.self) { i in
                            let day = sortedDays[i]
                            NavigationLink(value: ArtistListStruct(titleText: day, festival: currentFestival, list: dayDict[day]!)) {
                                ZStack {
                                    let finalCategoryBool: Bool = (finalSectionBool && dayAccordian && day == dayDict.keys.sorted().last!)
                                    UnevenRoundedRectangle(bottomLeadingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                           bottomTrailingRadius: finalCategoryBool ? CORNER_RADIUS : 0,
                                                           style: .continuous)
                                    .foregroundStyle(Color("BW Color Switch Reverse"))
                                    HStack {
                                        Spacer()
                                        Text(getDayText(from: day))
                                        Text(getWeekendNumberText(from: day))
                                            .italic()
                                            .font(.subheadline)
                                        Image(systemName: "chevron.right")
                                        Spacer()
                                    }
                                }
                                
                                .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                                .buttonStyle(PlainButtonStyle())
                            }
                            if i < sortedDays.count - 1 {
                                let current = sortedDays[i]
                                let next = sortedDays[i + 1]
                                
                                if current.contains("Weekend 1") && next.contains("Weekend 2") {
                                    Spacer().frame(height: 3)
                                } else {
                                    Divider()
                                }
                            }
                        }
                        .padding(.horizontal, SIDE_BUFFER)
                    }
                }
//                .padding(.vertical, 1)
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
    
    func getDayText(from text: String) -> String {
        text.components(separatedBy: " (").first ?? text
    }

    func getWeekendNumberText(from text: String) -> String {
        let parts = text.components(separatedBy: " (")
        guard parts.count > 1 else { return "" }
        return " (" + parts[1]
    }
    
    var SortByStage: some View {
        VStack(spacing: 0) {
            let firstSectionBool: Bool = (allGenresDict.isEmpty && dayDict.count < 2)
            let finalSectionBool: Bool = tierDict.isEmpty
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: (finalSectionBool /*&& !stageAccordian*/) ? CORNER_RADIUS : 0,
                                       bottomTrailingRadius: (finalSectionBool /*&& !stageAccordian*/) ? CORNER_RADIUS : 0,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                //                UnevenRoundedRectangle(topLeadingRadius: CORNER_RADIUS, topTrailingRadius: CORNER_RADIUS, style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                //                    .shadow(radius: SHADOW)
                HStack {
                    Image(systemName: stageAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Stages").bold()
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
                    closeFavoritesSection()
                }
            }
            //            Divider()
            if stageAccordian {
                VStack (spacing: 0) {
                    let stagesSorted = stageDict.keys.sorted()
                    if !stagesSorted.isEmpty {
                        Divider()
                        ForEach(stagesSorted, id: \.self) { stage in
                            NavigationLink(value: ArtistListStruct(titleText: stage, festival: currentFestival, list: stageDict[stage]!)) {
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
                                
                                .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                                .buttonStyle(PlainButtonStyle())
                            }
                            if stage != stagesSorted.last! { Divider() }
                        }
                        .padding(.horizontal, SIDE_BUFFER)
                    }
                }
//                .padding(.vertical, 1)
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
            let firstSectionBool: Bool = (allGenresDict.isEmpty && dayDict.count < 2 && stageDict.isEmpty)
            ZStack {
                UnevenRoundedRectangle(topLeadingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       bottomLeadingRadius: /*tierAccordian ? 0 : */CORNER_RADIUS,
                                       bottomTrailingRadius: /*tierAccordian ? 0 : */CORNER_RADIUS,
                                       topTrailingRadius: firstSectionBool ? CORNER_RADIUS : 0,
                                       style: .continuous)
                .foregroundStyle(Color("BW Color Switch Reverse"))
                HStack {
                    Image(systemName: tierAccordian ? "chevron.up" : "chevron.down")
                    Spacer()
                    Text("Billing").bold()
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
                    closeFavoritesSection()
                }
            }
            if tierAccordian {
                VStack (spacing: 0) {
                    let tiersSorted = data.sortByTier(tiers: Array(tierDict.keys))
                    if !tiersSorted.isEmpty {
                        Divider()
                        ForEach(tiersSorted, id: \.self) { tier in
                            NavigationLink(value: ArtistListStruct(titleText: tier, festival: currentFestival, list: tierDict[tier]!)) {
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
                                
                                .frame(height: SMALL_BUTTON_HEIGHT, alignment: .center)
                                .buttonStyle(PlainButtonStyle())
                            }
                            if tier != tiersSorted.last { Divider() }
                        }
                        .padding(.horizontal, SIDE_BUFFER)
                    }
                }
//                .padding(.vertical, 1)
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
    
    var WebsiteSection: some View {
        Group {
            if let urlString = currentFestival.website, let URL = URL(string: toHttpWww(urlString)) {
                ZStack {
                    RoundedRectangle(cornerRadius: CORNER_RADIUS)
                    .foregroundStyle(Color("BW Color Switch Reverse"))
                    .shadow(radius: SHADOW)
                    HStack{
                        Spacer()
                        Text("Website").bold()
                        Image(systemName: "network")
                            .imageScale(.large)
                        Spacer()
                    }
                    .foregroundStyle(Color("BW Color Switch"))
                }
                .transaction { $0.animation = nil }
                .frame(height: SMALL_BUTTON_HEIGHT)
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.open(URL)
                }
                .foregroundStyle(Color("BW Color Switch"))
                .padding(10)
                
            }
        }
    }
    
    
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

struct FriendFavorites {
    let name: String
    let favorite: Array<String>
}

struct AddFestivalToGroupSheet: View {
    @EnvironmentObject var firestore: FirestoreViewModel

    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @State var navigationPath = NavigationPath()
    
    var festival: Festival
    
    @Binding var showAddFestivalToGroupSheet: Bool
    
    @State var selectedGroups: Set<String> = []
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                NavigationButtons
                (Text("Add ") + Text(festival.name).bold() + Text(" To Your Groups"))
//                Text("Add \(festival.name) To Your Groups")
                    .font(.title3)
                    .padding(.vertical)
                let sortedGroups = firestore.mySocialGroups.sorted(by: { $0.name < $1.name })
                let unaddedGroups = sortedGroups.filter({ !$0.festivals.contains(festival.id.uuidString) })
                let alreadyAddedGroups = sortedGroups.filter({ $0.festivals.contains(festival.id.uuidString) })
                ScrollView {
                    if !unaddedGroups.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(unaddedGroups.indices, id: \.self) { index in
                                let group = unaddedGroups[index]
                                HStack {
                                    SocialImage(imageURL: group.photo, name: group.name, frame: 50)
                                    Text(group.name)
                                        .foregroundStyle(.black)
                                    Spacer()
                                    GroupMemberPhotos(memberIDs: group.members)
                                    Image(systemName: selectedGroups.contains(group.id!) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(Color("OASIS Dark Orange"))
                                        .imageScale(.large)
                                        .padding(.leading, 20)
                                    //                        if firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                                    //                            Image(systemName: "chevron.right")
                                    //                                .foregroundStyle(.black)
                                    //                        } else {
                                    //                            FollowButtonShort(profile: profile)
                                    //                        }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 10)
                                .onTapGesture {
                                    if selectedGroups.contains(group.id!) {
                                        selectedGroups.remove(group.id!)
                                    } else {
                                        selectedGroups.insert(group.id!)
                                    }
                                }
                                if index < sortedGroups.count - 1 {
                                    Divider()
                                }
                            }
                            
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .background(Color.white)
                        //                .frame(maxHeight: maxHeight) // <- caps the height; scrolls after this
                        .cornerRadius(10)
                        .border(Color.gray, width: 2)
                        .padding(.horizontal, 10)
                    }
                    
                    
                    HStack {
                        Spacer()
                        NavigationLink(value: "New Group") {
                            ZStack {
                                RoundedRectangle(cornerRadius: 25)
                                    .fill(Color.white)
                                    .frame(width: 190, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.oasisDarkOrange, lineWidth: 2)
                                    )
                                    .shadow(radius: 5)
                                HStack {
                                    Image(systemName: "plus")
                                        .imageScale(.large)
                                    Text("New Group")
                                }
                                .foregroundStyle(.oasisDarkOrange)
                            }
                            .navigationDestination(for: String.self) { _ in
                                NewGroupSheet(navigationPath: $navigationPath)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    
                    
                    if !alreadyAddedGroups.isEmpty {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Already Included:")
                                Spacer()
                            }
                            .padding(.horizontal, 2)
                            VStack(spacing: 0) {
                                ForEach(alreadyAddedGroups.indices, id: \.self) { index in
                                    let group = alreadyAddedGroups[index]
                                    HStack {
                                        SocialImage(imageURL: group.photo, name: group.name, frame: 50)
                                        Text(group.name)
                                            .foregroundStyle(.black)
                                        Spacer()
                                        GroupMemberPhotos(memberIDs: group.members)
                                        //                                Image(systemName:  "checkmark.square.fill")
                                        //                                    .foregroundColor(Color(.oasisLightOrange))
                                        //                                    .imageScale(.large)
                                        //                                    .padding(.leading, 20)
                                        //                        if firestore.myUserProfile.safeFollowing.contains(profile.id!) {
                                        //                            Image(systemName: "chevron.right")
                                        //                                .foregroundStyle(.black)
                                        //                        } else {
                                        //                            FollowButtonShort(profile: profile)
                                        //                        }
                                    }
                                    .padding(.vertical, 8)
                                    .contentShape(Rectangle())
                                    .padding(.horizontal, 10)
                                    //                        .onTapGesture {
                                    //                            if selectedGroups.contains(group.id!) {
                                    //                                selectedGroups.remove(group.id!)
                                    //                            } else {
                                    //                                selectedGroups.insert(group.id!)
                                    //                            }
                                    //                        }
                                    if index < sortedGroups.count - 1 {
                                        Divider()
                                    }
                                }
                                
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .background(Color.white)
                            //                .frame(maxHeight: maxHeight) // <- caps the height; scrolls after this
                            .cornerRadius(10)
                            .border(Color.gray, width: 2)
                            
                        }
                        .padding(10)
                        //                    .padding(.vertical, 20)
                    }
                }
            }
        }
        //        .onAppear() {
        //            groupSelection = Array(repeating: false, count: firestore.mySocialGroups.count)
        //        }
    }
    
    var NavigationButtons: some View {
        VStack {
            HStack {
                Button(action: {
                    showAddFestivalToGroupSheet = false
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.red)
                })
                Spacer()
                Button(action: {
                    addGroups()
                    showAddFestivalToGroupSheet = false
                }, label: {
                        Text("Add")
                    .foregroundStyle(selectedGroups.isEmpty ? .gray : .blue)
                })
                .disabled(selectedGroups.isEmpty)
                //                        .disabled(newArtist == oldArtist)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
//            Divider()
        }
    }
    
    func addGroups() {
        Task {
            let success = await firestore.addFestivalToGroups(groupIDs: Array(selectedGroups), festivalID: festival.id.uuidString)
            if success {
                
            }
        }
    }
}

struct NewGroupSheet: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    @Binding var navigationPath: NavigationPath
    
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var setupDone = false
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State var createdGroup: DataSet.SocialGroup?
    
    @State var errorAlert: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Create New Group")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(5)
                
                ZStack(alignment: .center) {
                    if let selectedImage {
                        ZStack (alignment: .topTrailing) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130, alignment: .center)
                                .clipShape(Circle())
                            Button {
                                withAnimation {
                                    self.selectedImage = nil
                                    selectedItem = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }
                    } else {
                        Image("Default Group Profile Picture")
                            .resizable()
                            .frame(width: 130, height: 130, alignment: .center)
                            .clipShape(Circle())
                        Text("Upload Image").foregroundStyle(Color.black)
                    }
                }
                .shadow(radius: 4)
                .onTapGesture {
                    showPhotoPicker = true
                }
                ZStack {
                    TextField("Group Name", text: $groupName)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.words)
                    if !groupName.isEmpty {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark.circle")
                                .padding(.horizontal, 10)
                                .foregroundStyle(.gray)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    groupName = ""
                                }
                        }
                    }
                }
                
                
                
                Button(action: addGroup) {
                    Text("Create")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(groupName.isEmpty ? Color.gray : .blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(groupName.isEmpty || isLoading)
            }
        }
        .padding()
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem)
        .onChange(of: selectedItem) { newItem in
            Task {
                // Retrieve the image from the PhotosPickerItem
                if let selectedItem, let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .alert(isPresented: $errorAlert) {
            Alert(
                title: Text("Something went wrong"),
                message: Text("Please try again later"),
                dismissButton: .default(Text("Ok"))
            )
        }
        .onChange(of: errorAlert) { newValue in
            if newValue == false {
                navigationPath.removeLast()
            }
        }
        .onAppear() {
            groupName = ""
            selectedItem = nil
            selectedImage = nil
        }
    }
    
    func addGroup() {
        Task {
            isLoading = true
            
            do {
                var photoURL: String? = nil
                
                if let selectedImage {
                    let groupID = UUID().uuidString
                    let path = "groupImages/\(groupID).jpg"
                    
                    photoURL = await withCheckedContinuation { continuation in
                        firestore.uploadGroupImageToFirebase(
                            image: selectedImage,
                            path: path
                        ) { url in
                            continuation.resume(returning: url)
                        }
                    }
                }
                
                let newGroup = try await firestore.createGroup(
                    name: groupName,
                    photo: photoURL
                )
                
                firestore.myUserProfile.groups?.append(newGroup.id!)
                firestore.mySocialGroups.append(newGroup)
                navigationPath.removeLast()
//                navigationPath.append(newGroup)
//                showGroupSheet = false
                
            } catch {
                //print("❌ Failed to create group:", error)
                errorAlert = true
            }
            
            isLoading = false
        }
    }
}

struct MessagePopUp: View {
    let message: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(.black)
                .frame(height: 50)
                .opacity(0.9)

            Text(message)
                .foregroundStyle(.white)
        }
        .padding(10)
    }
}

//struct GroupSelector: View {
//    @EnvironmentObject var firestore: FirestoreViewModel
//    
//    @Binding var navigationPath: NavigationPath
//    var groups: [SocialGroup]
//
//    var maxHeight: CGFloat = 300
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 0) {
//                let sortedGroups = groups.sorted(by: { $0.name < $1.name })
//                
//                ForEach(sortedGroups.indices, id: \.self) { index in
//                    let group = sortedGroups[index]
//                    HStack {
//                        SocialImage(imageURL: group.photo, name: group.name, frame: 50)
////                        VStack(alignment: .leading, spacing: 5) {
//                            Text(group.name)
////                                .bold()
////                                .font(.title)
//                                .foregroundStyle(.black)
////                                .padding(.leading, 10)
//                            
////                        }
//                        Spacer()
//                        GroupMemberPhotos(memberIDs: group.members)
////                        if firestore.myUserProfile.safeFollowing.contains(profile.id!) {
//                            Image(systemName: "chevron.right")
//                                .foregroundStyle(.black)
////                        } else {
////                            FollowButtonShort(profile: profile)
////                        }
//                    }
//                    .padding(.vertical, 8)
//                    .contentShape(Rectangle())
//                    .padding(.horizontal, 10)
//                    .onTapGesture {
//                        navigationPath.append(group)
//                    }
//
//                    if index < sortedGroups.count - 1 {
//                        Divider()
//                    }
//                }
//
//            }
//            .fixedSize(horizontal: false, vertical: true)
//        }
//        .background(Color.white)
//        .frame(maxHeight: maxHeight) // <- caps the height; scrolls after this
//        .cornerRadius(10)
//        .border(Color.gray, width: 2)
//        .padding(.horizontal, 10)
//    }
//}



//#Preview {
//    FestivalPage()
//}
