package com.ccs.kitand

import android.content.Intent
import android.os.Bundle
import android.view.*
import android.view.ViewTreeObserver.OnPreDrawListener
import android.widget.*
import androidx.appcompat.app.ActionBar
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView

//	This is the EditChapterActivity. This scene will be entered
//	only when a current Book and current Chapter have been chosen.
//
//	NOTE: The EditChapterActivity of kitand matches the VersesTableViewController in kitios
//
//  Created by Graeme Costin on 2OCT20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class EditChapterActivity : AppCompatActivity() {

	private lateinit var txt_ched_prompt: TextView
	private lateinit var ch_name:String
	private lateinit var ps_name:String
	lateinit var recyclerView: RecyclerView
	private var viewAdapter: VerseItemAdapter? = null
	private var viewManager: RecyclerView.LayoutManager? = null
	lateinit var edChAct: EditChapterActivity
	var bkInst: Book? = null

	var currItOfst = -1	// -1 until one of the VerseItems is chosen for editing;
						// then it is the offset into the BibItems[] array which equals
						// the offset into the list of cells in the RecyclerView.

	// Scale factor for calculating size of PopupWindows
	var scale: Float = 0.0F
	// Layout width for calculating positioning of PopupWindows
	var layout_width = 0
	// Layout height for calculating scrolling offset
	var layout_height = 0

	var suppActionBar: ActionBar? = null

	// Properties of the EditChapterActivity instance related to popover menus
	var curPoMenu: VIMenu? = null	// instance in memory of the current popover menu
	private var popupWin: PopupWindow? = null
	// Cursor position in text of current VerseItem
	// Set in showPopOverMenu() which gets the value from a parameter
	// The value is kept in case it is needed in popMenuAction()
	var cursPos = 0

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		setContentView(R.layout.activity_edit_chapter)
		bkInst = KITApp.bkInst

		edChAct = this
		// Get access to the SupportActionBar
		suppActionBar = getSupportActionBar()

		// Get widget and names for prompt string
		txt_ched_prompt = findViewById(R.id.txt_ched_prompt)
		ch_name = KITApp.res.getString(R.string.nm_chapter)
		ps_name = KITApp.res.getString(R.string.nm_psalm)

		val result = KITApp.chInst!!.goCurrentItem()
		this.currItOfst = result
		viewManager = LinearLayoutManager(this)
		viewAdapter = VerseItemAdapter(KITApp.chInst!!.BibItems, this) as VerseItemAdapter

		recyclerView = findViewById<RecyclerView>(R.id.lv_verseitemlist).apply {
			// use this setting to improve performance if you know that changes
			// in content do not change the layout size of the RecyclerView
			setHasFixedSize(true)
			// use a linear layout manager
			layoutManager = viewManager
			// specify a viewAdapter
			adapter = viewAdapter
		}

//		// Ensure that the soft keyboard will appear
		// TODO: Find a way that works!
//		getWindow().setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_PAN)
	}

	override fun onCreateOptionsMenu(menu: Menu): Boolean {
		val inflater: MenuInflater = menuInflater
		inflater.inflate(R.menu.editchaptermenu, menu)
		return true
	}

	override fun onStart() {
		super.onStart()
		val bibName = KITApp.bibInst.bibName
		val chNumStr = KITApp.chInst!!.chNum.toString()
		val prompt = if (bkInst!!.bkID == 19)
			"Edit " + ps_name + " " + chNumStr else
			"Edit " + ch_name + " " + chNumStr + " of " + bkInst!!.bkName
		txt_ched_prompt.setText(prompt)
		val actionBarTitle = "Key It  -  " + bibName
		if (suppActionBar != null) {
			suppActionBar?.setDisplayShowTitleEnabled(true)
			suppActionBar?.setTitle(actionBarTitle)
		}
	}

	override fun onResume() {
		super.onResume()
		val curItOfst = KITApp.chInst!!.goCurrentItem()
		this.currItOfst = curItOfst
		// NOTE: at the time that onResume() is called, the RecyclerView has not been fully set up
		// so attempting to show the correct VerseItem as selected will not work (and may crash).
		// Setting a listener for the point when RecyclerView is fully set up is an OK approach.
		recyclerView.getViewTreeObserver().addOnPreDrawListener(object : OnPreDrawListener {
			override fun onPreDraw(): Boolean {
				if (recyclerView.getChildCount() > 0) {
					// Remove the listener to avoid continually triggering this code - once is enough.
					recyclerView.viewTreeObserver.removeOnPreDrawListener(this)
					// Get the screen's density scale
					scale = resources.displayMetrics.density
					// Get the width of the layout
					layout_width = recyclerView.getMeasuredWidth()
					layout_height = recyclerView.getMeasuredHeight()
					(viewManager as LinearLayoutManager).scrollToPositionWithOffset(currItOfst, layout_height/2)
					viewAdapter?.selectCurrItem(currItOfst)
					return true
				}
				return false
			}
		})
	}

	// The Android system calls this function when KIT is going into the background
	override fun onStop() {
		saveCurrentItemText()
		super.onStop()
	}

	// The Android system calls this function when EditChapterActivity is being removed
	override fun onDestroy() {
		viewManager = null
		viewAdapter = null
		super.onDestroy()
	}

	// The Android system's Action Bar calls this function when the user taps the Back button
	override fun onOptionsItemSelected(item: MenuItem): Boolean {
		when (item.getItemId()) {
			android.R.id.home -> onBackPressed()
			R.id.export -> goToExport()
		}
		return true
	}

	override fun onBackPressed() {
		goToChapters()
	}

	private fun goToChapters() {
		// Save the current VerseItem text if necessary
		saveCurrentItemText()
		// Go to the ChooseChapterActivity
		val i = Intent(this, ChooseChapterActivity::class.java)
		startActivity(i)
		// Dispose of the EditChapterActivity to reduce memory usage
		finish()
	}

	// Go to the ExportChapterActivity
	private fun goToExport() {
		// Save the current VerseItem text if necessary
		saveCurrentItemText()
		// Go to the ExportChapterActivity
		val i = Intent(this, ExportChapterActivity::class.java)
		startActivity(i)
	}

	// Show popover menu; called from showPopoverMenu() in VerseItemAdapter
	fun showPopOverMenu(butn: Button, cursPos: Int) {
		this.cursPos = cursPos
		val locations = IntArray(2)
		butn.getLocationInWindow(locations)
		val butW: Int = butn.getWidth()
		curPoMenu = KITApp.chInst!!.curPoMenu
		var numRows = 0
		if (curPoMenu == null) numRows = 0 else numRows = curPoMenu!!.numRows
		val poMenuWidth: Float = curPoMenu?.menuLabelLength!!		// Scaled points
		val popupWidth: Int = ((poMenuWidth + 35.5f) * scale).toInt()	// Pixels
		val pHeightIntdp = numRows.times(44)
		val popupHeight = (pHeightIntdp.toFloat() * scale + 0.5f).toInt()
		val inflater = getSystemService(LAYOUT_INFLATER_SERVICE) as LayoutInflater
		val popupView = inflater.inflate(R.layout.activity_popup, null)
		popupWin = PopupWindow(popupView, popupWidth, popupHeight, true)
		val layoutMgr = LinearLayoutManager(applicationContext)
		val popupMenu = popupView.findViewById<RecyclerView>(R.id.popmenu)
		popupMenu.apply  {
			// use this setting to improve performance if you know that changes
			// in content do not change the layout size of the RecyclerView
			setHasFixedSize(true)
			// use a linear layout manager
			layoutManager = layoutMgr
			// specify a viewAdapter
			adapter = PopupAdapter(curPoMenu!!, edChAct)
		}
//		popupWin!!.setOutsideTouchable(true)

		popupWin!!.showAtLocation(
			recyclerView, // View for popup window to appear over
			Gravity.NO_GRAVITY, // How to bias the position of the popup window
			butW + 100, // X offset
			locations[1] // Y offset
		)
	}

	fun popMenuAction(pos: Int) {
		val popMenuCode = curPoMenu!!.VIMenuItems[pos].VIMenuAction
		// Ensure that the current BibItem is saved prior to possibly changing which one is the current one.
		saveCurrentItemText()
		var noerr:Boolean = true
		try {
			KITApp.chInst!!.popMenuAction(popMenuCode, cursPos)
		} catch (e:SQLiteCreateRecExc){
			noerr = false
			KITApp.ReportError(DBC_PopErr,e.message + "\npopMenuAction()\nEditChapterActivity", this)
		} catch (e:SQLiteUpdateRecExc){
			noerr = false
			KITApp.ReportError(DBU_PopErr,e.message + "\npopMenuAction()\nEditChapterActivity", this)
		} catch (e:SQLiteReadRecExc){
			noerr = false
			KITApp.ReportError(DBR_PopErr,e.message + "\npopMenuAction()\nEditChapterActivity", this)
		} catch (e:SQLiteDeleteRecExc){
			noerr = false
			KITApp.ReportError(DBD_PopErr,e.message + "\npopMenuAction()\nEditChapterActivity", this)
		}
		// Avoid executing the rest of this function if there is a fatal error
		if (noerr) {
			popupWin!!.dismiss()
			// Refresh the RecyclerView of VerseItems
			// Replacing the content of the RecyclerView causes its current contents to be saved to the database,
			// but the database has already been updated correctly (for example, with an Ascription deleted) and
			// so every VerseItem that is at present in the RecyclerView is saved to its preceding VerseItem in
			// the database -- Verse 2 text goes to Verse 1, etc.!!
			// This Boolean is a hack to prevent this; but there must be a better way!
			viewAdapter?.setIsRefreshingRecyclerView(true)
			recyclerView.setAdapter(null);
			recyclerView.setLayoutManager(null);
			recyclerView.setAdapter(viewAdapter);
			recyclerView.setLayoutManager(viewManager);
			viewAdapter?.notifyDataSetChanged()
			viewAdapter?.setIsRefreshingRecyclerView(false)
			// Get the current offset calculated by chInst after the pomenu action had finished
			currItOfst = KITApp.chInst!!.currItOfst
			// Set currCellOfst of the VerseItemAdapter
			if (viewAdapter != null) viewAdapter!!.currCellOfst = currItOfst
			// NOTE: at this time, the RecyclerView may not have been fully set up
			// so attempting to show the correct VerseItem as selected may not work (and may crash).
			// Setting a listener for the point when RecyclerView is fully set up is an OK approach.
			recyclerView.getViewTreeObserver().addOnPreDrawListener(object : OnPreDrawListener {
				override fun onPreDraw(): Boolean {
					if (recyclerView.getChildCount() > 0) {
						// Remove the listener to avoid continually triggering this code - once is enough.
						recyclerView.viewTreeObserver.removeOnPreDrawListener(this)
						(viewManager as LinearLayoutManager).scrollToPositionWithOffset(
							currItOfst,
							layout_height / 2
						)
						viewAdapter?.selectCurrItem(currItOfst)
						return true
					}
					return false
				}
			})
		}
	}

	// Called when another VerseItem cell is selected in order to save the current VerseItem text
	// before making another VerseItem the current one
	private fun saveCurrentItemText() {
		viewAdapter?.saveCurrentItemText()
	}
}
