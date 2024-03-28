//
//  VIMenuView.swift
//  kitsui
//
//  Created by Graeme Costin on 28/3/2024.
//

import SwiftUI

struct VIMenuView: View {
	@EnvironmentObject var bibMod: BibleModel

	var selectedCommand: VIMenuItem?
	
	init(selectedCommand: VIMenuItem) {
		self.selectedCommand = selectedCommand
	}
	var body: some View {
		List {
			ForEach(getChapInst().curPoMenu!.VIMenuItems) { VIMItem in
				VIMenuItemView(VIMItem: VIMItem).environmentObject(bibMod)
			}
		}
    }

	func getChapInst() -> Chapter {
		return bibMod.getCurBibInst().bookInst!.chapInst!
	}
}

#Preview {
	VIMenuView(selectedCommand : VIMenuItem("Heading Before", "crHdBef", "C"))
}
