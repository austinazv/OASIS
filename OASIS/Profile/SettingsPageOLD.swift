//
//  SettingsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 1/19/25.
//

import SwiftUI

struct SettingsPageOLD: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var spotify: SpotifyViewModel
    
    @State private var navigationPath = NavigationPath()
    
    
    
    var body: some View {
        VStack {
            NavigationStack(path: $navigationPath) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Settings")
                            .font(.title)
                            .bold()
                        Spacer()
                    }
                    .padding(.horizontal, 15)
                    .padding(.top, 20)
                    .padding(.bottom, 5)
                    Divider()
                    ZStack {
//                        Color(.oasisDarkBlue)
//                        Color(red: 65/255, green: 135/255, blue: 165/255)
//                            .edgesIgnoringSafeArea([.leading, .trailing, .bottom])
                        ScrollView {
                            LogOutOASISButton
                            DisconnectSpotifyButton
//                            Text(
                        }
                        .padding(.top, 5)
                    }
                }
            }
        }
        .onAppear() {

        }
    }
    
    @State var logOutAlert: Bool = false
    
    var LogOutOASISButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white) // white background
                .frame(width: 190, height: 50, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.black, lineWidth: 2) // black border
                )
            HStack {
                Text("Log Out")
                    .foregroundColor(.black)
                OASISTitle(fontSize: 18, kerning: 2)
            }
        }
        .shadow(radius: 5)
        .padding(10)
        .onTapGesture {
            logOutAlert = true
        }
        .alert(isPresented: self.$logOutAlert) {
            Alert(title: Text("Log Out of OASIS?"),

                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Log Out")) {
                firestore.signOutUser() { completion in
                    print("Done")
                }
            }
            )
        }
    }
    
    @State var disconnectAlert: Bool = false
    
    var DisconnectSpotifyButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(.spotifyColorGreen) // white background
                .frame(width: 175, height: 50, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.black, lineWidth: 2) // black border
                )
            HStack {
                Text("Disconnect")
                Image(.spotifyImageBlack)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
            }
            .foregroundColor(.black)
        }
        .shadow(radius: 5)
        .padding(10)
        .onTapGesture {
            disconnectAlert = true
        }
        .alert(isPresented: self.$disconnectAlert) {
            Alert(title: Text("Disconnect your Spotify Account?"),

                  primaryButton: .cancel(),
                  secondaryButton: .destructive(Text("Disconnect")) {
                spotify.revokeSpotifyAccessToken() { completion in
                    print("Done")
                }
//                print("TO DISCONNECT")
//                firestore.signOutUser() { completion in
//                    print("Done")
//                }
            }
            )
        }
    }
    
}

//#Preview {
//    SettingsPage()
//}
