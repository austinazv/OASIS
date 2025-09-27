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

struct AccountSetUpPage: View {
    @EnvironmentObject var data: DataSet
    
    
//    @StateObject var viewModel = UserProfileViewModel()
    
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var loggedIn = false
    
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State private var navigationPath = NavigationPath()
    

    var body: some View {
        if loggedIn {
            SocialPage(navigationPath: $navigationPath, userID: Auth.auth().currentUser!.uid).environmentObject(data)
        } else {
            NameField
        }
    }
    
    var NameField: some View {
        VStack(spacing: 20) {
            Text("Account Linked")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Add your name and profile picture")
                .multilineTextAlignment(.center)
                .italic()
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
            .onTapGesture {
                showPhotoPicker = true
            }
            TextField("Your Name", text: $name)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.words)

            Button(action: saveUserInfo) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(name.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(name.isEmpty || isLoading)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Spacer()
        }
        .padding()
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
    
    private func saveUserInfo() {
        data.saveName(name: name) { success in
            if success {
                if let photo = selectedImage {
                    data.uploadImageAndSaveToFirestore(image: photo) { _ in
                        if Auth.auth().currentUser != nil {
//                            self.
//                            DispatchQueue.main.async {
                                self.loggedIn = true
//                            }
                        }
                    }
                } else {
                    if Auth.auth().currentUser != nil {
//                        DispatchQueue.main.async {
                            self.loggedIn = true
//                        }
                    }
                }
            }
        }
    }


    
    
    
}
