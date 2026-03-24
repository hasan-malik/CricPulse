import SwiftUI
import SwiftData

@main
struct CricPulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [FavouriteTeam.self, RecentlyViewedMatch.self])
    }
}
