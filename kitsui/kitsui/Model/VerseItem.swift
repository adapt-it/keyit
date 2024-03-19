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

	
}
