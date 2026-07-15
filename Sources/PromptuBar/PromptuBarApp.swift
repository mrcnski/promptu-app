import SwiftUI

@main
struct PromptuBarApp: App {
    @StateObject private var session = Session()

    var body: some Scene {
        MenuBarExtra("Promptu", systemImage: "square.stack.3d.up") {
            ComposerView(session: session)
        }
        .menuBarExtraStyle(.window)
    }
}
