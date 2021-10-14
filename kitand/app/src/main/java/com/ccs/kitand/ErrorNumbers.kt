package com.ccs.kitand
//
//  ErrorNumbers.kt
//
//  Adapted by Graeme Costin on 31/8/21 from ErrorNumbers.swift.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

//	Error numbers from 100 to 199 are catastrophic and need the app to close
//	Error numbers from 200 to 299 may result in reduced capabilities but app should continue
//	Error numbers from 300 to 399 are minor and need not be reported to the user
//	Error numbers from 400 to 499 require waiting for remote operations; alert user and continue

	val NO_ERROR = 0			// no error

	val DB_crErr = 100			// Cannot create kdb.sqlite
	val DB_opErr = 101			// Cannot open kdb.sqlite
	val DB_clErr = 102			// Cannot close kdb.sqlite (close result was SQLITE_BUSY)
	val DBT_BibErr = 103		// Error creating Bibles table
	val DBT_BooErr = 104		// Error creating Books table
	val DBT_ChaErr = 105		// Error creating Chapters table
	val DBT_VseErr = 106		// Error creating VerseItems table
	val DBT_BrgErr = 107		// Error creating BridgeItems table
	val DBC_BibErr = 108		// Error creating Bible record
	val DBR_BibErr = 109		// Error reading Bible record
	val DBU_BibNErr = 110		// Error updating name of Bible
	val DBU_BibRErr = 111		// Error updating records created flag in Bible record
	val DBU_BibCErr = 112		// Error updating current Book in Bible record
	val DBC_BooErr = 113		// Error creating Book record into database
	val DBR_BooErr = 114		// Error reading Book record from database
	val DBU_BooErr = 115		// Error updating the record for this Book
	val DBC_ChaErr = 116		// Error creating Chapter record into database
	val DBR_ChaErr = 117		// Error reading Chapter record from database
	val DBC_VItErr = 118		// Error creating VerseItem record into database
	val DBR_VItErr = 119		// Error reading VerseItem record from database
	val DBU_ChaNItErr = 120		// Error updating numItems in Chapter record
	val DBU_ChaRcrErr = 121		// Error updating ItRcr in Chapter record
	val DBU_ChaCItGoErr = 122	// Error updating currIt for Go current item
	val DBU_ChaCItSeErr = 123	// Error updating currIt for Set current item
	val DBU_ChaCAscrErr = 124	// Error updating Chapter record for create Ascription
	val DBU_VItTxtErr = 126		// Error updating text of VerseItem record
	val DBC_VItCAscrErr = 127	// Error creating Item record for Ascription
	val DBD_VItDAscrErr = 128	// Error deleting Item record for Ascription
	val DBU_ChaPubErr = 129		// Error updating Chapter record for Pub item change
	val DBC_VItTitErr = 130		// Error creating VerseItem for Title
	val DBD_VItTitErr = 131		// Error deleting VerseItem for Title
	val DBC_VItPBfErr = 132		// Error creating VerseItem for Paragraph before
	val DBD_VItPBfErr = 133		// Error deleting VerseItem for Paragraph before
	val DBC_VItPInErr = 134		// Error creating VerseItem for ParaCont
	val DBD_VItPInErr = 135		// Error deleting VerseItem for ParaCont
	val DBC_VItVcoErr = 136		// Error creating VerseItem for VerseCont
	val DBD_VItVcoErr = 137		// Error deleting VerseItem for VerseCont
	val DBC_VItDBrErr = 138		// Error creating VerseItem during unbridge action
	val DBC_VItSHdErr = 139		// Error creating VerseItem for SubjHead
	val DBD_VItSHdErr = 140		// Error deleting VerseItem for SubjHead
	val DBC_VItPRfErr = 141		// Error creating VerseItem for ParlRef
	val DBD_VItPRfErr = 142		// Error deleting VerseItem for ParlRef
	val DBU_VItBItErr = 143		// Error updating VerseItem for bridging/unbridging
	val DBD_VItBItErr = 144		// Error deleting VerseItem for unbridging

	val DBC_VItITiErr = 145		// Error creating VerseItem for IntroTitle
	val DBD_VItITiErr = 146		// Error deleting VerseItem for IntroTitle
	val DBC_VItIHdErr = 147		// Error creating VerseItem for IntroSubj
	val DBD_VItIHdErr = 148		// Error deleting VerseItem for IntroSubj
	val DBC_VItIPaErr = 149		// Error creating VerseItem for IntroPara
	val DBD_VItIPaErr = 150		// Error deleting VerseItem for IntroPara

	val DBC_BItErr = 151		// Error creating BridgeItem record
	val DBR_BItErr = 152		// Error reading BridgeItem record from database
	val DBD_BItErr = 153		// Error deleting BridgeItem record

	val DBU_ChaUSFMErr = 154	// Error updating USFM text in Chapter record

	val DBC_PopErr = 155		// Error creating a record during popover menu actions
	val DBR_PopErr = 156		// Error reading a record during popover menu actions
	val DBU_PopErr = 157		// Error updating a record during popover menu actions
	val DBD_PopErr = 158		// Error deleting a record during popover menu actions

	val DB_UnexpErr = 199		// Unexpected SQLite database error
