//
//  FilmRollApp.swift
//  FilmRoll
//
//  Created by 김민재 on 4/2/26.
//

import SwiftUI
import SwiftData

@main
struct FilmRollApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(for: [Roll.self, Frame.self])
    }
}
