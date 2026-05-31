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
    }
}
