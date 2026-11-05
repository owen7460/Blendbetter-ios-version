//
//  RecipeAPI.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//
import Foundation

struct RecipeAPI {
    static func streamRecipe(
        prompt: String,
        onDelta: @escaping @MainActor (String) -> Void,
        onFinish: @escaping @MainActor () -> Void
    ) async throws {
        guard let url = URL(string: "https://blendbetterai.com/api/chat") else {
            throw URLError(.badURL)
        }

        let body: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "parts": [
                        [
                            "type": "text",
                            "text": prompt
                        ]
                    ]
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        request.timeoutInterval = 120

        let (bytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard 200...299 ~= httpResponse.statusCode else {
            throw NSError(
                domain: "RecipeAPI",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Server returned \(httpResponse.statusCode)"]
            )
        }

        for try await rawLine in bytes.lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !line.isEmpty else { continue }
            guard line.hasPrefix("data:") else { continue }

            let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)

            guard let data = jsonString.data(using: .utf8) else { continue }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let type = json["type"] as? String {

                    if type == "text-delta",
                       let delta = json["delta"] as? String {
                        onDelta(delta)
                    }

                    if type == "finish" {
                        onFinish()
                        break
                    }
                }
            } catch {
                continue
            }
        }
    }
}
