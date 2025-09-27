//
//  MyProfilePage.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 2/26/25.
//

import SwiftUI
import PhotosUI

struct MyProfilePage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    var profile: DataSet.UserProfile
    
    @State var editView = false
    @State var signOutAlert = false
    
    @State private var name = ""
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    
    
    var body: some View {
        MyProfileView
    }
    
    var MyProfileView: some View {
        Group {
            VStack {
                ZStack {
                    if editView && selectedImage != nil {
                        Image(uiImage: selectedImage!)
                            .resizable()
                            .scaledToFill()
                            .frame(width: PHOTO_SIZE, height: PHOTO_SIZE, alignment: .center)
                            .clipShape(Circle())
                    } else if let localPath = profile.profilePic, let image = UIImage(contentsOfFile: localPath) {
                        Image(uiImage: image)
//                        AsyncImage(url: url) { image in
//                            image
//
//                        } placeholder: {
//                            ProgressView()
//                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: PHOTO_SIZE, height: PHOTO_SIZE, alignment: .center)
                        .clipShape(Circle())
                    } else {
                        Image("Default Profile Picture")
                            .resizable()
                            .frame(width: PHOTO_SIZE, height: PHOTO_SIZE, alignment: .center)
                            .clipShape(Circle())
                    }
                    if editView {
                        Text("Choose New Photo")
                            .foregroundStyle(Color.black)
                            .bold().italic()
                            .font(Font.system(size: 20))
                            .frame(maxWidth: PHOTO_SIZE)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(10)
                .onTapGesture {
                    if editView {
                        showPhotoPicker = true
                    }
                }
                ZStack {
                    if editView {
                        TextField("Your Name", text: $name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.words)
                    } else {
                        Text(profile.name)
                            .multilineTextAlignment(.center)
                            .font(Font.system(size: 25))
                    }
                }
                .padding(10)
                Group {
                    if editView {
                        Button(action: {
                            self.signOutAlert.toggle()
                        }, label: {
                            Text("Sign Out")
                                .frame(width: 200, height: 40)
                                .background(Color.red)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                            
                        })
                    }
                }
                .padding(10)
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if editView {
                            data.saveName(name: name) { success in
                                if success {
                                    if let photo = selectedImage {
                                        data.uploadImageAndSaveToFirestore(image: photo) { _ in }
                                    }
                                }
                            }
//                            data.saveName(name: name)
//                            if let photo = selectedImage {
//                                data.uploadImageAndSaveToFirestore(image: photo)
//                            }
                        } else {
                            self.name = self.profile.name
                        }
                        editView.toggle()
                    }) {
                        HStack {
                            if editView {
                                Text("Save")
                                    .foregroundStyle(name.isEmpty ? Color.gray : Color.blue)
                            } else {
                                Text("Edit")
                                Image(systemName: "square.and.pencil")
                            }
                        }
                    }
                    .disabled(editView && name.isEmpty)
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
            .alert(isPresented: self.$signOutAlert) {
                Alert(title: Text("Sign Out"),
                      message: Text("Are you sure you want to sign out?"),
                      primaryButton: .destructive(Text("Sign Out")) {
                    data.signOutUser { result in
                        switch result {
                        case .success:
                            print("User signed out successfully")
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                            }
                            navigationPath = NavigationPath()
                        case .failure(let error):
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }
                }, secondaryButton: .cancel()
                )
            }
        }
    }
    
    let PHOTO_SIZE: CGFloat = 150
    
}

//#Preview {
////    MyProfilePage()
//}
