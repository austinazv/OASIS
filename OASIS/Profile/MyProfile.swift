//
//  Profile.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 11/14/25.
//

import SwiftUI

struct Profile: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        if firestore.phoneConnected {
//            FriendPage(navigationPath: $navigationPath, profile: <#T##DataSet.FriendProfile#>)
        } else {
            AccountSetUpPage()
        }
    }
}

//#Preview {
//    Profile()
//}
