package com.ccs.kitand

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

//  Created by Graeme Costin on 12AUG20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
//	All interaction between the running app and the SQLite database is handled by this class.
//	The rest of the app can treat the SQLite database as a software object with interaction
//	directed through the member functions of the KITDAO class which is named from the phrase
//	KIT Data Access Object.
//
//	Parameters passed to KITDAO's functions are in the natural types for the programming
//	language of the rest of the app; any conversion to or from data types that SQLite requires
//	is handled within this class.
//
//	This class is instantiated at the launching of the app and it opens a connection to the
//	database, keeps that connection in the instance property db and retains it until the app
//	terminates. Only one instance of the class is used.
//
//	Error Handling: The SQLite errors that may be encountered by the functions in KITDAO are
//	sufficiently serious that continued operation of the app if they occur doesn't make sense.
//	They will also be extremely rare and would be either a result of a bug that the programmer
//	had not caught before release(!!) or else running out of memory in the smartphone in which
//	the app is running. In the case of memory errors, about all that can be done is for the user
//	to restart the app; that is why the action taken with these errors is to simply show an
//	error number and exit the app. 	Thus there are no Exceptions for
//		cannotCreateDatabase
//		cannotOpenDatabase
//		cannotCloseDatabase
//		cannotCreateTable
//	If a later version of this app uses an SQL database on LAN or Internet there may be
//	more reason to make use of Exceptions for the above four errors - for example, failure to
//	open or create the database may be followed by a prompt to the user to check the
//	SQL server and try again.
//
//	TODO: Check whether interruption of the app (such as by a phone call coming to the
//	smartphone) needs the database connection to be closed and then reopened when the app
//	returns to the foreground.

class SQLiteCreateRecExc(message: String) : Exception(message)
class SQLiteReadRecExc(message: String) : Exception(message)
class SQLiteUpdateRecExc(message: String) : Exception(message)
class SQLiteDeleteRecExc(message: String) : Exception(message)

class KITDAO(
	var context: Context
	) : SQLiteOpenHelper(context, "kdb.sqlite", null, 1) {
    private lateinit var db: SQLiteDatabase

    // On first launch the data tables do not exist, so create all the tables and the initial Bible record
    override fun onCreate(db: SQLiteDatabase) {
        // Keep a reference to kdb.sqlite
        this.db = db
        // Create the Bibles table
		val sqlBibT = "CREATE TABLE " + TAB_Bibles + "(" +
				COL_BibleID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
				COL_BibleName + " TEXT, " +
				COL_BookRecsCr + " BOOL, " +
				COL_CurrentBook + " INT)"
		db.execSQL(sqlBibT)
		// Create the Books table
		val sqlBookT = "CREATE TABLE " + TAB_Books + "(" +
				COL_BookID + " INT, " +
				COLF_BibID + " INT, " +
				COL_BookCode + " TEXT, " +
				COL_BookName + " TEXT, " +
				COL_ChapRecsCr + " BOOL, " +
				COL_NumChaps + " INT, " +
				COL_CurrChID + " INT, " +
				COL_CurrChNum + " INT, " +
				COL_USFMBookText + " TEXT)"
		db.execSQL(sqlBookT)
		// Create the Chapters table
		val sqlChapT = "CREATE TABLE " + TAB_Chapters + "(" +
				COL_ChapterID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
				COLF_ChBibID + " INT, " +
				COLF_BookID + " INT, " +
				COL_ChapNum + " INT, " +
				COL_ItemRecsCr + " BOOL, " +
				COL_NumVerses + " INT, " +
				COL_NumItems + " INT, " +
				COL_CurrItem + " INT, " +
				COL_CurrVsNum + " INT, " +
				COL_USFMText + " TEXT)"
		db.execSQL(sqlChapT)
		// Create the VerseItems table
		val sqlVerseT = "CREATE TABLE " + TAB_VerseItems + "(" +
				COL_ItemID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
				COLF_ChapID + " INT, " +
				COL_VerseNum + " INT, " +
				COL_ItemType + " TEXT, " +
				COL_ItemOrder + " INT, " +
				COL_ItemText + " TEXT, " +
				COL_IntSeq + " INT, " +
				COL_IsBridge + " BOOL, " +
				COL_LastVsBridge + " INT)"
		db.execSQL(sqlVerseT)
		// Create the BridgeItems table
		val sqlBridgT = "CREATE TABLE " + TAB_BridgeItems + "(" +
				COL_BridgeID + " INTEGER PRIMARY KEY AUTOINCREMENT, " +
				COLF_ItemID + " INT, " +
				COL_TextCurrBridge + " TEXT, " +
				COL_TextExtraVerse + " TEXT)"
        db.execSQL(sqlBridgT)
        // Create the single Bibles record
		val cv = ContentValues()
		cv.put(COL_BibleID, 1)
		cv.put(COL_BibleName, "Bible")
		cv.put(COL_BookRecsCr, false)
		cv.put(COL_CurrentBook, 0)
		val insert = db.insert(TAB_Bibles, null, cv)
    }

    override fun onUpgrade(p0: SQLiteDatabase?, p1: Int, p2: Int) {
        TODO("Not yet implemented")
    }

//--------------------------------------------------------------------------------------------
//	Bibles data table

	// The single record in the Bibles table needs to be inserted when the app first launches.
	// A future extension of KIT may allow more than one Bible, so this function
	// may be called more than once.
	// NOTE: There were problems throwing an exception from this because the onCreate()
	// override is called on the first use of the database, and throwing an error back through
	// Android's GetWriteableDatabase just didn't work as expected. So onCreate calls directly
	// to Android's SQLite facilities; bibleInsertRec() may be used in future if a later version
	// of KIT allows more than one Bible at a time.

	fun bibleInsertRec (bibID:Int, bibName:String, bkRCr:Boolean, currBook:Int) {
	    val cv = ContentValues()
        cv.put(COL_BibleID, bibID)
        cv.put(COL_BibleName, bibName)
        cv.put(COL_BookRecsCr, bkRCr)
        cv.put(COL_CurrentBook, currBook)
        val insert = db.insert(TAB_Bibles, null, cv)
		if (insert == -1L) {
			throw SQLiteCreateRecExc("Can't create Bible record for $bibName")
		}
	}

    // The single record in the Bibles table needs to be read when the app launches to find out
    //	* whether the Books records need to be created (on first launch) or
    //	* what is the current Book (on subsequent launches)
    //
    //  Return values
    // cv("1") = COL_BibleID
    // cv("2") = COL_BibleName
    // cv("3") = COL_BookRecsCr
    // cv("4") = COL_CurrentBook

    fun bibleGetRec(): ContentValues {
        this.db = this.getReadableDatabase()
        val sql = "SELECT * FROM " + TAB_Bibles + " WHERE " + COL_BibleID + " = 1"
        val cursor = db.rawQuery(sql, null)
        val cv = ContentValues()
        if (cursor.moveToFirst()) {
            cv.put("1", cursor.getInt(0))
            cv.put("2", cursor.getString(1))
			cv.put("3", cursor.getInt(2) == 1)
            cv.put("4", cursor.getInt(3))
        } else {
        	throw SQLiteReadRecExc("Can't read Bible record")
        }
        cursor.close()
        return cv
    }
	// The single Bible record needs to be updated
	//  * to set a new name for the Bible at the user's command
	//	* to set the flag that indicates that the Books records have been created (on first launch)
	//	* to change the current Book whenever the user selects a different Book to work on

	// This function needs a String parameter for the revised Bible name
	fun bibleUpdateName(bibName:String) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_BibleName, bibName)
		val rows = db.update(TAB_Bibles, cv, COL_BibleID + " = 1", null)
        if (rows != 1) {
			throw SQLiteUpdateRecExc("Can't update Bible name to $bibName")
		}
	}

	// The bookRecsCreated flag starts as false and is changed to true during the first launch;
	// it is never changed back to false, and so this function does not need any parameters.
	fun bibleUpdateRecsCreated() {
    	this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_BookRecsCr, true)
		val rows = db.update(TAB_Bibles, cv, COL_BibleID + " = 1", null)
        if (rows != 1) {
        	throw SQLiteUpdateRecExc("Can't update Books records created")
		}
	}


	// This function needs an Integer parameter for the current Book
	fun bibleUpdateCurrBook (currBk:Int) {
        this.db = this.getWritableDatabase()
        val cv = ContentValues()
        cv.put(COL_CurrentBook, currBk)
        val rows = db.update(TAB_Bibles, cv, COL_BibleID + " = 1", null)
        if (rows != 1) {
        	throw SQLiteUpdateRecExc("Can't update in bibleUpdateCurrBook()")
		}
	}

    //--------------------------------------------------------------------------------------------
    //	Books data table

    // The 66 records for the Books table need to be created and populated on the initial launch of the app
    // This function will be called 66 times by the KIT software

    fun booksInsertRec (bkID:Int, bibID:Int, bkCode:String, bkName:String, chRCr:Boolean, numCh:Int, curChID:Int, curChNum:Int) {
        this.db = this.getWritableDatabase()
        val cv = ContentValues()
        cv.put(COL_BookID, bkID)
        cv.put(COLF_BibID, bibID)
        cv.put(COL_BookCode, bkCode)
        cv.put(COL_BookName, bkName)
        cv.put(COL_ChapRecsCr, chRCr)
        cv.put(COL_NumChaps, numCh)
        cv.put(COL_CurrChID, curChID)
		cv.put(COL_CurrChNum, curChNum)
        val insert = db.insert(TAB_Books, null, cv)
        if (!(insert > 0L)) {
        	throw SQLiteCreateRecExc("Can't create Books record for $bkCode in booksInsertRec()")
		}
    }

    // The Books records need to be read to populate the array of books for the Bible
    // that the user can choose from. They need to be sorted in ascending order of the
    // UBS assigned bookID.
    //
    //  Returns column values via the call back function appendBibBookToArray()

    fun readBooksRecs(bibInst: Bible) {
        this.db = this.getReadableDatabase()
        val sql = "SELECT * FROM " + TAB_Books + " WHERE " + COLF_BibID + " = 1 ORDER BY " + COL_BookID
        val cursor = db.rawQuery(sql, null)
        if (!cursor.moveToFirst()) {
        	throw SQLiteReadRecExc ("Can't read Book records of ${bibInst.bibName} in readBooksRecs()")
		} else {
			do {
				val bkID = cursor.getInt(0)
				val bibID = cursor.getInt(1)
				val bkCode = cursor.getString(2)
				val bkName = cursor.getString(3)
				val chRCr = cursor.getInt(4) == 1
				val numCh = cursor.getInt(5)
				val curChID = cursor.getInt(6)
				val curChNum = cursor.getInt(7)
				bibInst.appendBibBookToArray(
					bkID,
					bibID,
					bkCode,
					bkName,
					chRCr,
					numCh,
					curChID,
					curChNum
				)
			} while (cursor.moveToNext())
			cursor.close()
		}
    }

	// The Books record for the current Book needs to be updated
	//	* to set the flag that indicates that the Chapter records have been created (on first edit of that Book)
	//	* to set the number of Chapters in the Book (on first edit of that Book)
	//	* to change the current Chapter when the user selects a different Chapter to work on

	fun booksUpdateRec (bibID:Int, bkID:Int, chRCr:Boolean, numCh:Int, curChID:Int, curChNum:Int) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_ChapRecsCr, chRCr)
		cv.put(COL_NumChaps, numCh)
		cv.put(COL_CurrChID, curChID)
		cv.put(COL_CurrChNum, curChNum)
        val whArray = arrayOf<String>(bibID.toString(), bkID.toString())
		val rows = db.update(TAB_Books, cv, COL_BibleID + " = ? AND " + COL_BookID + " = ?", whArray)
        if (rows != 1) {
        	throw SQLiteUpdateRecExc("Cannot update record for Book $bkID in booksUpdateRec()")
		}
	}


	//--------------------------------------------------------------------------------------------
	//	Chapters data table

	// The Chapters records for the current Book need to be created when the user first selects that
    // Book to edit.
	// This function will be called once by the KIT software for every Chapter in the current Book;
    // it will be called before any VerseItem Records have been created for the Chapter.
    // Each Chapters record has an INTEGER PRIMARY KEY, chapterID, that is assigned automatically
    // by SQLite; this is not included in the insert record SQL.
    // The field for USFM is left empty until the user taps the "Export" button after
    // keyboarding enough to export.

	fun chaptersInsertRec (bibID:Int, bkID:Int, chNum:Int, itRCr:Boolean, numVs:Int, numIt:Int, currIt:Int, currVsNum:Int) {
        this.db = this.getWritableDatabase()
        val cv = ContentValues()
        cv.put(COLF_ChBibID, bibID)
        cv.put(COLF_BookID, bkID)
        cv.put(COL_ChapNum, chNum)
        cv.put(COL_ItemRecsCr, itRCr)
        cv.put(COL_NumVerses, numVs)
        cv.put(COL_NumItems, numIt)
        cv.put(COL_CurrItem, currIt)
		cv.put(COL_CurrVsNum, currVsNum)
        val insert = db.insert(TAB_Chapters, null, cv)
        if (!(insert > 0L)) {
        	throw SQLiteCreateRecExc("Cannot create Chapter record in chaptersInsertRec()")
		}
	}

	// The Chapters records for the currently selected Book need to be read to populate the array
	// of Chapters for the Book bkInst that the user can choose from. The records need to be sorted
	// in ascending order of chapterNumber

	fun readChaptersRecs (bibID:Int, bkInst:Book) {
        this.db = this.getReadableDatabase()
        val sql1 = "SELECT chapterID, bibleID, bookID, chapterNumber, itemRecsCreated, numVerses, numItems, currItem, currVsNum FROM " + TAB_Chapters
        val sql2 =  " WHERE " + COLF_ChBibID + " = ? AND " + COLF_BookID + " = ? ORDER BY " + COL_ChapNum
        val sql = sql1 + sql2
        val whArray = arrayOf<String>(bibID.toString(), bkInst.bkID.toString())
        val cursor = db.rawQuery(sql, whArray)
        if (!cursor.moveToFirst() ) {
        	throw SQLiteReadRecExc("Cannot read Chapter records in readChaptersRecs()")
		} else {
			do {
				val chapID = cursor.getInt(0)
				val biblID = cursor.getInt(1)
				val bookID = cursor.getInt(2)
				val chNum = cursor.getInt(3)
				val itRCr = cursor.getInt(4) == 1
				val numVs = cursor.getInt(5)
				val numIt = cursor.getInt(6)
				val curIt = cursor.getInt(7)
				val curVNm = cursor.getInt(8)
				bkInst.appendChapterToArray(
					chapID,
					biblID,
					bookID,
					chNum,
					itRCr,
					numVs,
					numIt,
					curIt,
					curVNm
				)
			} while (cursor.moveToNext())
			cursor.close()
		}
	}

	// The Chapters record for the current Chapter needs to be updated
	//	* to set the flag that indicates that the VerseItem records have been created (on first edit of that Chapter)
	//	* to change the current VerseItem when the user selects a different VerseItem to work on

	fun chaptersUpdateRec (chID:Int, itRCr:Boolean, currIt:Int, currVN:Int) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_ItemRecsCr, itRCr)
		cv.put(COL_CurrItem, currIt)
		cv.put(COL_CurrVsNum, currVN)
        val whArray = arrayOf<String>(chID.toString())
		val rows = db.update(TAB_Chapters, cv, COL_ChapterID + " = ?", whArray)
        if (rows != 1) {
        	throw SQLiteUpdateRecExc("Cannot update Chapter record in chaptersUpdateRec()")
		}
	}

	// The Chapters record for the current Chapter needs to be updated after changes to the publication items:
	//	* to change the number of VerseItems after one has been deleted or inserted
	//	* to change the current VerseItem after one has been deleted or inserted.

	fun chaptersUpdateRecPub (chID:Int, numIt:Int, currIt:Int, currVN:Int) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_NumItems, numIt)
		cv.put(COL_CurrItem, currIt)
		cv.put(COL_CurrVsNum, currVN)
		val whArray = arrayOf<String>(chID.toString())
		val rows = db.update(TAB_Chapters, cv, COL_ChapterID + " = ?", whArray)
		if (rows != 1) {
			throw SQLiteUpdateRecExc("Cannot update Chapter record in chaptersUpdateRecPub()")
		}
	}

	// Set the value of the field USFMText when the Export scene is used
	fun updateUSFMText (chID:Int, text:String) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_USFMText, text)
		val whArray = arrayOf<String>(chID.toString())
		val rows = db.update(TAB_Chapters, cv, COL_ChapterID + " = ?", whArray)
		if (rows != 1) {
			throw SQLiteUpdateRecExc("Cannot update USFM text in updateUSFMText()")
		}
	}

	//--------------------------------------------------------------------------------------------
	//	VerseItems data table

	// The VerseItems records for the current Chapter need to be created when the user first selects that Chapter
	// This function will be called once by the KIT software for every VerseItem in the current Chapter
	// It will also be called
	//	* when the user chooses to insert a publication VerseItem
	//	* when the user chooses to undo a verse bridge
	// This function returns the rowID of the newly inserted record or -1 if the insert fails

	fun verseItemsInsertRec (chID:Int, vsNum:Int, itTyp:String, itOrd:Int, itText:String, intSeq:Int, isBrid:Boolean, lstVsBrid:Int) : Long {
        this.db = this.getWritableDatabase()
        val cv = ContentValues()
        cv.put(COLF_ChapID, chID)
        cv.put(COL_VerseNum, vsNum)
        cv.put(COL_ItemType, itTyp)
        cv.put(COL_ItemOrder, itOrd)
        cv.put(COL_ItemText, itText)
        cv.put(COL_IntSeq, intSeq)
        cv.put(COL_IsBridge, isBrid)
        cv.put(COL_LastVsBridge, lstVsBrid)
        val insID = db.insert(TAB_VerseItems, null, cv)
		if (!(insID > 0L)) {
			throw SQLiteCreateRecExc("Cannot create VerseItem record in verseItemsInsertRec()")
		} else {
			return insID
		}
	}

	// The VerseItems records for the current Chapter need to be read in order to set up the scrolling display of
	// VerseItem records that the user interacts with. These records need to be sorted in ascending order of itemOrder.

	fun readVerseItemsRecs (chap:Chapter) {
        this.db = this.getReadableDatabase()
        val sql1 = "SELECT itemID, chapterID, verseNumber, itemType, itemOrder, itemText, intSeq, isBridge, lastVsBridge FROM " + TAB_VerseItems
        val sql2 =  " WHERE " + COLF_ChapID + " = ? ORDER BY " + COL_ItemOrder
        val sql = sql1 + sql2
        val whArray = arrayOf<String>(chap.chID.toString())
        val cursor = db.rawQuery(sql, whArray)
        if (!cursor.moveToFirst()) {
        	throw SQLiteReadRecExc("Cannot read VerseItem records in readVerseItemsRecs()")
		} else {
			do {
				val itemID = cursor.getInt(0)
				val chapID = cursor.getInt(1)
				val vsNum = cursor.getInt(2)
				val itTyp = cursor.getString(3)
				val itOrd = cursor.getInt(4)
				val itTxt = cursor.getString(5)
				val intSeq = cursor.getInt(6)
				val isBrg = if (cursor.getInt(7) == 1) true else false
				val lvBrg = cursor.getInt(8)
				KITApp.chInst!!.appendItemToArray(
					itemID,
					chapID,
					vsNum,
					itTyp,
					itOrd,
					itTxt,
					intSeq,
					isBrg,
					lvBrg
				)
			} while (cursor.moveToNext())
			cursor.close()
		}
	}

	// The text of a VerseItem record in the EditChapterActivity needs to be saved to kdb.sqlite
	//	* when the user selects a different VerseItem to work on
	//	* when the VerseItem cell scrolls outside the visible range
	//	* when various life cycle stages of the Activity or App are reached
	// returns true if successful

	fun itemsUpdateRecText (itID:Int, itTxt:String) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_ItemText, itTxt)
        val whArray = arrayOf<String>(itID.toString())
		val rows = db.update(TAB_VerseItems, cv, COL_ItemID + " = ?", whArray)
        if (rows != 1) {
        	throw SQLiteUpdateRecExc("Cannot update VerseItem record text in itemsUpdateRecText()")
		}
	}


	// When a verse is added to form (or extend) a bridge, the VerseItem record that is the head
	// of the bridge needs to be updated.
	fun itemsUpdateForBridge(itID:Int, itTxt:String, isBridge:Boolean, LastVsBr:Int) {
		this.db = this.getWritableDatabase()
		val cv = ContentValues()
		cv.put(COL_ItemText, itTxt)
        cv.put(COL_IsBridge, isBridge)
        cv.put(COL_LastVsBridge, LastVsBr)
        val whArray = arrayOf<String>(itID.toString())
		val rows = db.update(TAB_VerseItems, cv, COL_ItemID + " = ?", whArray)
		if (rows != 1) {
			throw SQLiteUpdateRecExc("Cannot update VerseItem record for Bridge in itemsUpdateForBridge()")
		}
	}

	// The VerseItem record for a publication VerseItem needs to be deleted when the user
	//	chooses to delete a publication item.
	// This function will also be called when the user chooses to bridge two verses
	//	(the contents of the second verse is appended to the first verse, the second verse
	//	text is put into a new BridgeItem, and then the second VerseItem is deleted.
	//	Unbridging follows the reverse procedure and the original second verse is
	//	re-created and the BridgeItem is deleted.
	// This function will also be called when the user deletes a Psalm Ascription because
	//	the translation being keyboarded does not include Ascriptions.
	// returns true if successful

	fun itemsDeleteRec (itID:Int) {
		this.db = this.getWritableDatabase()
		val whArray = arrayOf<String>(itID.toString())
		val result = db.delete(TAB_VerseItems, COL_ItemID + " = ?", whArray)
		if (!(result > 0)) {
			throw SQLiteDeleteRecExc("Cannot delete record in itemsDeleteRec()")
		}
	}

	//--------------------------------------------------------------------------------------------
	// BridgeItems data table

	// When a bridge is created a BridgeItem record is created to hold the following verse that is being appended
	// to the bridge. This is needed only if the user later undoes the bridge and the original following verse is
	// restored; otherwise the BridgeItem record just sits there out of the way of normal operations.
	// This function returns the rowID of the newly inserted record or -1 if insert fails

	fun bridgeInsertRec(itemID: Int, txtCurr: String, txtExtra: String) : Long {
        this.db = this.getWritableDatabase()
        val cv = ContentValues()
		cv.put(COLF_ItemID, itemID)
        cv.put(COL_TextCurrBridge, txtCurr)
        cv.put(COL_TextExtraVerse, txtExtra)
		val insID = db.insert(TAB_BridgeItems, null, cv)
		if (!(insID > 0L)) {
			throw SQLiteCreateRecExc("Cannot create Bridge record in bridgeInsertRec()")
		} else {
			return insID
		}
	}

	// When a bridge is being undone it is necessary to retrieve the record containing the original
	// following verse that is about to be restored. There may be more than one BridgeItems record
	// for the current VerseItem; the one that will be used during the unbridging is the most recent one.

	fun bridgeGetRecs(itemID:Int, chInst:Chapter) {
		this.db = this.getReadableDatabase()
		val sql = "SELECT bridgeID, textCurrBridge, textExtraVerse FROM BridgeItems WHERE itemID = ?1 ORDER BY bridgeID;"
		val whArray = arrayOf<String>(itemID.toString())
		val cursor = db.rawQuery(sql, whArray)
		if (!cursor.moveToFirst()) {
			throw SQLiteReadRecExc("Cannot read Bridge records in bridgeGetRecs()")
		} else {
			do {
				val bridgeID = cursor.getInt(0)
				val txtBrid = cursor.getString(1)
				val txtExtra = cursor.getString(2)
				chInst.appendItemToBridArray(bridgeID, txtBrid, txtExtra)
			} while (cursor.moveToNext())
			cursor.close()
		}
	}

	// When a bridge has been undone the BridgeItem record involved needs to be deleted

	fun bridgeDeleteRec(bridgeID:Int) {
		this.db = this.getWritableDatabase()
		val whArray = arrayOf<String>(bridgeID.toString())
		val result = db.delete(TAB_BridgeItems, COL_BridgeID + " = ?", whArray)
		if (!(result > 0)) {
			throw SQLiteDeleteRecExc("Cannot delete Bridge record in bridgeDeleteRec()")
		}
	}

	companion object {
        const val TAB_Bibles = "Bibles"
        const val COL_BibleID = "bibleID"
        const val COL_BibleName = "name"
        const val COL_BookRecsCr = "bookRecsCreated"
        const val COL_CurrentBook = "currBook"

        const val TAB_Books = "Books"
        const val COL_BookID = "bookID"
        const val COLF_BibID = "bibleID"
        const val COL_BookCode = "bookCode"
        const val COL_BookName = "bookName"
        const val COL_ChapRecsCr = "chapRecsCreated"
        const val COL_NumChaps = "numChaps"
        const val COL_CurrChID = "currChID"
		const val COL_CurrChNum = "currChNum"
		const val COL_USFMBookText = "USFMText"

        const val TAB_Chapters = "Chapters"
        const val COL_ChapterID = "chapterID"
        const val COLF_ChBibID = "bibleID"
        const val COLF_BookID = "bookID"
        const val COL_ChapNum = "chapterNumber"
        const val COL_ItemRecsCr = "itemRecsCreated"
        const val COL_NumVerses = "numVerses"
        const val COL_NumItems = "numItems"
        const val COL_CurrItem = "currItem"
		const val COL_CurrVsNum = "currVsNum"
        const val COL_USFMText = "USFMText"

        const val TAB_VerseItems = "VerseItems"
        const val COL_ItemID = "itemID"
        const val COLF_ChapID = "chapterID"
        const val COL_VerseNum = "verseNumber"
        const val COL_ItemType = "itemType"
        const val COL_ItemOrder = "itemOrder"
        const val COL_ItemText = "itemText"
        const val COL_IntSeq = "intSeq"
        const val COL_IsBridge = "isBridge"
        const val COL_LastVsBridge = "lastVsBridge"

        const val TAB_BridgeItems = "BridgeItems"
        const val COL_BridgeID = "bridgeID"
        const val COLF_ItemID = "itemID"
        const val COL_TextCurrBridge = "textCurrBridge"
        const val COL_TextExtraVerse = "textExtraVerse"
    }
}
