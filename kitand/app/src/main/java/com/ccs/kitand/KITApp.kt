package com.ccs.kitand

import android.app.Application
import android.content.Context
import android.content.res.Resources
import androidx.appcompat.app.AlertDialog


//  Created by Graeme Costin on 3JUL20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.
//
// KITApp functions in a similar manner to the AppDelegate in kitios because it enables
// some important class instances to be accessed from many parts of the app.

class KITApp : Application() {

    override fun onCreate() {
        super.onCreate()
        instance = this
     }

    companion object {

        var instance: KITApp? = null
            private set

        lateinit var res: Resources
        lateinit var dao: KITDAO        // For access to kdb.sqlite
        lateinit var bibInst: Bible     // For access to the single instance of Bible
                        // The owning ref to bibInst which lasts for the entire run of the app
        var bkInst: Book? = null        // For access to the instance of the currently selected Book
                        // This is the weak ref to bkInst which allows rest of app to access the current
                        // Book instance; lasts only for the time that Book is the current one - the owning
                        // ref is in the Bible instance
        var chInst: Chapter? = null    // For access to the instance of the currently selected Chapter
                        // The weak ref to chInst which allows rest of app to access the current
                        // Chapter instance; lasts only for the time that Chapter is the current one -
                        // the owning ref is in the Book instance

        fun ReportError(errorNum: Int, msg: String, actContext: Context) {
            val builder: AlertDialog.Builder = AlertDialog.Builder(actContext)
                .setTitle("Fatal Error")
                .setMessage(msg + "\nPlease report Error No. $errorNum to the developers")
                .setCancelable(false)
                .setPositiveButton("OK", {
                    dialog, id -> dialog.cancel()
                    System.exit(0);
                }
            )
            val alertDialog = builder.create()
            alertDialog.show()
        }
    }
}
