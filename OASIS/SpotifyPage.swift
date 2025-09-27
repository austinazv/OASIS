//
//  SpotifyPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 3/17/25.
//

import SwiftUI

struct SpotifyPage: View {
    @EnvironmentObject var data: DataSet
    
    var body: some View {
        VStack {
            HStack {
                Image("Spotify Full Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30, alignment: .center)
            }
            Spacer()
                Button(action: {
                    
                }, label: {
                    Text("Log In")
                        .frame(width: 100, height: 40)
                        .background(Color("Spotify Color Green"))
                        .foregroundStyle(.black)
                        .cornerRadius(30)
                        .shadow(radius: 5)
                    
                })
            Spacer()
                
//            }
        }
        
    }
        
}

//#Preview {
//    SpotifyPage()
//}
