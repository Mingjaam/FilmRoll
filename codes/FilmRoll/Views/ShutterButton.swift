import SwiftUI

struct ShutterButton: View {
    let isCapturing: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // 바깥 링
                Circle()
                    .stroke(Color(hex: "#C8762A"), lineWidth: 2.5)
                    .frame(width: 68, height: 68)

                // 안쪽 원
                Circle()
                    .fill(isPressed || isCapturing
                          ? Color(hex: "#C8762A")
                          : Color(hex: "#C8762A").opacity(0.15))
                    .frame(width: 54, height: 54)
            }
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .disabled(isCapturing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
