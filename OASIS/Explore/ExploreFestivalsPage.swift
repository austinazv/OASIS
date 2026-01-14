//
//  MyFestivalsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI
import Search

struct ExploreFestivalsPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @StateObject private var explore = ExploreViewModel()
    
    @State private var navigationPath = NavigationPath()
    
    @State var searching: Bool = false
    
    
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
                        Image(systemName: searching ? "xmark" : "magnifyingglass")
                            .imageScale(.large)
                            .foregroundStyle(searching ? .red : .blue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                searching.toggle()
                                if searching { searchFocused = true }
                            }
                        
                        //                            }
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                    Divider()
                    ZStack {
                        //                        Color(.oasisDarkOrange)
                        Color(red: 235/255, green: 230/255, blue: 245/255)
                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                        if !searching {
                            if explore.isLoading {
                                Spacer()
                                ProgressView()
                                    .foregroundStyle(.black)
                                Spacer()
                            } else {
                                //                            if !searching {
                                ScrollView {
                                    FestivalsListed(navigationPath: $navigationPath, festivalList: explore.festivals, title: "Upcoming", collapsable: true)
                                }
                                .padding(.top, 5)
                                .refreshable {
                                    explore.fetchVerifiedFestivals()
                                }
                            }
                        } else {
                            SearchView
                        }
                    }
                    
                }
                .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
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
    
    @State var searchText = ""
    @FocusState var searchFocused: Bool
    
    @State var filtering = false
    
    
    var SearchView: some View {
        Group {
            VStack {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                filtering.toggle()
                                searchFocused = !filtering
                            }
                        ZStack {
                            TextField(filtering ? "Search With Filters": "Search For Events", text: $searchText)
                                .padding(5)
                                .background(Color(.systemGray6))
                                .cornerRadius(30)
                                .autocapitalization(.words)
                            //                        .frame(height: FRAME_HEIGHT)
                                .focused($searchFocused)
                            if !searchText.isEmpty {
                                HStack {
                                    Spacer()
                                    Image(systemName: "xmark.circle")
                                        .padding(.horizontal, 10)
                                        .contentShape(Rectangle())
                                        .foregroundStyle(.gray)
                                        .onTapGesture {
                                            searchText = ""
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 5)
                        Image(systemName: "magnifyingglass")
                            .imageScale(.large)
                            .foregroundStyle(.blue)
                            .contentShape(Rectangle())
                            .onTapGesture() {
                                if !searchText.isEmpty {
                                    Task {
                                        let results = await explore.searchAlgoliaDatabase(query: searchText,
                                                                      searchBy: searchBy,
                                                                      searchDate: searchDate,
                                                                      date1: date,
                                                                      date2: afterDate,
                                                                      verified: verifiedOnly)
                                        print("Found \(results.count) festivals")
                                    }
                                }
                            }
                    }
                    .padding(10)
                    if filtering {
                        Divider()
                        FilterView
                    }
                }
                .background(Color.gray.opacity(0.2))
//                .shadow(radius: 2)
                //                Divider()
                //            }
                
                //            Spacer()
                ScrollView {
                    //TODO: Search Results
                    Text("...Search Results")
                }
            }
        }
    }
    
    
    
    var FilterView : some View {
        Group {
            SearchBySection
            Divider()
            DateSection
            Divider()
            VerifiedSection
            Divider()
            SearchButton
            Divider()
        }
    }
    
    @State var searchBy: ExploreViewModel.SearchBy = .Name
    
    var SearchBySection: some View {
//        VStack(spacing: 0) {
            HStack {
                Text("Search By:")
                    .foregroundStyle(.black)
                Spacer()
                Picker("Search By", selection: $searchBy) {
                    Text("Event Name").tag(ExploreViewModel.SearchBy.Name)
                    Text("Event Location").tag(ExploreViewModel.SearchBy.Location)
                    Text("Artist").tag(ExploreViewModel.SearchBy.Artist)
                    Text("Creator").tag(ExploreViewModel.SearchBy.Creator)
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.blue)
            }
            .padding(.leading, 10)
            .padding(.vertical, 2)
            
//        }
    }
    @State var searchDate: ExploreViewModel.SearchDate = .After
    @State var date = Date()
    @State var showCal = false
    
    @State var afterDate = Date()
    @State var showAfterCal = false
    
    var DateSection: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Date", selection: $searchDate) {
                    Text("After Date").tag(ExploreViewModel.SearchDate.After)
                    Text("Before Date").tag(ExploreViewModel.SearchDate.Before)
                    Text("Between Dates").tag(ExploreViewModel.SearchDate.Between)
                    Text("On").tag(ExploreViewModel.SearchDate.On)
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.blue)
                Spacer()
                if searchDate != .Between {
                    Text("\(date.formatted(date: .long, time: .omitted))")
                        .foregroundStyle(.blue)
                        .onTapGesture {
                            showAfterCal = false
                            showCal.toggle()
                        }
                }
            }
            .padding(.trailing, 10)
            if searchDate != .Between && showCal {
                DatePicker(
                    "Select a date",
                    selection: $date,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
            }
//            Divider()
            if searchDate == .Between {
                VStack {
                    HStack {
                        Text("Start Date:")
                        Spacer()
                        Text("\(date.formatted(date: .long, time: .omitted))")
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showAfterCal = false
                                showCal.toggle()
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 5 )
                    if showCal {
                        DatePicker(
                            "Select a date",
                            selection: $afterDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                    }
                    
                    HStack {
                        Text("End Date:")
                        Spacer()
                        Text("\(afterDate.formatted(date: .long, time: .omitted))")
                            .foregroundStyle(.blue)
                            .onTapGesture {
                                showCal = false
                                showAfterCal.toggle()
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)
                    if showAfterCal {
                        DatePicker(
                            "Select a date",
                            selection: $afterDate,
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                    }
//                    Divider()
                }
            }
//            Divider()
        }
        .padding(.vertical, 2)
    }
    
    @State var verifiedOnly = false
    
    var VerifiedSection: some View {
        HStack {
            Toggle(isOn: $verifiedOnly) {
                Text("Search Verified Only:")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
    
    var SearchButton: some View {
        HStack {
            Spacer()
            Text("Search With Filters")
            Image(systemName: "chevron.right")
            Spacer()
        }
        .foregroundStyle(.blue)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            print("TODO: search")
        }
    }
    
//    var EventDates: some View {
//        Group {
//            Section(header:
//                        HStack {
//                Text(singleDayEvent ? "Date" : "Dates")
//                Text("*").foregroundStyle(.red)
//            }
//            ) {
//                VStack {
//                    Toggle(isOn: $singleDayEvent, label: { Text("Single Day Event") }).padding(.vertical, 1)
//                    Divider()
//                    HStack {
//                        Text(getStartDateText())
//                        Spacer()
//                        Text("\(draft.newFestival.startDate.formatted(date: .long, time: .omitted))")
//                            .foregroundStyle(Color("OASIS Dark Orange"))
//                    }
//                    .padding(.vertical, 4)
//                    .onTapGesture {
//                        showStartDates.toggle()
//                        showEndDates = false
//                        dismissKeyboard()
//                    }
//                    if showStartDates {
//                        Divider()
//                        DatePicker(
//                            "Select a date",
//                            selection: $draft.newFestival.startDate,
//                            //                            selection: $startDate,
//                            displayedComponents: [.date]
//                        )
//                        .datePickerStyle(.graphical)
//                    }
//                    if !singleDayEvent {
//                        Divider()
//                        HStack {
//                            Text(draft.newFestival.secondWeekend ? "Weekend 1 End Date:" : "End Date:")
//                            Spacer()
//                            Text("\(draft.newFestival.endDate.formatted(date: .long, time: .omitted))")
//                                .foregroundStyle(Color("OASIS Dark Orange"))
//                        }
//                        .padding(.vertical, 4)
//                        .onTapGesture {
//                            showEndDates.toggle()
//                            showStartDates = false
//                            dismissKeyboard()
//                        }
//                        if showEndDates {
//                            Divider()
//                            DatePicker(
//                                "Select a date",
//                                selection: $draft.newFestival.endDate,
//                                in: draft.newFestival.startDate...,
//                                displayedComponents: [.date]
//                            )
//                            .datePickerStyle(.graphical)
//                        }
//                        Divider()
//                        HStack {
//                            if draft.newFestival.secondWeekend {
//                                let secondWeekendText = festivalVM.getSecondWeekendText(startDate: draft.newFestival.startDate, endDate: draft.newFestival.endDate)
//                                Text("Weekend 2: \(secondWeekendText)")
//                                Spacer()
//                                Image(systemName: "minus.circle")
//                                    .padding(.trailing, 5)
//                            } else {
//                                Image(systemName: "plus.circle")
//                                Text("Add Second Weekend")
//                                Spacer()
//                            }
//                        }
//                        .foregroundStyle(.gray)
//                        .padding(.vertical, 3)
//                        .contentShape(Rectangle())
//                        .onTapGesture() {
//                            draft.newFestival.secondWeekend.toggle()
//                        }
//                        
//                    }
//                }
//            }
//            .onChange(of: singleDayEvent) { _ in
//                draft.newFestival.endDate = draft.newFestival.startDate
//                draft.newFestival.secondWeekend = false
//                dismissKeyboard()
//            }
//            .onChange(of: draft.newFestival.startDate) { newDate in
//                if singleDayEvent {
//                    draft.newFestival.endDate = newDate
//                } else if draft.newFestival.endDate < newDate {
//                    draft.newFestival.endDate = newDate
//                }
//            }
//            .onChange(of: draft.newFestival) { _ in
//                if !hasBeenEdited {
//                    hasBeenEdited = true
//                }
//            }
//            
//        }
//    }
}
