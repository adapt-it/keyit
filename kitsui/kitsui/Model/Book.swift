//
//  Book.swift
//
// There will be one instance of this class for the currently selected Book.
// This instance will have a lifetime of the current book selection; its life
// will be terminated when the user selects a different Book to keyboard, at
// which time a new Book instance will be created for the newly selected Book.
// Data changes made by the user are always saved directly to the database as
// well as held in this instance for further use while the user continues to
// work on this Book.

//	GDLC 25NOV23 Starting to adjust to suit kitsui
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 1JUL21 Added currVsNum to Chapter records
//
//  Created by Graeme Costin on 25/10/19.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.


import Foundation
import SwiftUI

public class Book: NSObject, ObservableObject {

	weak var bibmod: BibleModel?
	weak var dao: KITDAO?		// access to the KITDAO instance for using kdb.sqlite
	weak var bibInst: Bible?		// access to the instance of Bible for updating BibBooks[]
									// Passed as a parameter to Book's init()

// Properties of a Book instance (dummy values to avoid having optional variables)
	var bkID: Int = 0			// bookID INTEGER
	var bibID: Int = 0			// bibleID INTEGER
	var bkCode: String = "BCD"	// bookCode TEXT
	var bkName: String = "Book"	// bookName TEXT
	var chapRCr: Bool = false	// chapRecsCreated INTEGER
	var numChap: Int = 0		// numChaps INTEGER
	var curChID: Int = 0		// currChID INTEGER (the ID assigned by SQLite when the Chapter was created)
	var curChNum: Int = 0		// currChNum INTEGER
	var currChapOfst: Int = -1	// offset to the current Chapter in BibChaps[] array (-1 means not yet set)
	
	@Published var needChooseChapter = false	// Assume no need for ChooseChapterView
	
	var chapInst: Chapter?	// instance in memory of the current Chapter
	var chapName: String?	// Name used for chapters (most books have "chapter", Psalms have "psalm")

// This struct and the BibChaps array are used for letting the user select the
// Chapter to keyboard in the current selected Book.
		
	struct BibChap: Identifiable, Hashable {
		var chID: Int		// chapterID INTEGER PRIMARY KEY
		var bibID: Int		// bibleID INTEGER
		var bkID: Int		// bookID INTEGER
		var chNum: Int		// chapterNumber INTEGER
		var itRCr: Bool		// itemRecsCreated INTEGER
		var numVs: Int		// numVerses INTEGER
		var numIt: Int		// numItems INTEGER
		var curIt: Int		// currItem INTEGER (ID of current VerseItem
		var curVN: Int		// currVsNum INTEGER (verse number for curIt)
		var selected: Bool
		var id = UUID()
		init (chID:Int, bibID:Int, bkID: Int, chNum: Int, itRCr: Bool,
			  numVs:Int, numIt:Int, curIt:Int, curVN:Int, selected:Bool = false) {
			self.chID = chID
			self.bibID = bibID
			self.bkID = bkID
			self.chNum = chNum
			self.itRCr = itRCr
			self.numVs = numVs
			self.numIt = numIt
			self.curIt = curIt
			self.curVN = curVN
			self.selected = selected
		}
	}

	@Published var BibChaps: [BibChap] = []

	// Initialise a default Book instance for use in creating ChooseBookView before
	// the user has selected any Book

	init(_ bInst: Bible, _ bibmod: BibleModel) {
        super.init()
        
        self.bibInst = bInst
        self.bkID = 41				// bookID INTEGER
        self.bibID = bInst.bibleID	// bibleID INTEGER
        self.bkCode = "MAT"			// bookCode TEXT
        self.bkName = "Matthew"		// bookName TEXT
        self.chapRCr = false        // chapRecsCreated INTEGER
        self.numChap = 28			// numChaps INTEGER
		self.curChID = 0			// currChID INTEGER
		self.curChNum = -1			// currChNum INTEGER
		self.bibmod = bibmod        // BibleModel
        self.chapName = "chapter"
    }

    // When the instance of Bible creates the instance for the current Book it supplies the
	// values for the currently selected book from the BibBooks array.
	// Initialisation of an instance of class Book with an array of Chapters to select from
	// But the array of Chapters cannot be produced until a current Book is chosen, so this
	// action needs to be avoided until after there is a current Book. Thus Book.init() must
	// not be called before a current Book is chosen or has been read from kdb.sqlite.

	init(_ bInst: Bible, _ bkID: Int, _ bibID: Int, _ bkCode: String, _ bkName: String, _ chapRCr: Bool, _ numChaps: Int, _ curChID: Int, _ curChNum:Int, _ bibmod: BibleModel) {
		super.init()
		
		self.bibInst = bInst
		self.bkID = bkID			// bookID INTEGER
		self.bibID = bibID			// bibleID INTEGER
		self.bkCode = bkCode		// bookCode TEXT
		self.bkName = bkName		// bookName TEXT
		self.chapRCr = chapRCr		// chapRecsCreated INTEGER
		self.numChap = numChaps		// numChaps INTEGER
		self.curChID = curChID		// currChID INTEGER
		self.curChNum = curChNum	// currChNum INTEGER
		self.bibmod = bibmod		// BibleModel
		if bkID == 19 {
			chapName = "psalm"
		} else {
			chapName = "chapter"
		}
		// Access to the KITDAO instance for dealing with kdb.sqlite
		dao = bibmod.dao
		// Access to the instance of Bible for dealing with BibInst[]
		bibInst = bibmod.getCurBibInst()

		// First time this Book has been selected the Chapter records must be created
		if !chapRCr {
			createChapterRecords(bkID, bibID, bkCode)
		}

		// Every time this Book is selected: The Chapters records in kdb.sqlite will have been
		// created at this point (either during this occasion or on a previous occasion),
		// so we set up the array BibChaps of Chapters by reading the records from kdb.sqlite.
		//
		// This array will last while this Book is the currently selected Book and will
		// be used whenever the user is allowed to select a Chapter; it will also be updated
		// when VerseItem records for this Chapter are created, and when the user chooses
		// a different Chapter to edit.
		// Its life will end when the user chooses a different Book to edit.
		
		dao!.readChaptersRecs (bibID, self)
		// calls readChaptersRecs() in KITDAO.swift to read the kdb.sqlite database Books table
		// readChaptersRecs() calls appendChapterToArray() in this file for each ROW read from kdb.sqlite
		if curChID == 0 {
			needChooseChapter = true	// Need to choose a Chapter
		} else {
			goCurrentChapter()
		}
	}

	func createChapterRecords (_ book:Int, _ bib:Int, _ code:String) {
		
		var specLines:[String] = []

		// Open KIT_BooksSpec.txt and read its data
		let booksSpec:URL = Bundle.main.url (forResource: "KIT_BooksSpec", withExtension: "txt")!
		do {
			let string = try String.init(contentsOf: booksSpec)
			specLines = string.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Find the line containing the String code
		var i: Int = 0
		while !specLines[i].contains(code) {
			i = i + 1
		}
		// Process that line to create the Chapter records for this Book
		var elements:[String] = specLines[i].components(separatedBy: ", ")
		elements.remove(at: 1)	// we already have the Book three letter code
		elements.remove(at: 0)	// we already have the Book ID
		numChap = elements.count

		// Create a Chapters record in kdb.sqlite for each Chapter in this Book
		var chNum = 1	// Start at Chapter 1
		let currIt = 0	// No current VerseItem yet
		let currVN = 0	// No current verse number yet
		for elem in elements {
			var numIt = 0
			var elemTr = elem		// for some Psalms a preceding "A" will be removed
			if elem.prefix(1) == "A" {
				numIt = 1	// 1 for the Psalm ascription
				elemTr = String(elem.suffix(elem.count - 1))	// remove the "A"
			}
			let numVs = Int(elemTr)!
			numIt = numIt + numVs	// for some Psalms numIt will include the ascription VerseItem
			dao!.chaptersInsertRec (bib, book, chNum, false, numVs, numIt, currIt, currVN)
			chNum = chNum + 1
		}
		// Update in-memory record of current Book to indicate that its Chapter records have been created
		chapRCr = true
		
		// Update kdb.sqlite Books record of current Book to indicate that its Chapter records have been
		// created, the number of Chapters has been found, but there is not yet a current Chapter
		dao!.booksUpdateRec (bibID, bkID, chapRCr, numChap, 0, 0)
	
		// Update the entry in BibBooks[] for the current Book to show that its Chapter records have
		// been created and that its number of Chapters has been found
		bibInst!.setBibBooksNumChap(numChap)
	}

//	dao.readChaptersRecs() calls appendChapterToArray() for each row it reads from the kdb.sqlite database
	func appendChapterToArray(_ chapID:Int, _ bibID:Int, _ bookID:Int,
							  _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ curIt:Int, _ curVN:Int) {
		var chRec = BibChap(chID: chapID, bibID: bibID, bkID: bookID, chNum: chNum, itRCr: itRCr, numVs: numVs, numIt: numIt, curIt: curIt, curVN: curVN)
		if chapID == self.curChID {
			chRec.selected = true
		}
		BibChaps.append(chRec)
	}

// Find the offset in BibChaps[] to the element having ChapterID withID.
// If out of range returns offset zero (first item in the array).

	func offsetToBibChap(withID: Int) -> Int {
		for i in 0...numChap-1 {
			if BibChaps[i].chID == withID {
				return i
			}
		}
		return 0
	}

// If, from kdb.sqlite, there is already a current Chapter for the current Book then go to it
	func goCurrentChapter() {
		currChapOfst = offsetToBibChap(withID: curChID)
		
		// delete any previous in-memory instance of Chapter
		chapInst = nil

		// create a Chapter instance for the current Chapter of the current Book
		let chap = BibChaps[currChapOfst]
		chapInst = Chapter(self, chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
	}
	
// When the user selects a Chapter from the Grid view of Chapters it needs to be recorded as the
// current Chapter and initialisation of data structures in a new Chapter instance must happen.
	
	func setupChosenChapter(_ chapChosen: BibChap) {
		let newChID = chapChosen.chID			// update to new ChapterID
		let newChOfst = offsetToBibChap(withID: newChID)
		
		// Set newChap true if the user is changing to a different Chapter
		// or if there was not yet a chosen Chapter
		let newChap = (newChOfst != currChapOfst) || (currChapOfst == -1)
		
		// If there is a current chapter, make it not selected
		if currChapOfst >= 0 {
			BibChaps[currChapOfst].selected = false
		}

		// update to new Chapter number, offset, selected
		curChID = newChID
		curChNum = chapChosen.chNum
		currChapOfst = newChOfst
		BibChaps[currChapOfst].selected = true
		let chap = BibChaps[currChapOfst]

		// update Book record in kdb.sqlite to show this current Chapter
		dao!.booksUpdateRec(bibID, bkID, chapRCr, numChap, curChID, curChNum)
		// Update the curChID and curChNum for this book in BibBooks[] in bibInst
		bibInst!.setBibBooksCurChap(curChID, curChNum)

		// If the user has changed to a different Chapter then
		// delete any previous in-memory instance of Chapter and create a new one
		if newChap {
			chapInst = nil

			// create a Chapter instance for the current Chapter of the current Book
			chapInst = Chapter(self, chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
		}
	}

	// Set into Book's BibChaps[] the new value for the current VerseItem
	// Called when the user selects a VerseItem of the current Chapter
	func setCurVItem (_ curIt:Int, _ curVN:Int) {
		BibChaps[currChapOfst].curIt = curIt
		BibChaps[currChapOfst].curVN = curVN
	}

	// When the user edits the Book name, the Book instance needs to have its bkName updated
	func updateBookName (_ edName: String) {
		bkName = edName
	}
}
