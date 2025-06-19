import SwiftUI

@available(macOS 26.0, *)
extension View {
    /// Applies the macOS 26 Liquid Glass material to the view's background.
    ///
    /// This creates a translucent, blurred backdrop with rounded corners,
    /// showcasing the new look introduced in macOS 26.
    func liquidGlassBackground(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: cornerRadius,
                                             style: .continuous))
            .glassBackgroundEffect()
    }
}
