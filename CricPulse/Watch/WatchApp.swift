// MARK: - watchOS App Entry Point
//
// ⚠️  Add this file to the watchOS target ONLY.
//    Never add to the iOS target — both use @main which conflicts.
//
// Xcode setup:
//   File → New Target → watchOS → Watch App
//   Name: "CricPulse Watch App"  |  Bundle: hasan.CricPulse.watchkitapp
//   Deployment target: watchOS 10.0
//   Then add to the watch target:
//     • Shared/Models/CricketModels.swift
//     • Shared/Models/CricSheetsModels.swift
//     • Shared/Networking/CricketAPIService.swift
//     • Shared/Networking/CricSheetsAPIService.swift
//     • Shared/ViewModels/MatchListViewModel.swift
//     • Shared/ViewModels/MatchDetailViewModel.swift
//     • CricPulse/Config/CricColors.swift
//     • CricPulse/Models/TeamHelpers.swift
//     • CricPulse/Config/APIConfig.swift
//     • CricPulse/Watch/WatchContentView.swift
//     • CricPulse/Watch/WatchMatchDetailView.swift
//     • CricPulse/Watch/WatchApp.swift  (this file)
//
// ATS: add NSAllowsLocalNetworking to the watch target's Info tab so
// the simulator can reach http://127.0.0.1:8000.

import SwiftUI

@main
struct CricPulseWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
