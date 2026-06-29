//
//  Due_AgainApp.swift
//  Due Again
//
//  Created by Cameron Baffuto on 6/22/26.
//

import SwiftUI
import SwiftData

@main
struct Due_AgainApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.modelContainer)
    }

    private static var modelContainer: ModelContainer {
        let schema = Schema([CadenceTask.self])
        let isUITestMode = ProcessInfo.processInfo.arguments.contains("UITestMode")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITestMode)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create Due Again model container: \(error)")
        }
    }
}
