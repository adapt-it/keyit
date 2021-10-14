package com.ccs.kitand

//
//  Chapter.kt
//
// There will be one instance of this class for the currently selected Book.
// This instance will have a lifetime of the current book selection; its life
// will be terminated when the user selects a different Book to keyboard, at
// which time a new Book instance will be created for the newly selected Book.

// The Chapter records in the database store the ID of the current VerseItem for each Chapter
// because there are over 31,000 VerseItems and so verse numbers are not enough, and updating
// a VerseItem record in the database is more efficiently done if the record is identified by
// just its ID rather than by a combination of Book, Chapter, and VerseItem.
// On the other hand, the user interface needs only the VerseItems for the current Chapter and,
// in addition, the user interface functions on both Android and iOS expect data to be supplied
// from the array BibItems[] whose index matches the indexes to the cells of the
// RecyclerView (on Android) or rows of the TableView (on iOS).
//
//	GDLC 17AUG21 Changed popMenuAction() to pass cursor position instead
//
//  Created by Graeme Costin on 25SEP20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class Chapter(
	val chID:Int,		// chapterID INTEGER PRIMARY KEY
	val bibID:Int,		// bibleID INTEGER
	val bkID:Int,		// bookID INTEGER,
	val chNum:Int,		// chapterNumber INTEGER
	var itRCr:Boolean,	// itemRecsCreated INTEGER
	val numVs:Int,		// numVerses INTEGER
	var numIt:Int,		// numItems INTEGER
	var currIt:Int,		// currItem INTEGER (the ID assigned by SQLite when the VerseItem was created)
	var currVN:Int		// currVsNum INTEGER (the Verse number associated with the current VerseItem)
) {
	// The following variables and data structures also have lifetimes of the Chapter instance
	val dao = KITApp.dao			// Access to the KITDAO instance for kdb.sqlite access
	val bibInst = KITApp.bibInst	// access to the instance of Bible for updating BibBooks[] (not needed?)
	val bkInst = KITApp.bkInst		// access to the instance for the current Book

	var USFMText:String = ""	// Property to hold the USFM text exported

	// currItOfst has custom getter and setter in order to ensure that a VIMenu is created for the
	// current VerseItem whenever the VerseItem is selected. This avoids putting the logic in the
	// setter is several places throughout the source code.
	//
	// The initial value of -1 means that there is not yet a current VerseItem
	// (the offsets for all actual VerseItems are >= zero)
	var currItOfst: Int = -1	// offset to current item in BibItems[] and row in the TableView
		get() = field
		set (ofst) {
			if (curPoMenu == null) {
				curPoMenu = VIMenu(ofst)
			} else if ((ofst != currItOfst) || (BibItems[ofst].itID != currIt)) {
				// Delete previous popover menu
				curPoMenu = null
				curPoMenu = VIMenu(ofst)
			}
			field = ofst
			currIt = BibItems[ofst].itID
		}

	//	GDLC 17AUG21 Changed so that cursor position in text of VerseItem is passed to
	//	popMenuAction() instead of a reference to the VerseItemAdapter instance
	// Reference to the current VerseItemAdapter needing Chapter services
	// When the EditChapterActivity calls popMenuAction() it passes a reference to the
	// current VerseItemAdapter
//	lateinit var vItAda: VerseItemAdapter

	// This struct and the BibItems array are used for letting the user select the
	// VerseItem to edit in the current Chapter of the current Book.

	data class BibItem (
		val itID: Int,		// itemID INTEGER PRIMARY KEY
		val chID: Int,		// chapterID INTEGER
		val vsNum: Int,		// verseNumber INTEGER
		var itTyp: String,	// itemType TEXT
		var itOrd: Int,		// itemOrder INTEGER
		var itTxt: String,	// itemText TEXT
		var intSeq: Int,	// intSeq INTEGER
		var isBrg: Boolean,	// isBridge INTEGER
		var lvBrg: Int		// last verse of bridge
	)

	val BibItems = ArrayList<BibItem>()

	// Properties of the Chapter instance related to popover menus
	var curPoMenu: VIMenu? = null	// instance in memory of the current popover menu
	var hasAscription = false		// true if the Psalm has an Ascription
	var hasTitle = false			// true if Chapter 1 has a Book Title
	var hasInTitle = false			// true if Chapter 1 has an introductory matter Title
	var nextIntSeq = 1				// next value to be used for an IntSeq field. Starts at 1 because
									// InTitle is in effect IntSeq = 0

	// When the instance of current Book creates the instance for the current Chapter it supplies
	// the values for the currently selected Chapter from the BibChaps array

	init {	// Chapter.init()
		// A reference to this instance of the current Chapter needs to be saved in KITApp
		KITApp.chInst = this

		// First time this Chapter has been selected the Item records must be created
		if (!itRCr) {
			try {
				createItemRecords()
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\nChapter.init()")
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\nChapter.init()")
			}
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

		// Calls readVerseItemsRecs() in KITDAO.swift to read the kdb.sqlite database VerseItems table
		// readVerseItemsRecs() calls appendItemToArray() in this file for each ROW read from kdb.sqlite
		try {
			dao.readVerseItemsRecs (this)
		} catch (e:SQLiteReadRecExc) {
			throw SQLiteReadRecExc(e.message + "\nChapter.init()")
		}
		// Adjust the numIt read from kdb.sqlite if necessary
		// This may have been found necessary because of errors caused during testing by interrupting
		// kitand during some creation of publication items. Eventually it may not be necessary, but
		// it could be a good safety measure even in the released app.
		if (BibItems.size != numIt) {
			numIt = BibItems.size
			try {
					dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\nChapter.init()")
			}
		}
	}

	// Create a VerseItem record in kdb.sqlite for each VerseItem in this Chapter
	// If this is a Psalm and it has an ascription then numIt will be 1 greater than numVs.
	// For all other Psalms or Chapters numIt will equal numVs at this early stage of building
	// the app's data

	fun createItemRecords() {
		// If there is a Psalm ascription then create it first.
		if (this.numIt > numVs) {
			val vsNum = 1
			val itTyp = "Ascription"
			val itOrd = 99
			val itText = ""
			val intSeq = 0
			val isBrid = false
			val lstVsBrid = 0
			try {
				val newRecID: Long = dao.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lstVsBrid)
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\ncreateItemRecords()")
			}
		}
		for (vsNum in 1..numVs) {
			val itTyp = "Verse"
			val itOrd = 100*vsNum
			val itText = ""
			val intSeq = 0
			val isBrid = false
			val lstVsBrid = 0
			try {
				val newRecID = dao.verseItemsInsertRec (chID, vsNum, itTyp, itOrd, itText, intSeq, isBrid, lstVsBrid)
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\ncreateItemRecords()")
			}
		}
		// Update in-memory record of current Chapter to indicate that its VerseItem records have been created
		itRCr = true
		// Also update the BibChap struct to show itRCr true and numVs & numIt
		bkInst!!.setBibChapsNums(numVs, numIt)
		// Update Chapter record to show that VerseItems have been created
		try {
			dao.chaptersUpdateRec(chID, itRCr, numIt, currIt)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ncreateItemRecords()")
		}
	}

	// dao.readVerseItemRecs() calls appendItemToArray() for each row it reads from the kdb.sqlite database

	fun appendItemToArray(itID:Int, chID:Int, vsNum:Int, itTyp:String, itOrd:Int, itTxt:String, intSeq:Int, isBrg:Boolean, lvBrg:Int) {
		val itRec = BibItem(itID, chID, vsNum, itTyp, itOrd, itTxt, intSeq, isBrg, lvBrg)
		BibItems.add(itRec)
		if (itTyp == "Ascription") {hasAscription = true}
		if (itTyp == "Title") {hasTitle = true}
		if (itTyp == "InTitle") {hasInTitle = true}
		// Set nextIntSeq to 1 more than the largest intSeq found in the existing VerseItem records
		// remembering that the VerseItem records will be read in ascending order of intSeq, but there
		// may be missing values because of records that were created but later deleted.
		if (intSeq > 0) {
			if (intSeq >= nextIntSeq) {
				nextIntSeq = 1 + intSeq
			}
		}
	}

	// Find the offset in BibItems[] to the element having VerseItemID withID
	// If out of range returns offset zero (first item in the array)

	fun offsetToBibItem(withID:Int) : Int {
		for (i in 0 until numIt) {
			if (BibItems[i].itID == withID) {
				return i
			}
		}
		return 0
	}


	// Go to the current BibItem
	// This function is called by the EditChapterActivity to find out which VerseItem
	// in the current Chapter is the current VerseItem (if one has already been made current).
	// If there is already a current VerseItem it goes to that one, but if not it makes the
	// first VerseItem the current one and makes the Chapter record remember that selection.
	//
	// Returns the current Item offset in BibItems[] array to the EditChapterActivity
	// because this equals the row number in the RecyclerView.
	// This functions sets both currIt and currItOfst to indicate the current VerseItem
	fun goCurrentItem() : Int {
		if (currIt == 0) {
			// Make the first VerseItem the current one
			currItOfst = 0		// Take first item in BibItems[] array
			currIt = BibItems[currItOfst].itID		// Get its itemID
			currVN = BibItems[currItOfst].vsNum		// Get its verse number
		} else {
			// Already have the itemID of the current item so need to get the offset into the
			// BibItems[] array
			currItOfst = offsetToBibItem(currIt)
			currVN = BibItems[currItOfst].vsNum		// Get its verse number
			// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
		}
		// Update the BibChap record for this Chapter
		bkInst!!.setCurVItem (currIt, currVN)
		// Update the database Chapter record
		try {
			dao.chaptersUpdateRec (chID, itRCr, currIt, currVN)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ngoCurrentItem()")
		}
		return currItOfst
	}

	// Set up the new current BibItem given the VerseItem's ID
	// (as assigned by SQLite when the database's VerseItem record was created)
	// TODO: This function is not yet used - delete it?
	fun setupCurrentItemFromID(curIt:Int) {
		currIt = curIt
		currItOfst = offsetToBibItem(curIt)
		// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
		currVN = BibItems[currItOfst].vsNum
		// Update the BibChap record for this Chapter
		bkInst!!.setCurVItem (currIt, currVN)
		// Update the database Chapter record
		try {
			dao.chaptersUpdateRec(chID, itRCr, currIt, currVN)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\nsetupCurrentItemFromID()")
		}
	}

	fun setupCurrentItemFromRecyclerRow(pos: Int) {
		currItOfst = pos
		// Setting currItOfst ensures that there is a VIMenu for the current VerseItem
		currIt = BibItems[pos].itID
		currVN = BibItems[pos].vsNum
		// Update the BibChap record for this Chapter
		bkInst!!.setCurVItem (currIt, currVN)
		// Update the database Chapter record
		try {
			dao.chaptersUpdateRec(chID, itRCr, currIt, currVN)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\nsetupCurrentItemFromRecyclerRow()")
		}
	}

	// Copy and save a VerseItem's text; parameters are
	// Offset of the VerseItem
	// Text of the VerseItem
	// TODO: Avoid doing this when there is no change in the text
	fun copyAndSaveVItem(ofSt:Int, text:String) {
		BibItems[ofSt].itTxt = text
		try {
			dao.itemsUpdateRecText (BibItems[ofSt].itID, BibItems[ofSt].itTxt)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ncopyAndSaveVItem()")
		}
//		chDirty = true	// An item in this chapter has been edited (No longer used in UI)
	}

	// Function to carry out on the data model the actions required for the popover menu items;
	// this function is called by the EditChapterActivity when the user taps on a popover menu item.
	// All of the possible actions change the BibItems[] array so, after carrying out the
	// specific action, this function clears BibItems[] and reloads it from the database;
	// following this the VersesTableViewController needs to reload the TableView.

	fun popMenuAction(act: String, cursPos: Int) {
//	GDLC 17AUG21 Changed to pass cursor position instead
//		this.vItAda = vItAda
		try {
			when (act) {
				"crAsc" -> createAscription()
				"delAsc" -> deleteAscription()
				"crTitle" -> createTitle()
				"delTitle" -> deleteTitle()
				"crParaBef" -> createParagraphBefore()
				"delPara" -> deleteParagraphBefore()
				"crParaCont" -> createParagraphCont(cursPos)
				"delPCon" -> deleteParagraphCont()
				"delVCon" -> deleteVerseCont()
				"crHdBef" -> createSubjHeading()
				"delHead" -> deleteSubjHeading()
				"crPalRef" -> createParallelRef()
				"delPalRef" -> deleteParallelRef()
				"brid" -> bridgeNextVerse()
				"unBrid" -> unbridgeLastVerse()
				"crInTit" -> createIntroTitle()
				"delInTit" -> deleteIntroTitle()
				"crInHed" -> createIntroHeading()
				"delInSubj" -> deleteIntroHeading()
				"crInPar" -> createIntroPara()
				"delInPar" -> deleteIntroPara()
				else -> println("BUG! Unknown action code")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\nChapter.popMenuAction()")
		} catch (e:SQLiteReadRecExc) {
			throw SQLiteReadRecExc(e.message + "\nChapter.popMenuAction()")
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\nChapter.popMenuAction()")
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\nChapter.popMenuAction()")
		}

		// GDLC 12JAN21 BUG10 The logic in the setter for currItOfst works for moving from one VerseItem
		// to another but it fails in some situations where a new VerseItem is created or deleted
		// (on creation because the new VerseItem may have the same offset as the one whose menu action
		// was used). So destroying the current popover menu once an action from it has been used
		// ensures that a new popover menu will be created.
		//
		// Delete the popover menu now that it has been used
		curPoMenu = null
		// Clear the current BibItems[] array
		BibItems.clear()
		// Reload the BibItems[] array of VerseItems from the modified database
		try {
			dao.readVerseItemsRecs (this)
		} catch (e:SQLiteReadRecExc) {
			throw SQLiteReadRecExc(e.message + "\npopMenuAction()")
		}
		// Calculate offset in BibItems[] to the new current item
		currItOfst = offsetToBibItem(currIt)
	}

	// Can be called when the current VerseItem is Verse 1 of a Psalm
	fun createAscription () {
		try {
			val newItemID:Long = dao.verseItemsInsertRec (chID, 1, "Ascription", 75, "", 0, false, 0)
			// Make the new Ascription the current VerseItem
			currIt = newItemID.toInt()
			currVN = 1
			// Note that the Psalm now has an Ascription
			hasAscription = true
			// Increment number of items
			numIt = numIt + 1
			// Update the database Chapter record so that the new Ascription item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateAscription()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateAscription()")
		}
	}

	// Can be called when the current VerseItem is an Ascription
	fun deleteAscription () {
		val vsNum = 1
		try {
			dao.itemsDeleteRec(currIt)
			// Note that the Psalm no longer has an Ascription
			hasAscription = false
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, vsNum)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteAscription()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteAscription()")
		}
	}

	// Create Book title
	fun createTitle() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, 1, "Title", 70, "", 0, false, 0)
			// Note that the Book now has a Title
			hasTitle = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new Title the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Title item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateTitle()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateTitle()")
		}
	}

	// Can be called when the current VerseItem is a Title
	fun deleteTitle () {
		try {
			dao.itemsDeleteRec(currIt)
			// Note that the Book no longer has a Title
			hasTitle = false
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteTitle()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteTitle()")
		}
	}


	// Create a paragraph break before a verse.
	fun createParagraphBefore () {
		// currIt and currVN are for the verse before which the paragraph break is to be created
		try {
			val newitemID:Long = dao.verseItemsInsertRec (chID, currVN, "Para", currVN * 100 - 10, "", 0, false, 0)
			// Increment number of items
			numIt = numIt + 1
			// Leave the Verse as the current VerseItem (there is nothing to keyboard in the Para record)
			// but increment the number of VerseItems
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateParagraphBefore()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateParagraphBefore()")
		}
	}

	// Can be called when the current VerseItem is a Para
	fun deleteParagraphBefore () {
		try {
			dao.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteParagraphBefore()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteParagraphBefore()")
		}
	}

	// Create a paragraph break inside a verse
	fun createParagraphCont(cursPos: Int) {
//	If passing cursPos runs into problems, a reinstated currTextSplit() function of
//	VerseItemAdapter may be a solution.
//		val cv = this.vItAda.currTextSplit()
//        val cursPos = cv.getAsInteger("1")
//        val txtBef = cv.getAsString("2")
//        val txtAft = cv.getAsString("3")
		val itemTxt = BibItems[currItOfst].itTxt
		val txtBef = itemTxt.substring(0, cursPos)
		val len = itemTxt.length
		val txtAft = itemTxt.substring(cursPos, len)
		val vsNum = BibItems[currItOfst].vsNum
		// Remove text after cursor from Verse
		try {
			dao.itemsUpdateRecText(BibItems[currItOfst].itID, txtBef)
			// Create the ParaCont record
			try {
				val newPContID = dao.verseItemsInsertRec (chID, vsNum, "ParaCont", vsNum * 100 + 10, "", 0, false, 0)
				// Increment number of items
				numIt = numIt + 1
				// Create the VerseCont record and insert the txtAft from the original Verse
				try {
					val newVContID = dao.verseItemsInsertRec (chID, vsNum, "VerseCont", vsNum * 100 + 20, txtAft, 0, false, 0)
					// Increment number of items
					numIt = numIt + 1
					// Update currIt to the new VerseCont item
					currIt = newVContID.toInt()
					// Update the database Chapter record so that the new VerseCont becomes the current item
					try {
						dao.chaptersUpdateRecPub(chID, numIt, currIt, vsNum)
					} catch (e:SQLiteUpdateRecExc) {
						throw SQLiteUpdateRecExc(e.message + "\n" +	"createParagraphCont()")
					}
				} catch (e:SQLiteCreateRecExc) {
					throw SQLiteCreateRecExc(e.message + "\ncreateParagraphCont()")
				}
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\ncreateParagraphCont()")
			}
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ncreateParagraphCont()")
		}
	}

	fun deleteParagraphCont() {
		val prevItem = BibItems[currItOfst - 1]
		val nextItem = BibItems[currItOfst + 1]
		val prevItID = prevItem.itID
		val vsNum = BibItems[currItOfst].vsNum
		// Delete ParaCont record
		try {
			dao.itemsDeleteRec(currIt)
			numIt = numIt - 1
			// Append continuation text to original Verse
			val txtBef = prevItem.itTxt
			val txtAft = nextItem.itTxt
			try {
				dao.itemsUpdateRecText(prevItem.itID, txtBef + txtAft)
				// Delete VerseCont record
				try {
					dao.itemsDeleteRec(nextItem.itID)
					numIt = numIt - 1
					// Update the database Chapter record so that the original VerseItem becomes the current item
					try {
						dao.chaptersUpdateRecPub (chID, numIt, prevItID, vsNum)
					} catch (e:SQLiteUpdateRecExc) {
						throw SQLiteUpdateRecExc(e.message + "\ndeleteParagraphCont()")
					}
				} catch (e:SQLiteDeleteRecExc){
					throw SQLiteDeleteRecExc(e.message + "\ndeleteParagraphCont()")
				}
			} catch (e:SQLiteUpdateRecExc){
				throw SQLiteUpdateRecExc(e.message + "\ndeleteParagraphCont()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteParagraphCont()")
		}
	}

	fun deleteVerseCont() {
		val prevItem = BibItems[currItOfst - 2]	// step back over the ParaCont to the previous Verse
		val contItem = BibItems[currItOfst]	// get the continuation of the Verse
		val prevVersID = prevItem.itID
		val txtBef = prevItem.itTxt
		val txtAft = contItem.itTxt
		val vsNum = BibItems[currItOfst].vsNum
		// Append continuation text to original Verse
		try {
			dao.itemsUpdateRecText(prevItem.itID, txtBef + txtAft)
			// Delete VerseCont record
			try {
				dao.itemsDeleteRec(currIt)
				numIt = numIt - 1
				// Delete ParaCont record
				val paraContItem = BibItems[currItOfst - 1]
				try {
					dao.itemsDeleteRec(paraContItem.itID)
					numIt = numIt - 1
					// Update currIt and the database Chapter record so that the original VerseItem becomes the current item
					currIt = prevVersID
					try {
						dao.chaptersUpdateRecPub (chID, numIt, prevVersID, vsNum)
					} catch (e:SQLiteUpdateRecExc) {
						throw SQLiteUpdateRecExc(e.message + "\ndeleteVerseCont()")
					}
				} catch (e:SQLiteDeleteRecExc) {
					throw SQLiteDeleteRecExc(e.message + "\ndeleteVerseCont()")
				}
			} catch (e:SQLiteDeleteRecExc){
				throw SQLiteDeleteRecExc(e.message + "\ndeleteVerseCont()")
			}
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\ndeleteVerseCont()")
		}
	}

	fun createSubjHeading() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, currVN, "Heading", currVN * 100 - 20, "", 0, false, 0)
			// Increment number of items
			numIt = numIt + 1
			// Make the new Subject Heading the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Subject Heading item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, newitemID.toInt(), currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateSubjHeading()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateSubjHeading()")
		}
	}

	// Can be called when the current VerseItem is a Subject Heading
	fun deleteSubjHeading() {
		try {
			dao.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteSubjHeading()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteSubjHeading()")
		}
	}

	// Creates a Parallel Ref before a Verse or after a Title
	fun createParallelRef() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, currVN, "ParlRef", currVN * 100 - 15, "", 0, false, 0)
			// Increment number of items
			numIt = numIt + 1
			// Make the new Parallel Ref the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Parallel Ref item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, newitemID.toInt(), currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateParallelRef()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateParallelRef()")
		}
	}

		// Can be called when the current VerseItem is a Parallel Ref
		fun deleteParallelRef () {
			try {
				dao.itemsDeleteRec(currIt)
				// Decrement number of items
				numIt = numIt - 1
				// Make the next VerseItem the current one
				currIt = BibItems[currItOfst + 1].itID
				// Update the database Chapter record so that the following item becomes the current item
				try {
					dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
				} catch (e:SQLiteUpdateRecExc) {
					throw SQLiteUpdateRecExc(e.message + "\ndeleteParallelRef()")
				}
			} catch (e:SQLiteDeleteRecExc) {
				throw SQLiteDeleteRecExc(e.message + "\ndeleteParallelRef()")
			}
		}

	// This function uses the current values in BibItems[] but makes changes in
	// the database via KITDAO. After the database changes have been made,
	//  BibItems[] will be refreshed from KITDAO.
	fun bridgeNextVerse() {
		val vsNum = BibItems[currItOfst].vsNum
		// Get the vsNum and itTxt from  the verse to be added to the bridge
		val nexVsNum = BibItems[currItOfst + 1].vsNum
		val nexVsTxt = BibItems[currItOfst + 1].itTxt
		// Delete the verse record being added to the bridge
		try {
			dao.itemsDeleteRec(BibItems[currItOfst + 1].itID)
			numIt = numIt - 1
			// Create related BridgeItems record
			val curVsItID = BibItems[currItOfst].itID
			val curVsTxt = BibItems[currItOfst].itTxt
			try {
				val bridID = dao.bridgeInsertRec(curVsItID, curVsTxt, nexVsTxt)
				// Copy text of next verse into the bridge head verse
				val newBridHdTxt = curVsTxt + " " + nexVsTxt
				try {
					dao.itemsUpdateForBridge(curVsItID, newBridHdTxt, true, nexVsNum)
					// Update the database Chapter record so that the bridge head VerseItem remains the current item
					// and the number of items is updated
					try {
						dao.chaptersUpdateRecPub (chID, numIt, curVsItID, vsNum)
					} catch (e:SQLiteUpdateRecExc) {
						throw SQLiteUpdateRecExc(e.message + "\nbridgeNextVerse()")
					}
				} catch (e:SQLiteUpdateRecExc) {
					throw SQLiteUpdateRecExc(e.message + "\nbridgeNextVerse()")
				}
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\nbridgeNextVerse()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\nbridgeNextVerse()")
		}
	}

	data class BridItem (
		var BridgeID: Int,			// ID of the BridgeItems record
		var textCurrBridge: String,	// text of current Verse or bridge
		var textExtraVerse: String	// text of extra verse added to bridge
	)

	val BridItems = ArrayList<BridItem>()

	// dao.bridgeGetRecs() calls appendItemToBridArray() for each row it reads from
	// the BridgeItems table in the kdb.sqlite database

	fun appendItemToBridArray(BridgeID:Int, textCurrBridge:String, textExtraVerse:String) {
			val bridRec = BridItem(BridgeID, textCurrBridge, textExtraVerse)
			BridItems.add(bridRec)
	}

		// This function uses the current values in BibItems[] but makes changes in
		// the database via KITDAO. After the database changes have been made,
		//  BibItems[] will be refreshed from KITDAO.
	fun unbridgeLastVerse() {
		val vsNum = BibItems[currItOfst].vsNum
		// Get the most recent BridgeItems record for this verse
		BridItems.clear()
		try {
			dao.bridgeGetRecs(BibItems[currItOfst].itID, this)
			// The most recent bridge item will be the last in the list
			val curBridItem = BridItems.last()
			// Create the verse record being removed from the bridge
			val nextVsNum = BibItems[currItOfst].lvBrg
			try {
				dao.verseItemsInsertRec (chID, nextVsNum, "Verse", 100 * nextVsNum, curBridItem.textExtraVerse, 0, false, 0) > 0
				numIt = numIt + 1
				// Copy text of the previous bridge head into the new bridge head
				var isBrid: Boolean// = false
				var lastVsBr = BibItems[currItOfst].lvBrg - 1
				if (lastVsBr == BibItems[currItOfst].vsNum) {
					// The head of the bridge will become a normal verse
					isBrid = false; lastVsBr = 0
				} else {
					// The head of the bridge will still be a bridge head
					isBrid = true
				}
				try {
					dao.itemsUpdateForBridge(BibItems[currItOfst].itID, curBridItem.textCurrBridge, isBrid, lastVsBr)
					// Delete this BridgeItems record
					try {
						dao.bridgeDeleteRec(curBridItem.BridgeID)
						// Update the database Chapter record so that the bridge head VerseItem remains the current item
						// and the number of items is updated
						try {
							dao.chaptersUpdateRecPub (chID, numIt, BibItems[currItOfst].itID, vsNum)
						} catch (e:SQLiteUpdateRecExc) {
							throw SQLiteUpdateRecExc(e.message + "\nunbridgeLastVerse()")
						}
					} catch (e:SQLiteDeleteRecExc) {
						throw SQLiteDeleteRecExc(e.message + "\nunbridgeLastVerse()")
					}
				} catch (e:SQLiteUpdateRecExc) {
					throw SQLiteUpdateRecExc(e.message + "\nunbridgeLastVerse()")
				}
			} catch (e:SQLiteCreateRecExc) {
				throw SQLiteCreateRecExc(e.message + "\nunbridgeLastVerse()")
			}
		} catch (e:SQLiteReadRecExc) {
			throw SQLiteReadRecExc(e.message + "\nunbridgeLastVerse()")
		}
	}

	// Publication items involved in Introductory Matter

	// Create Introductory Matter Title
	fun createIntroTitle() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, currVN, "InTitle", 10, "", 0, false, 0)
			// Note that the Book now has an InTitle
			hasInTitle = true
			// Increment number of items
			numIt = numIt + 1
			// Make the new InTitle the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Title item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateIntroTitle()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateIntroTitle()")
		}
	}

	// Delete Introductory Matter Title
	fun deleteIntroTitle() {
		try {
			dao.itemsDeleteRec(currIt)
			// Note that the Book no longer has an InTitle
			hasInTitle = false
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteIntroTitle()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteIntroTitle()")
		}
	}

	// Create Introductory Matter Heading
	fun createIntroHeading() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, 1, "InSubj", 10 + nextIntSeq, "", nextIntSeq, false, 0)
			nextIntSeq = nextIntSeq + 1
			// Increment number of items
			numIt = numIt + 1
			// Make the new InSubj the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Title item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateIntroHeading()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateIntroHeading()")
		}
	}

	// Delete Introductory Matter Heading
	fun deleteIntroHeading() {
		try {
			dao.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteIntroHeading()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteIntroHeading()")
		}
	}

	// Create Introductory Matter Paragraph
	fun createIntroPara() {
		try {
			val newitemID = dao.verseItemsInsertRec (chID, 1, "InPara", 10 + nextIntSeq, "", nextIntSeq, false, 0)
			nextIntSeq = nextIntSeq + 1
			// Increment number of items
			numIt = numIt + 1
			// Make the new InSubj the current VerseItem
			currIt = newitemID.toInt()
			// Update the database Chapter record so that the new Title item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ncreateIntroPara()")
			}
		} catch (e:SQLiteCreateRecExc) {
			throw SQLiteCreateRecExc(e.message + "\ncreateIntroPara()")
		}
	}

	// Delete Introductory Matter Paragraph
	fun deleteIntroPara() {
		try {
			dao.itemsDeleteRec(currIt)
			// Decrement number of items
			numIt = numIt - 1
			// Make the next VerseItem the current one
			currIt = BibItems[currItOfst + 1].itID
			// Update the database Chapter record so that the following item becomes the current item
			try {
				dao.chaptersUpdateRecPub (chID, numIt, currIt, currVN)
			} catch (e:SQLiteUpdateRecExc) {
				throw SQLiteUpdateRecExc(e.message + "\ndeleteIntroPara()")
			}
		} catch (e:SQLiteDeleteRecExc) {
			throw SQLiteDeleteRecExc(e.message + "\ndeleteIntroPara()")
		}
	}

	fun calcUSFMExportText() : String {
		var USFM = "\\id " + bkInst!!.bkCode + " " + bibInst.bibName + "\n\\c " + chNum.toString()
		for (i in 0 until numIt) {		// 0 until numIt includes zero but does not include numIt
			var s: String
			var vn: String
			val item = BibItems[i]
			val tx: String = item.itTxt
			when (item.itTyp) {
				"Verse" -> {
					if (item.isBrg) {
						vn = item.vsNum.toString() + "-" + item.lvBrg.toString()
					} else {
						vn = item.vsNum.toString()
					}
					s = "\n\\v $vn $tx"
				}
				"VerseCont" -> s = "\n" + tx
				"Para" -> s = "\n\\p "
				"ParaCont" -> s = "\n\\p "
				"Heading" -> s = "\n\\s " + tx
				"ParlRef" -> s = "\n\\r " + tx
				"Title" -> s = "\n\\mt " + tx
				"InTitle" -> s = "\n\\imt " + tx
				"InSubj" -> s = "\n\\ims " + tx
				"InPara" -> s = "\n\\ip " + tx
				"Ascription" -> s = "\n\\d " + tx
				else -> s = ""
			}
			USFM = USFM + s
		}
		return USFM
	}

	// Save the USFM text to the Chapter instance and to kdb.sqlite
	fun saveUSFMText (chID:Int, text:String) {
		USFMText = text
		try {
			dao.updateUSFMText (chID, text)
		} catch (e:SQLiteUpdateRecExc) {
			throw SQLiteUpdateRecExc(e.message + "\nsaveUSFMText()")
		}
	}
}