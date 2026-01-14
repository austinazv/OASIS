//
//  AccountInfoPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/17/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import FirebaseStorage
import CryptoKit

struct AccountSetUpPage: View {
    @EnvironmentObject var data: DataSet
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedIn = false
    
    @State private var verificationID: String?
    @State private var isCodeSent = false
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State private var navigationPath = NavigationPath()
    

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                ZStack {
                    Spacer()
                        .frame(height: 40)
                    if isCodeSent {
                        BackButton
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }

                // TitleField stays in place without animating
                TitleField
                    .id("TitleField") // Ensures SwiftUI treats it as the same view
                 
                // Changing content below TitleField
                if isCodeSent {
                    VStack(spacing: 15) {
                        CodeTextField
                        VerifyButton
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    VStack(spacing: 15) {
                        PhotoField
                        NameField
                        PhoneNumberField
                        ContinueButton
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
                Spacer()
            }
            .animation(.easeInOut, value: isCodeSent) // Animate only when isCodeSent changes
            .padding()
            if isLoading {
                Color.black.opacity(0.4)
                            .ignoresSafeArea()
                ProgressView()
            }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem)
        .onChange(of: selectedItem) { newItem in
            Task {
                // Retrieve the image from the PhotosPickerItem
                if let selectedItem, let data = try? await selectedItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
    }
    
    var BackButton: some View {
        HStack {
            Button(action: { isCodeSent = false }) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            Spacer()
        }
        .padding(.horizontal, 10)
//        .padding(.top, 10)
        .foregroundStyle(.blue)
    }
    
    var TitleField: some View {
        VStack {
            Text("Find Friends on")
                .font(Font.system(size: 20))
            OASISTitle(fontSize: 65.0)
               
            Spacer()
                .frame(height: 10)
        }
    }
    
    
    
    var PhotoField: some View {
        Group {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .center) {
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130, alignment: .center)
                            .clipShape(Circle())
                    } else {
                        Image("Default Profile Picture")
                            .resizable()
                            .frame(width: 130, height: 130, alignment: .center)
                            .clipShape(Circle())
                        Text("Upload Image").foregroundStyle(Color.black)
                    }
                }
                
                // 'x' button appears only when a user-selected image exists
                if selectedImage != nil {
                    Button {
                        withAnimation {
                            selectedImage = nil
                            selectedItem = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.85))
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 1)
                            )
                    }
                    // Position slightly outside the 130x130 circle visually
                    .offset(x: 6, y: -6)
                    .accessibilityLabel("Remove photo")
                }
            }
            // Add a circular black outline and subtle shadow to both cases
            .overlay(
                Circle()
                    .stroke(.oasisDarkOrange, lineWidth: 2)
                    .frame(width: 130, height: 130)
            )
            .shadow(radius: 4)
            .onTapGesture {
                showPhotoPicker = true
            }
            .padding(.vertical, 10)
        }
    }
    
    @State private var name = ""
    
    var NameField: some View {
        HStack {
            Spacer().frame(width: 26)
            TextField("", text: $name)
                .padding()
                .autocorrectionDisabled(true)
                .background(.oasisDarkOrange.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.oasisDarkOrange, lineWidth: 2)
                )
                .overlay(
                    Group {
                        if name.isEmpty {
                            Text("Your Name *")
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                    }, alignment: .leading
                )
                .autocapitalization(.words)
                .onSubmit {
                    if allowContinue() {
                        sendCode()
                    }
                }
            Spacer().frame(width: 26)
        }
        
    }
    
    @State private var rawPhoneNumber = ""
    @State private var phoneNumber = ""
    
    
    var PhoneNumberField: some View {
        HStack {
            Text("+1")
            TextField("", text: $phoneNumber)
                .keyboardType(.numbersAndPunctuation)
                .padding()
                .background(.oasisDarkOrange.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.oasisDarkOrange, lineWidth: 2)
                )
                .overlay(
                    Group {
                        if phoneNumber.isEmpty {
                            Text("Phone Number *")
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                    }, alignment: .leading
                )
                .onChange(of: phoneNumber) { newValue in
                    updatePhoneNumber(newValue)
                }
                .onSubmit {
                    if allowContinue() {
                        sendCode()
                    }
                }
            Spacer().frame(width: 26)
        }
    }
    
    private func updatePhoneNumber(_ newValue: String) {
        let cleanNumber = newValue.filter { $0.isNumber }  // Keep only numbers
        rawPhoneNumber = cleanNumber // Update raw number for Firebase
        phoneNumber = formatPhoneNumber(cleanNumber) // Update formatted number for UI
    }
    
    private func formatPhoneNumber(_ number: String) -> String {
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
    
    
    var ContinueButton: some View {
        VStack {
            Button(action: sendCode) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(allowContinue() ? .oasisDarkBlue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!allowContinue())
            
            
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding(.vertical, 30)
    }
    
    private func allowContinue() -> Bool {
        return (!name.isEmpty && phoneNumber.count == 14 && !isLoading)
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
    
    @State var codeText = ""
    
    var CodeTextField: some View {
        HStack {
            Spacer().frame(width: 26)
            TextField("", text: $codeText)
                .padding()
                .background(.oasisDarkOrange.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.oasisDarkOrange, lineWidth: 2)
                )
                .overlay(
                    Group {
                        if name.isEmpty {
                            Text("Enter 6-digit Code")
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                    }, alignment: .leading
                )
                .autocapitalization(.words)
                .onSubmit {
                    if codeText.count == 6 {
                        verifyCodeAndSaveUserInfo()
                    }
                }
            Spacer().frame(width: 26)
        }
    }
    
    var VerifyButton: some View {
        VStack {
            Button(action: verifyCodeAndSaveUserInfo) {
                Text("Verify Code")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .keyboardType(.numbersAndPunctuation)
                    .padding()
                    .foregroundStyle(.white)
                    .background(codeText.count == 6 ? .oasisDarkBlue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(codeText.count != 6)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding(.vertical, 30)
    }
    
    
//    private func saveUserInfo() {
//        firestore.saveName(name: name) { success in
//            if success {
//                if let photo = selectedImage {
//                    firestore.uploadImageAndSaveToFirestore(image: photo) { _ in
//                        if Auth.auth().currentUser != nil {
//                            self.loggedIn = true
//                        }
//                    }
//                } else {
//                    if Auth.auth().currentUser != nil {
//                        self.loggedIn = true
//                    }
//                }
//            }
//        }
//    }
    
//    private func saveUserInfo() {
//        // Normalize & hash the phone number
//        var phoneHash: String? = nil
//        if let normalized = normalizePhoneNumber(rawPhoneNumber) {
//            phoneHash = hashPhoneNumber(normalized)
//        }
//
//        firestore.saveNamePhoneAndHash(
//            name: name,
//            phoneNumber: rawPhoneNumber,    
//            phoneHash: phoneHash
//        ) { success in
//            if success {
//                if let photo = selectedImage {
//                    firestore.uploadImageAndSaveToFirestore(image: photo) { _ in
//                        isLoading = false
//                        if Auth.auth().currentUser != nil {
//                            self.loggedIn = true
//                        }
//                    }
//                } else {
//                    isLoading = false
//                    if Auth.auth().currentUser != nil {
//                        self.loggedIn = true
//                    }
//                }
//            }
//        }
//    }
//    
//    
//    private func verifyCode() {
//        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
//            errorMessage = "No verification ID found"
//            return
//        }
//        
//        isLoading = true
//        let credential = PhoneAuthProvider.provider().credential(
//            withVerificationID: verificationID,
//            verificationCode: codeText
//        )
//        
//        Auth.auth().signIn(with: credential) { authResult, error in
//            isLoading = false
//            if let error = error {
//                errorMessage = "Verification failed: \(error.localizedDescription)"
//                return
//            }
//            
//            // ✅ User is signed in
//            if let user = authResult?.user {
//                let uid = user.uid
//                let phone = user.phoneNumber ?? "Unknown"
//
//                let db = Firestore.firestore()
//                let userRef = db.collection("users").document(uid)
//
//                userRef.getDocument { snapshot, error in
//                    if let error = error {
//                        print("❌ Error fetching user: \(error.localizedDescription)")
//                        return
//                    }
//
////                    self.hasName = snapshot?.data()?["name"] != nil
////
////                    if !hasName {
////                        // You can handle onboarding flow here (e.g. ask for name)
////                        print("👤 No name found — user needs to create one.")
////                    } else {
////                        print("🎉 User has a name already.")
////                    }
//
//                    // Save/update phone and createdAt regardless
//                    userRef.setData([
//                        "phone": phone,
//                        "createdAt": FieldValue.serverTimestamp()
//                    ], merge: true) { error in
//                        if let error = error {
//                            print("❌ Error saving user: \(error.localizedDescription)")
//                        } else {
//                            print("✅ User saved to Firestore!")
//                        }
//
//                        // Now that everything is done
////                        isLoggedIn = true
//                    }
//                }
//            }
//        }
//    }

    
    private func verifyCodeAndSaveUserInfo() {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            errorMessage = "No verification ID found"
            return
        }

        isLoading = true

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: codeText
        )

        // Step 1: Verify the code with Firebase Auth
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                isLoading = false
                errorMessage = "Verification failed: \(error.localizedDescription)"
                return
            }

            // ✅ Code is valid — user is now signed in (or reauthenticated)
            guard let user = authResult?.user else {
                isLoading = false
                errorMessage = "Could not retrieve user after verification."
                return
            }

            // Step 2: Save user info to Firestore
            saveUserInfo(for: user)
        }
    }

    private func saveUserInfo(for user: User) {
        // We already have a verified Firebase user
        var phoneHash: String? = nil
        if let normalized = normalizePhoneNumber(rawPhoneNumber) {
            phoneHash = hashPhoneNumber(normalized)
        }

        firestore.saveNamePhoneAndHash(
            name: name,
            phoneNumber: rawPhoneNumber,
            phoneHash: phoneHash
        ) { success in
            isLoading = false
            if success {
                if let photo = selectedImage {
                    firestore.uploadImageAndSaveToFirestore(image: photo) { _ in
                        isLoading = false
                        loggedIn = true
                    }
                } else {
                    loggedIn = true
                }
            } else {
                errorMessage = "Failed to save user info."
            }
        }
    }


    func normalizePhoneNumber(_ number: String) -> String? {
        let digits = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard digits.count >= 7 else { return nil }
        return digits
    }

    func hashPhoneNumber(_ number: String) -> String {
        let data = Data(number.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    
}
