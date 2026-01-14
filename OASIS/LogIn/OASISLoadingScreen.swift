//
//  OASISLoadingScreen.swift
//  OASIS
//
//  Created by Austin Zambito-Valente on 10/18/25.
//

import SwiftUI

struct OASISLoadingScreen: View {
    private let gradient = LinearGradient(
        colors: [
            Color("OASIS Dark Orange"),
            Color("OASIS Light Orange"),
            Color("OASIS Light Blue"),
            Color("OASIS Dark Blue")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Use the shared namespace for matched geometry with the destination title
    let namespace: Namespace.ID

    var body: some View {
        // Compose spinner “O” + “ASIS” with matchedGeometryEffect
        let content = OASISTitleComposable(
            namespace: namespace,
            fontSize: 48,
            kerning: 10,
            showSpinnerO: true,
            isSource: true // <- SOURCE while loading
        )

        gradient
            .frame(width: 300, height: 120)
            .mask(content)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
}

struct OASISSpinner: View {
    var lineWidth: CGFloat = 6.5
    var size: CGFloat = 32
    var trimTo: CGFloat = 0.75
    @State private var rotation: Angle = .degrees(0)

    var body: some View {
        ZStack {
            // Main arc
            Circle()
                .trim(from: 0.0, to: trimTo)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0.0), location: 0.0),
                            .init(color: .white.opacity(0.5), location: trimTo * 0.6),
                            .init(color: .white, location: trimTo)
                        ]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
                )
                .frame(width: size, height: size)
        }
        .rotationEffect(rotation)
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = .degrees(360)
            }
        }
    }
}

#Preview {
    struct Wrapper: View {
        @Namespace var ns
        var body: some View {
            OASISLoadingScreen(namespace: ns)
        }
    }
    return Wrapper()
}
