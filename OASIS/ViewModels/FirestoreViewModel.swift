//
//  FirestoreViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/20/25.
//

import Foundation

import Foundation
import SwiftUI
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirestoreViewModel: ObservableObject {
    
    private let saveName: String
    
    var publicFestivals: Array<DataSet.Festival>
    
    init(name: String) {
        self.saveName = name
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
//        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
//        let ladyGaga = DataSet.artistNEW(id: "1HY2Jd0NmPuamShAr6KMms", name: "Lady Gaga", genres: ["Pop", "Jazz", "Dance"], photo: UIImage(resource: .ladyGaga), stage: "Coachella Stage")
//        let postMalone = DataSet.artistNEW(id: "246dkjvS1zLTtiykXe5h60", name: "Post Malone", genres: ["Pop", "Country"], photo: UIImage(resource: .postMalone), stage: "Coachella Stage")
//        let greenDay = DataSet.artistNEW(id: "7oPftvlwr6VrsViSDV7fJY", name: "Green Day", genres: ["Pop"], photo: UIImage(resource: .greenDay), stage: "Coachella Stage")
//        let zedd = DataSet.artistNEW(id: "2qxJFvFYMEDqd7ui6kSAcq", name: "Zedd", genres: ["EDM", "Dance"], photo: UIImage(resource: .zedd), stage: "Outdoor Stage")
//        
//        self.publicFestivals = [
//            DataSet.festival(id: UUID(uuidString: "6DB0C167-CE8D-4C33-B8F9-78C4955C5EFC")!, name: "Coachella", startDate: formatter.date(from: "2025-04-11")!, endDate: formatter.date(from: "2025-04-13")!, logo: Image("Coachella"), artistList: [ladyGaga, postMalone, greenDay, zedd], website: URL(string: "https://www.coachella.com/"), published: true),
//            DataSet.festival(id: UUID(uuidString: "FC9887EB-98AF-4637-876E-F71588B343C9")!, name: "Stagecoach", startDate: formatter.date(from: "2025-04-25")!, endDate: formatter.date(from: "2025-04-27")!, logo: Image("Stagecoach"), artistList: [ladyGaga], website: URL(string: "https://www.stagecoachfestival.com/"), published: true),
////            DataSet.festival(id: UUID(uuidString: "GC9887EC-98AF-4637-876F-F71588B343C8")!, name: "EDC", startDate: formatter.date(from: "2025-04-25")!, endDate: formatter.date(from: "2025-04-27")!, logo: Image("Stagecoach"), artistList: [ladyGaga], website: URL(string: "https://www.stagecoachfestival.com/")),
////            DataSet.festival(name: "EDC Las Vegas", dates: edcDates, logo: Image("EDC"), artistList: [ladyGaga]),
//            DataSet.festival(id: UUID(uuidString: "3408C3E5-2927-43C2-9078-EE5090BB01BD")!, name: "Lollapalooza", startDate: formatter.date(from: "2025-07-31")!, endDate: formatter.date(from: "2025-08-03")!, artistList: [ladyGaga], published: true),
////            DataSet.festival(name: "Boiler Room", dates: boilerDates, artistList: [ladyGaga])
//        ]
        self.publicFestivals = []
    }
    
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    func getUserID() -> String? {
        return Auth.auth().currentUser?.uid
    }
}
