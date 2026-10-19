import SwiftUI

/// Independent beginner example. Replace the demo's ContentView with this view
/// to follow the Hello World chapter; it is not added to the game target.
struct ContentView: View {
    @State private var count = 0
    var body: some View {
        VStack(spacing: 24) {
            Text("Hello, World!").font(.largeTitle).bold()
            Button("点击次数：\(count)") { count += 1 }
                .accessibilityIdentifier("incrementCount")
        }.padding()
    }
}
