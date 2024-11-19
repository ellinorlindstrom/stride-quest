//
//  StrideQuestApp.swift
//  StrideQuest
//
//  Created by Ellinor Lindström on 2024-11-19.
//

import SwiftUI

@main
struct StrideQuestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
