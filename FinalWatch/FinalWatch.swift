//
//  FinalWatch.swift
//  FinalWatch
//
//  Created by  Apple on 22.05.2025.
//

import AppIntents

struct FinalWatch: AppIntent {
    static var title: LocalizedStringResource { "FinalWatch" }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
