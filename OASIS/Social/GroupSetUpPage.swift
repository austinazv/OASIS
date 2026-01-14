//
//  GroupSetUp.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 3/7/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import FirebaseStorage

struct GroupSetUpPage: View {
    @EnvironmentObject var data: DataSet
    
    @Binding var navigationPath: NavigationPath
    
    @State private var groupName = ""
    @State private var isLoading = false
    @State private var setupDone = false
    
    
    @State private var showPhotoPicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State var selectedImage: UIImage?
    
    @State var createdGroup: DataSet.SocialGroup?
    
    @State var errorAlert: Bool = false
    

    var body: some View {
        if setupDone {
//            GroupPage(navigationPath: $navigationPath, group: self.createdGroup!).environmentObject(data)
        } else {
            ZStack {
                GroupNameField
                if isLoading {
                    ProgressView()
                }
            }
        }
    }
    
    var GroupNameField: some View {
        VStack(spacing: 20) {
            Text("Create New Group")
                .font(.largeTitle)
                .fontWeight(.bold)
            ZStack(alignment: .center) {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130, alignment: .center)
                        .clipShape(Circle())
                } else {
                    Image("Default Group Profile Picture")
                        .resizable()
                        .frame(width: 130, height: 130, alignment: .center)
                        .clipShape(Circle())
                    Text("Upload Image").foregroundStyle(Color.black)
                }
            }
            .onTapGesture {
                showPhotoPicker = true
            }
            TextField("Group Name", text: $groupName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .autocapitalization(.words)

            Button(action: saveGroupInfo) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(groupName.isEmpty ? Color.gray : Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
            }
            .disabled(groupName.isEmpty || isLoading)

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
        .alert(isPresented: $errorAlert) {
            Alert(
                title: Text("Something went wrong"),
                message: Text("Please try again later"),
                dismissButton: .default(Text("Ok"))
            )
        }
        .onChange(of: errorAlert) { newValue in
            if newValue == false {
                navigationPath.removeLast()
            }
//                print("🔄 pendingFriendRequest updated: \(String(describing: newValue))")
        }
    }
    
    private func saveGroupInfo() {
        isLoading = true
        data.createGroup(groupName: groupName, groupPhoto: selectedImage) { newGroup in
            if let group = newGroup {
                print("🎉 Group created successfully!")
                isLoading = false
                self.createdGroup = group
                setupDone = true
            } else {
                isLoading = false
                print("❌ Failed to create group.")
                errorAlert = true
            }
        }
    }


    
    
    
}
