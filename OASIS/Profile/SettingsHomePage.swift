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
    
    @State var showLogInSheet: Bool = false
    
    var body: some View {
        VStack {
            MenuOptions
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showLogInSheet) {
//            LogInPage(signInText: true)
            AccountSetUpPage(showSheet: $showLogInSheet)
        }
//        .onChange(of: showLogInSheet) { _, newVal in
//            if !newVal {
//
//            }
//        }
    }
    
    var MenuOptions: some View {
        VStack {
            Spacer()
            Divider()
                .frame(height: 1)
                .background(Color.gray)

            if firestore.phoneConnected {
                Button(action: { navigationPath.append("Edit Profile") }) {
                    ZStack {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .imageScale(.large)
                            Text("Edit Profile")
                        }
                        HStack {
                            Spacer()
                            Image(systemName: "chevron.right")
                                .padding(.trailing, 20)
                        }
                    }
                    .frame(height: OPTION_HEIGHT)
                    .foregroundStyle(.bwColorSwitch)
                }
                Divider()
                    .frame(height: 1)
                    .background(Color.gray)
            }
//            Button(action: { navigationPath.append("Spotify Account") }) {
//                ZStack {
//                    HStack {
//                        Text("Spotify Account")
//                        Image(.spotifyImageBlack)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 20, alignment: .center)
//                    }
//                    HStack {
//                        Spacer()
//                        Image(systemName: "chevron.right")
//                            .padding(.trailing, 20)
//                    }
//                }
//                .frame(height: OPTION_HEIGHT)
//            }
//            Divider()
//                .frame(height: 1)
//                .background(Color.gray)

            Button(action: { navigationPath.append("About Page") }) {
                ZStack {
                    HStack {
                        Image(systemName: "bell.circle")
                            .imageScale(.large)
                        Text("Notifications")
                        
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: OPTION_HEIGHT)
                .foregroundStyle(.bwColorSwitch)
            }
            
            Divider()
                .frame(height: 1)
                .background(Color.gray)
            
            Button(action: { navigationPath.append("About Page") }) {
                ZStack {
                    HStack {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                        Text("About")
                    }
                    HStack {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .padding(.trailing, 20)
                    }
                }
                .frame(height: OPTION_HEIGHT)
                .foregroundStyle(.bwColorSwitch)
            }
            
            Divider()
                .frame(height: 1)
                .background(Color.gray)

//            LogOutOASISButton
            Spacer()
            
            LogInOutButton
            
        }
        .foregroundStyle(.oasisDarkPurple)
    }
    
    @State var logOutAlert: Bool = false
    
    var LogOutOASISButton: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white) // white background
                .frame(width: 190, height: 50, alignment: .center)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.oasisDarkPurple, lineWidth: 2) // black border
                )
            HStack {
                Text("Log Out")
                    .foregroundColor(.oasisDarkPurple)
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
                    //print("Done")
                }
            }
            )
        }
    }
    
    @State var showLogOutAlert = false
    
    var LogInOutButton: some View {
        VStack {
            if firestore.phoneConnected {
                Button(action: { showLogOutAlert = true }) {
                    Text("Log Out")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(.red)
                        .cornerRadius(10)
                }
            } else {
                Button(action: { showLogInSheet = true }) {
                    Text("Log In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(.oasisBlue)
                        .cornerRadius(10)
                }
            }
        }
        .padding(30)
        .alert(isPresented: $showLogOutAlert) {
            Alert(title: Text("Log Out?"),
//                  message: Text("This cannot be undone."),
                  primaryButton: .destructive(Text("Log Out")) {
                firestore.signOutUser() { completion in
                    navigationPath = NavigationPath()
                    //print("Logged Out")
                }
//                data.signOutUser { result in
//                    switch result {
//                    case .success:
//                        //print("User signed out successfully")
////                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
////                            }
//                        navigationPath = NavigationPath()
//                    case .failure(let error):
//                        //print("Error signing out: \(error.localizedDescription)")
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
