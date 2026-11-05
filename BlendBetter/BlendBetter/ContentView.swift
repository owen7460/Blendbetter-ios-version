// xcode: set sdk=iOS

//
//  ContentView.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        TabView(selection: $appViewModel.selectedTab) {

            HomeView()
                .tabItem {
                    Label("Blend", systemImage: "takeoutbag.and.cup.and.straw.fill")
                }
                .tag(0)

            CollectionsView()
                .tabItem {
                    Label("Collections", systemImage: "star.fill")
                }
                .tag(1)

            UsersView()
                .tabItem {
                    Label("Users", systemImage: "person.fill")
                }
                .tag(2)

            CameraView()
                .tabItem {
                    Label("Camera", systemImage: "camera.fill")
                }
                .tag(3)
        }
        .tint(Color(red: 0.48, green: 0.78, blue: 0.51))
    }
}
