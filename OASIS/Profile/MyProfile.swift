//
//  Profile.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 11/14/25.
//

import SwiftUI

struct MyProfile: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    @EnvironmentObject var festivalVM: FestivalViewModel
    @EnvironmentObject var social: SocialViewModel
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        if firestore.phoneConnected {
            NavigationStack(path: $navigationPath) {
                ProfilePage(navigationPath: $navigationPath, profile: firestore.myUserProfile)
                    .withAppNavigationDestinations(navigationPath: $navigationPath, festivalVM: festivalVM)
                    
            }
            
        } else {
            AccountSetUpPage()
        }
    }
    
//    let myprofile = UserProfile(id: "9nvpkBn7DtMd1dDdPCJhm1OYmb93",
//                                name: "Austin",
//                                profilePic: "https://firebasestorage.googleapis.com:443/v0/b/oasis-austinzv.firebasestorage.app/o/images%2F0C88A9E3-67A9-4AC8-AF95-116D54181178.jpg?alt=media&token=f06aef65-a301-436f-9c9d-258e68372f3e",
//                                following: ["FFF8gsIB5WgFBrHY6ruBTM5s0sR3",
//                                            "GGG8gsIB5WgFBrHY6ruBTM5s0sR3",
//                                            "HHH8gsIB5WgFBrHY6ruBTM5s0sR3",
//                                            "III8gsIB5WgFBrHY6ruBTM5s0sR3"],
//                                followers: ["FFF8gsIB5WgFBrHY6ruBTM5s0sR3",
//                                            "HHH8gsIB5WgFBrHY6ruBTM5s0sR3"],
//                                festivalFavs: ["00AB0F97-A947-4C53-96D8-2CEE087BA484" : [],
//                                                "19AD3192-767C-40CA-86D2-986B08AD058B" : [],
//                                                "B5D6265D-68D6-4A56-AA11-E25C574922A6" : []]
//    )
}

//#Preview {
//    Profile()
//}
