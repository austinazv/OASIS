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
    
    @State var currentFestival = Festival.newFestival()
    
    @State var notificationAction: NotificationAction = .showNotificationRequest
    @State var oneWeekNotificationBool = true
    
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
                        ForEach(festivalVM.dayRangeToStringArray(start: currentFestival.startDate, end: currentFestival.endDate), id: \.self) { day in
                            Toggle(
                                day,
                                isOn: Binding(
                                    get: { festivalVM.settings.festivalDays[day] ?? true },
                                    set: { festivalVM.settings.festivalDays[day] = $0 }
                                )
                            )
                            .tint(.oasisDarkBlue)
                        }
                    }
                }
                Section(header: Text("Notifications")) {
                    if notificationAction == .showToggle {
                        Toggle(isOn: $oneWeekNotificationBool, label: { Text("Get Festival Notifications") })
                    } else {
                        Button (action: {
                            if notificationAction == .openSettings {
                                openSettingsAction()
                            } else {
                                requestPermissionAction()
                            }
                        }, label: {
                            Text("Allow Notifications")
                        })
//                        switch(notificationAction) {
//                        case .showOASISAlert:
//                            Button (action: {
//                                requestPermissionAction()
//                            }, label: {
//                                Text("Allow Notifications")
//                            })
//                        case .showNotificationRequest:
//                            Button (action: {
//                                requestPermissionAction()
//                            }, label: {
//                                Text("Allow Notifications")
//                            })
//                        case .openSettings:
//                            Button (action: {
//                                openSettingsAction()
//                            }, label: {
//                                Text("Allow Notifications")
//                            })
//                        case .showToggle:
//                            Toggle(isOn: $oneWeekNotificationBool, label: { Text("Get Festival Notifications") })
//                        }
                    }
                }
                .tint(.oasisDarkBlue)
            }
        }
        .navigationTitle("\(currentFestival.name) Settings")
        .onAppear() {
            if let currFest = festivalVM.currentFestival {
                currentFestival = currFest
            } else {
                navigationPath.removeLast()
            }
            oneWeekNotificationBool = NotificationManager.shared.hasFestivalReminder(for: currentFestival.id)
        }
        .onChange(of: oneWeekNotificationBool) { _, showNotifications in
            if showNotifications {
                scheduleFestivalReminder()
            } else {
                removeFestivalReminder()
            }
        }
        .task {
            let status = await NotificationManager.shared.notificationStatus()
            
            if !NotificationManager.shared.festivalNotificationsRequested {
                NotificationManager.shared.festivalNotificationsRequested = true
                notificationAction = .showOASISAlert
            } else if status == .notDetermined {
                notificationAction = .showNotificationRequest
//                popupAction = requestPermissionAction
//                popupMessage = "Enable notifications to get festival reminders."
            } else if status == .denied {
                notificationAction = .openSettings
//                popupAction = openSettingsAction
//                popupMessage = "Enable notifications to get festival reminders."
            } else {
                notificationAction = .showToggle
//                scheduleFestivalReminder()
            }
        }
        .onChange(of: oneWeekNotificationBool) { oldBool, newBool in
            
        }
    }
    
    
    func requestPermissionAction() {
        Task {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                scheduleFestivalReminder()
            }
        }
    }
    
    func openSettingsAction() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    func scheduleFestivalReminder() {
        Task {
//            defer { popupMessage = "" }
            await NotificationManager.shared.scheduleFestivalReminder(
                festivalID: currentFestival.id,
                festivalName: currentFestival.name,
                startDate: currentFestival.startDate
            )
        }
    }
    
    func removeFestivalReminder() {
        Task {
//            defer { popupMessage = "" }
            await NotificationManager.shared.removeFestivalReminder(festivalID: currentFestival.id)
        }
    }
    
//    Button (action: {
//        let wasFavorited = festivalVM.festivalIsFavorited(festivalID: currentFestival.id)
//
//        festivalVM.starPressed(festival: currentFestival)
//        firestore.myUserProfile.starredFestivalsList = festivalVM.myFestivals.map { $0.id.uuidString }
//
//        if !wasFavorited {
//            //                            if !wasFavorited {
//            Task {
//                let status = await NotificationManager.shared.notificationStatus()
//                
//                print("statusing...")
//                switch(status) {
//                case .authorized: print("authorized")
//                case .denied: print("denied")
//                case .notDetermined: print("ND")
//                case .ephemeral: print("ephemeral")
//                case .provisional: print("provisional")
//                @unknown default: print("idk bro")
//                }
//                
//                if !NotificationManager.shared.festivalNotificationsRequested {
//                    NotificationManager.shared.festivalNotificationsRequested = true
//                    showNotificationAlert = true
//                } else if status == .notDetermined {
//                    popupAction = requestPermissionAction
//                    popupMessage = "Enable notifications to get festival reminders."
//                } else if status == .denied {
//                    popupAction = openSettingsAction
//                    popupMessage = "Enable notifications to get festival reminders."
//                } else {
//                    scheduleFestivalReminder()
//                }
//                
//                
//                
//                //                                else if status == .notDetermined || status == .denied {
//                //                                    if let url = URL(string: UIApplication.openSettingsURLString) {
//                //                                        popupLink = url
//                //                                    }
//                //                                    popupMessage = "Enable notifications to get festival reminders"
//                //                                }
//                
//            }
//        } else {
//            removeFestivalReminder()
//        }
//    }, label: {
//        ZStack {
//            Circle()
//                .foregroundStyle(TRYDARKMODE ? .bwColorSwitchReverse : .white)
//                .shadow(radius: SHADOW)
//            Image(systemName: festivalVM.festivalIsFavorited(festivalID: currentFestival.id) ? "star.fill" : "star")
////                            .foregroundStyle(.yellow)
//                .foregroundStyle(.oasisLightOrange)
//                .font(.system(size: 34))
//        }
//    })
    
//    func dayRangeToStringArray(start: Date, end: Date) -> [String] {
//        let calendar = Calendar.current
//        var days: [String] = []
//        var currentDate = calendar.startOfDay(for: start)
//        let endDate = calendar.startOfDay(for: end)
//
//        let formatter = DateFormatter()
//        formatter.dateFormat = "EEEE" // "Monday", "Tuesday", etc.
//
//        while currentDate <= endDate {
//            let dayName = formatter.string(from: currentDate)
//            days.append(dayName)
//            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
//        }
//
//        return days
//    }
    
    func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full day name, e.g. "Friday"
        return formatter.string(from: date)
    }
    
    enum NotificationAction {
        case showOASISAlert
        case showNotificationRequest
        case openSettings
        case showToggle
    }
}
