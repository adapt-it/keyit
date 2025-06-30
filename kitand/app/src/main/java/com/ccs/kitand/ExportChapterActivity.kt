package com.ccs.kitand

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import android.widget.TextView
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.FileProvider
import androidx.core.content.FileProvider.getUriForFile
//import kotlinx.android.synthetic.main.activity_exportchapter.*
import java.io.File
import java.io.FileWriter

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
	lateinit var txt_chex_prompt: TextView
	var bInst: Bible? = null
	var bkInst: Book? = null

	var suppActionBar: ActionBar? = null

	// Variable to hold the USFM generated for the Chapter
	var USFMexp: String = ""

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.activity_exportchapter)

		// Get access to the SupportActionBar
		suppActionBar = getSupportActionBar()

		// Provide a Back button
		suppActionBar?.setDisplayHomeAsUpEnabled(true)

		// Get references to layout widgets
		txt_USFM = findViewById(R.id.txt_usfm)
		txt_chex_prompt = findViewById(R.id.txt_chex_prompt)
		bInst = KITApp.bibInst
		bkInst = KITApp.bkInst

		// Get names for prompt string
		ch_name = KITApp.res.getString(R.string.nm_chapter)
		ps_name = KITApp.res.getString(R.string.nm_psalm)
	}

	override fun onCreateOptionsMenu(menu: Menu): Boolean {
		val inflater: MenuInflater = menuInflater
		inflater.inflate(R.menu.exportchaptermenu, menu)
		return true
	}

	override fun onStart() {
		super.onStart()
		val bibName = bInst!!.bibName
		val chNumStr = KITApp.chInst!!.chNum.toString()
		val prompt = (if (bkInst!!.bkID == 19)
			" " + ps_name + " " + chNumStr else
			" " + ch_name + " " + chNumStr + " of " + bkInst!!.bkName) + " USFM"
		txt_chex_prompt.setText(prompt)
		val actionBarTitle = "Key It " + bibName
		if (suppActionBar != null) {
			suppActionBar?.setDisplayShowTitleEnabled(true)
			suppActionBar?.setTitle(actionBarTitle)
		}
	}

	override fun onResume() {
		super.onResume()
		// Generate the USFM text
		USFMexp = KITApp.chInst!!.calcUSFMExportText()
		// Display it to the user
		txt_USFM.setText(USFMexp)
	}

	// The Android system's Action Bar calls this function when the user taps
	// either the Back button or the Export button
	override fun onOptionsItemSelected(item: MenuItem): Boolean {
		when (item.getItemId()) {
			android.R.id.home -> onBackPressed()
			R.id.toAIM -> sendToAIM()
		}
		return true
	}

	private fun sendToAIM() {
		// Save it into the current Chapter record of kdb.sqlite
		try {
			KITApp.chInst!!.saveUSFMText (KITApp.chInst!!.chID, USFMexp)
		} catch (e:SQLiteUpdateRecExc) {
			KITApp.ReportError(DBU_ChaUSFMErr, e.message + "\nonResume()\nExportChapterActivity", this)
		}
		// Save it to a .usfm text file
		val usfmPath = filesDir.absolutePath + File.separator + "usfm"
		val usfmDir = File(usfmPath)
		if (!usfmDir.exists()) {
			usfmDir.mkdirs()
		}

		val filename = KITApp.bibInst!!.bibName + "-" + KITApp.bkInst!!.bkName + "-" + "Ch" + KITApp.chInst!!.chNum.toString() + ".usfm"
		try {
			val usfmFile = File(usfmPath, filename)
			val writer = FileWriter(usfmFile)
			writer.append(USFMexp)
			writer.flush()
			writer.close()

			// Use the FileProvider to get a content URI
			val contentUri = getUriForFile(this, "com.ccs.kitand.fileprovider", usfmFile)

			val exportIntent = Intent().apply {
				action = Intent.ACTION_SEND
				putExtra(Intent.EXTRA_STREAM, contentUri)
				type = "text/plain"
			}
			exportIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
			exportIntent.setDataAndType(contentUri, contentResolver.getType(contentUri))
			startActivity(exportIntent)
		} catch (e: Exception) {
			e.printStackTrace()
		}
	}
}
