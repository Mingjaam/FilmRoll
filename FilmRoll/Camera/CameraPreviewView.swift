import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var manager: CameraManager  // previewLayer 변화 감지

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        if let layer = manager.previewLayer {
            view.setPreviewLayer(layer)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let layer = manager.previewLayer {
            uiView.setPreviewLayer(layer)
        }
    }

    class PreviewUIView: UIView {
        private var previewLayer: AVCaptureVideoPreviewLayer?

        func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
            // 동일한 레이어면 프레임만 업데이트
            guard previewLayer !== layer else {
                previewLayer?.frame = bounds
                return
            }
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
