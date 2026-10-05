//
//  FestLogoView.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/6/26.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import CryptoKit

struct FestivalLogoView: View {
    let logoPath: String?
    let title: String
    let frame: CGFloat
    
    var invert: Bool = true
    var smallFont: Bool = false

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                InvertInDarkModeImage(image: image, frame: frame, invert: invert)
            } else {
                Text(title)
                    .font(smallFont ? .subheadline : .title)
                    .frame(height: frame)
                    .foregroundStyle(.bwColorSwitch)
            }
        }
        .task(id: logoPath) {
            guard let logoPath else { return }
            image = await ImageCache.shared.image(for: logoPath)
        }
    }
}

struct InvertInDarkModeImage: View {
    let image: UIImage
    let frame: CGFloat
    
    var invert: Bool

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Image(uiImage: processedImage)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: frame, alignment: .center)
    }

    private var processedImage: UIImage {
        if !invert { return image }
        if colorScheme == .dark {
            return invertImage(image) ?? image
        } else {
            return image
        }
    }
    
    func invertImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        let filter = CIFilter.colorInvert()
        filter.inputImage = ciImage

        guard let outputImage = filter.outputImage else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}


final class ImageCache {
    static let shared = ImageCache()

    private let cacheDir: URL
    private let memoryCache = NSCache<NSString, UIImage>() // 🔥 add this
    
    enum Shared {
        static let appGroup = "group.com.austinzambitovalente.OASIS"
    }

    private init() {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Shared.appGroup
        ) else {
            fatalError("Unable to locate App Group container.")
        }

        cacheDir = container.appendingPathComponent("imageCache", isDirectory: true)

        try? FileManager.default.createDirectory(
            at: cacheDir,
            withIntermediateDirectories: true
        )
    }

    private func localPath(for url: String) -> URL {
        cacheDir.appendingPathComponent(hashedFilename(for: url))
    }

    func getCachedImage(for url: String) -> UIImage? {
        // 1. Memory (fastest)
        if let image = memoryCache.object(forKey: url as NSString) {
            return image
        }

        // 2. Disk
        let path = localPath(for: url)
        if let image = UIImage(contentsOfFile: path.path) {
            memoryCache.setObject(image, forKey: url as NSString) // 🔥 promote to memory
            return image
        }

        return nil
    }

    func cacheImage(_ data: Data, for url: String) {
        let path = localPath(for: url)

        // Save to disk
        try? data.write(to: path)

        // Save to memory
        if let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: url as NSString)
        }
    }
    
    func removeCachedImage(for key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }
    
    private func hashedFilename(for url: String) -> String {
        let digest = SHA256.hash(data: Data(url.utf8))
        let hash = digest.map { String(format: "%02x", $0) }.joined()
        return "\(hash).img"
    }
    
    
    func image(for path: String) async -> UIImage? {

        // 1. Memory / shared disk cache
        if let cached = getCachedImage(for: path) {
            return cached
        }

        let url: URL

        // 2. Determine whether the path is remote or local
        if path.hasPrefix("http://") ||
            path.hasPrefix("https://") ||
            path.hasPrefix("gs://") {

            guard let remoteURL = URL(string: path) else {
                return nil
            }

            url = remoteURL

        } else {

            let documentsURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]

            url = documentsURL.appendingPathComponent(path)
        }

        // 3. Local file
        if url.isFileURL {
            guard
                let data = try? Data(contentsOf: url),
                let image = UIImage(data: data)
            else {
                return nil
            }

            cacheImage(data, for: path)
            return image
        }

        // 4. Remote image
        guard
            let (data, _) = try? await URLSession.shared.data(from: url),
            let image = UIImage(data: data)
        else {
            return nil
        }

        cacheImage(data, for: path)
        return image
    }
    
    func cachedFileURL(for url: String, displayName: String) -> URL? {
        let cachedPath = localPath(for: url)

        guard FileManager.default.fileExists(atPath: cachedPath.path) else {
            return nil
        }

        let previewURL = cacheDir
            .appendingPathComponent("\(displayName) Poster.jpg")

        do {
            if !FileManager.default.fileExists(atPath: previewURL.path) {
                try FileManager.default.copyItem(
                    at: cachedPath,
                    to: previewURL
                )
            }

            return previewURL
        } catch {
            print("Unable to create Quick Look file:", error)
            return nil
        }
    }
}
