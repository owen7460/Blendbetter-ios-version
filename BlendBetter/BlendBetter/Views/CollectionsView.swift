import SwiftUI

struct CollectionsView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image("homelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 100)

                Text("Collection function will be available in Version 1.1.0")
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Collections")
        }
    }
}
