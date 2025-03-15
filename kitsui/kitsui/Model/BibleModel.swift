//
//  BibleModel.swift
//  kitsui
//
//	The BibleModel class handles the data model for KIT.
//	Other classes involved are Bible, Book, and Chapter.
//	Swift structs are used for BibItem (Verse Items) and BridItem (bridging of verses).
//	The SwiftUI Views communicate with the data model via the single instance of BibleModel;
//	KITDAO is called only by the BibleModel and its classes, not by SwiftUI Views.
//
//	The BibleModel class instantiates KITDAO (named from the phrase KIT Data Access Object)
//	during its instantiation, and uses this instance of KITDAO for all interaction with the
//	SQLite database. The rest of the app deals only with the data model.
//
//	BibleModel has array bibArray[] of instances of class Bible
//	Bible has array BibBooks[] of instances of struct BibBooks, used for choosing Book
//	Book has array BibChaps[] of instances of struct BibChap, used for choosing Chapter
//	Chapter has array BibItems[] of instances of struct BibItem, used for editing BibItems
//
//	Created by Graeme Costin on 15/11/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
// 	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import Foundation
import SwiftUI

class BibleModel: ObservableObject {
	let dao = KITDAO()
	@Published var numBibles: Int = 0
	@Published var bibArray = [Bible]()
	// Offset to the current Bible. Views and functions mostly deal with the current Bible
    @Published var curBibOfst = 0
	@Published var needSetup = false	// If a default Bible is created SetupView must be used
										// Assume no need for SetupView

	// Because SwiftUI runtime scans through possible future Views before the Views are actually created,
	// and because ChooseChapterView needs its parent Book instance (as part of facilitiating View updates),
	// and because EditChapterView needs it parent Chapter instance (as part of facilitating updates),
	// we need a way of providing default values for Book instance and Chapter instance to SwiftUI before
	// a Book or a Chapter has been chosen.
	// defBkInst and defChInst are created at the end of the init() of BibleModel.
	var defBkInst: Book? = nil
	var defChInst: Chapter? = nil
	
    init () {
		// Populate bibArray[] from any Bible records in the database
		// If there are no Bible records in the database, create the default one
		var nBib = 0
		var bID = 1
		var lastBib = false
		while (lastBib == false) {
			let BR = dao.bibleGetRec (bID)
			if BR.bibID > 0 {
				bibArray.append( Bible(bibleID: BR.bibID, bibleName: BR.bibName, bkRecsCr: BR.bkRCr, currBk: BR.currBk, bibMod: self) )
				nBib = nBib + 1
				bID = bID + 1
			} else {
				lastBib = true
			}
		}
		if nBib == 0 {
			// Create a Bible database record
			dao.bibleInsertRec (1, "Bible", false, 0)
			bibArray.append( Bible(bibleID: 1, bibleName: "Bible", bkRecsCr: false, currBk: 0, bibMod: self) )
			nBib = 1
			needSetup = true	// Need SetupView because default Bible created
		}
		numBibles = nBib
		setCurBibOfst(0)
		// 20FEB25 decided this setting of needSetup is not needed
//		// 19FEB25 If currBk is zero, ensure SetupView is shown
//		if bibArray[curBibOfst].currBk == 0 {
//			needSetup = true
//		}
		defBkInst = Book(getCurBibInst(), self)
		defChInst = Chapter(defBkInst!)
    }

// Functions for current Bible - called by SwiftUI Views and other parts of the data model
// to get/set data in the data model.
	
	func getCurBibOfst() -> Int {
		return curBibOfst
	}

	// Make the Bible at bibArray[ofst] the current Bible
	func setCurBibOfst(_ ofst:Int) {
		curBibOfst = ofst
		// Load the 66 Bible books, creating the database records if they have not yet been created
		bibArray[ofst].loadBibBooks(bibArray[ofst].bibleID)
	}
	
	func getCurBibInst() -> Bible {
		return bibArray[curBibOfst]
	}

	// Need to provide a default Book instance when no Book has been selected because
	// ChooseBookView passes bkInst to ChooseChapterView
	func getDefaultBookInst() -> Book {
		return defBkInst!
	}

	// Need to provide a default Chapter instance when no Chapter has been selected because
	// ChooseChapterView passes chInst to EditChapterView
	func getDefaultChapterInst() -> Chapter {
		return defChInst!
	}

	func getCurBibName() -> String {
		return bibArray[curBibOfst].bibleName
	}

	func getCurBookName() -> String {
		if let curBkName = bibArray[curBibOfst].bookInst?.bkName {
			return curBkName
		} else {
			return "ERR: Book not chosen"
		}
	}
	
	// Updates the name of the current Bible in both the bibArray[] and the database
	func bibleUpdateName(_ editedName: String) {
		let curBibOff = getCurBibOfst()
		// Update in-memory array
		bibArray[curBibOff].bibleName = editedName
		// Update database
		dao.bibleUpdateName(bibArray[curBibOff].bibleID, editedName)
	}
}
