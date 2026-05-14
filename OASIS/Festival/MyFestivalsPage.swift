//
//  MyFestivalsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI

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
                    OASISTitle(fontSize: 40, kerning: 10)
                    .padding(.bottom, 5)
                    
                    Divider()
                    ZStack {
                        Color(red: 245/255, green: 235/255, blue: 215/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                        Group {
                            if !festivalVM.myFestivals.isEmpty {
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
                                                .foregroundStyle(.black)
                                            
                                            Button(action: {
                                                selectedTab = 1
                                            }) {
                                                HStack {
                                                    Text("Explore More Festivals")
                                                    Image(systemName: "chevron.right")
                                                }
                                            }
                                            .italic()
                                            .padding(.top, 8)
                                        }
                                        .padding(.vertical, 40)
//                                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                                        Divider()
                                            .padding(.bottom, 8)

                                        // Bottom Half (Attended)
                                        FestivalsListed(
                                            navigationPath: $navigationPath,
                                            festivalList: split.attended,
                                            title: "Attended",
                                            collapsable: true,
                                            showList: true,
                                            reversed: true
                                        )
//                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        Spacer()
                                    }
                                } else {
                                    // Default scrolling layout
                                    ScrollView {
                                        VStack {
                                            
                                            // Upcoming Section
                                            if noUpcoming {
                                                Text("No Upcoming Festivals!")
                                                    .foregroundStyle(.black)
                                                    .padding(.top, 75)
                                            } else {
                                                FestivalsListed(
                                                    navigationPath: $navigationPath,
                                                    festivalList: split.upcoming,
                                                    title: "My Festivals",
                                                    largeText: true,
                                                    collapsable: false
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
                                            .italic()
                                            .padding(8)
                                            .padding(.bottom, noUpcoming ? 75 : 0)

                                            // Attended Section
                                            if hasAttended {
                                                FestivalsListed(
                                                    navigationPath: $navigationPath,
                                                    festivalList: split.attended,
                                                    title: "Attended",
                                                    collapsable: true,
                                                    showList: false,
                                                    reversed: true
                                                )
                                                .padding(.top, 5)
                                            }
                                        }
                                    }
                                }
                            } else {
                                VStack {
//                                    if split.a
                                    Text("No Saved Festivals Yet!")
                                        .foregroundStyle(.black)
                                    Button(action: {
                                        selectedTab = 1
                                    }) {
                                        HStack {
                                            Text("Explore Festivals")
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                    .italic()
                                    .padding(8)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
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
        
        var friendInfoToPopup: [UUID : [Artist]]?
        var profile: UserProfile?
        @State var showSheet = false
        @State var selectedFestival: Festival?
        
        
        var body: some View {
            Group {
                if !festivalList.isEmpty {
                    VStack {
                        HStack {
                            Text(title)
                                .padding(10)
                                .font(largeText ? .title3 : .body)
                            if collapsable {
                                Image(systemName: showList ? "chevron.up" : "chevron.down")
                            }
                            Spacer()
                        }
                        .padding(.leading, 2)
                        .foregroundStyle(.black)
                        .bold()
                        .onTapGesture {
                            if collapsable {
                                showList.toggle()
                            }
                        }
                        if showList {
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
                                                            .foregroundStyle(.blue)
                                                    }
                                                }
                                                HStack {
                                                    Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
                                                        
                                                    if festival.secondWeekend {
                                                        Text(" | ")
                                                        Text(festivalVM.getSecondWeekendText(startDate: festival.startDate, endDate: festival.endDate))
                                                    }
                                                    Text("(\(festival.startDate.formatted(.dateTime.year())))")
//                                                    Text(festival.startDate, format: .dateTime.year())
                                                }
                                                .foregroundStyle(.gray)
                                                .font(.subheadline)
                                            }
                                            .padding(.vertical, 10)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .contentShape(Rectangle())
                                        .padding(.horizontal, 10)
                                        .onTapGesture() {
                                            if friendInfoToPopup != nil {
                                                selectedFestival = festival
                                                
                                            } else if draftView {
                                                navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView))
                                            } else {
                                                festivalVM.currentFestival = festival
                                                navigationPath.append(festival)
                                            }
                                        }
                                        
    //                                }
                                    Divider()
                                }
                                
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .border(Color.gray, width: 2)
                            .padding([.leading, .trailing, .bottom], 10)
                            
                        }
                    }
                    .onChange(of: selectedFestival) { newFestival in
                        if newFestival != nil {
                            showSheet = true
                        }
                    }
                    .onChange(of: showSheet) { bool in
                        if !bool {
                            selectedFestival = nil
                        }
                    }
                    .onChange(of: navigationPath) { _ in
                        showSheet = false
                    }
                    .sheet(isPresented: $showSheet) {
                        NavigationStack(path: $newNavigationPath) {
                            VStack {
//                                Spacer().frame(height: 200)
                                if let festival = selectedFestival, let artistDict = friendInfoToPopup, let listToShow = artistDict[festival.id] {
//                                    ArtistList(navigationPath: $newNavigationPath, currentFestival: festival, artistList: listToShow)
                                    ArtistList(navigationPath: $newNavigationPath,
                                               titleText: profile == nil ?  "Favorites" : "\(profile!.name)'s Favorites",
                                               currentFestival: festival,
                                               artistList: listToShow,
                                               secondaryNavigationPath: $navigationPath
                                    )
                                }
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
                            .withAppNavigationDestinations(navigationPath: $newNavigationPath, festivalVM: festivalVM)
                        }
//                        ArtistList(navigationPath: $navigationPath, currentFestival: currentFestival, artistList: <#T##Array<Artist>#>)
                        
                        
//                        ArtistListStruct(titleText: "\(profile.name)'s Favorites",
//                                                                       festival: currentFestival,
//                                                                       list: festivalVM.getArtistListFromID(artistIDs: friendsFavs[profile]!, festival: currentFestival))
                    }
                }
    //            else {
    //                if !festivalIDs.isEmpty {
    //                    HStack(spacing: 10) {
    //                        ProgressView()
    //                        Text("Loading")
    //                    }
    //                }
    //            }
            }
    //        .onAppear() {
    //            print("ids: \(festivalIDs)")
    //            festivalList = getFestivals(ids: festivalIDs)
    //            print("list: \(festivalList)")
    //        }
        }
        
        
        
    //    func
        
    //    struct FestivalNavTarget: Hashable {
    //        let festival: DataSet.festival
    //        let draftView: Bool
    //    }
        
        func sortFestivals(_ festivalList: Array<Festival>, reversed: Bool) -> Array<Festival> {
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

struct FestivalLogoView: View {
    let logoPath: String?
    let title: String
    let frame: CGFloat
    @State private var image: UIImage?
    
    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
//                .aspectRatio(contentMode: .fit)
                .scaledToFit()
                .frame(maxHeight: frame, alignment: .center)
        } else {
            Text(title)
                .font(.title)
                .frame(height: frame)
                .foregroundStyle(.black)
                .onAppear {
                    loadImage()
                }
        }
    }
    
    private func loadImage() {
        guard let path = logoPath else { return }

        // 1️⃣ Check cache first
        if let cached = ImageCache.shared.getCachedImage(for: path) {
            self.image = cached
            return
        }

        let url: URL

        // 2️⃣ Determine if remote or local
        if path.hasPrefix("http://") ||
           path.hasPrefix("https://") ||
           path.hasPrefix("gs://") {

            // Remote (Firebase / web)
            guard let remoteURL = URL(string: path) else { return }
            url = remoteURL

        } else {

            // Local file (relative path stored)
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            url = documentsURL.appendingPathComponent(path)
        }

        // 3️⃣ Load local file directly
        if url.isFileURL {
            if let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {

                ImageCache.shared.cacheImage(data, for: path)

                DispatchQueue.main.async {
                    self.image = img
                }
            }
            return
        }

        // 4️⃣ Load remote image
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let img = UIImage(data: data) else { return }

            ImageCache.shared.cacheImage(data, for: path)

            DispatchQueue.main.async {
                self.image = img
            }
        }.resume()
    }

}



