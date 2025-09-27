//
//  NavigationBottomBarView.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI

struct NavigationBottomBarView: View {
    @EnvironmentObject var data: DataSet
    
    @State private var navigationPath = NavigationPath()
    
    @State private var selectedTab = 0
    
    var body: some View {
        
        VStack {
//            Divider()
            TabView(selection: $selectedTab) {
//            TabView {
               
                ExploreFestivalsPage()
                    .tabItem {
                        Image(systemName: "magnifyingglass").imageScale(.large)
                        Text("Explore")
                    }
                    .tag(1)
                AuthPage()
                    .tabItem {
                        Image(systemName: "person.2.fill").imageScale(.large)
                        Text("Social")
                    }
                    .tag(2)
                MyFestivalsPage(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "star.fill").imageScale(.large)
                        Text("My Festivals")
                    }
                    .tag(0)
                CreatePage()
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver.fill").imageScale(.large)
                        Text("Create")
                    }
                    .tag(3)
                SettingsPage()
                    .tabItem {
                        Image(systemName: "gearshape.2.fill").imageScale(.large)
                        Text("Settings")
                    }
                    .tag(4)
            }
            .accentColor(Color("OASIS Dark Orange"))
//            .shadow(radius: 10)
        }
//        .onAppear() {
//            if data.userInfoTemp.festivalList.isEmpty {
//                selectedTab = 1
//            }
//        }
    }
    
    
}

#Preview {
    NavigationBottomBarView()
}
