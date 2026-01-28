//
//  SpotifyAccount.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/14/26.
//

import SwiftUI

struct SpotifyAccount: View {
    @EnvironmentObject var spotify: SpotifyViewModel
    
    //    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        DisconnectSpotifyButton
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
            })
        }
    }
}

#Preview {
    SpotifyAccount()
}
