//
//  kitsuiApp.swift
//  kitsui
//
//  Created by Graeme Costin on 15/11/2023.
//

import SwiftUI

@main
struct kitsuiApp: App {
	// The kitsuiApp owns an instance of the class BibleModel
	// This is referenced by SwiftUI Views as bibMod in the SwiftUI environment
    @StateObject var bibMod = BibleModel()
    
    var body: some Scene {
        WindowGroup {
			SetupView(bibleName: bibMod.getCurBibName(), needSetup: bibMod.needSetup)
                .environmentObject(bibMod)	// bibMod is injected into SetupView
        }
    }
}
