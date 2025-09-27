//
//  AuthPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/15/25.
//

import SwiftUI
import FirebaseAuth
import Foundation
import FirebaseFirestore

struct AuthPage: View {
    @EnvironmentObject var data: DataSet
    
    @State private var rawPhoneNumber = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var verificationID: String?
    @State private var isCodeSent = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false
    @State private var hasName = false
    @State private var userSelectedFestivals = false
    @State private var goHome = false

    var body: some View {
        Group {
            if isLoggedIn {
                if !hasName {
                    AccountSetUpPage().environmentObject(data)
                } else {
//                    if festivals chooser 
//                  HomePage()
                }
            } else {
                PhoneLogInView
            }
        }
        .navigationBarBackButtonHidden(false)
    }
    
    var PhoneLogInView: some View {
        VStack(spacing: 20) {
            Text("Welcome to")
                .font(.title)
                .italic()
            Text("OASIS")
                .foregroundStyle(Color("OASIS Light Blue"))
                .kerning(20)
                .font(Font.system(size: 60))
                .scaledToFill()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.bottom, 20)
//                .italic()
                .bold()
            if !isCodeSent {
                Text("Enter your phone number to \nsign up or sign in.")
                    .multilineTextAlignment(.center)
                    .italic()
                HStack {
                    Text("+1")
                    TextField("Enter your phone number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onChange(of: phoneNumber) { newValue in
                            updatePhoneNumber(newValue)
                        }
                }
                
                Button(action: sendCode) {
                    Text("Send Code")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumber.count > 13 ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(phoneNumber.isEmpty || isLoading)
            } else {
                TextField("Enter verification code", text: $verificationCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                
                Button(action: verifyCode) {
                    Text("Verify & Login")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(verificationCode.count == 6 ? Color.green : Color.gray)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
                .disabled(verificationCode.isEmpty || isLoading)
                Button(action: {
                    isCodeSent = false
                }) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                }
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
        }
        .padding(30)
        
    }
    
    private func updatePhoneNumber(_ newValue: String) {
        let cleanNumber = newValue.filter { $0.isNumber }  // Keep only numbers
        rawPhoneNumber = cleanNumber // Update raw number for Firebase
        phoneNumber = formatPhoneNumber(cleanNumber) // Update formatted number for UI
    }
    
    private func sendCode() {
        let formattedNumber = "+1" + phoneNumber.filter { $0.isNumber }
        isLoading = true
        
        PhoneAuthProvider.provider().verifyPhoneNumber(formattedNumber, uiDelegate: nil) { verificationID, error in
            isLoading = false
            if let error = error {
                errorMessage = "Error: \(error.localizedDescription)"
                return
            }
            self.verificationID = verificationID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            isCodeSent = true
        }
    }
    
    private func verifyCode() {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            errorMessage = "No verification ID found"
            return
        }
        
        isLoading = true
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode
        )
        
        Auth.auth().signIn(with: credential) { authResult, error in
            isLoading = false
            if let error = error {
                errorMessage = "Verification failed: \(error.localizedDescription)"
                return
            }
            
            // ✅ User is signed in
            if let user = authResult?.user {
                let uid = user.uid
                let phone = user.phoneNumber ?? "Unknown"

                let db = Firestore.firestore()
                let userRef = db.collection("users").document(uid)

                userRef.getDocument { snapshot, error in
                    if let error = error {
                        print("❌ Error fetching user: \(error.localizedDescription)")
                        return
                    }

                    self.hasName = snapshot?.data()?["name"] != nil

                    if !hasName {
                        // You can handle onboarding flow here (e.g. ask for name)
                        print("👤 No name found — user needs to create one.")
                    } else {
                        print("🎉 User has a name already.")
                    }

                    // Save/update phone and createdAt regardless
                    userRef.setData([
                        "phone": phone,
                        "createdAt": FieldValue.serverTimestamp()
                    ], merge: true) { error in
                        if let error = error {
                            print("❌ Error saving user: \(error.localizedDescription)")
                        } else {
                            print("✅ User saved to Firestore!")
                        }

                        // Now that everything is done
                        isLoggedIn = true
                    }
                }
            }
        }
    }
    
    
    func formatPhoneNumber(_ number: String) -> String {
        let digits = number.filter { $0.isNumber }
        var formatted = ""
        let count = digits.count
        
        if count > 0 {
            let start = digits.startIndex
            let first3 = digits.index(start, offsetBy: min(3, count))
            formatted += "\(digits[start..<first3])" // No parentheses yet
        }
        
        if count > 3 {
            let next3 = digits.index(digits.startIndex, offsetBy: min(6, count))
            formatted = "(\(formatted)) \(digits[digits.index(digits.startIndex, offsetBy: 3)..<next3])"
        }
        
        if count > 6 {
            let last = digits.index(digits.startIndex, offsetBy: min(10, count))
            formatted += "-\(digits[digits.index(digits.startIndex, offsetBy: 6)..<last])"
        }
        
        return formatted
    }
    
    private var backButton: some View {
        Button(action: {
            goHome = true
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
                
            }
            .foregroundColor(.blue)
        }
    }
}



//#Preview {
//    AuthPage()
//}
