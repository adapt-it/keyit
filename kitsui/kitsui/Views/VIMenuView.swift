//
//  VIMenuView.swift
//  kitsui
//
//  Created by Graeme Costin on 28/3/2024.
//

import SwiftUI

struct VIMenuView: View {
	@EnvironmentObject var bibMod: BibleModel
	@State private var settingsDetent = PresentationDetent.medium

	var selectedCommand: VIMenuItem?
	
	init(selectedCommand: VIMenuItem) {
		self.selectedCommand = selectedCommand
	}
	var body: some View {
		List {
			Section(calcMenuTitle().capitalized,
				content: {
				ForEach(getChapInst().curPoMenu!.VIMenuItems) { VIMItem in
					VIMenuItemView(VIMItem: VIMItem).environmentObject(bibMod)
						.presentationDetents(
							[.medium, .large],
							selection: $settingsDetent
						 )
					}
				}
			)
		}
    }

	func getChapInst() -> Chapter {
		return bibMod.getCurBibInst().bookInst!.chapInst!
	}

	func calcMenuTitle() -> String {
		let bibItem = getChapInst().BibItems[getChapInst().currItOfst]
		return "Action for " + bibItem.getItemTypText() + "?"
	}
}

#Preview {
	VIMenuView(selectedCommand : VIMenuItem("Heading Before", "crHdBef", "C"))
}
