//
//  SettingsHomePage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 12/2/25.
//

import SwiftUI

struct SettingsHomePage: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    
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
                .frame(height: 1)
                .background(Color.gray)

            Button(action: { navigationPath.append("Edit Profile") }) {
                ZStack {
                    HStack {
                        Text("Edit Profile")
                        Image(systemName: "gear.circle")
                            .imageScale(.large)
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: OPTION_HEIGHT)
            }
            Divider()
                .frame(height: 1)
                .background(Color.gray)

            Button(action: { navigationPath.append("Spotify Account") }) {
                ZStack {
                    HStack {
                        Text("Spotify Account")
                        Image(.spotifyImageBlack)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20, alignment: .center)
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: OPTION_HEIGHT)
            }
            Divider()
                .frame(height: 1)
                .background(Color.gray)

            Button(action: { navigationPath.append("About Page") }) {
                ZStack {
                    HStack {
                        Text("About")
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: OPTION_HEIGHT)
            }
            
            Divider()
                .frame(height: 1)
                .background(Color.gray)

//            LogOutOASISButton
            Spacer()
            LogOutButton
            
        }
        .foregroundStyle(.black)
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
    
    @State var showLogOutAlert = false
    
    var LogOutButton: some View {
        VStack {
            Button(action: { showLogOutAlert = true }) {
                Text("Log Out")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.red)
                    .cornerRadius(10)
            }
        }
        .padding(30)
        .alert(isPresented: $showLogOutAlert) {
            Alert(title: Text("Log Out?"),
//                  message: Text("This cannot be undone."),
                  primaryButton: .destructive(Text("Log Out")) {
                firestore.signOutUser() { completion in
                    print("Logged Out")
                }
//                data.signOutUser { result in
//                    switch result {
//                    case .success:
//                        print("User signed out successfully")
////                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
////                            }
//                        navigationPath = NavigationPath()
//                    case .failure(let error):
//                        print("Error signing out: \(error.localizedDescription)")
//                    }
//                }
            }, secondaryButton: .cancel()
            )
        }
    }
    
    let OPTION_HEIGHT: CGFloat = 40
}

//#Preview {
//    SettingsHomePage()
//}
