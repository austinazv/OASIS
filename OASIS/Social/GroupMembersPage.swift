//
//  GroupMembersPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 3/29/25.
//

import SwiftUI

struct GroupMembersPage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    var group: DataSet.SocialGroup
    var groupPhotos: [String : UIImage]
    
    
    var body: some View {
        Text("\(group.name) Members")
            .font(.title)
            .multilineTextAlignment(.center)
        List {
            ForEach(group.members, id: \.self) { member in
                NavigationLink(value: member) {
                    HStack {
                        if let image = groupPhotos[member.id] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Image("Default Profile Picture")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        }
                        Text(member.name)
                            .foregroundColor(.primary)
                            
                    }
                }
            }
        }
    }
}

//
//#Preview {
//    GroupMembersPage()
//}
