//
//  UIVerseItemCell.swift
//
//	A custom class for UITableView cells presenting VerseItems for editing.
//
//	GDLC 22AUG21 Added setCellState() for better control of cell editability, selectability
//		and response (or otherwise) to keyboard actions.
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//
//  Created by Graeme Costin on 26FEB20.

// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

/* Declare a Delegate Protocol method */
protocol UIVerseItemCellDelegate:AnyObject {
	func customCell(cell:UIVerseItemCell, didTapPub button:UIButton)
}
 

class UIVerseItemCell: UITableViewCell, UITextViewDelegate {

	@IBOutlet weak var viCell: UIView!
	@IBOutlet weak var itText: UITextView!
	@IBOutlet weak var pubBut: UIButton!

	//Define delegate variable
	weak var cellDelegate:UIVerseItemCellDelegate?

	var textChanged: ((String) -> Void)?
	
	var tableRow = 0	// As each instance of UIVerseItemCell is created its tableRow is set
	weak var VTVCtrl: VersesTableViewController?	// Link to the ViewController that owns this cell
	var dirty = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		itText.delegate = self
    }

	func textChanged(action: @escaping (String) -> Void) {
		self.textChanged = action
	}

	func textViewDidChange(_ textView: UITextView) {
		dirty = true
		textChanged?(textView.text)
	}

	// Called by iOS when the user taps inside the cell's editable text field
	func textViewDidBeginEditing(_ textView: UITextView) {
		VTVCtrl!.userTappedInTextOfCell(tableRow)
	}
	
	// Called by iOS when the UIKit wants to reuse a cell for a different table row
	override func prepareForReuse() {
		super.prepareForReuse()
		if dirty {
			let textSrc = itText.text as String
			VTVCtrl!.saveCellText(tableRow, textSrc)
		}
		dirty = false
	}

	// Action for the itType button in the VerseItem cell
	@IBAction func pubPopover(_ button: UIButton) {
		let buttonFrame = button.frame
		let showRect    = self.convert(buttonFrame, to: VTVCtrl!.tableView)
		VTVCtrl!.pubItemsPopoverAction(button, tableRow, showRect)
	}

	// GDLC 22AUG21 Added to better handle making cells selected or not selected
	func setCellState(selectable: Bool, editable: Bool, active: Bool) {
		itText.isSelectable = selectable
		itText.isEditable = editable
		if active {
			itText.backgroundColor = UIColor.init(red: 0.95, green: 0.90, blue: 1.0, alpha: 1.0)
			itText.becomeFirstResponder()
		} else {
			itText.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
// GDLC 25AUG21 Testing what happens if this resign is omitted
//			itText.resignFirstResponder()
		}
	}

	func setCellDeselected() {
		// Don't change isSelectable or isEditable, just reset background colour
		itText.backgroundColor = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	}
}

extension UIVerseItemCell: UIPopoverPresentationControllerDelegate {
	
	func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
		return .none
	}
}
