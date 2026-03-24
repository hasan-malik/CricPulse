import SwiftUI
import SwiftData

@main
struct CricPulseApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // Randomly switch between ball and bat icon on each launch
                let dark = UserDefaults.standard.bool(forKey: "isDarkMode")
                randomiseIconOnLaunch(isDark: dark)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(for: [FavouriteTeam.self, RecentlyViewedMatch.self])
    }
}
