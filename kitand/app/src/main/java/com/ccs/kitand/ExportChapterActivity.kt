package com.ccs.kitand

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.ActionBar

//  Created by Graeme Costin on 2MAY20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class ExportChapterActivity : AppCompatActivity() {

	private lateinit var ch_name:String
	private lateinit var ps_name:String
	lateinit var txt_USFM: TextView
	var bkInst: Book? = null

	var suppActionBar: ActionBar? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.activity_exportchapter)

		// Get access to the SupportActionBar
		suppActionBar = getSupportActionBar()

		// Provide a Back button
		suppActionBar?.setDisplayHomeAsUpEnabled(true)

		// Get references to layout widgets
		txt_USFM = findViewById(R.id.txt_usfm)
		bkInst = KITApp.bkInst

		// Get names for prompt string
		ch_name = KITApp.res.getString(R.string.nm_chapter)
		ps_name = KITApp.res.getString(R.string.nm_psalm)
	}

	override fun onStart() {
		super.onStart()
		val bibName = KITApp.bibInst.bibName
		val chNumStr = KITApp.chInst!!.chNum.toString()
		val prompt = if (bkInst!!.bkID == 19)
			" " + ps_name + " " + chNumStr else
			" " + ch_name + " " + chNumStr + " of " + bkInst!!.bkName
		val actionBarTitle = bibName + prompt
		if (suppActionBar != null) {
			suppActionBar?.setDisplayShowTitleEnabled(true)
			suppActionBar?.setTitle(actionBarTitle)
		}
	}

	override fun onResume() {
		super.onResume()
		// Generate the USFM text
		val USFMexp = KITApp.chInst!!.calcUSFMExportText()
		// Display it to the user
		txt_USFM.setText(USFMexp)
		// Save it into the current Chapter record of kdb.sqlite
		try {
			KITApp.chInst!!.saveUSFMText (KITApp.chInst!!.chID, USFMexp)
		} catch (e:SQLiteUpdateRecExc) {
			KITApp.ReportError(DBU_ChaUSFMErr, e.message + "\nonResume()\nExportChapterActivity", this)
		}
	}
}