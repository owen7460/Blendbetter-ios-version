//
//  AppLinks.swift
//  BlendBetter
//

import Foundation

enum AppLinks {
    /// Linked from the AI consent screen and the Allergies page.
    /// The page MUST be live (public, no login) before submitting to the App Store,
    /// and it should name the AI provider (DeepSeek) and where data is stored.
    static let privacyPolicyURL: URL? = URL(string: "https://blendbetterai.com/privacy#ios")
}
