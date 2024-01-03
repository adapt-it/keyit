//
//  Bible.swift
//  kitsui
//
// The class Bible of which one instance will be created in the first version of kitsui.
// A later version may create two instances to display two Bibles side by side.
// The initialisation of an instance of the class Bible will happen when it is made the
// current Bible. If the Book records have not yet been created for that Bible, they will
// be created and saved to kdb.sqlite. Then they will be read into the array BibBooks[].
//
// Data changes made by the user are always saved directly to the database as well as
// held in the instance of this class for further use during the current launch of KIT.
//
//	GDLC 23NOV23 Started adjusting to suit kitsui
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//	GDLC 12MAR20 Updated for KIT05
//
//  Created by Graeme Costin on 9OCT19.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import Foundation
import SwiftUI

class Bible: ObservableObject {
	var bibleID: Int
	var bibleName: String
	var bkRecsCr: Bool
	var currBk: Int		// 0 means that a Book has not yet been chosen
	var bibMod: BibleModel
	var currBookOfst = -1	// Offset in BibBooks[] to the current book 0 to 38 (OT) 39 to 65 (NT)
							// -1 means that a current Book has not yet been selected
	var bookInst: Book?		// Instance in memory of the current Book - this is the strong ref that owns it
	@Published var goChooseBook = false	// Assume no need for ChooseBookView

	init (bibleID bibID: Int, bibleName bibName: String, bkRecsCr bkRCr: Bool, currBk curBk: Int, bibMod: BibleModel) {
		self.bibleID = bibID
		self.bibleName = bibName
		self.bkRecsCr = bkRCr
		self.currBk = curBk
		self.bibMod = bibMod
	}

// The struct BibBook of which one instance will be created for each Book of the current Bible.
// Instances of BibBook will be held in the array BibBooks[] and each current Bible will have
// a BibBooks[] array.

	struct BibBook {
		var bookID: Int
		var bibleID: Int
		var bookCode: String
		var bookName: String
		var chapRecsCreated: Bool
		var numChaps: Int
		var currChID: Int
		var currChNum: Int
		var USFMText: String
	}

	var BibBooks: [BibBook] = []

	// struct bookLst is used in SwiftUI List Views for choosing a Book
	struct bookLst: Identifiable, Hashable {
		var bookID: Int
		var bookCode: String
		var bookName: String
		var bookInNT: Bool
		var id = UUID()
	}

	var booksOT: [bookLst] = []
	var booksNT: [bookLst] = []

	// Initialisation of an instance of class Bible with an array of Books to select from
	//	init()
	//		createBooksRecords()
	//		appendBibBookToArray()  - called by dao.readBooksRecs()

	// CHANGES:- setCurBibOfst() of BibleModel should call
	// loadBibBooks(_ bID: Int) and this function will create the Book records if they have
	// not yet been created and then read the Book records into BibBooks[]
	func loadBibBooks(_ bID: Int) {
		let dao = bibMod.dao		// Instance of KITDAO
		if !bkRecsCr {
			createBibBooks(bID)
		}
		// Set up the array BibBooks[] by reading the 66 Books records from kdb.sqlite.
		// This array will last for the current launch of this Bible and will be used
		// whenever the user is allowed to select a book; it will also be updated
		// when Chapters records for a book are created, and when the user chooses
		// a different Book to edit.
		dao.readBooksRecs (bibInst: self)
		// calls readBooksRecs() in KITDAO.swift to read the kdb.sqlite database Books table
		// readBooksRecs() calls appendBibBookToArray() in this file for each ROW read from kdb.sqlite
		
		// Load booksOT and booksNT
		for BibBook in BibBooks {
			if BibBook.bookID < 40 {
				booksOT.append(bookLst(bookID: BibBook.bookID, bookCode: BibBook.bookCode, bookName: BibBook.bookName, bookInNT: false))
			} else {
				booksNT.append(bookLst(bookID: BibBook.bookID, bookCode: BibBook.bookCode, bookName: BibBook.bookName, bookInNT: true))

			}
		}
		if bibMod.getCurBibInst().currBk == 0 {
			goChooseBook = true	// Need to choose a Book
		}
	}
	
	// For Bible with bID createBooksRecords() creates database Bible records from the
	// text data files in the app's resources and stores these records in the database kdb.sqlite
	func createBibBooks(_ bID: Int) {
		// Open KIT_BooksSpec.txt and read its data
		var specLines:[String] = []
		var nameLines:[String] = []
		var bookNames = [Int: String]()
		
		let booksSpec:URL = Bundle.main.url (forResource: "KIT_BooksSpec", withExtension: "txt")!
		do {
			let string = try String.init(contentsOf: booksSpec)
			specLines = string.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Open KIT_BooksNames.txt and read its data
		let booksNames:URL = Bundle.main.url (forResource: "KIT_BooksNames", withExtension: "txt")!
		do {
			let namesStr = try String.init(contentsOf: booksNames)
			nameLines = namesStr.components(separatedBy: .newlines)
		} catch  {
			print(error);
		}
		// Make a look-up dictionary for book name given book ID number
		for nameItem in nameLines {
			if !nameItem.isEmpty {
				let nmStrs:[String] = nameItem.components(separatedBy: ", ")
				let i = Int(nmStrs[0])!
				let n = nmStrs[1]
				bookNames[i] = n
			}
		}

		// Step through the lines of KIT_BooksSpec.txt, getting the book names from the look-up
		// dictionary made from KIT_BooksNames.txt, and creating the Books records in the database
		let hashMark:Character = "#"
		for spec in specLines {
			// Ignore empty lines and line starting with #
			if (!spec.isEmpty && spec[spec.startIndex] != hashMark) {
				// Create the BibBook struct for this Book
				let bkStrs:[String] = spec.components(separatedBy: ", ")
				let bkID = Int(bkStrs[0])!
				let bibID = bID
				let bkCode:String = bkStrs[1]
				let bkName = bookNames[bkID]!
				let chRCr = false
				let numCh = 0
				let curChID = 0
				let curChNum = 0
				// Create db record in Books
				bibMod.dao.booksInsertRec (bkID, bibID, bkCode, bkName, chRCr, numCh, curChID, curChNum)
			}
		}
		
		// Update the in-memory current Bible to note that its Books recs have been created
		bkRecsCr = true
		
		// Update the database Bible record to note that its Books recs have been created
		bibMod.dao.bibleUpdateRecsCreated(bID)
	}

	// dao.readBooksRecs() calls appendBibBookToArray() for each row it reads from the kdb.sqlite database
	 
	 func appendBibBookToArray (_ bkID:Int,_ bibID:Int, _ bkCode:String, _ bkName:String,
								_ chapRCr:Bool, _ numCh:Int, _ curChID:Int, _ curChNum:Int, _ USFMTxt:String) {
		 let bkRec = BibBook(bookID: bkID, bibleID: bibID, bookCode: bkCode, bookName: bkName, chapRecsCreated: chapRCr,
							 numChaps: numCh, currChID: curChID, currChNum: curChNum, USFMText: USFMTxt)
		 BibBooks.append(bkRec)
	 }

	// Refresh display of the Bible Books table on return to foreground
	 
	 func refreshUIAfterReturnToForeground () {
		 // TODO: Check whether there anything to do here?
	 }

 // If there is a current Book (as read from kdb.sqlite) then instantiate that Book.
	 func goCurrentBook () {
		 if currBookOfst == -1 {
			 currBookOfst = 39		// Assume Matthew; this error should never happen
		 }
		 let book = BibBooks[currBookOfst]

		 // delete any previous in-memory instance of Book
		 bookInst = nil

		 // Create a Book instance for the currently selected book
		 bookInst = Book(self, book.bookID, book.bibleID, book.bookCode, book.bookName,
						book.chapRecsCreated, book.numChaps, book.currChID, book.currChNum, bibMod)
	 }

 // When the user selects a book from the ChooseBookView it needs to be recorded as the
 // current book and initialisation of data structures in a new Book instance must happen.
	func setupChosenBook(_ bookChosen: bookLst) {
		let chosenBkOfst = (bookChosen.bookID > 39 ? bookChosen.bookID - 2 : bookChosen.bookID - 1 )
		setupCurrentBook(BibBooks[chosenBkOfst])
	}

	func setupCurrentBook(_ book: BibBook) {
		let dao = bibMod.dao		// Instance of KITDAO
		currBk = book.bookID
		currBookOfst = (currBk > 39 ? currBk - 2 : currBk - 1 )
		// update Bible record in kdb.sqlite to show this current book
		dao.bibleUpdateCurrBook(bibMod.getCurBibInst().bibleID, currBk)

		// delete any previous in-memory instance of Book
		bookInst = nil		// strong ref

		// Create a Book instance for the currently selected book (strong ref)
		// and copy the reference to the AppDelegate
		bookInst = Book(self, book.bookID, book.bibleID, book.bookCode, book.bookName,
			book.chapRecsCreated, book.numChaps, book.currChID, book.currChNum, bibMod)
	}

 // When the Chapter records have been created for the current Book, the entry for that Book in
 // the Bible's BibBooks[] array must be updated. Once chapRCr is set true it will never go back to false
 // (the kdb.sqlite records are not going to be deleted) so no parameter is needed for that,
 // but a parameter is needed for the number of Chapters in the Book.

	 func setBibBooksNumChap(_ numChap: Int) {
		 BibBooks[currBookOfst].chapRecsCreated = true
		 BibBooks[currBookOfst].numChaps = numChap
	 }
	/*
	 func getCurrBookOfst() -> Int {
		 return (currBook > 39 ? currBook - 2 : currBook - 1 )
	 }

 // When a Chapter is selected as the current Chapter (in ChaptersTableViewController), the entry
 // for the current Book in the Bible's BibBooks[] array must be updated.

	 func setBibBooksCurChap(_ curChID: Int, _ curChNum: Int) {
		 BibBooks[currBookOfst].curChID = curChID
		 BibBooks[currBookOfst].curChNum = curChNum
	  }
*/
}