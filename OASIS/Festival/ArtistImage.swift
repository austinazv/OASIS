//
//  ArtistI.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/7/26.
//

import SwiftUI

struct ArtistImage: View {
    let imageURL: String
    let frame: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: frame, height: frame)
                    .clipShape(Rectangle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: frame, height: frame)
                    .onAppear { loadImage() }
            }
        }
        .onChange(of: imageURL) {
            image = nil
        }
    }

    private func loadImage() {
        // 1. Cached?
        if let cached = ImageCache.shared.getCachedImage(for: imageURL) {
            image = cached
            return
        }

        // 2. Remote fetch
        guard let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
//                ImageCache.shared.cacheImage(data, for: imageURL)
                DispatchQueue.main.async {
                    self.image = img
                }
            }
        }.resume()
    }
}
