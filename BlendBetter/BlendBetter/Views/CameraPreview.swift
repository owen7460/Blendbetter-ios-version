import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {

    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.backgroundColor = .black
        view.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        if uiView.previewLayer !== previewLayer {
            uiView.previewLayer = previewLayer
        }
    }
}

/// Keeps the preview layer the same size as the view on every layout pass.
/// (Setting the frame once at creation leaves it at 0×0 → black screen.)
final class PreviewContainerView: UIView {

    var previewLayer: AVCaptureVideoPreviewLayer? {
        didSet {
            guard oldValue !== previewLayer else { return }
            oldValue?.removeFromSuperlayer()
            if let previewLayer {
                layer.addSublayer(previewLayer)
            }
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // No implicit animation when the frame changes.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer?.frame = bounds
        CATransaction.commit()
    }
}
