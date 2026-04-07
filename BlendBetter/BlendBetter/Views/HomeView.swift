//
//  HomeView.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var showRecipePicker = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("\(appViewModel.selectedRecipeOption.emoji) \(appViewModel.selectedRecipeOption.subtitle)")
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        Text("Please choose 1-3 kinds of fruits, you can check what you have in your fridge")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Fruit.all) { fruit in
                            FruitCardView(
                                fruit: fruit,
                                isSelected: appViewModel.selectedFruits.contains(fruit.name)
                            )
                            .onTapGesture {
                                appViewModel.toggleFruit(fruit.name)
                            }
                        }
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8) {
                        Text("You selected: \(appViewModel.finalFruitList.joined(separator: ", "))")
                            .font(.subheadline)

                        if let detectedFruit = appViewModel.detectedFruit {
                            Text("Camera detected: \(detectedFruit)")
                                .font(.footnote)
                                .foregroundStyle(.green)
                        }
                    }

                    Button {
                        Task {
                            await appViewModel.generateRecipe()
                        }
                    } label: {
                        Text("Generate")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.48, green: 0.78, blue: 0.51))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    if appViewModel.isLoading {
                        Text("Generating recipe...")
                            .foregroundStyle(.green)
                            .font(.subheadline)
                    }

                    if let errorMessage = appViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .padding(.horizontal)
                    }

                    if !appViewModel.generatedText.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Result")
                                .font(.headline)

                            ScrollView {
                                Text(appViewModel.generatedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .frame(minHeight: 160)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button("Clear & Start Over") {
                                appViewModel.clearAll()
                            }
                            .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("BlendBetter")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Type") {
                        showRecipePicker = true
                    }
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipeTypePickerView()
            }
        }
    }
}
