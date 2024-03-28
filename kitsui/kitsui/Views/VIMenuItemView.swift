//
//  VIMenuItemView.swift
//  kitsui
//
//  Created by Graeme Costin on 28/3/2024.
//

import SwiftUI

struct VIMenuItemView: View {
	@EnvironmentObject var bibMod: BibleModel
	var VIMItem: VIMenuItem

	init(VIMItem:VIMenuItem) {
		self.VIMItem = VIMItem
	}

	var body: some View {
		HStack {
			Image(uiImage: getIcon())
				.resizable()
				.frame(width: 15.0, height: 15.0)
			Text(VIMItem.VIMenuLabel)
			Spacer()
		}
    }

	func getIcon() -> UIImage {
		switch VIMItem.VIMenuIcon {
		case "C": return UIImage(named: "CreatePubItem.png")!
		case "D": return UIImage(named: "DeletePubItem.png")!
		case "B": return UIImage(named: "BridgePubItem.png")!
		case "U": return UIImage(named: "UnbridgePubItem.png")!
		default:  return UIImage(named: "CreatePubItem.png")!
		}
	}
}

#Preview {
	Group {
		VIMenuItemView(VIMItem: VIMenuItem("Ascription", "delAsc", "D"))
		VIMenuItemView(VIMItem: VIMenuItem("Heading Before", "crHdBef", "C"))
		VIMenuItemView(VIMItem: VIMenuItem("Bridge Next", "brid", "B"))
		VIMenuItemView(VIMItem: VIMenuItem("Unbridge", "unBrid", "U"))
	}
}
