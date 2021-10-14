package com.ccs.kitand

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.view.MenuItem
import android.view.ViewTreeObserver
import android.widget.TextView
import androidx.appcompat.app.ActionBar
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

//	This is the ChooseChapterActivity that allows the user to select the Chapter. This Activity
//	will be entered	after the current Book is selected and set up, and so it will have available
//	the array of Chapters for the current Book.
//
//  Created by Graeme Costin on 15OCT20?
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class ChooseChapterActivity : AppCompatActivity() {

	// Boolean for whether to let the user choose a Chapter
	var letUserChooseChapter = false	// Will be set from bkInst.canChooseAnotherChapter

	lateinit var txt_ch_prompt: TextView
	lateinit var lst_chapters: RecyclerView
	lateinit var recyclerView: RecyclerView
	lateinit var viewAdapter: ChapterAdapter
	private lateinit var viewManager: RecyclerView.LayoutManager
	lateinit var ch_name: String
	lateinit var ps_name: String
	lateinit var chOrPsName: String
	var bkInst: Book? = null

	// tableRow of the selected Chapter
	// chRow = -1 means that no Chapter has been selected yet
	// chRow is used when determining whether the user had chosen a different Chapter from before
	var chRow = -1

	var suppActionBar: ActionBar? = null

	// Layout height for calculating scrolling offset
	var layout_height = 0

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.activity_choosechapter)

		// Get access to the SupportActionBar
		suppActionBar = getSupportActionBar()

		// Provide a Back button
		suppActionBar?.setDisplayHomeAsUpEnabled(true)

		// Get references to layout widgets
		txt_ch_prompt = findViewById(R.id.txt_ch_prompt)
		lst_chapters = findViewById(R.id.lst_chapters)
		ch_name = KITApp.res.getString(R.string.nm_chapter)
		ps_name = KITApp.res.getString(R.string.nm_psalm)
		bkInst = KITApp.bkInst
		if (bkInst!!.bkID == 19) {
			chOrPsName = ps_name
		} else {
			chOrPsName = ch_name
		}
	}

	override fun onStart() {
		super.onStart()

		val bibName = KITApp.bibInst.bibName
		bkInst = KITApp.bkInst
		val actionBarTitle = "Key It  -  " + bibName
		if (suppActionBar != null) {
			suppActionBar?.setDisplayShowTitleEnabled(true)
			suppActionBar?.setTitle(actionBarTitle)
		}
	}

	override fun onResume() {
		super.onResume()
		// Set flag for when user comes back to choose another chapter
		letUserChooseChapter = bkInst!!.canChooseAnotherChapter
		// Most launches will have a current Chapter and will go straight to it
		if (!letUserChooseChapter && bkInst!!.curChID > 0) {
			try {
				bkInst!!.goCurrentChapter()
				// Creates an instance for the current Book (from kdb.sqlite)
				// If the user comes back to the Choose Book scene we need to let him choose again
				bkInst!!.canChooseAnotherChapter = true
				// Go to the EditChapterActivity
				val i = Intent(this, EditChapterActivity::class.java)
				startActivity(i)
				// Dispose of ChooseChapterActivity to reduce memory usage
				finish()
			} catch (e:SQLiteUpdateRecExc) {
				KITApp.ReportError(DBU_BooErr, e.message + "\nonResume()\nChooseChapterActivity", this)
			}
		} else {

			// On first launch, and when user wants to choose another chapter,
			// do nothing and wait for the user to choose a Chapter.
			val prompt =
				if (bkInst!!.bkID == 19) "Choose " + ps_name else "Choose " + ch_name + " of " + bkInst!!.bkName
			txt_ch_prompt.setText(prompt)
			viewManager = LinearLayoutManager(this)
			viewAdapter = ChapterAdapter(bkInst!!.BibChaps, this) as ChapterAdapter
			recyclerView = findViewById<RecyclerView>(R.id.lst_chapters).apply {
				// use this setting to improve performance if you know that changes
				// in content do not change the layout size of the RecyclerView
				setHasFixedSize(true)
				// use a linear layout manager
				layoutManager = viewManager
				// specify a viewAdapter
				adapter = viewAdapter
			}

			recyclerView.getViewTreeObserver().addOnPreDrawListener(object :
				ViewTreeObserver.OnPreDrawListener {
				override fun onPreDraw(): Boolean {
					if (recyclerView.getChildCount() > 0) {
						// Remove the listener to avoid continually triggering this code - once is enough.
						recyclerView.viewTreeObserver.removeOnPreDrawListener(this)
						// Get the height of the layout
						layout_height = recyclerView.getMeasuredHeight()
						(viewManager as LinearLayoutManager).scrollToPositionWithOffset(bkInst!!.currChapOfst, layout_height/2)
						return true
					}
					return false
				}
			})
		}
	}

	override fun onOptionsItemSelected(item: MenuItem): Boolean {
		when (item.getItemId()) {
			android.R.id.home -> onBackPressed()
		}
		return true
	}

	override fun onBackPressed() {
		goToBooks()
	}

	private fun goToBooks() {
		// Go to the ChooseBookActivity
		val i = Intent(this, ChooseBookActivity::class.java)
		startActivity(i)
		// Dispose of ChooseChapterActivity to reduce memory usage
		finish()
	}

	fun chooseChapterAction(position:Int) {
		val chRowNew = position
		chRow = chRowNew
		// Set up the selected Chapter as the current Chapter
		try {
			bkInst!!.setupCurrentChapter(position)

			// If the user comes back to the Choose Chapter scene we need to let him choose again
			bkInst!!.canChooseAnotherChapter = true

			// Go to the EditChapterActivity
			val i = Intent(this, EditChapterActivity::class.java)
			startActivity(i)
			// Dispose of ChooseChapterActivity to reduce memory usage
			finish()
		} catch (e:SQLiteUpdateRecExc) {
			KITApp.ReportError(DBU_ChaRcrErr, e.message + "\nchooseChapterAction\nChooseChapterActivity", this)
		} catch (e:SQLiteCreateRecExc) {
			KITApp.ReportError(DBC_VItErr, e.message + "\nchooseChapterAction\nChooseChapterActivity", this)
		} catch (e:SQLiteReadRecExc) {
			KITApp.ReportError(DBR_VItErr, e.message + "\nchooseChapterAction\nChooseChapterActivity", this)
		}
	}
}