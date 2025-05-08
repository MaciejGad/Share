//
//  BrightSpotDetectionApp.swift
//  BrightSpotDetection
//
//  Created by bazyl on 05/05/2025.
//

import SwiftUI

@main
struct BrightSpotDetectionApp: App {
    var body: some Scene {
        WindowGroup {
            GlareDetectionView()
                .environmentObject(GlareDetectionViewModel())
        }
    }
}
