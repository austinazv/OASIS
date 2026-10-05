//
//  FestivalWall.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 8/17/26.
//

import SwiftUI

struct FestivalWall: View {
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
    
    var profile: UserProfile?

    var socialGroup: SocialGroup?
    
    var color: Color = Color.oasisLightBlue
    
    var warningMessage: String?
    
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
                        let sortedList = sortFestivals(festivalList, reversed: reversed)
                        FestivalPosterGrid(festivals: sortedList, color: color, navigationPath: $navigationPath)
                        
                        
                        
                        
                        
//                        VStack(spacing: 8) {
//                            VStack {
//                                
//                                ForEach(sortedList) { festival in
//                                    //                                NavigationLink(value: FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView)) {
//                                    //                                NavigationLink(value: festival) {
//                                    HStack {
//                                        VStack(alignment: .leading) {
//                                            HStack {
//                                                FestivalLogoView(
//                                                    logoPath: festival.logoPath,
//                                                    title: festival.name,
//                                                    frame: 40.0
//                                                )
//                                                if festival.verified {
//                                                    Image(systemName: "checkmark.seal.fill")
//                                                    //                                                        .foregroundStyle(.blue)
//                                                        .foregroundStyle(.oasisBlue)
//                                                }
//                                            }
//                                            VStack(alignment: .leading, spacing: 2) {
//                                                HStack {
//                                                    Image(systemName: "calendar")
//                                                    Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
//                                                    
//                                                    if festival.secondWeekend {
//                                                        Text(" | ")
//                                                        Text(festivalVM.getSecondWeekendText(startDate: festival.startDate, endDate: festival.endDate))
//                                                    }
//                                                    Text("(\(festival.startDate.formatted(.dateTime.year())))")
//                                                }
//                                                if let festivalLocation = festival.location {
//                                                    HStack {
//                                                        Image(systemName: "map")
//                                                        Text(festivalLocation)
//                                                    }
//                                                }
//                                            }
//                                            .foregroundStyle(.gray)
//                                            .font(.subheadline)
//                                        }
//                                        .padding(.vertical, 10)
//                                        Spacer()
//                                        Image(systemName: "chevron.right")
//                                    }
//                                    .contentShape(Rectangle())
//                                    .padding(.horizontal, 10)
//                                    .onTapGesture() {
//                                        if profile != nil || socialGroup != nil {
//                                            selectedFestival = festival
//                                            
//                                        } else if draftView {
//                                            navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView))
//                                        } else {
//                                            festivalVM.currentFestival = festival
//                                            navigationPath.append(festival)
//                                        }
//                                    }
//                                    
//                                    //                                }
//                                    Divider()
//                                        .foregroundStyle(.bwColorSwitch)
//                                }
//                                
//                            }
//                            .background(Color.bwColorSwitchReverse)
//                            
//                            if let string = warningMessage {
//                                HStack {
//                                    //                                        Spacer()
//                                    Image(systemName: "exclamationmark.triangle")
//                                    Text(string)
//                                    Spacer()
//                                }
//                                //                                .padding(.horizontal, 12)
//                                .font(.footnote)
//                                .foregroundStyle(.oasisDarkGrey)
//                                .padding(.horizontal, 4)
//                            }
//                        }
                        
                        
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


struct FestivalPosterGrid: View {
    let festivals: [Festival]
    
    var color: Color = Color.oasisLightBlue
    
    @Binding var navigationPath: NavigationPath
    
//    let columnSpacing: CGFloat = 22

    private let columns = [
        GridItem(.flexible(), spacing: 22),
        GridItem(.flexible(), spacing: 22),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(festivals) { festival in
                FestivalPosterView(festival: festival, navigationPath: $navigationPath)
            }
        }
//        .padding(.vertical, 12)
        .padding(.bottom, 12)
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .background(Color.bwColorSwitchReverse)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color, lineWidth: 2)
            //                                    .stroke(Color.gray, lineWidth: 2)
        )
        .padding([.leading, .trailing, .bottom], 10)
    }
}


struct FestivalPosterView: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    let festival: Festival
    
    @Binding var navigationPath: NavigationPath
    
    @State private var poster: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    // MARK: - Hanging string
        
    private let stringWidth: CGFloat = 15
    private let stringHeight: CGFloat = 12
    private let stringThickness: CGFloat = 1
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if let poster {
                    Button(action: {
                        festivalVM.currentFestival = festival
                        navigationPath.append(festival)
                    }, label: {
                        Image(uiImage: poster)
                            .resizable()
                            .scaledToFill()
                    })
                } else {
                    Rectangle()
//                        .fill(colorFromString(festival.id.uuidString))
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color("OASIS Dark Orange"),
                                Color("OASIS Light Orange"),
                                Color("OASIS Light Blue"),
                                Color("OASIS Dark Blue")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(maxWidth: .infinity)
                        
                        .aspectRatio(4 / 5, contentMode: .fit)
                        .overlay {
//                            if isLoading {
//                                ProgressView()
//                            } else {
                                Button(action: {
                                    festivalVM.currentFestival = festival
                                    navigationPath.append(festival)
                                }, label: {
                                    PosterStandIn
                                })
                                .foregroundStyle(.oasisDarkPurple)
//                            }
                        }
//                        .scaleEffect(1.3)
                }
            }
//            .aspectRatio(2 / 3, contentMode: .fit)
            .overlay {
                Rectangle()
                    .stroke(.oasisDarkPurple, lineWidth: 2)
                    .overlay {
                        Rectangle()
                            .inset(by: 1)
                            .stroke(Color.white, lineWidth: 2)
                    }
            }
            HangingString(
                    width: stringWidth,
                    height: stringHeight
                )
            .stroke(.oasisDarkPurple, lineWidth: stringThickness)
                .frame(height: stringHeight)
                .offset(y: -stringHeight)
        }
        .rotationEffect(Angle(degrees: getRotation(festival.startDate)))
        .padding(.vertical, 5)
        .task {
            await loadPoster()
        }
    }
    
    var PosterStandIn: some View {
        VStack(spacing: 10) {
            VStack {
                Text(festival.name).bold()
                Text("\(festival.startDate.formatted(.dateTime.year()))")
            }
            .font(Font.system(size: 16))
            .foregroundStyle(.oasisDarkPurple)
            //                .padding()]
            VStack(spacing: 2) {
                Text(festivalVM.getDates(startDate: festival.startDate, endDate: festival.endDate))
                if festival.secondWeekend {
                    Text(festivalVM.getSecondWeekendText(startDate: festival.startDate, endDate: festival.endDate))
                }
                if let festivalLocation = festival.location {
                    //                        Image(systemName: "map")
                    Text(festivalLocation)
                }
            }
            
            .font(Font.system(size: 13))
            .foregroundStyle(.oasisDarkGrey)
        }
        .multilineTextAlignment(.center)
    }
    
    private func colorFromString(_ string: String) -> Color {
        var hash: UInt64 = 0

        for scalar in string.unicodeScalars {
            hash = hash &* 31 &+ UInt64(scalar.value)
        }

        let hue = Double(hash % 360) / 360.0
        let saturation = 0.6
        let brightness = 0.85

        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func loadPoster() async {
        isLoading = true

        // Try cache first
        if let posterPath = festival.posterPath,
           let cachedURL = ImageCache.shared.cachedFileURL(
               for: posterPath,
               displayName: festival.name
           ),
           let image = UIImage(contentsOfFile: cachedURL.path) {
            
            poster = image
            isLoading = false
            return
        }

        // Fallback to Firebase
        await withCheckedContinuation { continuation in
            firestore.loadPoster(
                festivalID: festival.id,
                festivalName: festival.name
            ) { result in
                switch result {
                case .success(let url):
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        DispatchQueue.main.async {
                            if let data, let image = UIImage(data: data) {
                                poster = image
                            } else {
                                hasError = true
                                
                                if let error {
                                    print("Failed to download poster: \(error)")
                                }
                            }

                            isLoading = false
                            continuation.resume()
                        }
                    }.resume()

                case .failure(let error):
                    DispatchQueue.main.async {
                        hasError = true
                        isLoading = false
                        print("Failed to load poster from Firebase: \(error)")
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    func getRotation(_ date: Date) -> Double {
        let maxDegree = 3
        let range = (maxDegree * 2) + 1
        
        var hash = UInt64(date.timeIntervalSince1970.bitPattern)
        
        hash ^= hash >> 33
        hash &*= 0xff51afd7ed558ccd
        hash ^= hash >> 33
        hash &*= 0xc4ceb9fe1a85ec53
        hash ^= hash >> 33
        
        return Double(Int(hash % UInt64(range)) - maxDegree)
    }
}

struct HangingString: Shape {
    let width: CGFloat
    let height: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let centerX = rect.midX
        let topY = rect.minY
        let bottomY = rect.maxY
        
        // Left side
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX - width / 2, y: bottomY))
        
        // Right side
        path.move(to: CGPoint(x: centerX, y: topY))
        path.addLine(to: CGPoint(x: centerX + width / 2, y: bottomY))
        
        return path
    }
}

//#Preview {
//    FestivalWall()
//}
