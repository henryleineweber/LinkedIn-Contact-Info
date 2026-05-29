import SwiftUI

@main
struct LinkedInContactSyncApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 720, height: 620)
        #endif
    }
}
