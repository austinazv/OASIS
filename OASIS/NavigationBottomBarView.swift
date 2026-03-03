//
//  NavigationBottomBarView.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 5/3/25.
//

import SwiftUI

struct NavigationBottomBarView: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var explorePath: NavigationPath
    @Binding var socialPath: NavigationPath
    @Binding var myFestivalsPath: NavigationPath
    @Binding var createPath: NavigationPath
    @Binding var myProfilePath: NavigationPath
    
    @Binding var selectedTab: Int
    
    var body: some View {
        
        VStack {
//            Divider()
            TabView(selection: $selectedTab) {
//            TabView {
               
                ExploreFestivalsPage(navigationPath: $explorePath)
                    .tabItem {
                        Image(systemName: "magnifyingglass").imageScale(.large)
                        Text("Explore")
                    }
                    .tag(1)
                
//                AuthPage()
                SocialPage(navigationPath: $socialPath)
                    .tabItem {
                        Image(systemName: "person.2.fill").imageScale(.large)
                        Text("Social")
                    }
                    .tag(2)
                MyFestivalsPage(navigationPath: $myFestivalsPath, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "star.fill").imageScale(.large)
                        Text("My Festivals")
                    }
                    .tag(0)
                CreatePage(navigationPath: $createPath)
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver.fill").imageScale(.large)
                        Text("Create")
                    }
                    .tag(3)
//                SettingsPage()
                MyProfile(navigationPath: $myProfilePath)
                    .tabItem {
                        Image(systemName: "person.fill").imageScale(.large)
                        Text("Profile")
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

//#Preview {
//    NavigationBottomBarView()
//}
