//
//  Fruit.swift
//  BlendBetter
//
//  Created by Owen on 4/7/26.
//

import Foundation

struct Fruit: Identifiable, Hashable {
    let id: Int
    let name: String
    let imageName: String

    static let all: [Fruit] = [
        Fruit(id: 1, name: "Apple", imageName: "apple"),
        Fruit(id: 2, name: "Banana", imageName: "banana"),
        Fruit(id: 3, name: "Orange", imageName: "orange"),
        Fruit(id: 4, name: "Pineapple", imageName: "pineapple"),
        Fruit(id: 5, name: "Strawberry", imageName: "strawberry"),
        Fruit(id: 6, name: "Watermelon", imageName: "watermelon"),
        Fruit(id: 7, name: "Kiwi", imageName: "kiwi"),
        Fruit(id: 8, name: "Mango", imageName: "mango"),
        Fruit(id: 9, name: "Peach", imageName: "peach")
    ]
}
