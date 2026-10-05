//
//  MyFestivalsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct MyFestivalsPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var spotify: SpotifyViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State var selectedFestival: Festival?
    
    @State var festivalDrafts: Array<Festival> = []
    @State var likedFestival: Array<Festival> = []
    
    @Binding var selectedTab: Int
    
    // Read the shared namespace from the environment (provided by OASISApp)
//    @Environment(\.oasisNamespace) private var oasisNamespaceEnv
//    @Namespace private var localNamespace // fallback for previews
//    private var ns: Namespace.ID { oasisNamespaceEnv ?? localNamespace }
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    // Use the composable with the same matchedGeometry ids as the loading screen
//                    OASISTitle(fontSize: 40, kerning: 10)
                    OASISTitleComposable(fontSize: 40, showSpinnerO: false)
                    .padding(.bottom, 5)
                    
                    Divider()
                    ZStack {
                        Color(.oasisBackgroundMyFestivals)
//                        Color(red: 245/255, green: 235/255, blue: 215/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                        Group {
                            if !festivalVM.myFestivals.isEmpty {
                                ScrollView {
                                    let split = festivalVM.splitFestivals(festivalVM.myFestivals)
                                    
                                    let noUpcoming = split.upcoming.isEmpty
                                    let hasAttended = !split.attended.isEmpty
                                    let showHalfSplit = noUpcoming && hasAttended
                                    
                                    if showHalfSplit {
                                        // Special layout: 50/50 split
                                        VStack(spacing: 0) {
                                            
                                            // Top Half (Empty Upcoming)
                                            VStack {
                                                Text("No Upcoming Festivals!")
                                                    .foregroundStyle(.oasisDarkPurpleUninverted)
                                                
                                                Button(action: {
                                                    selectedTab = 1
                                                }) {
                                                    HStack {
                                                        Text("Explore More Festivals")
                                                        Image(systemName: "chevron.right")
                                                    }
                                                }
                                                .italic()
                                                .bold()
                                                .foregroundStyle(.oasisBlue)
                                                .padding(.top, 8)
                                            }
                                            .padding(.vertical, 40)
                                            //                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            
                                            Divider()
                                                .padding(.bottom, 8)
                                            
                                            // Bottom Half (Attended)
                                            FestivalWall(navigationPath: $navigationPath,
                                                         festivalList: split.attended,
//                                                             festivalList: festivalVM.myFestivals,
                                                         title: "My Festival Wall",
                                                         collapsable: true,
                                                         reversed: true,
                                                         color: .oasisBorderMyFestivals,
                                                         selectedTab: $selectedTab
                                            )
                                            //                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            Spacer()
                                        }
                                    } else {
                                        // Default scrolling layout
                                        //                                    ScrollView {
                                        VStack {
                                            
                                            // Upcoming Section
                                            if noUpcoming {
                                                Text("No Upcoming Festivals!")
                                                    .foregroundStyle(.oasisDarkPurple)
                                                    .padding(.top, 75)
                                            } else {
                                                FestivalsListed(
                                                    navigationPath: $navigationPath,
                                                    festivalList: split.upcoming,
                                                    title: "My Festivals",
                                                    largeText: true,
                                                    collapsable: false,
                                                    color: .oasisBorderMyFestivals,
                                                    selectedTab: $selectedTab
                                                )
                                            }
                                            
                                            Button(action: {
                                                selectedTab = 1
                                            }) {
                                                HStack {
                                                    Text("Explore More Festivals")
                                                    Image(systemName: "chevron.right")
                                                }
                                            }
                                            .foregroundStyle(.oasisBlue)
                                            .bold()
                                            .italic()
                                            .padding(8)
                                            .padding(.bottom, noUpcoming ? 75 : 0)
                                            
                                            // Attended Section
                                            if hasAttended {
                                                FestivalWall(navigationPath: $navigationPath,
                                                             festivalList: split.attended,
//                                                             festivalList: festivalVM.myFestivals,
                                                             title: "My Festival Wall",
                                                             collapsable: true,
                                                             reversed: true,
                                                             color: .oasisBorderMyFestivals,
                                                             selectedTab: $selectedTab
                                                )
                                                //                                                FestivalsListed(
                                                //                                                    navigationPath: $navigationPath,
                                                //                                                    festivalList: split.attended,
                                                //                                                    title: "Attended",
                                                //                                                    collapsable: true,
                                                //                                                    showList: false,
                                                //                                                    reversed: true,
                                                //                                                    color: .oasisBorderMyFestivals
                                                //                                                )
                                                .padding(.top, 5)
                                            }
                                        }
                                        //                                    }
                                    }
                                }
                            } else {
                                VStack {
//                                    if split.a
                                    Text("No Saved Festivals Yet!")
                                        .foregroundStyle(.oasisDarkPurple)
                                    Button(action: {
                                        selectedTab = 1
                                    }) {
                                        HStack {
                                            Text("Explore Festivals")
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                    .italic()
                                    .bold()
                                    .foregroundStyle(.oasisBlue)
                                    .padding(8)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM, selectedTab: $selectedTab)
                }
            }
        }
//        .onAppear {
//            print(festivalDrafts)
//            
//        }
    }
    
    //            self.selectedFestival = nil
//            }
//        }
        
        
        
        func sortedFestivals(festivalList: Array<Festival>) -> Array<Festival> {
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
        
        
        
    //    init() {
    //        likedFestival = []
    //
    ////        let formatter = DateFormatter()
    ////        formatter.dateFormat = "yyyy-MM-dd"
    //////        formatter.timeZone = TimeZone(secondsFromGMT: 0)
    ////
    ////        let ladyGaga = DataSet.artistNEW(id: "1HY2Jd0NmPuamShAr6KMms", name: "Lady Gaga", genres: ["Pop", "Jazz", "Dance"], photo: UIImage(resource: .ladyGaga), stage: "Coachella Stage")
    ////        let postMalone = DataSet.artistNEW(id: "246dkjvS1zLTtiykXe5h60", name: "Post Malone", genres: ["Pop", "Country"], photo: UIImage(resource: .postMalone), stage: "Coachella Stage")
    ////        let greenDay = DataSet.artistNEW(id: "7oPftvlwr6VrsViSDV7fJY", name: "Green Day", genres: ["Pop"], photo: UIImage(resource: .greenDay), stage: "Coachella Stage")
    ////        let zedd = DataSet.artistNEW(id: "2qxJFvFYMEDqd7ui6kSAcq", name: "Zedd", genres: ["EDM", "Dance"], photo: UIImage(resource: .zedd), stage: "Outdoor Stage")
    ////
    ////        self.likedFestival = [
    ////            DataSet.festival(id: UUID(uuidString: "6DB0C167-CE8D-4C33-B8F9-78C4955C5EFC")!, name: "Coachella", startDate: formatter.date(from: "2025-04-11")!, endDate: formatter.date(from: "2025-04-13")!, logo: Image("Coachella"), artistList: [ladyGaga, postMalone, greenDay, zedd], website: URL(string: "https://www.coachella.com/"), published: true),
    ////            DataSet.festival(id: UUID(uuidString: "FC9887EB-98AF-4637-876E-F71588B343C9")!, name: "Stagecoach", startDate: formatter.date(from: "2025-04-25")!, endDate: formatter.date(from: "2025-04-27")!, logo: Image("Stagecoach"), artistList: [ladyGaga], website: URL(string: "https://www.stagecoachfestival.com/"), published: true),
    //////            DataSet.festival(name: "EDC Las Vegas", dates: edcDates, logo: Image("EDC"), artistList: [ladyGaga]),
    ////            DataSet.festival(id: UUID(uuidString: "3408C3E5-2927-43C2-9078-EE5090BB01BD")!, name: "Lollapalooza", startDate: formatter.date(from: "2025-07-31")!, endDate: formatter.date(from: "2025-08-03")!, artistList: [ladyGaga], published: true),
    //////            DataSet.festival(name: "Boiler Room", dates: boilerDates, artistList: [ladyGaga])
    ////        ]
    //    }
            
        
        
    }

    struct QuarterCircle: View {
        let radius: CGFloat = 44
        
        
        var body: some View {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addArc(center: .zero,
                            radius: radius,
                            startAngle: .degrees(90),
                            endAngle: .degrees(180),
                            clockwise: false)
                path.closeSubpath()
            }
            .fill(Color.white)
            .frame(width: radius, height: radius)
            .offset(x: radius)
        }
    }

    struct FestivalsListed: View {
        @EnvironmentObject var data: DataSet
        @EnvironmentObject var firestore: FirestoreViewModel
        @EnvironmentObject var festivalVM: FestivalViewModel
        
        @Binding var navigationPath: NavigationPath
        @State var newNavigationPath = NavigationPath()
        
        var festivalList: Array<Festival>

        var title: String
        var largeText: Bool = false
        
        var collapsable: Bool
        var draftView: Bool = false
        
        @State var showList = true
        @State var reversed = false
        
        
        @State var showSheet = false
        
        @State var selectedFestival: Festival?
        
//        var friendInfoToPopup: [UUID : [Artist]]?
        var profile: UserProfile?
        
//        var groupInfoToPopup: [UUID : [Artist]]?
        var socialGroup: SocialGroup?
        
        var color: Color = Color.oasisLightBlue
        
        var warningMessage: String?
        
        var dontSort: Bool = false
        
        var showStar: Bool = false
        
//        var selectedTab: Binding<Int>?
        @Binding var selectedTab: Int
        
        var body: some View {
            ZStack {
                if !festivalList.isEmpty {
                    VStack {
                        HStack {
                            Text(title)
                                .padding(10)
                                .font(largeText ? .title3 : .body)
                                
                            if collapsable {
                                Image(systemName: "chevron.down").rotationEffect(showList ? Angle(degrees: -180) : Angle(degrees: 0))
//                                Image(systemName: showList ? "chevron.up" : "chevron.down")
                            }
                            Spacer()
                        }
                        .padding(.leading, 2)
                        .foregroundStyle(.oasisDarkPurpleUninverted)
                        .bold()
                        .onTapGesture {
                            if collapsable {
                                withAnimation {
                                    showList.toggle()
                                }
                            }
                        }
                        if showList {
                            VStack(spacing: 8) {
                                VStack {
                                    let sortedList = sortFestivals(festivalList, reversed: reversed)
                                    ForEach(sortedList) { festival in
                                        //                                NavigationLink(value: FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView)) {
                                        //                                NavigationLink(value: festival) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack {
                                                    FestivalLogoView(
                                                        logoPath: festival.logoPath,
                                                        title: festival.name,
                                                        frame: 40.0
                                                    )
                                                    if festival.verified {
                                                        Image(systemName: "checkmark.seal.fill")
                                                        //                                                        .foregroundStyle(.blue)
                                                            .foregroundStyle(.oasisBlue)
                                                    }
                                                }
                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack {
                                                        Image(systemName: "calendar")
                                                        Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
                                                        
                                                        if festival.secondWeekend {
                                                            Text(" | ")
                                                            Text(festivalVM.getSecondWeekendText(startDate: festival.startDate, endDate: festival.endDate))
                                                        }
                                                        Text("(\(festival.startDate.formatted(.dateTime.year())))")
                                                    }
                                                    if let festivalLocation = festival.location {
                                                        HStack {
                                                            Image(systemName: "map")
                                                            Text(festivalLocation)
                                                        }
                                                    }
                                                }
                                                .foregroundStyle(.gray)
                                                .font(.subheadline)
                                            }
                                            .padding(.vertical, 10)
                                            Spacer()
                                            if showStar {
                                                if festivalVM.festivalIsFavorited(festivalID: festival.id) {
                                                    Image(systemName: "star.fill")
                                                        .foregroundStyle(.oasisLightOrange)
                                                        .font(.system(size: 25))
                                                }
                                            }
                                            Image(systemName: "chevron.right")
                                        }
                                        .contentShape(Rectangle())
                                        .padding(.horizontal, 10)
                                        .onTapGesture() {
                                            if profile != nil || socialGroup != nil {
                                                selectedFestival = festival
                                            } else if draftView {
                                                navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView, selectedTab: $selectedTab))
                                            } else {
                                                festivalVM.currentFestival = festival
                                                navigationPath.append(festival)
                                            }
                                        }
                                        
                                        //                                }
                                        Divider()
                                            .foregroundStyle(.bwColorSwitch)
                                    }
                                    
                                }
                                .background(Color.bwColorSwitchReverse)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(color, lineWidth: 2)
                                    //                                    .stroke(Color.gray, lineWidth: 2)
                                )
                                if let string = warningMessage {
                                    HStack {
//                                        Spacer()
                                        Image(systemName: "exclamationmark.triangle")
                                        Text(string)
                                        Spacer()
                                    }
                                    //                                .padding(.horizontal, 12)
                                    .font(.footnote)
                                    .foregroundStyle(.oasisDarkGrey)
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding([.leading, .trailing, .bottom], 10)
                            
                        }
                    }
                    .onChange(of: selectedFestival) { _, newFestival in
                        if newFestival != nil {
                            showSheet = true
                        }
                    }
                    .onChange(of: showSheet) { _, bool in
                        if !bool {
                            selectedFestival = nil
                        }
                    }
                    .onChange(of: navigationPath) {
                        showSheet = false
                    }
                    .sheet(isPresented: $showSheet) {
                        NavigationStack(path: $newNavigationPath) {
                            VStack {
                                if let festival = selectedFestival {
                                    if let user = profile {
                                        let userFavorites = festivalVM.getUserFavorites(userLikes: user.safeFavoriteArtistsList, artistList: festival.artistList)
                                        if !userFavorites.isEmpty {
                                            ArtistList(navigationPath: $newNavigationPath,
                                                       titleText: "\(user.name)'s Favorites",
                                                       currentFestival: festival,
                                                       artistList: userFavorites,
                                                       secondaryNavigationPath: $navigationPath
                                            )
                                        } else {
                                            VStack {
                                                Text("\(user.name) has no favorited artists attending \(festival.name).")
                                                HStack {
                                                    Text("Go to festival")
                                                    Image(systemName: "chevron.right")
                                                }
                                                .padding()
                                                .italic()
                                                .underline()
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showSheet = false
                                                    navigationPath.append(festival)
                                                }
                                            }
                                            .padding(10)
                                            .multilineTextAlignment(.center)
                                        }
                                    } else if let group = socialGroup {
                                        let groupUsers = group.members.compactMap { firestore.usersByID[$0] }
                                        let groupFavorites = festivalVM.getGroupFavorites(from: groupUsers)
                                        if !groupFavorites.isEmpty {
                                            let artistList = festivalVM.getArtistListFromID(artistIDs: groupFavorites.map(\.artistID), festival: festival)
                                            ArtistList(navigationPath: $newNavigationPath,
                                                       titleText: "\(group.name) Favorites",
                                                       currentFestival: festival,
                                                       artistList: artistList,
                                                       groupFavs: groupFavorites,
                                                       sortType: .group,
                                                       secondaryNavigationPath: $navigationPath
                                            )
                                        } else {
                                            VStack {
                                                Text("No \(group.name) members have any favorited artists attending \(festival.name).")
                                                HStack {
                                                    Text("Go to festival")
                                                    Image(systemName: "chevron.right")
                                                }
                                                .padding()
                                                .italic()
                                                .underline()
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    showSheet = false
                                                    navigationPath.append(festival)
                                                }
                                            }
                                            .padding(10)
                                            .multilineTextAlignment(.center)
                                        }
                                    }
                                    
                                    
                                    
                                    
                                    
                                    
                                    
//                                    if let artistDict = friendInfoToPopup, let listToShow = artistDict[festival.id] {
//                                        ArtistList(navigationPath: $newNavigationPath,
//                                                   titleText: profile == nil ?  "Favorites" : "\(profile!.name)'s Favorites",
//                                                   currentFestival: festival,
//                                                   artistList: listToShow,
//                                                   secondaryNavigationPath: $navigationPath
//                                        )
//                                    } else if (false) {//TODO: GROUP STUFF
//                                        Text("TODO")
//                                    } else {
//                                        VStack {
//                                            if let name = profile?.name {
//                                                Text("\(name) has no favorited artists attending \(festival.name).")
//                                            } else if let groupName = group?.name {
//                                                Text("No \(groupName) members have any favorited artists attending \(festival.name).")
//                                            } else {
//                                                Text("No artists to show.")
//                                            }
//                                            HStack {
//                                                Text("Go to festival")
//                                                Image(systemName: "chevron.right")
//                                            }
//                                            .padding()
//                                            .italic()
//                                            .underline()
//                                            .contentShape(Rectangle())
//                                            .onTapGesture {
//                                                showSheet = false
//                                                navigationPath.append(festival)
//                                            }
//                                        }
//                                        .padding(10)
//                                        .multilineTextAlignment(.center)
//                                    }
                                } else {
                                    Text("No artists to show.")
                                }
                                
                                
                                
                                
                                //                                Spacer().frame(height: 200)
//                                if let festival = selectedFestival, let artistDict = friendInfoToPopup, let listToShow = artistDict[festival.id] {
//                                    ArtistList(navigationPath: $newNavigationPath,
//                                               titleText: profile == nil ?  "Favorites" : "\(profile!.name)'s Favorites",
//                                               currentFestival: festival,
//                                               artistList: listToShow,
//                                               secondaryNavigationPath: $navigationPath
//                                    )
//                                    //                                    }
//                                } else {
//                                    VStack {
//                                        if let festival = selectedFestival {
//                                            if let name = profile?.name {
//                                                Text("\(name) has no favorited artists attending \(festival.name).")
//                                            } else {
//                                                Text("No artists to show.")
//                                            }
//                                            HStack {
//                                                Text("Go to festival")
//                                                Image(systemName: "chevron.right")
//                                            }
//                                            .italic()
//                                            .underline()
//                                            .contentShape(Rectangle())
//                                            .onTapGesture {
//                                                showSheet = false
//                                                navigationPath.append(festival)
//                                            }
//                                        } else {
//                                            Text("No artists to show.")
//                                        }
//                                    }
//                                    .padding(10)
//                                    .multilineTextAlignment(.center)
//                                }
                                
                                
                            }
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Group {
                                        Button (action: {
                                            showSheet = false
                                        }, label: {
                                            Image(systemName: "xmark")
                                        })
                                    }
                                    //                                    .foregroundStyle(.blue)
                                }
                            }
                            .withAppNavigationDestinations(navigationPath: $newNavigationPath, festivalVM: festivalVM, selectedTab: $selectedTab)
                        }
                    }
                }
            }
//            .onAppear() {
//                print("FESTIVALS LISTED: \(selectedTab?.wrappedValue)")
//            }
            
        }
        
        
        
    //    func
        
    //    struct FestivalNavTarget: Hashable {
    //        let festival: DataSet.festival
    //        let draftView: Bool
    //    }
        
        func sortFestivals(_ festivalList: Array<Festival>, reversed: Bool) -> Array<Festival> {
            if dontSort { return festivalList }
            var sortedFestivals = festivalList.sorted {
                if $0.startDate == $1.startDate {
                    if $0.endDate == $1.endDate {
                        return $0.name < $1.name
                    }
                    return $0.endDate < $1.endDate
                }
                return $0.startDate < $1.startDate
    //            ($0.dates.first ?? Date.distantFuture) < ($1.dates.first ?? Date.distantFuture)
            }
            if reversed { sortedFestivals = sortedFestivals.reversed() }
            return sortedFestivals
        }
        
        
    }


struct SelectedFestivals: View {
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    var festivalList: Array<Festival>
    @Binding var selectedFestivals: Set<UUID>
    var title: String
    
    var fontSize: CGFloat
    
    var isLoading: Bool
    
    var body: some View {
        VStack {
            if !festivalList.isEmpty || isLoading {
                VStack(spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: fontSize))
                            .bold()
                        Spacer()
                        Image(systemName: festivalList.count == selectedFestivals.count ? "checkmark.square.fill" : "square")
                            .imageScale(.large)
                            .foregroundColor(.oasisDarkOrange)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if festivalList.count == selectedFestivals.count {
                                    selectedFestivals.removeAll()
                                } else {
                                    selectedFestivals.formUnion(festivalList.map { $0.id })
                                }
                            }
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        if !isLoading {
                            ForEach(Array(festivalList.enumerated()), id: \.element.id) { index, festival in
                                //                                let festival = unconnectedFestivals[index]
                                HStack {
                                    VStack(alignment: .leading) {
                                        FestivalLogoView(logoPath: festival.logoPath, title: festival.name, frame: 35.0)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Image(systemName: "calendar")
                                                Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
                                                
                                                if festival.secondWeekend {
                                                    Text(" | ")
                                                    Text(festivalVM.getSecondWeekendText(startDate: festival.startDate, endDate: festival.endDate))
                                                }
                                                Text("(\(festival.startDate.formatted(.dateTime.year())))")
                                            }
                                            if let festivalLocation = festival.location {
                                                HStack {
                                                    Image(systemName: "map")
                                                    Text(festivalLocation)
                                                }
                                            }
                                        }
                                        .foregroundStyle(.gray)
                                        .font(.subheadline)
                                    }
                                    //                                    SocialImage(imageURL: group.photo, name: group.name, frame: 50)
                                    //                                    Text(festival.name)
                                    //                                        .foregroundStyle(.oasisDarkPurple)
                                    Spacer()
                                    //                                    GroupMemberPhotos(memberIDs: group.members)
                                    //                                Text(festival.startDate.formatted(.dateTime.year()))
                                    //                                    .foregroundStyle(.gray)
                                    //                                    .font(.subheadline)
                                    //                                Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
                                    Image(systemName: selectedFestivals.contains(festival.id) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.oasisLightOrange)
                                        .imageScale(.large)
                                        .padding(.leading, 20)
                                    
                                    
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .padding(.horizontal, 10)
                                .onTapGesture {
                                    if selectedFestivals.contains(festival.id) {
                                        selectedFestivals.remove(festival.id)
                                    } else {
                                        selectedFestivals.insert(festival.id)
                                    }
                                }
                                if index < festivalList.count - 1 {
                                    Divider()
                                }
                            }
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color.bwColorSwitchReverse)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    
                    .padding(.top, 2)
                }
                .padding(.horizontal, 10)
            }
        }
    }
}

//struct FestivalLogoView: View {
//    let logoPath: String?
//    let title: String
//    let frame: CGFloat
//    @State private var image: UIImage?
//    
//    var body: some View {
//        Group {
//            if let image = image {
//                InvertInDarkModeImage(image: image, frame: frame)
//                //            Image(uiImage: image)
//                //                .resizable()
//                ////                .aspectRatio(contentMode: .fit)
//                //                .scaledToFit()
//                //                .frame(maxHeight: frame, alignment: .center)
//            } else {
//                Text(title)
//                    .font(.title)
//                    .frame(height: frame)
//                    .foregroundStyle(.bwColorSwitch)
////                    .onAppear {
////                        loadImage()
////                    }
//            }
//        }
//        .onAppear {
//            loadImage()
//        }
//        .onChange(of: logoPath) {
//            image = nil
//            loadImage()
//        }
//    }
//    
//    private func loadImage() {
//        guard let path = logoPath else { return }
//
//        // 1️⃣ Check cache first
//        if let cached = ImageCache.shared.getCachedImage(for: path) {
//            self.image = cached
//            return
//        }
//
//        let url: URL
//
//        // 2️⃣ Determine if remote or local
//        if path.hasPrefix("http://") ||
//           path.hasPrefix("https://") ||
//           path.hasPrefix("gs://") {
//
//            // Remote (Firebase / web)
//            guard let remoteURL = URL(string: path) else { return }
//            url = remoteURL
//
//        } else {
//
//            // Local file (relative path stored)
//            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            url = documentsURL.appendingPathComponent(path)
//        }
//
//        // 3️⃣ Load local file directly
//        if url.isFileURL {
//            if let data = try? Data(contentsOf: url),
//               let img = UIImage(data: data) {
//
//                ImageCache.shared.cacheImage(data, for: path)
//
//                DispatchQueue.main.async {
//                    self.image = img
//                }
//            }
//            return
//        }
//
//        // 4️⃣ Load remote image
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            guard let data = data,
//                  let img = UIImage(data: data) else { return }
//
//            ImageCache.shared.cacheImage(data, for: path)
//
//            DispatchQueue.main.async {
//                self.image = img
//            }
//        }.resume()
//    }
//
//}





