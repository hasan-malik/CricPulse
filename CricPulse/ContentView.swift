import SwiftUI

struct ContentView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "cricket.ball.circle.fill")
                }

            MatchesTabView()
                .tabItem {
                    Label("Matches", systemImage: "list.bullet.rectangle")
                }

            ArchiveBrowseView()
                .tabItem {
                    Label("Archive", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                }
        }
        .tint(CricColors.accent)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
