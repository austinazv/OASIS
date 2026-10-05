//
//  NotificationManager.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 8/5/26.
//

import Foundation
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared = NotificationManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let festivalNotificationsRequested = "festivalNotificationsRequested"
        static let socialNotificationsRequested = "socialNotificationsRequested"
        static let festivalNotificationIDs = "festivalNotificationIDs"
    }
    
    private(set) var festivalNotificationIDs: Set<UUID> = []
    
    private override init() {
        super.init()
        
        if let savedIDs = UserDefaults.standard.array(
            forKey: Keys.festivalNotificationIDs
        ) as? [String] {
            festivalNotificationIDs = Set(
                savedIDs.compactMap { UUID(uuidString: $0) }
            )
        }
    }
    
    var festivalNotificationsRequested: Bool {
        get {
            defaults.bool(forKey: Keys.festivalNotificationsRequested)
        }
        set {
            defaults.set(newValue, forKey: Keys.festivalNotificationsRequested)
        }
    }
    
    var socialNotificationsRequested: Bool {
        get {
            defaults.bool(forKey: Keys.socialNotificationsRequested)
        }
        set {
            defaults.set(newValue, forKey: Keys.socialNotificationsRequested)
        }
    }
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print(error)
            return false
        }
    }
    
    func messaging(
            _ messaging: Messaging,
            didReceiveRegistrationToken fcmToken: String?
        ) {
            guard let fcmToken else { return }

            saveFCMToken(fcmToken)
        }

    func saveFCMToken(_ token: String) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No signed-in user; FCM token not saved.")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userID)
            .setData([
                "fcmTokens": FieldValue.arrayUnion([token])
            ], merge: true) { error in
                if let error {
                    print("Error saving FCM token:", error.localizedDescription)
                } else {
                    print("FCM token saved.")
                }
            }
    }
    
//    func requestPermission() async -> Bool {
//        do {
//            return try await UNUserNotificationCenter.current()
//                .requestAuthorization(options: [.alert, .badge, .sound])
//        } catch {
//            print(error)
//            return false
//        }
//    }
    
    func notificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current()
            .notificationSettings()
        
        return settings.authorizationStatus
    }
    
    private func saveFestivalNotificationIDs() {
        let strings = festivalNotificationIDs.map { $0.uuidString }
        UserDefaults.standard.set(strings, forKey: Keys.festivalNotificationIDs)
    }
    

    
    func scheduleFestivalReminder(
        festivalID: UUID,
        festivalName: String,
        startDate: Date
    ) async {

        // MARK: - Save notification preference

        // Always add the festival locally, regardless of when it starts.
        festivalNotificationIDs.insert(festivalID)
        saveFestivalNotificationIDs()

        // Always add the festival to Firebase.
        if let userID = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            
            do {
                try await db
                    .collection("users")
                    .document(userID)
                    .updateData([
                        "festivalNotificationIDs": FieldValue.arrayUnion([
                            festivalID.uuidString
                        ])
                    ])

                print("✅ Saved notification preference for \(festivalName)")

            } catch {
                print("❌ Failed to save notification preference to Firebase: \(error)")
            }
        } else {
            print("⚠️ No signed-in user; notification preference only saved locally")
        }


        // MARK: - Schedule one-week reminder

        // Only schedule the reminder if the festival is more than one week away.
        guard let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -7,
            to: startDate
        ),
        reminderDate > Date() else {
            print("ℹ️ Festival is less than one week away; no scheduled reminder needed")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "One week til \(festivalName)!"
        content.body = "Explore the lineup now!"
        content.sound = .default
        content.userInfo = [
            "url": "https://oasis-austinzv.web.app/share/festival/\(festivalID.uuidString)"
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "festival-\(festivalID.uuidString)-week",
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)

            print("✅ Scheduled one-week notification for \(festivalName)")

        } catch {
            print("❌ Failed to schedule notification: \(error)")
        }
    }

//    func scheduleFestivalReminder(festivalID: UUID, festivalName: String, startDate: Date) async {
//        
//        guard let reminderDate = Calendar.current.date(
//            byAdding: .day,
//            value: -7,
//            to: startDate
//        ),
//              reminderDate > Date() else {
//            return
//        }
//        
//        let content = UNMutableNotificationContent()
//        content.title = "One week til \(festivalName)!"
//        content.body = "Explore the lineup now!"
//        content.sound = .default
//        content.userInfo = [
//            "url": "https://oasis-austinzv.web.app/share/festival/\(festivalID.uuidString)"
//        ]
//        
//        let components = Calendar.current.dateComponents(
//            [.year, .month, .day, .hour, .minute, .second],
//            from: reminderDate
//        )
//        
//        let trigger = UNCalendarNotificationTrigger(
//            dateMatching: components,
//            repeats: false
//        )
//        
//        let request = UNNotificationRequest(
//            identifier: "festival-\(festivalID.uuidString)-week",
//            content: content,
//            trigger: trigger
//        )
//        
//        do {
//            try await UNUserNotificationCenter.current().add(request)
//            
//            festivalNotificationIDs.insert(festivalID)
//            saveFestivalNotificationIDs()
//            
//            print("✅ Scheduled notification for \(festivalName)")
//        } catch {
//            print("❌ Failed to schedule notification: \(error)")
//        }
//    }
    
    func removeFestivalReminder(festivalID: UUID) async {
        
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [
                    "festival-\(festivalID.uuidString)-week"
                ]
            )
        
        // Remove locally
        festivalNotificationIDs.remove(festivalID)
        saveFestivalNotificationIDs()
        
        // Remove from Firebase
        if let userID = Auth.auth().currentUser?.uid {
            let db = Firestore.firestore()
            
            do {
                try await db
                    .collection("users")
                    .document(userID)
                    .updateData([
                        "festivalNotificationIDs": FieldValue.arrayRemove([
                            festivalID.uuidString
                        ])
                    ])
                
                print("✅ Removed notification preference from Firebase")
                
            } catch {
                print("❌ Failed to remove notification preference from Firebase: \(error)")
            }
        } else {
            print("⚠️ No signed-in user; notification preference only removed locally")
        }
    }
    
//    func removeFestivalReminder(festivalID: UUID) {
//        UNUserNotificationCenter.current()
//            .removePendingNotificationRequests(
//                withIdentifiers: [
//                    "festival-\(festivalID.uuidString)-week"
//                ]
//            )
//        
//        festivalNotificationIDs.remove(festivalID)
//        saveFestivalNotificationIDs()
//    }
    
    func hasFestivalReminder(for festivalID: UUID) -> Bool {
        festivalNotificationIDs.contains(festivalID)
    }
    
}






//final class PushNotificationManager: NSObject,
//                                    UIApplicationDelegate,
//                                    UNUserNotificationCenterDelegate,
//                                    MessagingDelegate {
//
//    static let shared = PushNotificationManager()
//
//    private let db = Firestore.firestore()
//
//    // Call this when the user opts in to notifications.
//    func requestPermission() {
//        UNUserNotificationCenter.current().delegate = self
//
//        UNUserNotificationCenter.current().requestAuthorization(
//            options: [.alert, .badge, .sound]
//        ) { granted, error in
//
//            if let error {
//                print("Notification permission error:", error.localizedDescription)
//                return
//            }
//
//            guard granted else {
//                print("Notification permission was not granted.")
//                return
//            }
//
//            DispatchQueue.main.async {
//                UIApplication.shared.registerForRemoteNotifications()
//            }
//        }
//    }
//
//    // Called when APNs registration succeeds.
//    func application(
//        _ application: UIApplication,
//        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//    ) {
//        Messaging.messaging().apnsToken = deviceToken
//        print("APNs registration succeeded.")
//    }
//
//    // Called when APNs registration fails.
//    func application(
//        _ application: UIApplication,
//        didFailToRegisterForRemoteNotificationsWithError error: Error
//    ) {
//        print("APNs registration failed:", error.localizedDescription)
//    }
//
//    // Called when Firebase provides or refreshes the FCM token.
//    func messaging(
//        _ messaging: Messaging,
//        didReceiveRegistrationToken fcmToken: String?
//    ) {
//        guard let fcmToken else { return }
//
//        print("FCM token received:", fcmToken)
//        saveFCMToken(fcmToken)
//    }
//
//    private func saveFCMToken(_ token: String) {
//        guard let userID = Auth.auth().currentUser?.uid else {
//            print("No signed-in user; FCM token not saved.")
//            return
//        }
//
//        db.collection("users")
//            .document(userID)
//            .setData([
//                "fcmTokens": FieldValue.arrayUnion([token])
//            ], merge: true) { error in
//
//                if let error {
//                    print("Failed to save FCM token:", error.localizedDescription)
//                } else {
//                    print("FCM token saved to Firestore.")
//                }
//            }
//    }
//}
