//
//  FestivalSettingsPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 9/18/25.
//

import SwiftUI

struct FestivalSettingsPage: View {
    
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var festivalVM: FestivalViewModel
    
    @Binding var navigationPath: NavigationPath
    
    @State var currentFestival = DataSet.Festival.newFestival()
    
    var body: some View {
        VStack {
            Form {
                if currentFestival.secondWeekend {
                    Section(header: Text("Weekend")) {
                        Picker("Weekend", selection: $festivalVM.settings.festivalWeekend) {
                            Text("Weekend 1").tag("Weekend 1")
                            Text("Weekend 2").tag("Weekend 2")
                            Text("Both").tag("Both")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                let dayRange = festivalVM.getAmountOfFestivalDays(startDate: currentFestival.startDate, endDate: currentFestival.endDate)
                if dayRange > 1 {
                    Section(header: Text("Days")) {
                        ForEach(daysInRange(start: currentFestival.startDate, end: currentFestival.endDate), id: \.self) { day in
                            Toggle(
                                day,
                                isOn: Binding(
                                    get: { festivalVM.settings.festivalDays[day] ?? true },
                                    set: { festivalVM.settings.festivalDays[day] = $0 }
                                )
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("\(currentFestival.name) Settings")
        .onAppear() {
            if let currFest = festivalVM.currentFestival {
                currentFestival = currFest
            } else {
                navigationPath.removeLast()
            }
        }
    }
    
    func daysInRange(start: Date, end: Date) -> [String] {
        let calendar = Calendar.current
        var days: [String] = []
        var currentDate = calendar.startOfDay(for: start)
        let endDate = calendar.startOfDay(for: end)

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // "Monday", "Tuesday", etc.

        while currentDate <= endDate {
            let dayName = formatter.string(from: currentDate)
            days.append(dayName)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return days
    }
    
    func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name, e.g. "Friday"
        return formatter.string(from: date)
    }
}
