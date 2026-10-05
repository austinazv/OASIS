//
//  OASISWidget.swift
//  OASISWidget
//
//  Created by Austin Zambito-Valente on 7/3/26.
//

import WidgetKit
import SwiftUI
import AppIntents

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> OASISEntry {
        OASISEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            festivalID: DISPLAY_UUID_STRING,
            festivalName: "Coachella 2026",
            logoPath: nil,
            artists: nil,
            genreCounts: [:],
            startDate: Date(),
            endDate: Date()
        )
    }
    
    func snapshot(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> OASISEntry {
        OASISEntry(
            date: Date(),
            configuration: configuration,
            festivalID: DISPLAY_UUID_STRING,
            festivalName: "Coachella 2026",
            logoPath: "https://firebasestorage.googleapis.com:443/v0/b/oasis-austinzv.firebasestorage.app/o/festival_logos%2FFB17ABDA-77B3-4BF7-A4A0-F50B9BE5B658.jpg?alt=media&token=8b1aef98-f2b3-4286-b4bd-ad0d17924f89",
            artists: DISPLAY_ARTIST_ARRAY,
            genreCounts: [:],
            startDate: Calendar.current.date(byAdding: .day, value: 4, to: Date())!,
            endDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!
        )
    }
    
    func timeline(
        for configuration: ConfigurationAppIntent,
        in context: Context
    ) async -> Timeline<OASISEntry> {
        
        let selectedFestival = sharedFestival(for: configuration.festival?.id)
        
        let entry = OASISEntry(
            date: Date(),
            configuration: configuration,
            festivalID: selectedFestival?.id ?? EMPTY_UUID_STRING,
            festivalName: selectedFestival?.name ?? "No Festival",
            logoPath: selectedFestival?.logoPath,
            artists: artistsForToday(from: selectedFestival),
            genreCounts: genrePopularityCounts(from: selectedFestival?.artistList ?? []),
            startDate: selectedFestival?.startDate ?? Date(),
            endDate: selectedFestival?.endDate ?? Date()
        )
        
        let tomorrow = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )
        
        return Timeline(
            entries: [entry],
            policy: .after(tomorrow)
        )
    }
    
    func genrePopularityCounts(from artistList: [Artist]) -> [String: Int] {
        var counts: [String: Int] = [:]

        for artist in artistList {
            for genre in artist.genres {
                counts[genre, default: 0] += 1
            }
        }

        return counts
    }
    
    
    
    
    
//    func artistForToday(from festival: SharedFestival?) -> Artist? {
//
//        guard let festival,
//              !festival.artistList.isEmpty else {
//            return nil
//        }
//
//        let shuffled = festival.artistList.seededShuffle(seed: festival.id)
//
//        let day = Calendar.current.ordinality(
//            of: .day,
//            in: .year,
//            for: Date()
//        ) ?? 0
//
//        return shuffled[day % shuffled.count]
//    }
    
    
    
    
    //    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
    //        // Generate a list containing the contexts this widget is relevant in.
    //    }
    
    
}

struct OASISEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent

    let festivalID: UUID
    let festivalName: String
    let logoPath: String?
    let artists: [Artist]?
    let genreCounts: [String: Int]
    let startDate: Date
    let endDate: Date
}


struct OASISWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            let calendar = Calendar.current
            if calendar.startOfDay(for: entry.date) > calendar.startOfDay(for: entry.endDate) {
                Text("Til Next Year!").multilineTextAlignment(.center).foregroundStyle(.oasisDarkPurpleUninverted)
            } else {
                switch family {
                case .systemSmall:
                    WidgetSmall
                case .systemMedium:
                    WidgetMedium
                case .systemLarge:
                    WidgetLarge
                case .systemExtraLarge:
                    WidgetSmall
                default:
                    WidgetSmall
                }
            }
        }
        
//        .containerBackground(.white, for: .widget)
    }
    
    var refreshIntent: RefreshFestivalIntent {
        let intent = RefreshFestivalIntent()
        intent.festival = entry.configuration.festival
        return intent
    }
    
    func currentDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    
    
    
    var WidgetSmall: some View {
        ZStack {
           
            if entry.festivalID == EMPTY_UUID_STRING {
                Text("No Festival Selected").multilineTextAlignment(.center)
            } else {
                VStack {
                    FestivalLogoView(logoPath: entry.logoPath, title: entry.festivalName, frame: 28, invert: false, smallFont: true)
                        .offset(y: -10)
                    Spacer()
                    if let artist = entry.artists?.first {
                        let widgetURL = URL(string: "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)/artist/\(artist.id)")
                        HStack {
                            ArtistImage(imageURL: artist.imageURL, frame: 50)
                            Spacer()
                            Text(artist.name)
                                .foregroundStyle(.oasisDarkPurpleUninverted)
                                .font(.system(size: 12))
                                .lineLimit(3)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .padding(7)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
                        )
                        
                        
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.oasisDarkPurpleUninverted, lineWidth: 1)
                        )
                        .widgetURL(widgetURL)
                        
                        Spacer()
                        HStack {
                            Text("Artist of the Day")
                                .foregroundStyle(.oasisDarkPurpleUninverted)
                                .italic()
                                .font(Font.system(size: 11))
                                .offset(x: 4, y: 0)
                            Spacer()
                            Button(intent: refreshIntent) {
                                Image(systemName: "shuffle")
                            }
                            .foregroundStyle(.oasisDarkPurpleUninverted)
                            .buttonStyle(.plain)
                            .offset(x: 3)
                            
                        }
                        .offset(y: 3)
                    }
                }
            }
        }
    }
    
    
    
    var WidgetMedium: some View {
        ZStack {
            if entry.festivalID == EMPTY_UUID_STRING {
                Text("No Festival Selected").multilineTextAlignment(.center)
            } else {
                if let artistList = entry.artists {
                    //                    if artistList.count > 2 {
                    let festivalURL = "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)"
                    VStack {
                        FestivalLogoView(logoPath: entry.logoPath, title: entry.festivalName, frame: 28, invert: false, smallFont: true)
                            .offset(y: -10)
                        Spacer()
                        ZStack {
                            HStack(spacing: 10) {
                                ForEach(artistList) { artist in
                                    let artistURL = "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)/artist/\(artist.id)"
                                    Link(destination: URL(string: artistURL)!) {
                                        VStack {
                                            ArtistImage(imageURL: artist.imageURL, frame: 49)
                                            Text(artist.name)
                                                .foregroundStyle(.oasisDarkPurpleUninverted)
                                                .font(.system(size: 12))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(height: 30, alignment: .center)
                                        }
                                        .frame(width: 62)
                                        .padding(7)
                                        //                                    .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.white)
                                                .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
                                        )
                                        
                                        
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.oasisDarkPurpleUninverted, lineWidth: 1)
                                        )
                                    }
                                }
                                Spacer()
                            }
                            HStack {
                                Spacer()
                                let days = daysUntilFestival(
                                    startDate: entry.startDate,
                                    currentDate: entry.date
                                )
                                VStack {
                                    Countdown(days: days, xOffset: 10, yOffset: 15)
                                    Spacer()
                                }
                            }
                            //                            Spacer()
//                            VStack {
//                                let days = daysUntilFestival(
//                                    startDate: entry.startDate,
//                                    currentDate: entry.date
//                                )
//                                Group {
//                                    if days > 0 {
////                                    if false {
//                                        VStack(spacing: 0) {
//                                            Text(String(days))
//                                            Text("Days")
//                                        }
//                                        .foregroundStyle(.oasisDarkPurpleUninverted)
//                                        .font(.system(size: 12))
//                                        .fixedSize(horizontal: true, vertical: false)
//                                        .padding(10)
//                                        .offset(y: -2)
//                                    } else {
//                                        Text("Today!")
//                                            .foregroundStyle(.oasisDarkPurpleUninverted)
//                                            .font(.system(size: 10))
//                                                .lineLimit(1)
//                                                .fixedSize(horizontal: true, vertical: false)
//                                                .padding(18)
//                                    }
//                                }
//                                .background(
//                                    Starburst(points: STARBURST_NUM_POINTS, innerRadiusRatio: 0.8)
//                                        .fill(.white)
//                                )
//                                .overlay(
//                                    Starburst(points: STARBURST_NUM_POINTS, innerRadiusRatio: 0.8)
//                                        .stroke(.oasisDarkPurpleUninverted, lineWidth: 1)
//                                )
//                                .rotationEffect(Angle(degrees: STARBURST_ANGLE))
//                                .scaleEffect(1.1)
//                                Spacer()
//                            }
//                            .offset(x: 3)
                            //                            .padding(.vertical)
                        }
                        //                    }
                        //                    Spacer()
                        //                    HStack {
                        //                        Text("Artist of the Day")
                        //                            .italic()
                        //                            .font(Font.system(size: 11))
                        //                            .offset(x: -3, y: 1)
                        //
                        //
                        //                    }
                        //                    .offset(y: 3)
                    }
                    .widgetURL(URL(string: festivalURL)!)
                    //                    } else {
                    //                        WidgetSmall
                    //                    }
                    //                } else {
                    //                    WidgetSmall
                    //                }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(intent: refreshIntent) {
                                //                        Image(systemName: "arrow.clockwise")
                                Image(systemName: "shuffle")
                                    .font(.system(size: 26, design: .monospaced))
                                
                            }
                            .foregroundStyle(.oasisDarkPurpleUninverted)
                            .buttonStyle(.plain)
                            .offset(/*x: -3,*/ y: 3)
                        }
                    }
                }
            }
        }
    }
    
    
    
    var WidgetLarge: some View {
        ZStack {
            if entry.festivalID == EMPTY_UUID_STRING {
                Text("No Festival Selected").multilineTextAlignment(.center)
            } else {
                if let artistList = entry.artists {
                    //                    if artistList.count > 2 {
                    let festivalURL = "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)"
                    VStack {
                        //                            Link(destination: URL(string: festivalURL)!) {
                        FestivalLogoView(logoPath: entry.logoPath, title: entry.festivalName, frame: 28, invert: false, smallFont: true)
                            .offset(y: -10)
                        //                            }
                        //                            Spacer()
                        HStack(spacing: 10) {
                            VStack(spacing: 10) {
                                //                                ForEach(artistList.enumerated().map { $0 }, id: \.1) { index, artist in
                                ForEach(artistList) { artist in
                                    let artistURL = "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)/artist/\(artist.id)"
                                    Link(destination: URL(string: artistURL)!) {
                                        HStack {
                                            ArtistImage(imageURL: artist.imageURL, frame: 57)
                                            Text(artist.name)
                                                .foregroundStyle(.oasisDarkPurpleUninverted)
                                                .font(.system(size: 16))
                                                .lineLimit(3)
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .frame(width: 85, alignment: .leading)
                                            FlowLayoutWidget() {
                                                //                                                FlowLayout(spacing: 8, maxRows: 2, alignment: .trailing) {
                                                ForEach(genresSortedByPopularity(genres: artist.genres, genreCounts: entry.genreCounts), id: \.self) { genre in
                                                    HStack {
                                                        Text(genre).font(.system(size: 12)).italic()
                                                    }
                                                    .foregroundStyle(.oasisDarkPurpleUninverted)
                                                    .padding(4)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .fill(.white)
                                                        //                                                                    .shadow(color: .oasisDarkPurpleUninverted, radius: 1, x: 0, y: 2)
                                                    )
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 5)
                                                            .stroke(.oasisDarkPurpleUninverted, lineWidth: 1)
                                                    )
                                                    //                                                        }
                                                    //                                                        .buttonStyle(.plain)
                                                    //                            .onTapGesture {
                                                    //                                let genreList = festivalVM.getGenreList(genre: genre, currList: currFest.artistList)
                                                    //                                navigationPath.append(ArtistListStruct(titleText: genre, festival: currFest, list: genreList))
                                                    //                            }
                                                }
                                            }
                                            
                                            //                                                if let firstGenre = artist.genres.first {
                                            //                                                    Text(firstGenre)
                                            //                                                }
                                            //                                                Divider()
                                            //                                                Spacer()
                                            //                                            }
                                        }
                                        .frame(height: 56)
                                        .padding(7)
                                        //                                    .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(.white)
                                                .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
                                        )
                                        
                                        
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.oasisDarkPurpleUninverted, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        let playListCreationURL = "https://oasis-austinzv.web.app/share/festival/\(entry.festivalID.uuidString)/makePlaylist"
                        Link(destination: URL(string: playListCreationURL)!) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Create Playlist")
                                    .font(.system(size: 14))
                            }
                            .foregroundStyle(.oasisDarkPurpleUninverted)
                            .padding(8)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white)
                                    .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.oasisDarkPurpleUninverted, lineWidth: 1)
                            )
                            .offset(y: 10)
                        }
                        //                            .padding(10)
                        Spacer()
                    }
                    .widgetURL(URL(string: festivalURL)!)
                    //                    } else {
                    //                        WidgetSmall
                    //                    }
//                } else {
//                    WidgetSmall
                    VStack {
                        Spacer()
                        HStack {
                            let days = daysUntilFestival(
                                startDate: entry.startDate,
                                currentDate: entry.date
                            )
                            Countdown(days: days, yOffset: -10).offset(x: 10)
                            
////                            Group {
////                                if days > 0 {
////                                    VStack(spacing: 0) {
////                                        Text(String(days))
////                                        Text("Days")
////                                    }
////                                    .foregroundStyle(.oasisDarkPurpleUninverted)
////                                    .font(.system(size: 12))
////                                    .padding(10)
////                                    .offset(y: -2)
////                                } else {
////                                    Text("Today!")
////                                        .foregroundStyle(.oasisDarkPurpleUninverted)
////                                        .font(.system(size: 10))
////                                        .padding(18)
////                                }
////                            }
//                            .background(
//                                Starburst(points: STARBURST_NUM_POINTS, innerRadiusRatio: 0.8)
//                                    .fill(.white)
//                            )
//                            .overlay(
//                                Starburst(points: STARBURST_NUM_POINTS, innerRadiusRatio: 0.8)
//                                    .stroke(.oasisDarkPurpleUninverted, lineWidth: 1)
//                            )
//                            .rotationEffect(Angle(degrees: STARBURST_ANGLE * -1.0))
//                            .scaleEffect(1.1)
                            .offset(y: 2)
                            
                            //                    Spacer()
                            
                            
                            //
                            ////                    Text("OASIS")
                            ////                        .font(.system(size: 18/*, weight: .bold*/))
                            ////                        .kerning(10)
                            ////                        .foregroundStyle(.oasisDarkPurpleUninverted)
                            ////                        .offset(y: 12)
                            //                    OASISTitleComposable(fontSize: 20, showSpinnerO: false)
                            
                            Spacer()
                            Button(intent: refreshIntent) {
                                //                        Image(systemName: "arrow.clockwise")
                                Image(systemName: "shuffle")
                                    .font(.system(size: 26, design: .monospaced))
                            }
                            .foregroundStyle(.oasisDarkPurpleUninverted)
                            .buttonStyle(.plain)
                            .offset(x: 3, y: 0)
                        }
                    }
                }
            }
            //            VStack {
            //                Spacer()
            ////                let numPoints = 15
            //                Text("103 Days")
            //                    .padding(.vertical, 10)
            //                    .padding(.horizontal, 15)
            ////                .offset(y: -2)
            //                .font(.system(size: 16))
            //                .background(
            ////                    Starburst(points: STARBURST_NUM_POINTS).scale(2)
            //                    StarburstRectangle(points: 13)
            //                        .fill(.white)
            //                )
            //                .overlay(
            ////                    Starburst(points: STARBURST_NUM_POINTS).scale(2)
            //                    StarburstRectangle(points: 13)
            //                        .stroke(.oasisDarkPurpleUninverted, lineWidth: 1)
            //                )
            //                .offset(y: 2)
            //            }
            
            
        }
    }
    
    
    
    
    let STARBURST_NUM_POINTS = 15
    let STARBURST_ANGLE: Double = 15
    
}



func daysUntilFestival(startDate: Date, currentDate: Date) -> Int {
    let calendar = Calendar.current

    let startOfCurrentDay = calendar.startOfDay(for: currentDate)
    let startOfFestivalDay = calendar.startOfDay(for: startDate)

    return calendar.dateComponents([.day],
                                   from: startOfCurrentDay,
                                   to: startOfFestivalDay).day ?? 0
}

//            if let selectedFestival = entry.configuration.festival {
//                FestivalLogoView(logoPath: selectedFestival.logoPath, title: <#T##String#>, frame: <#T##CGFloat#>)
//            }
//            Text(entry.configuration.festival?.name ?? "No Festival")
//            Text("OASIS").font(.system(size: 25)).kerning(10).foregroundStyle(.oasisDarkPurpleUninverted)
//            gradient.ignoresSafeArea(.all)
//            OASISTitleComposable(fontSize: 25, showSpinnerO: false)
//            Text("Time:")
//            Text(entry.date, style: .time)
//
//            Text("Favorite Emoji:")
//            Text(entry.configuration.favoriteEmoji)

struct OASISWidget: Widget {
    let kind: String = "OASISWidget"
    
    private let gradient = LinearGradient(
            colors: [
                Color("OASIS Dark Orange"),
                Color("OASIS Light Orange"),
                Color("OASIS Light Blue"),
                Color("OASIS Dark Blue")
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            OASISWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            Color.white
//                            Color(.bwColorSwitchReverse)
                                .frame(height: addWhiteBorder(entry: entry) ? 40 : 0)
//                                .frame(height: entry.festivalID == EMPTY_UUID_STRING ? 0 : 40)
                            gradient
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
        }
    }
    
    func addWhiteBorder(entry: OASISEntry) -> Bool {
        let calendar = Calendar.current
        if calendar.startOfDay(for: entry.date) > calendar.startOfDay(for: entry.endDate) { return false }
        
        if entry.festivalID == EMPTY_UUID_STRING { return false }
        
        return true
    }
}

//extension ConfigurationAppIntent {
////    static var title: LocalizedStringResource = "Configure Widget"
//    
////    @Parameter(title: "Festival")
////    var festival: FestivalEntity?
//    
//        fileprivate static var smiley: ConfigurationAppIntent {
//            let intent = ConfigurationAppIntent()
//            intent.favoriteEmoji = "😀"
//            return intent
//        }
//    
//        fileprivate static var starEyes: ConfigurationAppIntent {
//            let intent = ConfigurationAppIntent()
//            intent.favoriteEmoji = "🤩"
//            return intent
//        }
//}

//#Preview(as: .systemSmall) {
//    OASISWidget()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley)
//    SimpleEntry(date: .now, configuration: .starEyes)
//}


struct Starburst: Shape {
    var points: Int = 20
    var innerRadiusRatio: CGFloat = 0.82

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * innerRadiusRatio

        var path = Path()

        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius

            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

struct StarburstRectangle: Shape {
    var points: Int = 24
    var innerRadiusRatio: CGFloat = 0.82

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let outerX = rect.width / 2
        let outerY = rect.height / 2

        let innerX = outerX * innerRadiusRatio
        let innerY = outerY * innerRadiusRatio

        var path = Path()

        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2

            let xRadius = i.isMultiple(of: 2) ? outerX : innerX
            let yRadius = i.isMultiple(of: 2) ? outerY : innerY

            let point = CGPoint(
                x: center.x + cos(angle) * xRadius,
                y: center.y + sin(angle) * yRadius
            )

            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }
}

struct Countdown: View {
    var days: Int
    var numberFontSize: CGFloat = 20
    var xOffset: CGFloat = 0
    var yOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 2) {
            if days <= 0 {
                Text("TODAY!").font(.system(size: 16 , design: .monospaced)).offset(x: xOffset, y: yOffset)
            } else {
                Text("\(days)").font(.system(size: numberFontSize, design: .monospaced)).bold()
                Text(days == 1 ? "day!" : "days!").font(.system(size: 16, design: .monospaced)).offset(x: 1)
            }
        }
        .shadow(radius: 1)
        .foregroundStyle(.white)
        
//        .padding(4)
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(.white)
//            //                .shadow(color: .oasisDarkPurpleUninverted, radius: 2, x: 0, y: 2)
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(Color.oasisDarkPurpleUninverted, lineWidth: 1)
//        )
    }

    
}
