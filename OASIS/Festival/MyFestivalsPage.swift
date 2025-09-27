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
    
    @State private var navigationPath = NavigationPath()
    
    @State var selectedFestival: DataSet.Festival?
    
    @State var festivalDrafts: Array<DataSet.Festival> = []
    @State var likedFestival: Array<DataSet.Festival> = []
    
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    Text("OASIS")
                        .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .kerning(10)
                        .font(Font.system(size: 40))
                        .padding(.bottom, 5)
                        .italic()
                    Divider()
                    ZStack {
                        Color(red: 245/255, green: 235/255, blue: 215/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
//                        HStack {
//                            Spacer()
//                            VStack {
//                                NavigationLink(value: "New Event") {
//                                    HStack {
//                                        Text("Create")
//                                            
//                                        Image(systemName: "plus")
//                                    }
//                                    .padding(.horizontal, 10)
//                                    .padding(.vertical, 3)
//                                    
//                                    .background(content: {
//                                        UnevenRoundedRectangle(bottomLeadingRadius: 20)
//                                            .frame(height: 35)
//                                            .foregroundStyle(Color("BW Color Switch Reverse"))
//                                            .shadow(radius: 0)
//                                    })
//                                }
//                                
////                                    ZStack {
////                                        UnevenRoundedRectangle(bottomLeadingRadius: 20)
////                                            .frame(width: 40, height: 40)
////                                            .foregroundStyle(Color("BW Color Switch Reverse"))
////                                            .shadow(radius: 0)
////                                        NavigationLink(value: "New Event") {
////                                            Image(systemName: "plus.circle.fill")
////                                                .imageScale(.large)
////                                                .foregroundStyle(Color("OASIS Dark Orange"))
////                                                .shadow(radius: 1)
////                                        }
////                                    }
////                                    .shadow(radius: 0)
//                                
//                                Spacer()
//                            }
//                            .ignoresSafeArea()
//                        }
//                        .ignoresSafeArea()
                        Group {
                            if !data.userInfoTemp.festivalList.isEmpty {
                                ScrollView {
//                                    FestivalsListed(festivalList: data.userInfoTemp.festivalList, title: "My Festivals", collapsable: false)
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
                                }
                                
                            } else {
                                VStack {
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
//                    .navigationDestination(for: DataSet.festival.self) { festival in
//                        FestivalPage(navigationPath: $navigationPath, festivalVM: festivalVM, currentFestival: festival)
//                    }
                   
                    .navigationDestination(for: DataSet.ArtistListStruct.self) { page in
//                        ArtistList(currDict: data.list, titleText: data.title, sortType: .alpha, subsectionLen: 1)
                        ArtistList(navigationPath: $navigationPath, titleText: page.titleText, artistList: page.list)
                            .environmentObject(spotify)
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
                    .navigationDestination(for: FestivalViewModel.FestivalNavTarget.self) { navTarget in
//                        if navTarget.draftView {
                            NewEventPage(festival: navTarget.festival, /*festivalCreator: festivalVM,*/ /*festivalList: $festivalDrafts, */navigationPath: $navigationPath)
                            .environmentObject(festivalVM)
//                        }
//                        else {
//                            FestivalPage(navigationPath: $navigationPath, festivalVM: festivalVM, currentFestival: navTarget.festival, previewView: navTarget.previewView)
//                        }
                    }
                    .navigationDestination(for: String.self) { value in
                        switch(value) {
                        case "Settings":
                            SettingsPage()
                        case "FestivalView":
                            FestivalPage(navigationPath: $navigationPath/*, festivalVM: festivalVM*/)
                                .environmentObject(festivalVM)
                        case "Favorites":
                            ArtistList(navigationPath: $navigationPath, titleText: "Favorites", artistList: festivalVM.getFavorites())
                                .environmentObject(festivalVM)
//                        case "New Event":
////                            print(festivalList)
//                            NewEventPage(festivalList: $festivalDrafts, navigationPath: $navigationPath)
//                        case "Shuffle All":
//                            ArtistPage(currentArtist: data.shuffleArtistNEW(currentList: festival.), includeFavorites: true)
                        default:
                            SettingsPage()
                        }
                    }
                }
                
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
            print(festivalDrafts)
//            self.selectedFestival = nil
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
    
    var festivalList: Array<DataSet.Festival>

    var title: String
    var collapsable: Bool
    var draftView: Bool = false
    
    @State var showList = true
    
    var body: some View {
        Group {
            if !festivalList.isEmpty {
                VStack {
                    HStack {
                        Text(title)
                            .padding(10)
                        if collapsable {
                            Image(systemName: showList ? "chevron.up" : "chevron.down")
                        }
                        Spacer()
                    }
                    .foregroundStyle(.black)
                    .bold()
                    .onTapGesture {
                        if collapsable {
                            showList.toggle()
                        }
                    }
                    if showList {
                        VStack {
                            ForEach(sortFestivals(festivalList)) { festival in
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
                                        if draftView {
                                            navigationPath.append(FestivalViewModel.FestivalNavTarget(festival: festival, draftView: draftView))
                                        } else {
                                            festivalVM.currentFestival = festival
                                            navigationPath.append("FestivalView")
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
    
    func sortFestivals(_ festivalList: Array<DataSet.Festival>) -> Array<DataSet.Festival> {
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
                .aspectRatio(contentMode: .fit)
                .frame(height: frame)
        } else {
            Text(title)
                .font(.title)
                .onAppear {
                    loadImage()
                }
        }
    }

    private func loadImage() {
        guard let logoPath else { return }
        
        if logoPath.starts(with: "http"),
           let url = URL(string: logoPath) {
            // Remote load
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = img
                    }
                }
            }.resume()
        } else {
            // Local load
            let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(logoPath)
            self.image = UIImage(contentsOfFile: fileURL.path)
        }
    }
}

//#Preview {
//    MyFestivalsPage()
//}
