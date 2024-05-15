//
//  Chapter.swift
//
//	There will be one instance of the class Chapter and it will be for the current Chapter
//	that the user has selected for keyboarding. When the user switches to keyboarding
//	a different Chapter, the current instance of Chapter will be deleted and a new instance
//	created for the newly selected Chapter.
//
// The Chapter records in the database store the ID of the current VerseItem for each Chapter
// because there are over 31,000 VerseItems and so verse numbers are not enough, and updating
// a VerseItem record in the database is more efficiently done if the record is identified by
// just its ID rather than by a combination of Book, Chapter, and VerseItem.
// On the other hand, the user interface needs only the VerseItems for the current Chapter and,
// in addition, the user interface functions on both Android and iOS expect data to be supplied
// from the array BibItems[] whose index matches the indexes to the cells of the
// RecyclerView (on Android) or rows of the TableView (on iOS).
//
//	GDLC 23JUL21 Cleaned out some print commands (were used in early stages of development)
//	GDLC 1JUL21 Added currVN for verse number associated with the currIt
//
//  Created by Graeme Costin on 8/1/20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import Foundation
import SwiftUI

public class Chapter: NSObject, ObservableObject {

// Properties of a Chapter instance (dummy values to avoid having optional variables)
	var chID: Int = 0		// chapterID INTEGER PRIMARY KEY
	var bibID: Int = 0		// bibleID INTEGER
	var bkID: Int = 0		// bookID INTEGER,
	var chNum: Int = 0		// chapterNumber INTEGER
	var itRCr: Bool = false	// itemRecsCreated INTEGER
	var numVs: Int = 0		// numVerses INTEGER
	var numIt: Int = 0		// numItems INTEGER
	var currIt: Int = 0		// currItem INTEGER (the ID assigned by SQLite when the VerseItem was created)
	var currVN: Int = 0		// currVsNum INTEGER (the Verse number associated with the current VerseItem)

	var currItOfst: Int = -1
// GDLC 20APR24 A curPoMenu is created only when the user taps a button in the EditChapterView that
// needs a popover menu. This means that the setter function for currItOfst that is part of
// kitios and kitand is no longer needed.
// This makes currItOfst a simple property with default setter.
	
	weak var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	weak var bibInst: Bible? 	// access to the instance of Bible for updating BibBooks[]
	weak var bkInst: Book?		// access to the instance for the current Book

// BibItems is an array of instances of the class VItem that are used for letting
// the user edit VerseItems in the current Chapter of the current Book.

	@Published var BibItems: [VItem] = []

	// Properties of the Chapter instance needed to create popover menus
	var hasAscription = false	// true if the Psalm has an Ascription
	var hasTitle = false		// true if Chapter 1 has a Book Title
	var hasInTitle = false		// true if Chapter 1 has an introductory matter Title
	var nextIntSeq = 1			// next value to be used for an IntSeq field. Starts at 1 because
								// InTitle is in effect IntSeq = 0

// When the instance of current Book creates the instance for the current Chapter it supplies the values
// for the currently selected Chapter from the BibChaps array
		
	init(_ parent: Book, _ chID: Int, _ bibID: Int, _ bkID: Int, _ chNum: Int, _ itRCr: Bool, _ numVs:Int, _ numIt: Int, _ currIt: Int, _ currVN: Int) {
		super.init()

		self.bkInst = parent	// access to current Book
		self.chID = chID		// chapterID INTEGER PRIMARY KEY
		self.bibID = bibID		// bibleID INTEGER
		self.bkID = bkID		// bookID INTEGER,
		self.chNum = chNum		// chapterNumber INTEGER
		self.itRCr = itRCr		// itemRecsCreated INTEGER
		self.numVs = numVs		// numVerses INTEGER
		self.numIt = numIt		// numItems INTEGER
		self.currIt = currIt	// currItem INTEGER (ID of the current VerseItem)
		self.currVN = currVN	// currVsNum INTEGER (Verse number for the current VerseItem)

		self.dao = bkInst!.dao			// access to the KITDAO instance for using kdb.sqlite
		self.bibInst = bkInst!.bibInst 	// access to the instance of Bible for updating BibBooks[]
		
		// First time this Chapter has been selected the Item records must be created
		if !itRCr {
			createItemRecords()
		}

		// Every time this Chapter is selected: The VerseItems records in kdb.sqlite will have been
		// created at this point (either during this occasion or on a previous occasion),
		// so we set up the array BibItems of VerseItems by reading the records from kdb.sqlite.
		//
		// This array will last while this Chapter is the currently selected Chapter and will
		// be used whenever the user is allowed to select a VerseItem for editing;
		// it will also be updated when VerseItem records for this Chapter are created,
		// and when the user chooses a different VerseItem to edit.
		// Its life will end when the user chooses a different Chapter or Book to edit.
		
		// Calls readVerseItemsRecs() in KITDAO.swift to read the kdb.sqlite database VerseItems table.
		// readVerseItemsRecs() calls appendItemToArray() in this file for each ROW read from kdb.sqlite
		// and appends an instance of class VItem for each ROW read.
		dao!.readVerseItemsRecs (self)

		// Ensure that numIt is correct (to guard against any accumulated data errors)
		self.numIt = BibItems.count
		dao!.chaptersUpdateRecPub (chID, self.numIt, self.currIt, self.currVN)
		
		// Setup for editing VerseItems in Chapter
		currItOfst = goCurrentItem()
	}

// Create a VerseItem record in kdb.sqlite for each VerseItem in this Chapter
// If this is a Psalm and it has an ascription then numIt will be 1 greater than numVs.
// For all other VerseItems numIt will equal numVs at this early stage of building the app's data

	func createItemRecords() {
		// If there is a Psalm ascription then create it first.
		if numIt > numVs {
			let vsNum = 1
			let itTyp = "Ascription"
			let itOrd = 70	// 100 * VerseNumber - 30
			let itText = ""
			let intSeq = 0
			let isBrid = false
			let lastVsBridge = 0
			_ = dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lastVsBridge)
		}
		for vsNum in 1...numVs {
			let itTyp = "Verse"
			let itOrd = 100*vsNum
			let itText = ""
			let intSeq = 0
			let isBrid = false
			let lastVsBridge = 0
				_ = dao!.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lastVsBridge)
		}
		// Update in-memory record of current Chapter to indicate that its VerseItem records have been created
		itRCr = true
		// Also update the BibChap struct to show itRCr true
		bkInst!.BibChaps[chNum - 1].itRCr = true
		// Update Chapter record to show that VerseItems have been created
		dao!.chaptersUpdateRec (chID, itRCr, currIt, currVN)
	}
	
	// dao.readVerseItemRecs() calls appendItemToArray() for each row it reads from the kdb.sqlite database
	// in order to append the records read to the array BibItems[]
	// appendItemToArray() also finds the largest value of intSeq in the VerseItem records read
	// and sets nextIntSeq to one more than the largest one found.

	func appendItemToArray(_ itID:Int, _ chID:Int, _ vsNum:Int, _ itTyp:String, _ itOrd:Int, _ itTxt:String, _ intSeq:Int, _ isBrg:Bool, _ lvBrg:Int) {
		let itRec = VItem(owner: self, itID: itID, chID: chID, vsNum: vsNum, itTyp: itTyp, itOrd: itOrd, itTxt: itTxt, intSeq: intSeq, isBrg: isBrg, lvBrg: lvBrg)
		BibItems.append(itRec)
		if itTyp == "Ascription" {hasAscription = true}
		if itTyp == "Title" {hasTitle = true}
		if itTyp == "InTitle" {hasInTitle = true}
		// Set nextIntSeq to 1 more than the largest intSeq found in the existing VerseItem records
		// remembering that the VerseItem records will be read in ascending order of intSeq, but there
		// may be missing values because of records that were created but later deleted.
		if intSeq > 0 {
			if intSeq >= nextIntSeq {
				nextIntSeq = 1 + intSeq
			}
		}
	}

// Find the offset in BibItems[] to the element having VerseItemID withID
// If out of range returns offset zero (first item in the array)

	func offsetToBibItem(withID:Int) -> Int {
		for i in 0...numIt-1 {
			if BibItems[i].itID == withID {
				return i
			}
		}
		return 0
	}

	// Return the BibItem at an index
	
	func getBibItem(at index:Int) -> VItem {
		return BibItems[index]
	}
	
// Go to the current BibItem
// This function is called by the VersesTableViewController to find out which VerseItem
// in the current Chapter is the current VerseItem, and to make the Chapter record
// remember that selection.
//
// Returns the current Item offset in BibItems[] array to the VersesTableViewController
// because this equals the row number in the TableView.

	func goCurrentItem() -> Int {
		if currIt == 0 {
			// If SQLite does not have a current VerseItem,
			// make the first VerseItem the current one
			currItOfst = 0		// Take first item in BibItems[] array
			currIt = BibItems[currItOfst].itID	// Get its itemID
			//GDLC 31JUL21 Added setting of currVN
			currVN = BibItems[currItOfst].vsNum	// Get its verse number
		} else {
			// Already have the itemID of the current item so need to get
			// the offset into the BibItems[] array
			currItOfst = offsetToBibItem(withID: currIt)
			//GDLC 31JUL21 Added setting of currVN
			currVN = BibItems[currItOfst].vsNum	// Get its verse number
		}
		// Set the VItem so that it is displayed as the current item
		BibItems[currItOfst].isCurVsItem = true
		// Update the database Chapter record
		dao!.chaptersUpdateRec (chID, itRCr, currIt, currVN)
		return currItOfst
	}

	// Copy the current VerseItem's text BibItems[]
	func copyCurrentVItemText(_ text: String) {
		BibItems[currItOfst].itTxt = text
	}

	// Copy and save the text of the VerseItem whose ID is itID
	func copyAndSaveVItem(_ itID: Int, _ text: String) {
		let itOfst = offsetToBibItem(withID: itID)
		BibItems[itOfst].itTxt = text
		dao!.itemsUpdateRecText (BibItems[itOfst].itID, BibItems[itOfst].itTxt)
	}

	// Function to make the VItem the current VItem
	func makeVItemCurrent(_ vItem: VItem) {
		// The current VItem ceases to be the current one
		BibItems[currItOfst].isCurVsItem = false
		// Now set the new current VItem
		currItOfst = offsetToBibItem(withID: vItem.itID)
		BibItems[currItOfst].isCurVsItem = true
		currIt = vItem.itID
		currVN = vItem.vsNum
		// Update the database Chapter record
		dao!.chaptersUpdateRec (chID, itRCr, currIt, currVN)
	}

	// DESIGN FLAW ALERT!!!!
	// This function as originally written for kitios and kitand does TWO jobs:-
	// 1. It sets the current VerseItem in the Chapter
	// 2. It creates the VIMenu for the VerseItem
	// Combining these two jobs worked OK in kitios and kitand, but created major
	// headaches with communication between Views in kitsui. A better design for kitsui
	// is to separate these functions and have the VIMenu owned by the VerseItem, not
	// the Chapter. TODO: see if this works out in practice!
	// Function to create a VIMenu when the user taps the Button in VerseItemView
/*	func createVIMenu(_ vItem: VItem) {
		let newOfst = offsetToBibItem(withID: vItem.itID)
		if (curPoMenu == nil) {
			// Now set the new current VItem and create the first VIMenu
			currItOfst = newOfst
			currIt = vItem.itID
			currVN = vItem.vsNum
		} else if (newOfst != currItOfst) /*|| (BibItems[currItOfst].itID != currIt))*/ {
			// Delete previous popover menu
			curPoMenu = nil
			// The current VItem ceases to be the current one
			BibItems[currItOfst].isCurVsItem = false
			// Now set the new current VItem and create the menu
			currItOfst = newOfst
			currIt = vItem.itID
			currVN = vItem.vsNum
		}
		BibItems[currItOfst].isCurVsItem = true
		curPoMenu = VIMenu(self, currItOfst)
		// Update the database Chapter record
		dao!.chaptersUpdateRec (chID, itRCr, currIt, currVN)
	}*/

	// Function to carry out on the data model the actions required for the popover menu items
	// All of the possible actions change the BibItems[] array so, after carrying out the
	// specific action, this function clears BibItems[] and reloads it from the database;
	// following this the VersesTableViewController needs to reload the TableView.
	func popMenuAction(_ act: String) {
		switch act {
		case "crAsc":
			createAscription()
		case "delAsc":
			deleteAscription()
		case "crTitle":
			createTitle()
		case "delTitle":
			deleteTitle()
		case "crParaBef":
			createParagraphBefore()
		case "delPara":
			deleteParagraphBefore()
		case "crParaCont":
			createParagraphCont()
		case "delPCon":
			deleteParagraphCont()
		case "delVCon":
			deleteVerseCont()
		case "crHdBef":
			createSubjHeading()
		case "crHdAft":
			createSubjHeading()
		case "delHead":
			deleteSubjHeading()
		case "crPalRef":
			createParallelRef()
		case "delPalRef":
			deleteParallelRef()
		case "brid":
			bridgeNextVerse()
		case "unBrid":
			unbridgeLastVerse()
		case "crInTit":
			createIntroTitle()
		case "delInTit":
			deleteIntroTitle()
		case "crInHed":
			createIntroHeading()
		case "delInHed":
			deleteIntroHeading()
		case "crInPar":
			createIntroPara()
		case "delInPar":
			deleteIntroPara()
		default:
			print("BUG! Unknown action code")
		}

		// GDLC 20APR24 The setter for currItOfst was removed in KITSUI because the necessary VIMenu is
		// created when the user taps the button to get that VerseItem's actions, so the 5 lines of
		// commentary below are obsolete.
		// GDLC 12JAN21 BUG10 The logic in the setter for currItOfst works for moving from one VerseItem
		// to another but it fails in some situations where a new VerseItem is created or deleted
		// (on creation because the new VerseItem may have the same offset as the one whose menu action
		// was used). So destroying the current popover menu once an action from it has been used
		// ensures that a new popover menu will be created.
		//
		// Dismiss the popover menu that gave this command
		// but how???
		// Clear the current BibItems[] array
		BibItems.removeAll()
		// Reload the BibItems[] array of VerseItems
		dao!.readVerseItemsRecs (self)
	}

	// Can be called when the current VerseItem is Verse 1 of a Psalm
	func createAscription () {
		// GDLC 4MAY21 Corrected 70 to 75 in creation of the ascription record
		// This function is only called when currVN == 1
			let newitemID = dao!.verseItemsInsertRec (chID, currVN, "Ascription", 75, "", 0, false, 0)
			// Note that the Psalm now has an Ascription
			hasAscription = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new Ascription the current VerseItem
			currIt = newitemID
			// Update the database Chapter record so that the new Ascription item becomes the current item
			dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Can be called when the current VerseItem is an Ascription
	func deleteAscription () {
		// This function is called only when currVN == 1
		dao!.itemsDeleteRec(currIt)
		// Note that the Psalm no longer has an Ascription
		hasAscription = false
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
	}

	// Create Book title
	func createTitle() {
			let newitemID = dao!.verseItemsInsertRec (chID, currVN, "Title", 70, "", 0, false, 0)
			// Note that the Book now has a Title
			hasTitle = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new Title the current VerseItem
			currIt = newitemID
			// Update the database Chapter record so that the new Title item becomes the current item
			dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Can be called when the current VerseItem is a Title
	func deleteTitle () {
		dao!.itemsDeleteRec(currIt)
		// Note that the Psalm no longer has a Title
		hasTitle = false
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
	}

	// Create a paragraph break before a verse.
	func createParagraphBefore () {
		_ = dao!.verseItemsInsertRec (chID, currVN, "Para", currVN * 100 - 10, "", 0, false, 0)
		// Increment number of items
		numIt = numIt + 1
		// Leave the Verse as the current VerseItem (there is nothing to keyboard in the Para record)
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
	}

	// Can be called when the current VerseItem is a Para
	func deleteParagraphBefore () {
		let vsNum = BibItems[currItOfst].vsNum
		dao!.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}

	// Create a paragraph break inside a verse
	func createParagraphCont() {
/*
 		let result = appDelegate.VTVCtrl!.currTextSplit()
		let txtBef = result.txtBef
		let txtAft = result.txtAft
		// Remove text after cursor from Verse
		do {
			try dao!.itemsUpdateRecText(BibItems[currItOfst].itID, txtBef)
		} catch {
			appDelegate.ReportError(DBU_VItTxtErr)
		}
		// Create the ParaCont record
		do {
			_ = try dao!.verseItemsInsertRec (chID, currVN, "ParaCont", currVN * 100 + 10, "", 0, false, 0)
			// Increment number of items
			numIt = numIt + 1
		} catch {
			appDelegate.ReportError(DBC_VItPInErr)
		}
		// Create the VerseCont record and insert the txtAft from the original Verse
		do {
			let newVCont = try dao!.verseItemsInsertRec (chID, currVN, "VerseCont", currVN * 100 + 20, txtAft, 0, false, 0)
			// Increment number of items
			numIt = numIt + 1
			// Update currIt and the database Chapter record so that the new VerseCont becomes the current item
			currIt = newVCont
			do {
				try dao!.chaptersUpdateRecPub (chID, numIt, newVCont, currVN)
			} catch {
				appDelegate.ReportError(DBU_ChaPubErr)
			}
		} catch {
			appDelegate.ReportError(DBC_VItVcoErr)
		}*/
	}

	func deleteParagraphCont() {
		let prevItem = BibItems[currItOfst - 1]
		let nextItem = BibItems[currItOfst + 1]
		let prevItID = prevItem.itID
		let vsNum = BibItems[currItOfst].vsNum
		// Delete ParaCont record
		dao!.itemsDeleteRec(currIt)
			numIt = numIt - 1
			// Append continuation text to original Verse
			let txtBef = prevItem.itTxt
			let txtAft = nextItem.itTxt
			dao!.itemsUpdateRecText(prevItem.itID, txtBef + txtAft)
			// Delete VerseCont record
			dao!.itemsDeleteRec(nextItem.itID)
			numIt = numIt - 1
			// Update currIt and the database Chapter record so that the original VerseItem becomes the current item
			currIt = prevItID
			dao!.chaptersUpdateRecPub (chID, numIt, prevItID, vsNum)
	}

	func deleteVerseCont() {
		let prevItem = BibItems[currItOfst - 2]	// step back over the ParaCont to the previous Verse
		let contItem = BibItems[currItOfst]	// get the continuation of the Verse
		let prevVersID = prevItem.itID
		let txtBef = prevItem.itTxt
		let txtAft = contItem.itTxt
		let vsNum = BibItems[currItOfst].vsNum
		// Append continuation text to original Verse
		dao!.itemsUpdateRecText(prevItem.itID, txtBef + txtAft)
		// Delete VerseCont record
		dao!.itemsDeleteRec(currIt)
		numIt = numIt - 1
		// Delete ParaCont record
		let paraContItem = BibItems[currItOfst - 1]
		dao!.itemsDeleteRec(paraContItem.itID)

		numIt = numIt - 1
		// Update currIt and the database Chapter record so that the original VerseItem becomes the current item
		currIt = prevVersID
		dao!.chaptersUpdateRecPub (chID, numIt, prevVersID, vsNum)
	}

	func createSubjHeading() {
		let newitemID = dao!.verseItemsInsertRec (chID, currVN, "Heading", currVN * 100 - 20, "", 0, false, 0)
		// Increment number of items
		numIt = numIt + 1
		// Make the new Subject Heading the current VerseItem
		currIt = newitemID
		// Update the database Chapter record so that the new Subject Heading item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Can be called when the current VerseItem is a Subject Heading
	func deleteSubjHeading () {
		let vsNum = BibItems[currItOfst].vsNum
		dao!.itemsDeleteRec(currIt)
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}

	// Creates a Parallel Ref before a Verse or after a Title
	func createParallelRef() {
		let newitemID = dao!.verseItemsInsertRec (chID, currVN, "ParlRef", currVN * 100 - 15, "", 0, false, 0)
		// Increment number of items
		numIt = numIt + 1
		// Make the new Parallel Ref the current VerseItem
		currIt = newitemID
		// Update the database Chapter record so that the new Parallel Ref item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Can be called when the current VerseItem is a Parallel Ref
	func deleteParallelRef () {
		let vsNum = BibItems[currItOfst].vsNum
		dao!.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}

	// This function uses the current values in BibItems[] but makes changes in
	// the database via KITDAO. After the database changes have been made,
	//  BibItems[] will be refreshed from KITDAO.
	func bridgeNextVerse() {
//		let vsNum = BibItems[currItOfst].vsNum
		// Get the vsNum and itTxt from the verse to be added to the bridge
		let nexVsNum = BibItems[currItOfst + 1].vsNum
		let nexVsTxt = BibItems[currItOfst + 1].itTxt
		// Delete the verse record being added to the bridge
		dao!.itemsDeleteRec(BibItems[currItOfst + 1].itID)
		numIt = numIt - 1
		// Create related BridgeItems record
//		let curVsItID = BibItems[currItOfst].itID
		let curVsTxt = BibItems[currItOfst].itTxt
		_ = dao!.bridgeInsertRec(currIt, curVsTxt, nexVsTxt)
		// Copy text of next verse into the bridge head verse
		let newBridHdTxt = curVsTxt + " " + nexVsTxt
		dao!.itemsUpdateForBridge(currIt, newBridHdTxt, true, nexVsNum)
		// Update the database Chapter record so that the bridge head VerseItem remains the current item
		// and the number of items is updated
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
	}

	struct BridItem {
		var BridgeID: Int			// ID of the BridgeItems record
		var textCurrBridge: String	// text of current Verse or bridge
		var textExtraVerse: String	// text of extra verse added to bridge

		init (_ BridgeID:Int, _ textCurrBridge:String, _ textExtraVerse:String) {
			self.BridgeID = BridgeID
			self.textCurrBridge = textCurrBridge
			self.textExtraVerse = textExtraVerse
		}
	}
	
	var BridItems: [BridItem] = []

	// dao.bridgeGetRecs() calls appendItemToBridArray() for each row it reads from
	// the BridgeItems table in the kdb.sqlite database

	func appendItemToBridArray(_ BridgeID:Int, _ textCurrBridge:String, _ textExtraVerse:String) {
			let bridRec = BridItem(BridgeID, textCurrBridge, textExtraVerse)
			BridItems.append(bridRec)
		}

	// This function uses the current values in BibItems[] but makes changes in
	// the database via KITDAO. After the database changes have been made,
	//  BibItems[] will be refreshed from KITDAO.
	func unbridgeLastVerse() {
//		let vsNum = BibItems[currItOfst].vsNum
		// Clear the BridItems[] array
		BridItems.removeAll()
		// Get the most recent BridgeItems record for this verse
		dao!.bridgeGetRecs(BibItems[currItOfst].itID, self)
		// The most recent BridgeItem will be the last in the list
		let curBridItem = BridItems.last
		// Create the verse record being removed from the bridge
		let nextVsNum = BibItems[currItOfst].lvBrg
			_ = dao!.verseItemsInsertRec (chID, nextVsNum, "Verse", 100 * nextVsNum, curBridItem!.textExtraVerse, 0, false, 0)
		numIt = numIt + 1
		// Copy text of the previous bridge head into the new bridge head
		var isBrid: Bool
		var lastVsBr = BibItems[currItOfst].lvBrg - 1
		if lastVsBr == BibItems[currItOfst].vsNum {
			// The head of the bridge will become a normal verse
			isBrid = false; lastVsBr = 0
		} else {
			// The head of the bridge will still be a bridge head
			isBrid = true
		}
		dao!.itemsUpdateForBridge(BibItems[currItOfst].itID, curBridItem!.textCurrBridge, isBrid, lastVsBr)
		// Delete this BridgeItems record
		dao!.bridgeDeleteRec(curBridItem!.BridgeID)
		// Update the database Chapter record so that the bridge head VerseItem remains the current item
		// and the number of items is updated
		dao!.chaptersUpdateRecPub (chID, numIt, BibItems[currItOfst].itID, currVN)
	}

	// Publication items involved in Introductory Matter
	
	// Create Introductory Matter Title
	func createIntroTitle() {
		// This function will be called only when currVN == 1
		let newitemID = dao!.verseItemsInsertRec (chID, currVN, "InTitle", 10, "", 0, false, 0)
		// Note that the Book now has an InTitle
		hasInTitle = true
		// Increment number of items
		numIt = numIt + 1
		// Make the new InTitle the current VerseItem
		currIt = newitemID
		// Update the database Chapter record so that the new Title item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Delete Introductory Matter Title
	func deleteIntroTitle() {
		let vsNum = 1
		dao!.itemsDeleteRec(currIt)
		// Note that the Book no longer has an InTitle
		hasInTitle = false
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}

	// Create Introductory Matter Heading
	func createIntroHeading() {
		// This function will be called only when currVN == 1
		let newitemID = dao!.verseItemsInsertRec (chID, currVN, "InSubj", 10 + nextIntSeq, "", nextIntSeq, false, 0)
		nextIntSeq = nextIntSeq + 1
		// Increment number of items
		numIt = numIt + 1
		// Make the new InSubj the current VerseItem
		currIt = newitemID
		// Update the database Chapter record so that the new Title item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Delete Introductory Matter Heading
	func deleteIntroHeading() {
		let vsNum = 1
		dao!.itemsDeleteRec(currIt)
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}

	// Create Introductory Matter Paragraph
	func createIntroPara() {
		// This function will be called only when currVN == 1
		let newitemID = dao!.verseItemsInsertRec (chID, currVN, "InPara", 10 + nextIntSeq, "", nextIntSeq, false, 0)
		nextIntSeq = nextIntSeq + 1
		// Increment number of items
		numIt = numIt + 1
		// Make the new InSubj the current VerseItem
		currIt = newitemID
		// Update the database Chapter record so that the new Title item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, newitemID, currVN)
	}

	// Delete Introductory Matter Paragraph
	func deleteIntroPara() {
		let vsNum = 1
		dao!.itemsDeleteRec(currIt)
		// Decrement number of items
		numIt = numIt - 1
		// Make the next VerseItem the current one
		currIt = BibItems[currItOfst + 1].itID
		// Update the database Chapter record so that the following item becomes the current item
		dao!.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
	}
	
	// Generate USFM export string for this Chapter
	func calcUSFMExportText() -> String {
		var USFM = "\\id " + bkInst!.bkCode + " " + bibInst!.bibleName + "\n\\c " + String(chNum)
			for item in BibItems {
			var s: String
			var vn: String
			let tx: String = item.itTxt
			switch item.itTyp {
			case "Verse":
				if item.isBrg {
					vn = String(item.vsNum) + "-" + String(item.lvBrg)
				} else {
					vn = String(item.vsNum)
				}
				s = "\n\\v " + vn + " " + tx
			case "VerseCont":		// Continuation of a verse that contains a paragraph break
				s = "\n" + tx
			case "Para", "ParaCont":	// Paragraph before or within a verse
				s = "\n\\p"
			case "Heading":			// Heading/Subject Heading
				s = "\n\\s " + tx
			case "ParlRef":			// Parallel Reference
				s = "\n\\r " + tx
			case "Title":			// Title for a Book
				s = "\n\\mt " + tx
			case "InTitle":			// Title within Book introductory matter
				s = "\n\\imt " + tx
			case "InSubj":			// Subject heading within Book introductory matter
				s = "\n\\ims " + tx
			case "InPara":			// Paragraph within Book introductory matter
				s = "\n\\ip " + tx
			case "Ascription":		// Ascriptions before verse 1 of some Psalms
				s = "\n\\d " + tx
			default:
				s = ""
			}
			USFM = USFM + s
		}
		return USFM
	}

	func saveUSFMText (_ chID:Int, _ text:String) {
		dao!.updateUSFMText (chID, text)
	}
}
