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
    var onColorExtracted: ((Color) -> Void)?
    
    @State private var prominentColor: Color = .black
    
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
            let color = cached.prominentColor()
            image = cached
            prominentColor = color
            onColorExtracted?(color)
            return
        }
        
        // 2. Remote fetch
        guard let url = URL(string: imageURL) else { return }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let img = UIImage(data: data) {
                let color = img.prominentColor()
                DispatchQueue.main.async {
                    self.image = img
                    self.prominentColor = color
                    self.onColorExtracted?(color)
                }
            }
        }.resume()
    }
}

//struct ArtistImage: View {
//    let imageURL: String
//    let frame: CGFloat
//    @State private var image: UIImage?
//
//    var body: some View {
//        Group {
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: frame, height: frame)
//                    .clipShape(Rectangle())
//            } else {
//                Image(systemName: "person.crop.circle.fill")
//                    .resizable()
//                    .foregroundColor(.gray)
//                    .frame(width: frame, height: frame)
////                    .onAppear { loadImage() }
//            }
//        }
//        .onChange(of: imageURL) {
//            image = nil
//        }
//    }

//    private func loadImage() {
//        // 1. Cached?
//        if let cached = ImageCache.shared.getCachedImage(for: imageURL) {
//            image = cached
//            return
//        }
//
//        // 2. Remote fetch
//        guard let url = URL(string: imageURL) else { return }
//
//        URLSession.shared.dataTask(with: url) { data, _, _ in
//            if let data = data, let img = UIImage(data: data) {
////                ImageCache.shared.cacheImage(data, for: imageURL)
//                DispatchQueue.main.async {
//                    self.image = img
//                }
//            }
//        }.resume()
//    }
//}

//struct ArtistImage: View {
//    let image: UIImage?
//    let frame: CGFloat
//
//    var body: some View {x
//        Group {
//            if let image = image {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFill()
//                    .frame(width: frame, height: frame)
//                    .clipShape(Rectangle())
//            } else {
//                Image(systemName: "person.crop.circle.fill")
//                    .resizable()
//                    .foregroundColor(.gray)
//                    .frame(width: frame, height: frame)
//            }
//        }
//    }
//}


extension UIImage {

    func prominentColor() -> Color {

        guard let cgImage = self.cgImage else { return .black }

        let width = 50
        let height = 50

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel

        var pixels = [UInt8](
            repeating: 0,
            count: width * height * bytesPerPixel
        )

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return .black }

        context.draw(
            cgImage,
            in: CGRect(x: 0, y: 0, width: width, height: height)
        )

        var colorCounts: [String: (count: Int, r: CGFloat, g: CGFloat, b: CGFloat)] = [:]

        for i in stride(from: 0, to: pixels.count, by: 4) {

            let r = CGFloat(pixels[i]) / 255
            let g = CGFloat(pixels[i + 1]) / 255
            let b = CGFloat(pixels[i + 2]) / 255

            let color = UIColor(red: r, green: g, blue: b, alpha: 1)

            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            var alpha: CGFloat = 0

            color.getHue(
                &hue,
                saturation: &saturation,
                brightness: &brightness,
                alpha: &alpha
            )

            // Ignore nearly black, white, and gray pixels
            guard brightness > 0.15,
                  brightness < 0.90,
                  saturation > 0.25 else {
                continue
            }

            // Exclude browns, tans, and skin tones
            let isSkinTone = (hue >= 0.035 && hue <= 0.13)
                && saturation < 0.75

            if isSkinTone {
                continue
            }

            // Group similar colors together
            let redBucket = Int(r * 10)
            let greenBucket = Int(g * 10)
            let blueBucket = Int(b * 10)

            let key = "\(redBucket)-\(greenBucket)-\(blueBucket)"

            if colorCounts[key] != nil {
                colorCounts[key]!.count += 1
            } else {
                colorCounts[key] = (1, r, g, b)
            }
        }

        // Find the most frequently occurring color bucket
        guard let dominant = colorCounts.values.max(by: {
            $0.count < $1.count
        }) else {
            return .black
        }

        return Color(
            red: dominant.r,
            green: dominant.g,
            blue: dominant.b
        )
    }
}
