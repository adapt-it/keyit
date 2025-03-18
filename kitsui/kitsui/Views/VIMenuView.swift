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

	@Binding var isVIMenuShowing: Bool
	var vItem: VItem

	var body: some View {
		List {
			Section(vItem.curPoMenu!.menuTitle,
				content: {
				ForEach(vItem.curPoMenu!.VIMenuItems) { VIMItem in
					VIMenuItemView(VIMItem: VIMItem, isVIMenuShowing: $isVIMenuShowing).environmentObject(bibMod)
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

// The menuTitle is calculated in VIMenu.swift where it is included in calculation of menu width
//	func calcMenuTitle() -> String {
//		let bibItem = getChapInst().BibItems[getChapInst().currItOfst]
//		return "Action for " + bibItem.getItemTypText() + "?"
//	}
}
/*
#Preview {
	VIMenuView(isVIMenuShowing: .constant(true))
}
*/
