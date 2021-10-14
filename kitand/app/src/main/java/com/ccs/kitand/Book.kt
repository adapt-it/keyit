package com.ccs.kitand

import java.io.BufferedReader

// There will be one instance of this class for the currently selected Book.
// This instance will have a lifetime of the current book selection; its life
// will be terminated when the user selects a different Book to keyboard, at
// which time a new Book instance will be created for the newly selected Book.

//  Created by Graeme Costin on 24SEP20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class Book(
	val bkID: Int,			// bookID INTEGER
	val bibID: Int,			// bibleID INTEGER - always 1 for KIT v1
	val bkCode: String,		// bookCode TEXT
	val bkName: String,		// bookName TEXT
	var chapRCr: Boolean,	// chapRecsCreated INTEGER
	var numChap: Int,		// numChaps INTEGER
	var curChID: Int,		// currChID INTEGER (the ID assigned by SQLite when the Chapter was created)
	var curChNum: Int		// currChNum INTEGER (the Chapter number)
) {

	// The following variables and data structures have lifetimes of the Book object

	// Access to the KITDAO instance for kdb.sqlite access
	val dao = KITApp.dao
	val bibInst = KITApp.bibInst	// access to the instance of Bible for updating BibBooks[]

	// When an instance of a Book is created, the ChooseChapterActivity should go straight to
	// the current Chapter recorded in kdb.sqlite.
	// But if the user comes back to ChooseChapterActivity after keyboarding VerseItems in a
	// Chapter, the user should be allowed to choose a different Chapter of the same Book.
	var canChooseAnotherChapter = false		// true if the user is allowed to choose another Chapter

	var currChapOfst: Int = -1	// offset to the current Chapter in BibChaps[] array
	var chapInst: Chapter? = null	// Instance in memory of the current Chapter -
									// this is the strong ref that owns it

	// BibChaps array (for listing the Chapters so the user can choose one)

	data class BibChap(
		var chID: Int,			// chapterID INTEGER PRIMARY KEY assigned by SQLite when the Chapter was created
		var bibID: Int,			// bibleID INTEGER
		var bkID: Int,			// bookID INTEGER
		var chNum: Int,			// chapterNumber INTEGER
		var itRCr: Boolean,		// itemRecsCreated INTEGER
		var numVs: Int,			// numVerses INTEGER
		var numIt: Int,			// numItems INTEGER
		var curIt: Int,			// currItem INTEGER (ID of current VerseItem)
		var curVN: Int			// currVsNum INTEGER (verse number for curIt)
	) {
		override fun toString(): String {
			val ch_name = KITApp.res.getString(com.ccs.kitand.R.string.nm_chapter)
			val ps_name = KITApp.res.getString(com.ccs.kitand.R.string.nm_psalm)
			val d1String = (if (bkID == 19) ps_name else ch_name) + " " + chNum.toString()
			val d2String = (if (numVs >0) " (" + numVs.toString() + " verses)" else "")
			val displayString = d1String + d2String
			return displayString
		}
	}

	val BibChaps = ArrayList<BibChap>()

	// When the instance of Bible creates the instance for the current Book it supplies the values for
	// the currently selected book from the BibBooks array

	init {	// Book.init()
		// On the first time this Book has been selected the Chapter records must be created
		if (!chapRCr) {
			try {
				createChapterRecords(bkID, bibID, bkCode)
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\nBook.init()")
			}
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
		try {
			dao.readChaptersRecs(bibID, this)
			// calls readChaptersRecs() in KITDAO.swift to read the kdb.sqlite database Books table
			// readChaptersRecs() calls appendChapterToArray() in this file for each ROW read from kdb.sqlite
		} catch (e:SQLiteReadRecExc) {
			throw SQLiteReadRecExc(e.message + "\nBook.init()")
		}
	}

	fun createChapterRecords(book: Int, bib: Int, code: String) {

		// Open kit_bookspec and read its data
		val res = KITApp.res
		val specStr = res.openRawResource(com.ccs.kitand.R.raw.kit_bookspec)
		val specRdr = BufferedReader(specStr.reader())
		val specTxt: String
		try {
			specTxt = specRdr.readText()
		} finally {
			specRdr.close()
		}

		val specLines = specTxt.split("\n").toTypedArray()

		// Find the line containing the String code
		var i = 0
		while (!specLines[i].contains(code)) {
			i = i + 1
		}

		// Process that line to create the Chapter records for this Book
		val bkStrs = specLines[i].split(", ").toTypedArray()
		val bkMList = bkStrs.toMutableList()
		bkMList.removeAt(1)	// we already have the Book three letter code
		bkMList.removeAt(0)	// we already have the Book ID
		numChap = bkMList.count()

		// Create a Chapters record in kdb.sqlite for each Chapter in this Book
		var chNum = 1	// Start at Chapter 1
		val currIt = 0	// No current VerseItem yet
		val currVN = 0	// No current Verse number yet
		for (elem in bkMList) {
			var numIt = 0
			var elemTr = elem		// for some Psalms a preceding "A" will be removed
			if (elem.first() == 'A') {
				numIt = 1	// 1 for the Psalm ascription
				elemTr = elem.drop(1)	// remove the "A"
			}
			val numVs = elemTr.toInt()
			numIt = numIt + numVs	// for some Psalms numIt will include the ascription VerseItem
			try {
				dao.chaptersInsertRec(bib, book, chNum, false, numVs, numIt, currIt, currVN)
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\ncreateChapterRecords()")
			}
			chNum = chNum + 1
		}
		// Update in-memory record of current Book to indicate that its Chapter records have been created
		chapRCr = true
		// numChap was set when the count of elements in the chapters string was found

		// Update kdb.sqlite Books record of current Book to indicate that its Chapter records have been created,
		// the number of Chapters has been found, but there is not yet a current Chapter
		try {
			dao.booksUpdateRec(bibID, bkID, chapRCr, numChap, curChID, curChNum)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ncreateChapterRecords()")
		}

		// Update the entry in BibBooks[] for the current Book to show that its Chapter records have been created
		// and that its number of Chapters has been found
		bibInst.setBibBooksNumChap(numChap)
	}

	// dao.readChaptersRecs() calls appendChapterToArray() for each row it reads from the kdb.sqlite database

	fun appendChapterToArray(
		chapID: Int, bibID: Int, bookID: Int,
		chNum: Int, itRCr: Boolean, numVs: Int, numIt: Int, curIt: Int, curVN: Int
	) {
		val chRec = BibChap(chapID, bibID, bookID, chNum, itRCr, numVs, numIt, curIt, curVN)
		BibChaps.add(chRec)
	}

	// Find the offset in BibChaps[] to the element having ChapterID withID.
	// If out of range returns offset zero (first item in the array).

	fun offsetToBibChap(withID: Int) : Int {
		for (i in 0..numChap-1) {
			if (BibChaps[i].chID == withID) {
				return i
			}
		}
		return 0
	}

	// Go to the current BibChap
	// This function is called by the ChooseChaptersActivity to find out which Chapter
	// in the current Book is the current Chapter, and to make the Book instance and
	// the Book record remember that selection.
	fun goCurrentChapter() {
		currChapOfst = offsetToBibChap(curChID)

		// allow any previous in-memory instance of Chapter to be garbage collected
		chapInst = null
		KITApp.chInst = null

		// create a Chapter instance for the current Chapter of the current Book
		// The initialisation of the instance of Chapter stores a reference in KITApp
		val chap = BibChaps[currChapOfst]
		try {
			chapInst = Chapter(chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ngoCurrentChapter()")
		}
		KITApp.chInst = chapInst
	}

	// When the user selects a Chapter from the list of Chapters it needs to be recorded as the
	// current Chapter and initialisation of data structures in a new Chapter instance must happen.

	fun setupCurrentChapter(chapOfst: Int) {
		val diffChap = (chapOfst != currChapOfst)
		val chap = BibChaps[chapOfst]
		curChNum = chap.chNum
		curChID = chap.chID
		currChapOfst = chapOfst
		// update Book record in kdb.sqlite to show this current Chapter
		try {
			dao.booksUpdateRec(bibID, bkID, chapRCr, numChap, curChID, curChNum)
			// Update the curChID and curChNum for this book in BibBooks[] in bibInst
			bibInst.setBibBooksCurChap (curChID, curChNum)

			// If a different chapter is being selected allow any previous in-memory instance of Chapter
			// to be garbage collected and create a new Chapter instance.
			if (diffChap) {
				chapInst = null
				KITApp.chInst = null

				// create a Chapter instance for the current Chapter of the current Book
				// The initialisation of the instance of Chapter stores a reference in KITApp
				try {
					chapInst = Chapter(chap.chID, chap.bibID, chap.bkID, chap.chNum, chap.itRCr, chap.numVs, chap.numIt, chap.curIt, chap.curVN)
//	An SQLite update error gets caught in the outer try; this gives an unwanted duplicate catch
//				} catch (e:SQLiteUpdateRecExc) {
//					throw SQLiteUpdateRecExc(e.message + "\nsetupCurrentChapter()")
				} catch (e:SQLiteCreateRecExc) {
					throw SQLiteCreateRecExc(e.message + "\nsetupCurrentChapter()")
				} catch (e:SQLiteReadRecExc) {
					throw SQLiteReadRecExc(e.message + "\nsetupCurrentChapter()")
				}
				KITApp.chInst = chapInst
			}
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\nsetupCurrentChapter()")
		}
	}


	// Set the new value for the current VerseItem into BibChaps[]
	// called when the user selects a VerseItem of the current Chapter
	fun setCurVItem (curIt:Int, curVN:Int) {
		BibChaps[currChapOfst].curIt = curIt
		BibChaps[currChapOfst].curVN = curVN
	}

	// When the VerseItem records have been created for the current Chapter, the entry for that Chapter in
	// the Book's BibChaps[] array must be updated. Once itRCr is set true it will never go back to false
	// (the kdb.sqlite Chapter records are not going to be deleted) so no parameter is needed for that,
	// but parameters are needed for the number of Verses and number of Items in the Chapter.
	// This function is called from the current Chapter instance, createItemRecords()

	fun setBibChapsNums(numVs:Int, numIt:Int) {
		BibChaps[currChapOfst].itRCr = true
		BibChaps[currChapOfst].numVs = numVs
		BibChaps[currChapOfst].numIt = numIt
	}
}
