//
//  SpotifyConnectPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 10/16/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import FirebaseStorage

struct SpotifyConnectPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var spotify: SpotifyViewModel
    
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedIn = false
    
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State private var navigationPath = NavigationPath()
    

    var body: some View {
        VStack(spacing: 20) {
            TitleField
            Spacer()
                .frame(height: 100)
            ConnectButton
            Spacer()
        }
        .padding()
        
    }
    
    var TitleField: some View {
        VStack {
            Text("Welcome to")
                .font(Font.system(size: 20))
                .padding(10)
            OASISTitle(fontSize: 75.0)
        }
    }
    
    var ConnectButton: some View {
        VStack(spacing: 40) {
            HStack {
                Text("Connect to")
                Image(.spotifyFullLogoBlack)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                Text("to continue")
            }
            .font(.headline)
            .multilineTextAlignment(.center)
            Button(action: spotify.openSpotifyLogin) {
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(.spotifyColorGreen)
                        .frame(width: 145, height: 50, alignment: .center)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.black, lineWidth: 2) // black border
                        )
                        .shadow(radius: 5) // Shadow on the pressable area only
                    HStack {
                        Text("Connect")
                        Image(.spotifyImageBlack)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
}
