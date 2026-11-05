//
//  CameraService.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//
import AVFoundation
import SwiftUI
import Combine

class CameraService: NSObject, ObservableObject {

    enum Status {
        case starting
        case ready
        /// The user denied (or restricted) camera access.
        case unauthorized
        /// No usable camera, e.g. the Simulator.
        case unavailable
    }

    @Published var capturedImage: UIImage?
    @Published private(set) var status: Status = .starting
    @Published private(set) var previewLayer: AVCaptureVideoPreviewLayer?

    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "camera.queue")
    private var isConfigured = false

    /// Checks permission (asking the first time), configures once, then runs.
    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if configureIfNeeded() { startRunning() }
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted {
                    if self.configureIfNeeded() { self.startRunning() }
                } else {
                    self.status = .unauthorized
                }
            }
        default:
            status = .unauthorized
        }
    }

    @discardableResult
    private func configureIfNeeded() -> Bool {
        if isConfigured { return true }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                 for: .video,
                                                 position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            status = .unavailable
            return false
        }

        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        previewLayer = layer

        isConfigured = true
        status = .ready
        return true
    }

    private func startRunning() {
        queue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        queue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    func capture() {
        guard status == .ready else { return }
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data)
        else { return }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}
