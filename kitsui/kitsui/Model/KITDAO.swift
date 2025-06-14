//
//  KITDAO.swift
//  kitios
//
//	All interaction between the running app and the SQLite database is handled by this class.
//	The data model of the app (an instance of the Bibles class) treats the SQLite database as
//  a software object with interaction via the member functions of the KITDAO class which is
//  named from the phrase KIT Data Access Object.
//
//	Parameters passed to KITDAO's functions are in the natural types for the programming
//	language of the rest of the app; any conversion to or from data types that SQLite requires
//	is handled within this class.
//
//	This class is instantiated by the data model at the launching of the app and it opens a
//  connection to the database, keeps that connection in the instance property db and retains
//  it until the app terminates. Only one instance of the class is used.
//
//  ??? In KITDAO.swift, a single Bible database record is created with default initial values.
//
//	Error Handling: The SQLite errors that may be encountered by the functions in KITDAO are
//	sufficiently serious that continued operation of the app if they occur doesn't make sense.
//	They will also be extremely rare and would be either a result of a bug that the programmer
//	had not caught before release(!!) or else running out of memory in the smartphone in which
//	the app is running. In the case of memory errors, about all that can be done is for the user
//	to restart the app; that is why the action taken with these errors is to simply show an
//	error number and exit the app. Thus the first four errors in the enum SQLiteError are not
//	used. If a later version of this app uses an SQL database on LAN or Internet there may be
//	reason to make more use of errors - for example, failure to open or create the database
//	may be followed by a prompt to the user to check the SQL server and try again.
//
//	TODO: Check whether interruption of the app (such as by a phone call coming to the
//	smartphone) needs the database connection to be closed and then reopened when the app
//	returns to the foreground.
//
//	GDLC 18NOV23 Adjustments of commentary to suit use in kitsui
//	GDLC 6AUG21 Started adding SQLite Swift error handling
//	GDLC 26JUL21 Prep for release (print commands removed, etc.).
//	GDLC 1JUL21 Added currVsNum to Chapters table
//  GDLC 21SEP20	Simplified serveral true/false returns from
//		return (result == 0 ? true : false) to return (result == 0)
//
//  Created by Graeme Costin on 16SEP19.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import Foundation
import SwiftUI

// TODO: Is this enum still needed?
enum SQLiteError: Error {
	case cannotCreateDatabase
	case cannotOpenDatabase
	case cannotCloseDatabase
	case cannotCreateTable(tableName: String)
	case cannotCreateRecord
	case cannotReadRecord
	case cannotUpdateRecord
	case cannotDeleteRecord
}

public class KITDAO: ObservableObject {
//    var bibInst: Bible? // During the launch of KIT an instance of the class Bible will be created REALLY???
                        // This is the strong ref to bibInst which lasts for the entire run of the app

//    var databaseAvail:Bool = false
    let dbName = "kdb.sqlite"
	let dirManager = FileManager.default
	var db: OpaquePointer?

	internal let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

	init() {
        let docsDir:URL = FileManager.default.urls (for: .documentDirectory, in: .userDomainMask).first!
        let kdbPath:URL = docsDir.appendingPathComponent ("kdb.sqlite")
        if !FileManager.default.fileExists(atPath: kdbPath.path) {
            let errNo = createAndOpenDatabase(kdbPath)
                if errNo != 0 {
                        // If the database kdb.sqlite cannot be created report to user and then exit the app
                    ReportError(errNo)
                }
        } else {
            // Open kdb.sqlite database
            if sqlite3_open(kdbPath.absoluteString.cString(using: String.Encoding.utf8)!, &db) != SQLITE_OK {
                // If the database kdb.sqlite cannot be opened report to user and then exit the app
                ReportError(DB_opErr)
            }
        }
	}
	
	// Ensure that the kdb.sqlite database is closed
	deinit {
		if sqlite3_close(db) == SQLITE_BUSY {
			// If the database kdb.sqlite cannot be closed report to user and then exit the app
			ReportError(DB_clErr)
		}
	}
	
	// Function for reporting error conditions to the user and exiting the app
	func ReportError (_ errNo:Int) {
		var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
		topWindow?.rootViewController = UIViewController()
		topWindow?.windowLevel = UIWindow.Level.alert + 1

		let alert = UIAlertController(title: "Fatal Error", message: "Please report Error No. \(errNo) to the developers", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
			// At present only fatal errors are considered; if non-fatal errors are handled
			// additional code can be put in here so that KIT continues after the user has
			// clicked OK to the warning
			exit(0)

			// Next two lines hide the window if KIT is to continue running
			// and also keeps a reference to the window until the action is invoked.
			topWindow?.isHidden = true    // Hide the window
			topWindow = nil                // Delete the topwindow
		 })
		
		topWindow?.makeKeyAndVisible()
		topWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}

	// Function for reporting an error warning to the user and allowing app to proceed
	func ReportWarning (_ errNo:Int) {
		var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
		topWindow?.rootViewController = UIViewController()
		topWindow?.windowLevel = UIWindow.Level.alert + 1

		let alert = UIAlertController(title: "Warning", message: "Error No. \(errNo) occurred", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
			// At present only fatal errors are considered; if non-fatal errors are handled
			// additional code can be put in here so that KIT continues after the user has
			// clicked OK to the warning

			// Next two lines hide the window if KIT is to continue running
			// and also keeps a reference to the window until the action is invoked.
			topWindow?.isHidden = true    // Hide the window
			topWindow = nil                // Delete the topwindow
		 })
		
		topWindow?.makeKeyAndVisible()
		topWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}

	//--------------------------------------------------------------------------------------------
	//	Create and open kdb.sqlite database
	//
	//	On the first launch there will not be a kdb.sqlite file in the Documents directory, so
	//	this function will be called to create it.
	//	Returns zero on success, non-zero error number if error occurs creating the database
	
	func createAndOpenDatabase (_ path:URL) -> Int {
		// Create an empty kdb.sqlite
		if sqlite3_open(path.absoluteString.cString(using: String.Encoding.utf8)!, &db) != SQLITE_OK {
			return DB_crErr
		}
		// Create the Bibles table
		var sqlite3_stmt:OpaquePointer?=nil
		var sql:String = "CREATE TABLE Bibles(bibleID INTEGER PRIMARY KEY, name TEXT, bookRecsCreated INTEGER, currBook  INTEGER);"
		var nByte:Int32 = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		var result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			return DBT_BibErr
		}
		// Create the Books table
		sqlite3_stmt = nil
		sql = "CREATE TABLE Books(bookID INTEGER, bibleID INTEGER, bookCode TEXT, bookName TEXT, chapRecsCreated INTEGER, numChaps INTEGER, currChID  INTEGER, currChNum INTEGER, USFMText TEXT);"
		nByte = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			return DBT_BooErr
		}
		// Create the Chapters table
		sqlite3_stmt = nil
		sql = "CREATE TABLE Chapters(chapterID INTEGER PRIMARY KEY, bibleID INTEGER, bookID INTEGER, chapterNumber INTEGER, itemRecsCreated INTEGER, numVerses INTEGER, numItems INTEGER, currItem INTEGER, currVsNum INTEGER, USFMText TEXT);"
		nByte = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			return DBT_ChaErr
		}
		// Create the VerseItems table
		sqlite3_stmt = nil
		sql = "CREATE TABLE VerseItems(itemID INTEGER PRIMARY KEY, chapterID INTEGER, verseNumber INTEGER, itemType TEXT, itemOrder INTEGER, itemText TEXT, intSeq INTEGER, isBridge INTEGER, lastVsBridge INTEGER);"
		nByte = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			return DBT_VseErr
		}
		// Create the BridgeItems table
		sqlite3_stmt = nil
		sql = "CREATE TABLE BridgeItems(bridgeID INTEGER PRIMARY KEY, itemID INTEGER, textCurrBridge TEXT, textExtraVerse TEXT);"
		nByte = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_step(sqlite3_stmt)
		result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			return DBT_BrgErr
		}
		return 0
	}

	//--------------------------------------------------------------------------------------------
	//	Bibles data table

	// The single record in the Bibles table needs to be inserted when the app first launches.
	// A future extension of KIT may allow more than one Bible, so this function
	// may be called more than once.

	func bibleInsertRec (_ bibID:Int, _ bibName:String, _ bkRCr:Bool, _ currBook:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO Bibles(bibleID, name, bookRecsCreated, currBook) VALUES(?, ?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_text(sqlite3_stmt, 2, bibName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_int(sqlite3_stmt, 3, Int32((bkRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(currBook))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBC_BibErr)
			return
		}
	}
	
	// Get the Bible record for bID.
	// If there is a database error reports the error and exits app, otherwise
	// returns a tuple with values from the record if there is a record for that bibID, or
	// returns a tuple with 0 for the bibID if there are no more records.

	func bibleGetRec (_ bID:Int) -> (bibID:Int, bibName:String, bkRCr:Bool, currBk:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT bibleID, name, bookRecsCreated, currBook FROM Bibles WHERE bibleID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bID))
		let result = sqlite3_step(sqlite3_stmt)
		if result == SQLITE_ERROR {
			// If the Bible record cannot be read, report error code
			ReportError(DBR_BibErr)
			return (-1, "", false, 0)
		} else if result == SQLITE_DONE {
			return (0, "", false, 0)
		} else {
			// Unpack the data
			let bID = Int(sqlite3_column_int(sqlite3_stmt, 0))
			let bNamep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 1)
			let bNamen = Int(sqlite3_column_bytes(sqlite3_stmt,1))
			let data = Data(bytes: bNamep!, count: Int(bNamen))
			let str = String(data: data, encoding: String.Encoding.utf8)
			let bkC = Int(sqlite3_column_int(sqlite3_stmt, 2))
			let cBk = Int(sqlite3_column_int(sqlite3_stmt, 3))
			sqlite3_finalize(sqlite3_stmt)
			return (bID, str!, (bkC > 0 ? true : false), cBk)
		}
	}

	// The Bible record needs to be updated
	//  * to set a new name for the Bible at the user's command
	//	* to set the flag that indicates that the Books records have been created (on first launch)
	//	* to change the current Book whenever the user selects a different Book to work on

	func bibleUpdateName (_ currBib:Int, _ bibName:String) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET name = ?2 WHERE bibleID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)
				
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(currBib))
		sqlite3_bind_text(sqlite3_stmt, 2, bibName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_BibNErr)
		}
	}

	// The bookRecsCreated flag starts as false and is changed to true during the first launch;
	// it is never changed back to false, and so this function does not need any parameters.
	func bibleUpdateRecsCreated (_ currBib:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET bookRecsCreated = 1 WHERE bibleID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(currBib))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_BibRErr)
		}
	}

	// This function needs an Integer parameter for the current Book
	func bibleUpdateCurrBook (_ currBib:Int, _ bookID: Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Bibles SET currBook = ?2 WHERE bibleID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(currBib))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bookID))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_BibCErr)
		}
	}

	//--------------------------------------------------------------------------------------------
	//	Books data table

	// The 66 records for the Books table need to be created and populated on the initial launch of the app
	// This function will be called 66 times by the KIT software
	
	func booksInsertRec (_ bkID:Int,_ bibID:Int, _ bkCode:String, _ bkName:String, _ chRCr:Bool, _ numCh:Int, _ curChID:Int, _ curChNum:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO Books(bookID, bibleID, bookCode, bookName, chapRecsCreated, numChaps, currChID, currChNum, USFMText) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)
		let USFM:String = ""
		
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bibID))
		sqlite3_bind_text(sqlite3_stmt, 3, bkCode.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_text(sqlite3_stmt, 4, bkName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_int(sqlite3_stmt, 5, Int32((chRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 6, Int32(numCh))
		sqlite3_bind_int(sqlite3_stmt, 7, Int32(curChID))
		sqlite3_bind_int(sqlite3_stmt, 8, Int32(curChNum))
		sqlite3_bind_text(sqlite3_stmt, 9, USFM.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBC_BooErr)
		}
	}

	// The Books records need to be read to populate the array of books for the Bible bib
	// that the user can choose from. They need to be sorted in ascending order of the UBS
	// assigned bookID.
	func readBooksRecs (bibInst: Bible) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT bookID, bibleID, bookCode, bookName, chapRecsCreated, numChaps, currChID, currChNum, USFMText FROM Books WHERE bibleID = ?1 ORDER BY bookID;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibInst.bibleID))
		var result:Int32 = 0
		repeat {
			result = sqlite3_step(sqlite3_stmt)
			if result == SQLITE_ERROR {
				ReportError(DBR_BooErr)
			}
			if result == SQLITE_ROW {
				// convert fields as needed
				let bkID = Int(sqlite3_column_int(sqlite3_stmt, 0))
				let bibID = Int(sqlite3_column_int(sqlite3_stmt, 1))
				let bCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 2)
				let bCoden = Int(sqlite3_column_bytes(sqlite3_stmt,2))
				let dCode = Data(bytes: bCodep!, count: Int(bCoden))
				let sCode = String(data: dCode, encoding: String.Encoding.utf8)
				let bNamep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 3)
				let bNamen = Int(sqlite3_column_bytes(sqlite3_stmt,3))
				let dName = Data(bytes: bNamep!, count: Int(bNamen))
				let sName = String(data: dName, encoding: String.Encoding.utf8)
				let cRC = Int(sqlite3_column_int(sqlite3_stmt, 4))
				let chRCr = (cRC == 0 ? false : true)
				let numCh = Int(sqlite3_column_int(sqlite3_stmt, 5))
				let curChID = Int(sqlite3_column_int(sqlite3_stmt, 6))
				let curChNum = Int(sqlite3_column_int(sqlite3_stmt, 7))
				let bUSFMp: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 8)
				let bUSFMn = Int(sqlite3_column_bytes(sqlite3_stmt,8))
				let dUSFMn = Data(bytes: bUSFMp!, count: Int(bUSFMn))
				let USFMt = String(data: dUSFMn, encoding: String.Encoding.utf8)

				bibInst.appendBibBookToArray(bkID, bibID, sCode!, sName!, chRCr, numCh, curChID, curChNum, USFMt!)
			}
		} while (result != SQLITE_DONE)
		sqlite3_finalize(sqlite3_stmt)
	}

	// The Books record for the current Book needs to be updated
	//	* to set the flag that indicates that the Chapter records have been created (on first edit of that Book)
	//	* to set the number of Chapters in the Book (on first edit of that Book)
	//	* to change the current Chapter when the user selects a different Chapter to work on

	func booksUpdateRec (_ bibID:Int, _ bkID:Int, _ chRCr:Bool, _ numCh:Int, _ curChID:Int, _ curChNum:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Books SET chapRecsCreated = ?3, numChaps = ?4, currChID = ?5, currChNum = ?6 WHERE bibleID = ?1 AND bookID = ?2;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32((chRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(numCh))
		sqlite3_bind_int(sqlite3_stmt, 5, Int32(curChID))
		sqlite3_bind_int(sqlite3_stmt, 6, Int32(curChNum))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_BooErr)
		}
	}

	// The Books record for a Book needs to have its bookName updated after editing in CHoose Book scene

	func booksUpdateName (_ bibID:Int, _ bkID:Int, _ bkName:String) throws {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Books SET bookName = ?3 WHERE bibleID = ?1 AND bookID = ?2;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkID))
		sqlite3_bind_text(sqlite3_stmt, 3, bkName.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		guard result == 0 else {
			throw SQLiteError.cannotUpdateRecord
		}
	}


	//--------------------------------------------------------------------------------------------
	//	Chapters data table

	// The Chapters records for the current Book need to be created when the user first selects that Book to edit
	// This function will be called once by the KIT software for every Chapter in the current Book; it will be
	// called before any VerseItem Records have been created for the Chapter
	// Each Chapters record has an INTEGER PRIMARY KEY, chapterID, that is assigned automatically
	// by SQLite; this is not included in the insert record SQL.
	// The field for USFM is left empty until the user taps the "Export" button after
	// keyboarding enough to export.

	func chaptersInsertRec (_ bibID:Int, _ bkID:Int, _ chNum:Int, _ itRCr:Bool, _ numVs:Int, _ numIt:Int, _ currIt:Int, _ currVsNum:Int ) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO Chapters(bibleID, bookID, chapterNumber, itemRecsCreated, numVerses, numItems, currItem, currVsNum) VALUES(?, ?, ?, ?, ?, ?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkID))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(chNum))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32((itRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 5, Int32(numVs))
		sqlite3_bind_int(sqlite3_stmt, 6, Int32(numIt))
		sqlite3_bind_int(sqlite3_stmt, 7, Int32(currIt))
		sqlite3_bind_int(sqlite3_stmt, 8, Int32(currIt))

		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBC_ChaErr)
		}
	}

	// The Chapters records for the currently selected Book need to be read to populate the array
	// of Chapters for the Book bkInst that the user can choose from. The records need to be sorted
	// in ascending order of chapterNumber
	func readChaptersRecs (_ bibID:Int,_ bkInst:Book) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT chapterID, bibleID, bookID, chapterNumber, itemRecsCreated, numVerses, numItems, currItem, currVsNum FROM Chapters WHERE bibleID = ?1 AND bookID = ?2 ORDER BY chapterNumber;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bibID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(bkInst.bkID))
		var result:Int32 = 0
		repeat {
			result = sqlite3_step(sqlite3_stmt)
			if result == SQLITE_ERROR {
				ReportError(DBR_ChaErr)
			}
			if result == SQLITE_ROW {
				// convert fields as needed
				let chapID = Int(sqlite3_column_int(sqlite3_stmt, 0))
				let bibID = Int(sqlite3_column_int(sqlite3_stmt, 1))
				let bookID = Int(sqlite3_column_int(sqlite3_stmt, 2))
				let chNum = Int(sqlite3_column_int(sqlite3_stmt, 3))
				let itRC = Int(sqlite3_column_int(sqlite3_stmt, 4))
				let itRCr = (itRC == 0 ? false : true)
				let numVs = Int(sqlite3_column_int(sqlite3_stmt, 5))
				let numIt = Int(sqlite3_column_int(sqlite3_stmt, 6))
				let curIt = Int(sqlite3_column_int(sqlite3_stmt, 7))
				let curVN = Int(sqlite3_column_int(sqlite3_stmt, 8))

				bkInst.appendChapterToArray(chapID, bibID, bookID, chNum, itRCr, numVs, numIt, curIt, curVN)
			}
		} while (result != SQLITE_DONE)
		sqlite3_finalize(sqlite3_stmt)
	}

	// The Chapters record for the current Chapter needs to be updated
	//	* to set the flag that indicates that the VerseItem records have been created (on first edit of that Chapter)
	//	* to change the current VerseItem when the user selects a different VerseItem to work on

	func chaptersUpdateRec (_ chID:Int, _ itRCr:Bool, _ currIt:Int, _ currVN:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Chapters SET itemRecsCreated = ?2, currItem = ?3, currVsNum = ?4 WHERE chapterID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32((itRCr ? 1 : 0)))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(currIt))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(currVN))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		// TODO: Improve so that errors updating records created and current VerseItem are distinguished
		if result != 0 {
			ReportError(DBU_ChaRcrErr)	// DBU_ChaCItGoErr
		}
	}

	// The Chapters record for the current Chapter needs to be updated after changes to the publication items:
	//	* to change the number of VerseItems
	//	* to change the current VerseItem after one has been deleted or inserted.

	func chaptersUpdateRecPub (_ chID:Int, _ numIt:Int, _ currIt:Int, _ currVN:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Chapters SET numItems = ?2, currItem = ?3, currVsNum = ?4 WHERE chapterID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
		sqlite3_bind_int(sqlite3_stmt, 2, Int32(numIt))
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(currIt))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(currVN))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_ChaPubErr)
		}
	}

	// Set the value of the field USFMText when the Export scene is used
	func updateUSFMText (_ chID:Int, _ text:String) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE Chapters SET USFMText = ?2 WHERE chapterID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
		sqlite3_bind_text(sqlite3_stmt, 2, text.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_ChaUSFMErr)
		}
	}

	// TODO: Implement a function to retrieve the value of the USFMText field when needed???

	//--------------------------------------------------------------------------------------------
	//	VerseItems data table

	// The VerseItems records for the current Chapter need to be created when the user first selects that Chapter
	// This function will be called once by the KIT software for every VerseItem in the current Chapter
	// It will also be called
	//	* when the user chooses to insert a publication VerseItem
	//	* when the user chooses to undo a verse bridge
	// This function returns the rowID of the newly inserted record or
	// throws SQLiteError.cannotCreateRecord if the insert fails.

	func verseItemsInsertRec (_ chID:Int, _ vsNum:Int, _ itTyp:String, _ itOrd:Int, _ itText:String,
							  _ intSeq:Int, _ isBrid:Bool, _ lastVsBridge:Int) -> Int {
			var sqlite3_stmt:OpaquePointer?=nil
			let sql:String = "INSERT INTO VerseItems(chapterID, verseNumber, itemType, itemOrder, itemText, intSeq, isBridge, lastVsBridge) VALUES(?, ?, ?, ?, ?, ?, ?, ?);"
			let nByte:Int32 = Int32(sql.utf8.count)

			sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
			sqlite3_bind_int(sqlite3_stmt, 1, Int32(chID))
			sqlite3_bind_int(sqlite3_stmt, 2, Int32(vsNum))
			sqlite3_bind_text(sqlite3_stmt, 3, itTyp.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
			sqlite3_bind_int(sqlite3_stmt, 4, Int32(itOrd))
			sqlite3_bind_text(sqlite3_stmt, 5, itText.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
			sqlite3_bind_int(sqlite3_stmt, 6, Int32(intSeq))
			sqlite3_bind_int(sqlite3_stmt, 7, Int32((isBrid ? 1 : 0)))
			sqlite3_bind_int(sqlite3_stmt, 8, Int32(lastVsBridge))
			sqlite3_step(sqlite3_stmt)
			let result = sqlite3_finalize(sqlite3_stmt)
			if result != 0 {
				var errNum = DBC_VItErr
				switch itTyp {
				case "Ascription": errNum = DBC_VItCAscrErr
				case "Title": errNum = DBC_VItTitErr
				case "Para": errNum = DBC_VItPBfErr
				case "ParaCont": errNum = DBC_VItPInErr
				case "VerseCont": errNum = DBC_VItVcoErr
				case "Heading": errNum = DBC_VItSHdErr
				case "ParlRef": errNum = DBC_VItPRfErr
				case "Verse": errNum = DBC_VItDBrErr
				case "InTitle": errNum = DBC_VItITiErr
				case "InSubj": errNum = DBC_VItIHdErr
				case "InPara": errNum = DBC_VItIPaErr
				default: errNum = DB_UnexpErr
				}
				ReportError(errNum)
			}
			return Int(sqlite3_last_insert_rowid(db))
		}

	// The VerseItems records for the current Chapter needs to be read in order to set up the scrolling
	// display of VerseItem records that the user interacts with. These records need to be sorted in
	// ascending order of itemOrder.

	func readVerseItemsRecs (_ chInst:Chapter) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT itemID, chapterID, verseNumber, itemType, itemOrder, itemText, intSeq, isBridge, lastVsBridge FROM VerseItems WHERE chapterID = ?1 ORDER BY itemOrder;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(chInst.chID))
		var result:Int32 = 0
		repeat {
			result = sqlite3_step(sqlite3_stmt)
			if result == SQLITE_ERROR {
				ReportError(DBR_VItErr)
			}
			if result == SQLITE_ROW {
				// convert fields as needed
				let itID = Int(sqlite3_column_int(sqlite3_stmt, 0))
				let chID = Int(sqlite3_column_int(sqlite3_stmt, 1))
				let vsNum = Int(sqlite3_column_int(sqlite3_stmt, 2))
				let bCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 3)
				let bCoden = Int(sqlite3_column_bytes(sqlite3_stmt,3))
				let dCode = Data(bytes: bCodep!, count: Int(bCoden))
				let itTyp = String(data: dCode, encoding: String.Encoding.utf8)!
				let itOrd = Int(sqlite3_column_int(sqlite3_stmt, 4))
				let cCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 5)
				let cCoden = Int(sqlite3_column_bytes(sqlite3_stmt,5))
				let cCode = Data(bytes: cCodep!, count: Int(cCoden))
				let itText = String(data: cCode, encoding: String.Encoding.utf8)!
				let intSeq = Int(sqlite3_column_int(sqlite3_stmt, 6))
				let isBr = Int(sqlite3_column_int(sqlite3_stmt, 7))
				let isBrg = (isBr == 0 ? false : true)
				let lvBrg = Int(sqlite3_column_int(sqlite3_stmt, 8))

				chInst.appendItemToArray(itID, chID, vsNum, itTyp, itOrd, itText, intSeq, isBrg, lvBrg)
			}
		} while (result != SQLITE_DONE)
		sqlite3_finalize(sqlite3_stmt)
	}

	// NOT YET USERD - Delete?
	// Reads the single VerseItem record with the specified ItemID
	// Needed for itemsDeleteRec()	???
	
	func readVerseItemRecord (_ itID:Int) {
		
	}
	
	// The text of a VerseItem record in the UITableView needs to be saved to kdb.sqlite
	//	* when the user selects a different VerseItem to work on
	//	* when the VerseItem cell scrolls outside the visible range
	//	* when various life cycle stages of the View or App are reached
	// returns true if successful

	func itemsUpdateRecText (_ itID:Int, _ itTxt:String) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE VerseItems SET itemText = ?2 WHERE itemID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itID))
		sqlite3_bind_text(sqlite3_stmt, 2, itTxt.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_VItTxtErr)
		}
	}

	// When a verse is added to form (or extend) a bridge, the VerseItem record that is the head
	// of the bridge needs to be updated.
	func itemsUpdateForBridge(_ itID:Int, _ itTxt:String, _ isBridge:Bool, _ LastVsBr:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "UPDATE VerseItems SET itemText = ?2, isBridge = ?3, lastVsBridge = ?4 WHERE itemID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itID))
		sqlite3_bind_text(sqlite3_stmt, 2, itTxt.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_int(sqlite3_stmt, 3, Int32(isBridge ? 1 : 0))
		sqlite3_bind_int(sqlite3_stmt, 4, Int32(LastVsBr))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBU_VItBItErr)
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
	//	Exits with error number if unsuccessful.

	func itemsDeleteRec (_ itID:Int) {
		// Get the itemType of the record in case it is needed for choosing the error number
		var sqlite3_stmt:OpaquePointer? = nil
		var sql:String = "SELECT itemType FROM VerseItems WHERE itemID = ?1;"
		var nByte:Int32 = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itID))
		var result:Int32 = 0
		result = sqlite3_step(sqlite3_stmt)
		if result == SQLITE_ERROR {
			ReportError(DBR_VItErr)
		}
		let bCodep: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 0)
		let bCoden = Int(sqlite3_column_bytes(sqlite3_stmt,0))
		let dCode = Data(bytes: bCodep!, count: Int(bCoden))
		let itTyp = String(data: dCode, encoding: String.Encoding.utf8)!

		sqlite3_stmt = nil
		sql = "DELETE FROM VerseItems WHERE itemID = ?1;"
		nByte = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itID))
		sqlite3_step(sqlite3_stmt)
		result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			var errNum = 0
			switch itTyp {
			case "Ascription": errNum = DBD_VItDAscrErr
			case "Title": errNum = DBD_VItTitErr
			case "Para": errNum = DBD_VItPBfErr
			case "ParaCont": errNum = DBD_VItPInErr
			case "VerseCont": errNum = DBD_VItVcoErr
			case "Heading": errNum = DBD_VItSHdErr
			case "ParlRef": errNum = DBD_VItPRfErr
			case "Verse": errNum = DBD_VItBItErr
			case "InTitle": errNum = DBD_VItITiErr
			case "InSubj": errNum = DBD_VItIHdErr
			case "InPara": errNum = DBD_VItIPaErr
			default: errNum = DB_UnexpErr
			}
			ReportError(errNum)
		}
	}

	//--------------------------------------------------------------------------------------------
	// BridgeItems data table

	// When a bridge is created a BridgeItem record is created to hold the following verse that is being appended
	// to the bridge. This is needed only if the user later undoes the bridge and the original following verse is
	// restored; otherwise the BridgeItem record just sits there out of the way of normal operations.
	// This function returns the rowID of the newly inserted record or exits with error number if insert fails.

	func bridgeInsertRec(_ itemID: Int, _ txtCurr: String, _ txtExtra: String) -> Int {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "INSERT INTO BridgeItems(itemID, textCurrBridge, textExtraVerse) VALUES(?, ?, ?);"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itemID))
		sqlite3_bind_text(sqlite3_stmt, 2, txtCurr.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_bind_text(sqlite3_stmt, 3, txtExtra.cString(using:String.Encoding.utf8)!, -1, SQLITE_TRANSIENT)
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBC_BItErr)
		}
		return Int(sqlite3_last_insert_rowid(db))
	}

	// When a bridge is being undone it is necessary to retrieve the record containing the original
	// following verse that is about to be restored. There may be more than one BridgeItems record
	// for the current VerseItem; the one that will be used during the unbridging is the most recent one.

	func bridgeGetRecs(_ itemID:Int, _ chInst:Chapter) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "SELECT bridgeID, textCurrBridge, textExtraVerse FROM BridgeItems WHERE itemID = ?1 ORDER BY bridgeID;"
		let nByte:Int32 = Int32(sql.utf8.count)
		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(itemID))

		var result:Int32 = 0
		repeat {
			result = sqlite3_step(sqlite3_stmt)
			if result == SQLITE_ERROR {
				ReportError(DBR_BItErr)
			}
			if result == SQLITE_ROW {
				let bridgeID = Int(sqlite3_column_int(sqlite3_stmt, 0))
				let bBridp: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 1)
				let bBridn = Int(sqlite3_column_bytes(sqlite3_stmt,1))
				let dataBr = Data(bytes: bBridp!, count: Int(bBridn))
				let txtBrid = String(data: dataBr, encoding: String.Encoding.utf8)
				let bExtrap: UnsafePointer<UInt8>? = sqlite3_column_text(sqlite3_stmt, 2)
				let bExtran = Int(sqlite3_column_bytes(sqlite3_stmt,2))
				let dataEx = Data(bytes: bExtrap!, count: Int(bExtran))
				let txtExtra = String(data: dataEx, encoding: String.Encoding.utf8)
				chInst.appendItemToBridArray (bridgeID, txtBrid!, txtExtra!)
			}
		} while (result != SQLITE_DONE)
		sqlite3_finalize(sqlite3_stmt)
	}

	// When a bridge has been undone the BridgeItem record involved needs to be deleted

	func bridgeDeleteRec(_ bridgeID:Int) {
		var sqlite3_stmt:OpaquePointer?=nil
		let sql:String = "DELETE FROM BridgeItems WHERE bridgeID = ?1;"
		let nByte:Int32 = Int32(sql.utf8.count)

		sqlite3_prepare_v2(db, sql, nByte, &sqlite3_stmt, nil)
		sqlite3_bind_int(sqlite3_stmt, 1, Int32(bridgeID))
		sqlite3_step(sqlite3_stmt)
		let result = sqlite3_finalize(sqlite3_stmt)
		if result != 0 {
			ReportError(DBD_BItErr)
		}
	}
}
