//
//  SettingsHomePage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 12/2/25.
//

import SwiftUI

struct SettingsHomePage: View {
    var body: some View {
        VStack {
            MenuOptions
        }
        .navigationTitle("Settings")
    }
    
    var MenuOptions: some View {
        VStack {
            Spacer()
            Divider()
            HStack {
                Text("Profile Settings")
                Image(systemName: "gear.circle")
            }
            .frame(height: OPTION_HEIGHT)
            Divider()
            HStack {
                Text("About")
                Image(systemName: "info.circle")
            }
            .frame(height: OPTION_HEIGHT)
            Divider()
            Spacer()
        }
        .foregroundStyle(.oasisDarkOrange)
    }
    
    let OPTION_HEIGHT: CGFloat = 40
}

#Preview {
    SettingsHomePage()
}
