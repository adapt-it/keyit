//
//  ExportChapterViewController.swift
//  kitios
//
//	GDLC 23JUL21 Cleaned out some print commands (were used in early stages of development)
//
//  Created by Graeme Costin on 2MAY20.

// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

class ExportChapterViewController: UIViewController {

	var bInst: Bible?
	weak var bkInst: Book?
	weak var chInst: Chapter?
	
	// Get access to the AppDelegate
	let appDelegate = UIApplication.shared.delegate as! AppDelegate

	@IBOutlet weak var ExportUSFM: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		bInst = appDelegate.bibInst	// Get access to the instance of the Bible
		bkInst = appDelegate.bookInst	// Get access to the instance of the current Book
		chInst = appDelegate.chapInst	// Get access to the instance of the current Chapter
		navigationItem.title = bInst!.bibName
		navigationItem.prompt = "Export chapter " + String(chInst!.chNum) + " of " + bkInst!.bkName

		// Generate the USFM text
		let USFMexp = chInst!.calcUSFMExportText()
		// Display it to the user
		ExportUSFM.text = USFMexp
		// Save it into the current Chapter record of kdb.sqlite
		do {
			try chInst!.saveUSFMText (chInst!.chID, USFMexp)
			ExportUSFM.isEditable = false
			// When a good method of sending USFM to AIM is implemented, this UITextView can be made non-selectable
			// ExportUSFM.isSelectable = false
		} catch {
			appDelegate.ReportWarning(DBU_ChaUSFMErr)
		}
    }
}
