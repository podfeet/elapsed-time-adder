//
//  ElapsedTimeAdderApp.swift
//  ElapsedTimeAdder
//
//  Created by Allison on 4/27/26.
//

import SwiftUI

@main
struct ElapsedTimeAdderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
#if os(macOS)
                .frame(minWidth: 680, minHeight: 400)
#endif
        }
#if os(macOS)
        // Replace the default (broken) "Elapsed Time Adder Help" menu item — which shows
        // "Help isn't available" because no help book is bundled — with a link to the
        // marketing page (which carries the how-to-get-help content).
        .commands {
            CommandGroup(replacing: .help) {
                Link("Elapsed Time Adder Help",
                     destination: URL(string: "https://timeadder.podfeet.com")!)
            }
        }
#endif
    }
}
