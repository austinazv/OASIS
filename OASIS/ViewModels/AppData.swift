//
//  AppData.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 7/7/26.
//

import Foundation
import SwiftUI
import UIKit
//import CryptoKit
//import Firebase
//import FirebaseAuth
//import FirebaseFirestore
//import FirebaseStorage


struct Artist: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var genres: [String]
    var imageURL: String
    var imageLocalPath: String?
    var day: String = "-- N/A --"
    var weekend: String = "Both"
    var tier: String = "-- N/A --"
    var stage: String = "-- N/A --"
    var addDate = Date()
    var modifyDate = Date()
//    var artistTags: [UUID] // ✅ now non-optional

    enum CodingKeys: String, CodingKey {
        case id, name, genres, imageURL, imageLocalPath
        case day, weekend, tier, stage
        case addDate, modifyDate
//        case artistTags
    }

    init(
        id: String,
        name: String,
        genres: [String],
        imageURL: String,
        imageLocalPath: String? = nil,
        day: String = "-- N/A --",
        weekend: String = "Both",
        tier: String = "-- N/A --",
        stage: String = "-- N/A --",
        addDate: Date = Date(),
        modifyDate: Date = Date(),
//        artistTags: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.genres = genres
        self.imageURL = imageURL
        self.imageLocalPath = imageLocalPath
        self.day = day
        self.weekend = weekend
        self.tier = tier
        self.stage = stage
        self.addDate = addDate
        self.modifyDate = modifyDate
//        self.artistTags = artistTags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        genres = try container.decode([String].self, forKey: .genres)
        imageURL = try container.decode(String.self, forKey: .imageURL)
        imageLocalPath = try container.decodeIfPresent(String.self, forKey: .imageLocalPath)
        day = try container.decodeIfPresent(String.self, forKey: .day) ?? "-- N/A --"
        weekend = try container.decodeIfPresent(String.self, forKey: .weekend) ?? "Both"
        tier = try container.decodeIfPresent(String.self, forKey: .tier) ?? "-- N/A --"
        stage = try container.decodeIfPresent(String.self, forKey: .stage) ?? "-- N/A --"
        addDate = try container.decodeIfPresent(Date.self, forKey: .addDate) ?? Date()
        modifyDate = try container.decodeIfPresent(Date.self, forKey: .modifyDate) ?? Date()

        // 👇 THE IMPORTANT LINE
//        artistTags = try container.decodeIfPresent([UUID].self, forKey: .artistTags) ?? []
    }
}




struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed != 0 ? seed : 0xDEADBEEF
    }

    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}

//private func makeSeed(from uuid: UUID) -> UInt64 {
//    let bytes = uuid.uuid
//
//    var seed: UInt64 = 0
//
//    seed |= UInt64(bytes.0) << 56
//    seed |= UInt64(bytes.1) << 48
//    seed |= UInt64(bytes.2) << 40
//    seed |= UInt64(bytes.3) << 32
//    seed |= UInt64(bytes.4) << 24
//    seed |= UInt64(bytes.5) << 16
//    seed |= UInt64(bytes.6) << 8
//    seed |= UInt64(bytes.7)
//
//    return seed
//}

extension UUID {
    var shuffleSeed: UInt64 {
        let bytes = uuid

        var seed: UInt64 = 0

        seed |= UInt64(bytes.0) << 56
        seed |= UInt64(bytes.1) << 48
        seed |= UInt64(bytes.2) << 40
        seed |= UInt64(bytes.3) << 32
        seed |= UInt64(bytes.4) << 24
        seed |= UInt64(bytes.5) << 16
        seed |= UInt64(bytes.6) << 8
        seed |= UInt64(bytes.7)

        return seed
    }
}

extension Array {

    func seededShuffle(seed: UUID) -> [Element] {
        var copy = self

        var generator = SeededGenerator(seed: seed.shuffleSeed)

        copy.shuffle(using: &generator)

        return copy
    }

}


struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var maxRows: Int? = nil
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentRow = 1

        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth {
                currentRow += 1

                if let maxRows, currentRow > maxRows {
                    break
                }

                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentRow = 1
        
        let rowWidth = currentX - spacing // subtract trailing spacing
        let xOffset: CGFloat

        switch alignment {
        case .trailing:
            xOffset = bounds.width - rowWidth
        default:
            xOffset = 0
        }

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > bounds.width {
                currentRow += 1

                if let maxRows, currentRow > maxRows {
                    break
                }

                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            subview.place(
                at: CGPoint(
                    x: bounds.minX + xOffset + currentX,
                    y: bounds.minY + currentY
                ),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}



struct FlowLayoutWidget: Layout {
    var spacing: CGFloat = 8
    let rowsMax: Int = 2

    struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func makeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)

            let proposedWidth = current.indices.isEmpty
                ? size.width
                : current.width + spacing + size.width

            if !current.indices.isEmpty && proposedWidth > maxWidth {
                rows.append(current)

                if rows.count == rowsMax {
                    return rows
                }

                current = Row()
            }

            if current.indices.isEmpty {
                current.width = size.width
            } else {
                current.width += spacing + size.width
            }

            current.height = max(current.height, size.height)
            current.indices.append(index)
        }

        if !current.indices.isEmpty && rows.count < rowsMax {
            rows.append(current)
        }

        return rows
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = makeRows(maxWidth: width, subviews: subviews)

        let height = rows.reduce(CGFloat(0)) { partial, row in
            partial + row.height
        } + CGFloat(max(0, rows.count - 1)) * spacing

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = makeRows(maxWidth: bounds.width, subviews: subviews)

        var placed = Set<Int>()
        var y = bounds.minY

        for row in rows {
            var x = bounds.maxX - row.width

            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)

                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )

                placed.insert(index)
                x += size.width + spacing
            }

            y += row.height + spacing
        }

        // Hide anything that didn't fit.
        for index in subviews.indices where !placed.contains(index) {
            subviews[index].place(
                at: CGPoint(x: -10_000, y: -10_000),
                proposal: .unspecified
            )
        }
    }
}

//func genresSortedByPopularity(genres: [String], artistList: [Artist]) -> [String] {
//    
//    // Count how many artists belong to each genre
//    var genreCounts: [String: Int] = [:]
//    
//    for artist in artistList {
//        for genre in artist.genres {
//            genreCounts[genre, default: 0] += 1
//        }
//    }
//    
//    // Sort the supplied genres by popularity
//    return genres.sorted { lhs, rhs in
//        let lhsCount = genreCounts[lhs, default: 0]
//        let rhsCount = genreCounts[rhs, default: 0]
//        
//        if lhsCount == rhsCount {
//            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
//        }
//        
//        return lhsCount > rhsCount
//    }
//}

