package com.ccs.kitand

import android.content.Intent
import android.os.Bundle
import android.view.ViewTreeObserver
import android.widget.TextView
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

//	The ChooseBookActivity will be entered after the Bible instance is created and so it will
//	always have available the array of Bible Books. But it will not always have a current Book:
//	*	During app launch a current Book may have been read from kdb.sqlite and so this
//		current Book can be set, and then control passed to the Select Chapter scene.
//	*	During app use the user may want to change to a different Book and so control
//		will be passed back to this Select Book scene to allow this to happen.
//
//  Created by Graeme Costin on ?.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class ChooseBookActivity : AppCompatActivity()  {

	// Boolean for whether to let the user choose a Book
	var letUserChooseBook = false	// Will be set from bibInst.canChooseAnotherBook

	lateinit var txt_bk_prompt: TextView
	lateinit var lst_booklist: RecyclerView
	lateinit var recyclerView: RecyclerView
	lateinit var viewAdapter: BookAdapter
	private lateinit var viewManager: RecyclerView.LayoutManager

	var suppActionBar: ActionBar? = null
	// By the time ChooseBookActivity is started the Bible instance will have been created
	var bInst: Bible = KITApp.bibInst

	// Layout height for calculating scrolling offset
	var layout_height = 0

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)

		setContentView(R.layout.activity_choosebook)

		// Get access to the SupportActionBar
		suppActionBar = getSupportActionBar()

		// Get references to layout widgets
		txt_bk_prompt = findViewById(R.id.txt_bk_prompt)
		lst_booklist = findViewById(R.id.lst_books)
	}

	override fun onStart() {
		super.onStart()

		val bibName = KITApp.bibInst.bibName
		bInst = KITApp.bibInst

		val actionBarTitle = "Key It  -  " + bibName
		if (suppActionBar != null) {
			suppActionBar?.setDisplayShowTitleEnabled(true)
			suppActionBar?.setTitle(actionBarTitle)
		}
	}

	override fun onResume() {
		super.onResume()
		// Most launches will have a current Book and will go straight to it
		letUserChooseBook = bInst.canChooseAnotherBook
		if (!letUserChooseBook && bInst.currBk > 0) {
			try {
				bInst.goCurrentBook()
				// Creates an instance for the current Book (from kdb.sqlite)
				// If the user comes back to ChooseBookActivity we need to let him choose again
				bInst.canChooseAnotherBook = true
				// Go to the ChooseChapterActivity
				val i = Intent(this, ChooseChapterActivity::class.java)
				startActivity(i)
				// Dispose of ChooseBookActivity to reduce memory usage
				finish()
			} catch (e:SQLiteCreateRecExc) {
				KITApp.ReportError(DBC_ChaErr, e.message + "\nonResume()\nChooseBookActivity", this)
			} catch (e:SQLiteReadRecExc) {
				KITApp.ReportError(DBR_ChaErr, e.message + "\nonResume()\nChooseBookActivity", this)
			}
		} else {
			// On first launch, and when user wants to choose another book,
			// set up the Books list and wait for the user to choose a Book.
			txt_bk_prompt.setText("Choose Book")
			viewManager = LinearLayoutManager(this)
			viewAdapter = BookAdapter(KITApp.bibInst.BibBooks, this) as BookAdapter
			recyclerView = findViewById<RecyclerView>(R.id.lst_books).apply {
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
						(viewManager as LinearLayoutManager).scrollToPositionWithOffset(bInst.currBookOfst, layout_height/2)
						return true
					}
					return false
				}
			})
		}
	}

	fun chooseBookAction(position: Int) {
		val bInst = KITApp.bibInst
		val selectedBook = bInst.BibBooks[position]
		// Set up the selected Book as the current Book (this updates kdb.sqlite with the currBook)
		try {
			bInst.setupCurrentBook(selectedBook)
			// Current Book is selected so go to ChooseChapterActivity
			// If the user comes back to the Choose Book scene we need to let him choose again
			bInst.canChooseAnotherBook = true
			// Go to the ChooseChapterActivity
			val i = Intent(this, ChooseChapterActivity::class.java)
			startActivity(i)
			// Dispose of ChooseBookActivity to reduce memory usage
			finish()
		} catch (e:SQLiteUpdateRecExc) {
			KITApp.ReportError(DBU_BibCErr, e.message + "\nchooseBookAction()\nChooseBookActivity", this)
		} catch (e:SQLiteCreateRecExc) {
			KITApp.ReportError(DBC_ChaErr, e.message + "\nchooseBookAction()\nChooseBookActivity", this)
		} catch (e:SQLiteReadRecExc) {
			KITApp.ReportError(DBR_ChaErr, e.message + "\nchooseBookAction()\nChooseBookActivity", this)
		}
	}
}