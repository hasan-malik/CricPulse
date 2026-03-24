import SwiftUI

struct ContentView: View {
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
        }
        .tint(CricColors.accent)  // cricket red
    }
}

#Preview {
    ContentView()
}
