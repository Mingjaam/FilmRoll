import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let manager: CameraManager

    func makeUIView(context: Context) -> PreviewUIView {
        PreviewUIView()
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let layer = manager.previewLayer {
            uiView.setPreviewLayer(layer)
        }
    }

    class PreviewUIView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?

        func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
            previewLayer?.removeFromSuperlayer()
            layer.frame = bounds
            self.layer.insertSublayer(layer, at: 0)
            previewLayer = layer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
