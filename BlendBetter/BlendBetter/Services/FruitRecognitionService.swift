import Foundation
import UIKit
import Vision

final class FruitRecognitionService {
    static let shared = FruitRecognitionService()

    /// (normalized keyword, fruit name), longest keywords first so that
    /// e.g. "pineapple" wins over "apple" and "blood orange" over "orange".
    private let keywords: [(key: String, fruit: String)] = {
        Fruit.all
            .flatMap { fruit in
                ([fruit.name] + fruit.aliases).map { (key: FruitRecognitionService.normalize($0), fruit: fruit.name) }
            }
            .sorted { $0.key.count > $1.key.count }
    }()

    nonisolated private static func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: .diacriticInsensitive, locale: nil)
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Matches a Vision label against a keyword on word boundaries,
    /// so "date" doesn't match inside unrelated labels.
    nonisolated private static func label(_ label: String, matches key: String) -> Bool {
        if label == key || label == key + "s" || label == key + "es" { return true }
        let padded = " \(label) "
        return padded.contains(" \(key) ") || padded.contains(" \(key)s ")
    }

    func recognizeFruit(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("Failed to get cgImage")
            completion(nil)
            return
        }

        let keywords = self.keywords

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

            for result in results.prefix(10) {
                let label = FruitRecognitionService.normalize(result.identifier)
                if let match = keywords.first(where: { FruitRecognitionService.label(label, matches: $0.key) }) {
                    completion(match.fruit)
                    return
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
