//
//  NewEventPageViewModel.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/20/25.
//

import Foundation
import Combine

class NewEventPageViewModel: ObservableObject {
    @Published var newFestival: DataSet.Festival
    
    

    private var cancellables = Set<AnyCancellable>()
    private var saveWorkItem: DispatchWorkItem?

    init(festival: DataSet.Festival) {
        self.newFestival = festival
//        $newFestival
//            .sink { [weak self] _ in
//                self?.debouncedSave()
//            }
//            .store(in: &cancellables)
    }
    
//    func isUnedited() -> Bool {
//        let uneditedFestival = DataSet.festival()
//        return (newFestival.name == uneditedFestival.name &&
//                newFestival.logoPath == uneditedFestival.logoPath &&
//                newFestival.artistList == uneditedFestival.artistList &&
//                newFestival.startDate.formatted(date: .complete, time: .omitted) == uneditedFestival.startDate.formatted(date: .complete, time: .omitted) &&
//                newFestival.endDate.formatted(date: .complete, time: .omitted) == uneditedFestival.endDate.formatted(date: .complete, time: .omitted) &&
//                newFestival.stageList == uneditedFestival.stageList &&
//                newFestival.website == uneditedFestival.website
//        )
//    }

//    private func debouncedSave() {
//        saveWorkItem?.cancel()
//
//        let workItem = DispatchWorkItem {
//            self.saveToUserDefaults()
//        }
//
//        saveWorkItem = workItem
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
//    }

//    private func saveToUserDefaults() {
        
        //TODO: Encode data
//        if let data = try? JSONEncoder().encode(newFestival) {
//            UserDefaults.standard.set(data, forKey: "myDraftKey")
//        }
//    }
}
