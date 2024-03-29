package com.ccs.kitand

import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
//import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
//import com.ccs.kitand.BuildConfig

//	The SetupActivity allows the user to edit the name of the Bible and then
//	starts the creation of the Bible -> curr Book -> curr Chapter -> curr VerseItem
//	in-memory data structures.
//
//	Once the name of the Bible has been set and its Books records have been created
//	this scene is bypassed on subsequent launches.
//
//  Created by Graeme Costin on 17SEP20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

class SetupActivity : AppCompatActivity() {

    private lateinit var gobtn: Button
    private lateinit var txt_bibname: EditText
    private lateinit var txt_version: TextView

    // Safe initialisations of the four Properties of the Bible record
    // These variables of SetupActivity are used when creating the Bible instance
    private var bibID: Int = 1	// Bible ID - always 1 for KIT v1
    private var bibName: String = "Bible"	// Bible name
    private var bkRCr: Boolean = false	// true when the Books records for this Bible have been created
    private var currBook: Int = 0	// current Book ID
    // Bible Book IDs are assigned by the Bible Societies as 1 to 39 OT and 41 to 67 NT)

//    lateinit var bibInst: Bible
// GDLC 12AUG21 No need for local var bibInst

// GDLC 7SEP23
    private var versionCode: Int = BuildConfig.VERSION_CODE
    private var versionName: String = BuildConfig.VERSION_NAME

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_setup)
        // Get references to layout widgets
        gobtn = findViewById(R.id.gobtn)
        txt_bibname = findViewById(R.id.txt_bibname)
        txt_version = findViewById(R.id.txt_version)
        val versTxt = getString(R.string.txt_version, versionName, versionCode)
        txt_version.text = versTxt

        gobtn.setOnClickListener {
            goButtonAction()
        }
    }

    override fun onResume() {
        super.onResume()
        // Create the KITDAO instance
        val dao = KITDAO(this)
        KITApp.dao = dao
        // Get access to the raw resource files
        KITApp.res = this.resources
        // Read the single Bibles record from kdb.sqlite
        try {
            val cv = KITApp.dao.bibleGetRec()
            bibID = cv.getAsInteger("1")
            bibName = cv.getAsString("2")
            bkRCr = cv.getAsBoolean("3")
            currBook = cv.getAsInteger("4")

            //	Once the user has dealt with the Setup scene, subsequent launches skip the Setup scene,
            //	but the Navigation stack can come back here for any future editing of the name of
            //	the Bible and any other matters that may be included here.
            if (bkRCr && KITApp.bibInst == null) {
                // Create the instance of Bible and
                // ensure rest of app has access to the Bible instance
                try {
                    KITApp.bibInst = Bible(bibID, bibName, bkRCr, currBook)
                    // Go to the ChooseBookActivity
                    val i = Intent(this, ChooseBookActivity::class.java)
                    startActivity(i)
                    finish()
//  If the Books records have already been created Bible.init() will not create any records
//  and there will be no record creation errors; so the following catch is not needed.
//              } catch (e:SQLiteCreateRecExc) {
//                  KITApp.ReportError(DBC_BooErr, e.message + ": OnResume(): SetupActivity", this)
                } catch (e:SQLiteReadRecExc) {
                    KITApp.ReportError(DBR_BooErr, e.message + "\nOnResume()\nSetupActivity", this)
                } catch (e: SQLiteUpdateRecExc) {
                    KITApp.ReportError(DBU_BibRErr, e.message + "\nOnResume()\nSetupActivity", this)
                }
            } else {
                // Initialise the text field and wait for user to edit Bible name
                txt_bibname.setText(bibName)
            }
        } catch (e:SQLiteReadRecExc){
            KITApp.ReportError(DBR_BibErr, e.message + "\nOnResume()\nSetupActivity", this)
        }
    }

    private fun goButtonAction () {
        // Get the (possibly edited) Bible name from the EditText widget
        val bibName: String = txt_bibname.text.toString()
        // Save the Bible name into the Bible record in kdb.sqlite
        try {
            KITApp.dao.bibleUpdateName(bibName)
            // Create the instance of Bible and
            // ensure rest of app has access to the Bible instance
            try {
                KITApp.bibInst = Bible(bibID, bibName, bkRCr, currBook)
                // Go to the ChooseBookActivity
                val i = Intent(this, ChooseBookActivity::class.java)
                startActivity(i)
                finish()
            } catch (e:SQLiteCreateRecExc) {
                KITApp.ReportError (DBC_BooErr, e.message + "\ngoButtonAction()\nSetupActivity", this)
            } catch (e:SQLiteReadRecExc) {
                KITApp.ReportError(DBR_BooErr, e.message + "\ngoButtonAction()\nSetupActivity", this)
            } catch (e: SQLiteUpdateRecExc) {
                KITApp.ReportError(DBU_BibRErr, e.message + "\ngoButtonAction()\nSetupActivity", this)
            }
        } catch (e:SQLiteUpdateRecExc) {
            KITApp.ReportError(DBU_BibNErr, e.message + "\ngoButtonAction()\nSetupActivity", this)
        }
    }
}