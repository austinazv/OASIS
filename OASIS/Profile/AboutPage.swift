//
//  AboutPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/14/26.
//

import SwiftUI

struct AboutPage: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("OASIS Dark Orange"),
                    Color("OASIS Light Orange"),
                    Color("OASIS Light Blue"),
                    Color("OASIS Dark Blue")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea([.leading, .trailing, .bottom, .top])
            ScrollView {
                CreatorImage
                AboutMe
                ContactMeOptions
                PrivacyPolicySection
            }
        }
    }
    
    var CreatorImage: some View {
        Image(.austinZambitoValenteOASISCreator)
            .resizable()
            .scaledToFill()
            .frame(width: 280, height: 280)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.black, lineWidth: 2) // change color and width as needed
            )
            .shadow(radius: SHADOW)
    }
    
    var AboutMe: some View {
        (Text("About Me: ").bold() + Text(aboutMeText))
            .multilineTextAlignment(.center)
            .padding()
            .font(.callout)
    }
    
    let aboutMeText = "Hello & welcome to OASIS!\nMy name is Austin Zambito-Valente, and I am the sole developer of OASIS. I started creating OASIS as a personal way to discover new artists and new events around me, but it blossed to become the best way to connect with friends and community before and during music festivals. Please feel free to reach out with any questions, comments, bugs, or collaboration requests.\nMost importantly, enjoy OASIS!"
    
    var ContactMeOptions: some View {
        Group {
            HStack(spacing: 32) {
                ZStack {
                    Circle()
                        .foregroundStyle(.white)
                        .shadow(radius: SHADOW)
                    Image(.tikTokLogo)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30, alignment: .center)
                        .onTapGesture() {
                            if let url = URL(string: "https://www.tiktok.com/@austin.zv?_r=1&_t=ZT-93vUpxheB0I") {
                                UIApplication.shared.open(url)
                            }
                        }
                }
                .frame(height: LARGE_BUTTON_HEIGHT/1.3)
                
                ZStack {
                    Circle()
                        .foregroundStyle(.white)
                        .shadow(radius: SHADOW)
                    Image(systemName: "envelope")
                        .foregroundStyle(.black)
                        .font(.system(size: 34))
                        .onTapGesture() {
                            if let url = URL(string: "mailto:oasis.festivals.info@gmail.com") {
                                UIApplication.shared.open(url)
                            }
                        }
                }
                .frame(height: LARGE_BUTTON_HEIGHT/1.05)
                
                ZStack {
                    Circle()
                        .foregroundStyle(.white)
                        .shadow(radius: SHADOW)
                    Image(systemName: "network")
                        .foregroundStyle(.black)
                        .font(.system(size: 24))
                        .onTapGesture() {
                            if let url = URL(string: "https://www.austinzv.com/") {
                                UIApplication.shared.open(url)
                            }
                            
                        }
                }
                .frame(height: LARGE_BUTTON_HEIGHT/1.3)
            }
            .foregroundStyle(Color("BW Color Switch"))
            .padding(5)
        }
//        .padding(.top, 10)
    }
    
    var PrivacyPolicySection: some View {
        Group {
//            if let urlString = currentFestival.website, let URL = URL(string: toHttpWww(urlString)) {
                ZStack {
                    RoundedRectangle(cornerRadius: CORNER_RADIUS)
                        .foregroundStyle(Color("BW Color Switch Reverse"))
                        .shadow(radius: SHADOW)
                    HStack{
//                        Spacer()
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .imageScale(.large)
//                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .foregroundStyle(.black)
                }
                .frame(height: SMALL_BUTTON_HEIGHT)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let url = URL(string: "https://www.austinzv.com/") {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundStyle(.white)
//                .padding(.vertical, 10)
                .padding(/*.horizontal, */20)
                
            }
    }
    
    let SMALL_BUTTON_HEIGHT: CGFloat = 55
    let LARGE_BUTTON_HEIGHT = 80.0
    let CORNER_RADIUS: CGFloat = 10
    let SHADOW = 5.0
}

#Preview {
    AboutPage()
}
