//
//  VerseItem.swift
//  kitsui
//
//  Created by Graeme Costin on 16/2/2024.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import Foundation
import SwiftUI

public class VItem: ObservableObject, Identifiable, Hashable {

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.id)
	}
	
	public static func == (lhs: VItem, rhs: VItem) -> Bool {
		lhs.id == rhs.id
	}
	
	
	// Properties of a VerseItem
	var itID: Int			// itemID INTEGER PRIMARY KEY
	var chID: Int			// chapterID INTEGER
	var vsNum: Int			// verseNumber INTEGER
	var itTyp: String		// itemType TEXT
	var itOrd: Int			// itemOrder INTEGER
	var itTxt: String		// itemText TEXT
	var intSeq: Int			// intSeq INTEGER
	var isBrg: Bool			// isBridge INTEGER
	var lvBrg: Int			// last verse of bridge
	var isCurVsItem: Bool	// true if the instance is the one currently selected in the UI
	public var id = UUID()
// Beginnings of making VerseItem own its VIMenu
//	var curPoMenu: VIMenu?	// instance in memory of the popover menu for this VerseItem

	init(itID: Int, chID: Int, vsNum: Int, itTyp: String, itOrd: Int, itTxt: String, intSeq: Int, isBrg: Bool, lvBrg: Int, isCurVsItem: Bool = false) {
		self.itID = itID
		self.chID = chID
		self.vsNum = vsNum
		self.itTyp = itTyp
		self.itOrd = itOrd
		self.itTxt = itTxt
		self.intSeq = intSeq
		self.isBrg = isBrg
		self.lvBrg = lvBrg
		self.isCurVsItem = isCurVsItem
	}

	func getItemTypText() -> String {
		var typeText = ""
		switch self.itTyp {
		case "Title": typeText = "Main Title"
		case "Para", "ParaCont": typeText = "Paragraph"
		case "ParlRef": typeText = "Parallel Ref"
		case "VerseCont": typeText = "Verse" + String(self.vsNum) + " (cont)"
		case "Verse":
			if self.isBrg {
				typeText = "Verses " + String(self.vsNum) + "-" + String(self.lvBrg)
			} else {
				typeText = "Verse " + String(self.vsNum)
			}
		case "InTitle": typeText = "Intro Title"
		case "InSubj": typeText = "Intro Heading"
		case "InPara": typeText = "Intro Paragraph"
		default: typeText = self.itTyp
		}
		return typeText
	}

/*	// Function to create a VIMenu when the user taps the Button in VerseItemView
	func createVIMenu() {
//		let newOfst = offsetToBibItem(withID: vItem.itID)
//		if (curPoMenu == nil) {
//			// Now set the new current VItem and create the first VIMenu
//			currItOfst = newOfst
//			currIt = vItem.itID
//			currVN = vItem.vsNum
//		} else if (newOfst != currItOfst) /*|| (BibItems[currItOfst].itID != currIt))*/ {
		// Delete previous popover menu
		curPoMenu = nil
//			// The current VItem ceases to be the current one
//			BibItems[currItOfst].isCurVsItem = false
//			// Now set the new current VItem and create the menu
//			currItOfst = newOfst
//			currIt = vItem.itID
//			currVN = vItem.vsNum
//		}
//		BibItems[currItOfst].isCurVsItem = true
		curPoMenu = VIMenu(self, currItOfst)
//		// Update the database Chapter record
//		dao!.chaptersUpdateRec (chID, itRCr, currIt, currVN)
	}*/

}
