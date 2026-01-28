//
//  AccountEditPage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/8/26.
//

import SwiftUI
import PhotosUI

struct AccountEditPage: View {
    @EnvironmentObject var firestore: FirestoreViewModel
    
    @Binding var navigationPath: NavigationPath
    
//    @State private var originalProfile: UserProfile?
//    @State var editingProfile = UserProfile()
    
    @State var didInitialize = false
    @State var hasBeenEdited = false
    @State var discardChangesAlert: Bool = false
    
    @State private var didRemovePhoto = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 100)
                PhotoField
                NameField
                Spacer()
            }

            VStack {
                Spacer()
                DeleteButton
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            newNameText = firestore.myUserProfile.name
        }
        .onChange(of: newNameText) { newText in
            if newText != firestore.myUserProfile.name {
                hasBeenEdited = true
            }
        }
        .onChange(of: selectedImage) { _ in
            hasBeenEdited = true
        }
        .onChange(of: didRemovePhoto) { _ in
            hasBeenEdited = true
        }
//        .onChange(of: editingProfile) { newValue in
//            hasBeenEdited = newValue != originalProfile
//        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    Button (action: {
                        if !hasBeenEdited {
                            navigationPath.removeLast()
                        } else {
                            discardChangesAlert = true
                        }
                    }, label: {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    })
                }
                .foregroundStyle(.blue)
            }
            ToolbarItem(placement: .topBarTrailing) {
                let isDisabled = (!hasBeenEdited || newNameText.isEmpty)
                Button (action: {
                    if hasBeenEdited {
                        Task {
                            let success = await firestore.updateUserInfo(
                                name: newNameText,
                                newPhoto: selectedImage,
                                didDeletePhoto: didRemovePhoto
                            )
                            
                            if success {
                                navigationPath.removeLast()
                            }
                        }
                    }
                }, label: {
                    Text("Save")
                })
                .foregroundStyle(isDisabled ? .gray : .blue)
                .disabled(isDisabled)
            }
            ToolbarItem(placement: .principal) {
                Text("Edit My Profile")
                    .font(.headline)
            }
        }
        .alert(isPresented: $discardChangesAlert) {
            return Alert(title: Text("Discard Changes?"),
                         message: Text("Are you sure you want to leave without saving?"),
                         primaryButton: .destructive(Text("Discard Changes")) {
                navigationPath.removeLast()
            }, secondaryButton: .cancel()
            )
        }
    }
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    
    
    var PhotoField: some View {
        Group {
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .center) {
                    if let selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())

                            Button {
                                withAnimation {
                                    self.selectedImage = nil
                                    selectedItem = nil
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }

                    } else if let urlString = firestore.myUserProfile.profilePic,
                              !didRemovePhoto,
                              let url = URL(string: urlString) {

                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Image("Default Profile Picture")
                                    .resizable()
                                    .scaledToFill()
                            }
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())

                            Button {
                                withAnimation {
                                    selectedImage = nil
                                    selectedItem = nil
                                    didRemovePhoto = true
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .offset(x: 6, y: -6)
                        }

                    } else {
                        ZStack {
                            Image("Default Profile Picture")
                                .resizable()
                                .frame(width: 130, height: 130)
                                .clipShape(Circle())

                            Text("Upload Image")
                                .foregroundStyle(Color.black)
                        }
                    }
                }
                .shadow(radius: 4)
                .onTapGesture {
                    showPhotoPicker = true
                }
                
                
                
                
                
                
                
                
                
                
                
                
                
//                ZStack(alignment: .center) {
//                    if let selectedImage {
//                        Image(uiImage: selectedImage)
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 130, height: 130, alignment: .center)
//                            .clipShape(Circle())
//                    } else {
//                        Image("Default Profile Picture")
//                            .resizable()
//                            .frame(width: 130, height: 130, alignment: .center)
//                            .clipShape(Circle())
//                        Text("Upload Image").foregroundStyle(Color.black)
//                    }
//                }
//                
//                // 'x' button appears only when a user-selected image exists
//                if selectedImage != nil {
//                    Button {
//                        withAnimation {
//                            selectedImage = nil
//                            selectedItem = nil
//                        }
//                    } label: {
//                        Image(systemName: "xmark")
//                            .font(.system(size: 10, weight: .bold))
//                            .foregroundColor(.white)
//                            .padding(6)
//                            .background(Color.black.opacity(0.85))
//                            .clipShape(Circle())
//                            .overlay(
//                                Circle().stroke(Color.white, lineWidth: 1)
//                            )
//                    }
//                    // Position slightly outside the 130x130 circle visually
//                    .offset(x: 6, y: -6)
//                    .accessibilityLabel("Remove photo")
//                }
            }
            // Add a circular black outline and subtle shadow to both cases
            .overlay(
                Circle()
                    .stroke(.oasisDarkBlue, lineWidth: 2)
                    .frame(width: 130, height: 130)
            )
            .shadow(radius: 4)
            .onTapGesture {
                showPhotoPicker = true
            }
            .padding(.vertical, 10)
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
    }
    
    @State var newNameText = ""
    
    var NameField: some View {
        HStack {
            Spacer().frame(width: 26)
            TextField("", text: $newNameText)
                .padding()
                .autocorrectionDisabled(true)
                .background(.oasisDarkBlue.opacity(0.2))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.oasisDarkBlue, lineWidth: 2)
                )
                .overlay(
                    Group {
                        if newNameText.isEmpty {
                            Text("Your Name *")
                                .foregroundColor(.gray)
                                .padding(.leading, 15)
                        }
                    }, alignment: .leading
                )
                .autocapitalization(.words)
//                .onSubmit {
//                    if allowContinue() {
//                        sendCode()
//                    }
//                }
            Spacer().frame(width: 26)
        }
        
    }
    
    @State var showDeleteAlert = false
    
    var DeleteButton: some View {
        VStack {
            Button(action: { showDeleteAlert = true }) {
                Text("Delete Account")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.red)
                    .cornerRadius(10)
            }
            
            
            
//            if let errorMessage = errorMessage {
//                Text(errorMessage)
//                    .foregroundStyle(.red)
//                    .multilineTextAlignment(.center)
//                    .padding()
//            }
        }
        .padding(30)
        
    }
    
    
    
}

//#Preview {
//    AccountEditPage()
//}
