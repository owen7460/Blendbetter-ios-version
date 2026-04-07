//
//  CameraView.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
import SwiftUI

struct CameraView: View {
    @StateObject private var camera = CameraService()
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var detectedText: String = "No fruit detected yet"
    
    var body: some View {
        ZStack {
            if let preview = camera.previewLayer {
                CameraPreview(previewLayer: preview)
                    .ignoresSafeArea()
            } else {
                ProgressView("Starting camera...")
            }
            
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
                        appViewModel.detectedFruit = fruit
                        
                        let added = appViewModel.addFruit(fruit)
                        
                        if added || appViewModel.selectedFruits.contains(fruit) {
                            detectedText = "Detected: \(fruit)"
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    appViewModel.selectedTab = 0
                                }
                            }
                        } else {
                            detectedText = "Maximum 3 fruits allowed"
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
