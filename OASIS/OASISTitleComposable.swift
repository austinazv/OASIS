import SwiftUI

// EnvironmentKey to pass the namespace down easily
private struct OasisNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
    var oasisNamespace: Namespace.ID? {
        get { self[OasisNamespaceKey.self] }
        set { self[OasisNamespaceKey.self] = newValue }
    }
}

// A composable “OASIS” where the first glyph can be a spinner or a static “O”.
// It applies matchedGeometryEffect to both the “O” slot and the trailing “ASIS” text.
struct OASISTitleComposable: View {
    let namespace: Namespace.ID
    var fontSize: CGFloat
    var kerning: CGFloat = 10
    var showSpinnerO: Bool
    var isSource: Bool // <- NEW

    private let gradient = LinearGradient(
        gradient: Gradient(colors: [
            Color("OASIS Dark Orange"),
            Color("OASIS Light Orange"),
            Color("OASIS Light Blue"),
            Color("OASIS Dark Blue")
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if showSpinnerO {
                    OASISSpinner()
                        .frame(width: fontSize * 0.66, height: fontSize * 0.66)
                        .matchedGeometryEffect(id: "OASIS-O", in: namespace, isSource: isSource)
                } else {
                    Text("O")
                        .font(.system(size: fontSize, weight: .bold))
                        .matchedGeometryEffect(id: "OASIS-O", in: namespace, isSource: isSource)
                        .offset(x: 5)
                }
            }
            Text("ASIS")
                .font(.system(size: fontSize, weight: .bold))
                .kerning(kerning)
                .matchedGeometryEffect(id: "OASIS-ASIS", in: namespace, isSource: isSource)
        }
        .foregroundStyle(gradient)
        .environment(\.oasisNamespace, namespace)
    }
}
