//
//  LogInPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 9/27/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import Security
import CryptoKit

struct LogInPage: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            Text("Welcome to")
                .font(Font.system(size: 20))
                .padding(10)
            OASISTitle(fontSize: 75.0)
               
            
            Spacer()
                .frame(height: 90)
            
            // Apple Sign-In Button
            SignInWithAppleButton(.signIn) { request in
                // Generate raw nonce and store it
                let nonce = randomNonceString()
                // Apple requires the SHA256 hash of the raw nonce in the request
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
                print("Apple Sign-In: Prepared request with hashed nonce.")
            } onCompletion: { result in
                print("Apple Sign-In: onCompletion called with result: \(result)")
                handleAppleSignIn(result: result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            .padding()
            .shadow(radius: 5)
            
            // Google Sign-In Button (custom to match Apple white outline style)
            Button(action: {
                signInWithGoogle()
            }) {
                HStack(spacing: 8) {
                    Image("Google Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                    Text("Sign in with Google")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity, alignment: .center) // center the whole [logo + text]
                .frame(height: 50)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding()
            .shadow(radius: 5)
            
            Spacer()
                .frame(height: 130)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Login Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    
    // MARK: - Apple Sign-In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            print("Apple Sign-In: Authorization success received.")
            guard let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential else {
                print("Apple Sign-In: Could not cast credential to ASAuthorizationAppleIDCredential.")
                return
            }
            
            guard let identityToken = appleIDCredential.identityToken else {
                print("Apple Sign-In: identityToken is nil. This typically happens when request.nonce is not SHA256 hashed.")
                DispatchQueue.main.async {
                    self.errorMessage = "Apple identity token missing. Please try again."
                    self.showError = true
                }
                return
            }
            
            guard let tokenString = String(data: identityToken, encoding: .utf8) else {
                print("Apple Sign-In: Unable to serialize identity token from data.")
                DispatchQueue.main.async {
                    self.errorMessage = "Unable to read Apple identity token."
                    self.showError = true
                }
                return
            }
            
            guard let nonce = currentNonce else {
                print("Invalid state: currentNonce is nil")
                DispatchQueue.main.async {
                    self.errorMessage = "Sign-in state invalid. Please try again."
                    self.showError = true
                }
                return
            }

            // Use the new typed providerID API
            let credential = OAuthProvider.credential(
                providerID: .apple,
                idToken: tokenString,
                rawNonce: nonce,
                accessToken: nil
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In (Apple) error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                    return
                }
                
                guard let user = authResult?.user else {
                    print("Apple Sign-In: Firebase user missing.")
                    return
                }
                
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                
                // Apple may only provide these once (first sign-in)
                let appleEmail = appleIDCredential.email
                let appleName: String? = {
                    guard let name = appleIDCredential.fullName else { return nil }
                    let formatter = PersonNameComponentsFormatter()
                    let full = formatter.string(from: name).trimmingCharacters(in: .whitespacesAndNewlines)
                    return full.isEmpty ? nil : full
                }()
                
                upsertUserDocument(user: user,
                                   extraEmail: appleEmail,
                                   name: appleName,
                                   photoURL: nil,
                                   isNewUser: isNewUser) { upsertError in
                    if let upsertError = upsertError {
                        print("⚠️ Failed to upsert Apple user doc: \(upsertError.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        firestore.isLoggedIn = true
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign-In: Authorization failure: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    // MARK: - Google Sign-In
    private func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let rootVC = UIApplication.shared
                .connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
                return
            }
            
            guard
                let googleUser = signInResult?.user,
                let idToken = googleUser.idToken?.tokenString
            else {
                print("Google Sign-In: Missing user or idToken.")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: googleUser.accessToken.tokenString)
            
            let googleEmail = googleUser.profile?.email
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Sign-In (Google) error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                    }
                    return
                }
                
                guard let user = authResult?.user else {
                    print("Google Sign-In: Firebase user missing.")
                    return
                }
                
                let isNewUser = authResult?.additionalUserInfo?.isNewUser ?? false
                let displayName = user.displayName
                let photoURL = user.photoURL?.absoluteString
                
                upsertUserDocument(user: user,
                                   extraEmail: googleEmail,
                                   name: displayName,
                                   photoURL: photoURL,
                                   isNewUser: isNewUser) { upsertError in
                    if let upsertError = upsertError {
                        print("⚠️ Failed to upsert Google user doc: \(upsertError.localizedDescription)")
                    }
                    DispatchQueue.main.async {
                        firestore.isLoggedIn = true
                    }
                }
            }
        }
    }
    
    // MARK: - Firestore upsert helper
    private func upsertUserDocument(user: FirebaseAuth.User,
                                    extraEmail: String? = nil,
                                    name: String? = nil,
                                    photoURL: String? = nil,
                                    isNewUser: Bool,
                                    completion: ((Error?) -> Void)? = nil) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "userID": user.uid
        ]
        if let email = user.email ?? extraEmail {
            data["email"] = email
        }
        if let name = name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            data["name"] = name
        }
        if let photoURL = photoURL, !photoURL.isEmpty {
            data["profileImageURL"] = photoURL
        }
        
        // Only set createdAt the first time we create this user
        if isNewUser {
            data["createdAt"] = formattedCreatedAtString()
        }
        
        db.collection("users").document(user.uid).setData(data, merge: true) { error in
            completion?(error)
        }
    }
    
    private func formattedCreatedAtString() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm:ss a"
        let datePart = formatter.string(from: now)
        
        // Build "UTC-5" style suffix
        let seconds = TimeZone.current.secondsFromGMT(for: now)
        let sign = seconds >= 0 ? "+" : "-"
        let absSeconds = abs(seconds)
        let hours = absSeconds / 3600
        let minutes = (absSeconds % 3600) / 60
        let tzSuffix: String
        if minutes == 0 {
            tzSuffix = "UTC\(sign)\(hours)"
        } else {
            tzSuffix = String(format: "UTC%@%d:%02d", sign, hours, minutes)
        }
        return "\(datePart) \(tzSuffix)"
    }
    
    // MARK: - Apple Nonce
    @State private var currentNonce: String?
    
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        currentNonce = result // store raw nonce for Firebase
        return result
    }
    
    // SHA256 hash helper for Apple request.nonce
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    LogInPage()
        .environmentObject(FirestoreViewModel(name: "Preview"))
}

struct OASISTitle: View {
    var fontSize: CGFloat
    var kerning: CGFloat = 10
    
    var body: some View {
        Text("OASIS")
            .foregroundStyle(LinearGradient(gradient: Gradient(colors: [Color("OASIS Dark Orange"), Color("OASIS Light Orange"), Color("OASIS Light Blue"), Color("OASIS Dark Blue")]), startPoint: .topLeading, endPoint: .bottomTrailing))
            .kerning(kerning)
            .font(Font.system(size: fontSize))
            .bold()
//            .italic()
    }
}
