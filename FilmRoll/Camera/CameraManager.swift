import AVFoundation
import UIKit
import SwiftUI
import Combine

@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var capturedImage: UIImage?
    @Published var isCapturing = false

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<UIImage?, Never>?

    override init() {
        super.init()
        Task { await setupSession() }
    }

    private func setupSession() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("🎥 Camera authorization status: \(status.rawValue)")
        
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            print("🎥 Camera access requested, granted: \(granted)")
        }
        
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            print("❌ Camera not authorized!")
            return
        }
        
        print("✅ Camera authorized, setting up session...")

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
        
        print("✅ Camera session configured")

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.previewLayer = layer
        
        print("✅ Preview layer created")

        Task.detached { [weak self] in
            self?.session.startRunning()
            print("✅ Camera session started")
        }
    }

    func capture() async -> UIImage? {
        guard !isCapturing else { return nil }
        isCapturing = true
        defer { isCapturing = false }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    func stop() {
        Task.detached { [weak self] in
            self?.session.stopRunning()
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        let image: UIImage?
        if let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        } else {
            image = nil
        }
        Task { @MainActor in
            self.continuation?.resume(returning: image)
            self.continuation = nil
        }
    }
}
