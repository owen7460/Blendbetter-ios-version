//
//  BlendBetterApp.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import SwiftUI

@main
struct BlendBetterApp: App {
    @StateObject private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
        }
    }
}
