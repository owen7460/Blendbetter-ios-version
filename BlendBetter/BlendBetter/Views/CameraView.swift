import SwiftUI

struct CameraView: View {
    @StateObject private var camera = CameraService()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var detectedText: String = "No fruit detected yet"
    
    var body: some View {
        ZStack {
            switch camera.status {
            case .ready:
                if let preview = camera.previewLayer {
                    CameraPreview(previewLayer: preview)
                        .ignoresSafeArea()
                }
            case .starting:
                ProgressView("Starting camera...")
            case .unauthorized:
                ContentUnavailableView {
                    Label("Camera Access Needed", systemImage: "camera.fill")
                } description: {
                    Text("Allow camera access in Settings to detect fruits. You can still pick fruits on the Blend page.")
                } actions: {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .unavailable:
                ContentUnavailableView(
                    "Camera Unavailable",
                    systemImage: "camera.slash",
                    description: Text("No camera is available on this device. You can still pick fruits on the Blend page.")
                )
            }
            
            if camera.status == .ready {
                VStack {
                    Spacer()
                    
                    if let image = camera.capturedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        Text(detectedText)
                            .padding(.bottom, 8)
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                    
                    Button {
                        camera.capture()
                    } label: {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                camera.start()
            }
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: camera.capturedImage) { _, newImage in
            guard let newImage else { return }
            
            print("Captured image received")
            detectedText = "Recognizing..."
            
            FruitRecognitionService.shared.recognizeFruit(from: newImage) { fruit in
                DispatchQueue.main.async {
                    if let fruit {
                        print("Detected fruit: \(fruit)")
                        let added = appViewModel.addFruit(fruit)
                        
                        if added || appViewModel.selectedFruits.contains(fruit) {
                            detectedText = "Detected: \(fruit)"
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    appViewModel.selectedTab = 0
                                }
                            }
                        } else if appViewModel.isLoading {
                            detectedText = "Please wait for the current recipe"
                        } else if appViewModel.isFinished {
                            detectedText = "Tap \"Clear & Start Over\" to pick new fruits"
                        } else {
                            detectedText = "Maximum \(AppViewModel.maxFruits) fruits allowed"
                        }
                    } else {
                        print("No fruit recognized")
                        detectedText = "Could not recognize fruit"
                    }
                }
            }
        }
    }
}
