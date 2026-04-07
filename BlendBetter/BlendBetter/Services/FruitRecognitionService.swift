//
//  FruitRecognitionService.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//
import Foundation
import UIKit
import Vision

final class FruitRecognitionService {
    static let shared = FruitRecognitionService()

    func recognizeFruit(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgImage")
            completion(nil)
            return
        }

        let request = VNClassifyImageRequest { request, error in
            if let error {
                print("Vision error:", error.localizedDescription)
                completion(nil)
                return
            }

            guard let results = request.results as? [VNClassificationObservation] else {
                print("No classification results")
                completion(nil)
                return
            }

            print("Top Vision results:")
            for result in results.prefix(10) {
                print("-", result.identifier, result.confidence)
            }

            let fruits: [String: String] = [
                "banana": "Banana",
                "apple": "Apple",
                "orange": "Orange",
                "pineapple": "Pineapple",
                "mango": "Mango",
                "peach": "Peach",
                "kiwi": "Kiwi",
                "strawberry": "Strawberry",
                "watermelon": "Watermelon"
            ]

            for result in results.prefix(10) {
                let label = result.identifier.lowercased()

                for (key, value) in fruits {
                    if label.contains(key) {
                        completion(value)
                        return
                    }
                }
            }

            completion(nil)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Handler perform error:", error.localizedDescription)
                completion(nil)
            }
        }
    }
}
