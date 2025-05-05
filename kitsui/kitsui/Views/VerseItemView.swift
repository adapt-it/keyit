//
//  VerseItemView.swift
//  kitios
//
//  Created by Graeme Costin on 27/1/2024.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct VerseItemView: View {
	@EnvironmentObject var bibMod: BibleModel
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@Environment(\.displayScale) var displayScale

	@ObservedObject var vItem: VItem
	@State var editedTxt: String

	@FocusState var isFocused: Bool
	@State var isVIMenuShowing: Bool = false

	init(vItem: VItem) {
		self.vItem = vItem
		self._editedTxt = State(wrappedValue: vItem.itTxt)
	}

	var body: some View {
		VStack {
			HStack {
				Button(getItemTypText(vItem)) {
					print("User tapped button for VerseItem \(vItem.vsNum):\(vItem.itTyp)")
					showPopoverMenu()
				}
				.font(.system(size: 10, weight: (isFocused || vItem.isCurVsItem ? .bold : .regular)))
				.buttonStyle(.bordered)
				.controlSize(.mini)
				.popover(isPresented: $isVIMenuShowing,
					attachmentAnchor: .point(.bottomTrailing),
					arrowEdge: .trailing,
					content: {
					VIMenuView(isVIMenuShowing: $isVIMenuShowing, vItem: vItem)
						.frame(width: popoverWidth(), height: popoverHeight())
					}
				)
// GDLC 18MAR25 This modifier requires iOS 16.4 or higher.
//				.presentationCompactAdaptation(.popover)
				Spacer()
			}
			if vItem.itTyp != "Para" && vItem.itTyp != "ParaCont"{
				TextEditor(text: $editedTxt)
					.font(.system(size: 13))
					.multilineTextAlignment(.leading)
					.lineSpacing(2)
					.autocorrectionDisabled(true)
					.autocapitalization(.none)
					.frame(minHeight: 12, maxHeight: .infinity)
					.border(Color.secondary, width: 1)	// GDLC test
					.clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))	// GDLC test
					.padding(.vertical, 0)
					.focused($isFocused)
					.foregroundColor(selectTextColour())
					.onChange(of: $editedTxt.wrappedValue) {
						saveEditedTxtIgnoreDirty()
					}
					.onChange(of: isFocused) {
						focusChange()
					}
			}
		}
		.onAppear(perform: {
			if vItem.isCurVsItem {
				beginEditing()
			}
			print("\(vItem.itTyp) vs \(vItem.vsNum) now shown")
		})
		.onDisappear(perform: {
			saveEditedTxt()
			print("Verse \(vItem.vsNum) \(vItem.itTyp) now off screen")
		})
	}


	func getChapInst() -> Chapter {
		return bibMod.getCurBibInst().bookInst!.chapInst!
	}

	func getItemTypText(_ vItem: VItem) -> String {
		var typeText = ""
		switch vItem.itTyp {
		case "Title": typeText = "Main Title"
		case "Para", "ParaCont": typeText = "Paragraph"
		case "ParlRef": typeText = "Parallel Ref"
		case "VerseCont": typeText = "Verse" + String(vItem.vsNum) + " (cont)"
		case "Verse":
			if vItem.isBrg {
				typeText = "Verses " + String(vItem.vsNum) + "-" + String(vItem.lvBrg)
			} else {
				typeText = "Verse " + String(vItem.vsNum)
			}
		case "InTitle": typeText = "Intro Title"
		case "InSubj": typeText = "Intro Heading"
		case "InPara": typeText = "Intro Paragraph"
		default: typeText = vItem.itTyp
		}
		return typeText
	}

	// GDLC 20MAR25 Moved the perform: content lines out of .onChange(of: $editedTxt.wrappedValue)
	// because the perform: part, has been deprecated since iOS 17.6
	func focusChange() {
		if !isFocused {
			// vItem has lost focus so ensure text is saved
			saveEditedTxt()
		} else {
			// vItem has gained focus so set this vItem as the currently editing one
			beginEditing()
		}
	}

	func beginEditing() {
		// GDLC 6MAR25 This function was being called on a tap on a vItem, but it is now
		// called in response to the vItem gaining focus; calling it on the tap that changes
		// focus resulted in the current vItem being changed too early.
		bibMod.getCurBibInst().bookInst!.chapInst!.makeVItemCurrent(vItem)
		vItem.isCurVsItem = true
		vItem.dirty = true
		print("vs \(vItem.vsNum), itID \(vItem.itID), itTyp \(vItem.itTyp) is now the current item")
	}

	// MARKER: Save changes
	 // this function is called on loss of focus on the vItem in VerseItemView
	 // or when the button on the vItem is tapped
	 func saveEditedTxt() {
		 // If the text is marked dirty then save it to vItem, BibItems and SQLite
 		if vItem.dirty {
			 let newText = editedTxt
			 if newText != vItem.itTxt {
				 vItem.itTxt = newText
				 bibMod.getCurBibInst().bookInst!.chapInst!.copyAndSaveVItem(vItem.itID, newText)
				 bibMod.getCurBibInst().bookInst!.chapInst!.calcUSFMExportText()
 				vItem.dirty = false
			 }
 		}
	 }

	// GDLC 20MAR25 Added to handle saving from onChange(of: $editedTxt.wrappedValue)
	func saveEditedTxtIgnoreDirty() {
		// As the text is changed, save it to vItem, BibItems and SQLite
			let newText = editedTxt
			if newText != vItem.itTxt {
				vItem.itTxt = newText
				bibMod.getCurBibInst().bookInst!.chapInst!.copyAndSaveVItem(vItem.itID, newText)
				// GDLC 20MAR25 When responding to keystrokes in vItem.itTxt don't also
				// calculate USFM text for the Chapter
				// bibMod.getCurBibInst().bookInst!.chapInst!.calcUSFMExportText()
			}
	}

// MARKER: Popover menu functions
	func popoverWidth() -> CGFloat {
		var w: CGFloat	// width in points

		if vItem.curPoMenu != nil {
			if horizontalSizeClass == .compact {
				w = vItem.curPoMenu!.menuLabelWidth + 15
			} else {
				w = vItem.curPoMenu!.menuLabelWidth + 25	// Assume 25 points for the menu icon
			}
			// Return width in pixels
			return w * displayScale
		} else {
			return 130 * displayScale	// Most popover menus will not need more than 130 pixels width
		}
	}

	func popoverHeight() -> CGFloat {
		var h: CGFloat	// Height in points

		if vItem.curPoMenu != nil {
			if horizontalSizeClass == .compact {
				h = CGFloat(vItem.curPoMenu!.numRows + 1) * 20
			} else {
				h = CGFloat(vItem.curPoMenu!.numRows + 1) * 25
			}
			// Return height in pixels
			return h * displayScale
		} else {
			return displayScale * 7 * 17	// Popover menus will seldom have more than 7 rows
		}
	}

	func showPopoverMenu() {
		// Ensure that current VItem is saved
		saveEditedTxt()
		// Mark this VItem as the current one
		bibMod.getCurBibInst().bookInst!.chapInst!.makeVItemCurrent(vItem)
		vItem.isCurVsItem = true
		print("vs \(vItem.vsNum), itID \(vItem.itID), itTyp \(vItem.itTyp) is now current item")

		// Build the popover menu for this VerseItem
		vItem.createVIMenu()
		// Display the popover menu
		isVIMenuShowing = true
	}

// NOT YET USED - Delete?
// TODO: From where could this be called?
	func dismissPopoverMenu() {
		isVIMenuShowing = false
	}

	// MARKER: Text colour
	// TODO: Needs better choice of colours to cater for dark mode
	func selectTextColour() -> Color {
		if isFocused || vItem.isCurVsItem {
			return Color.black
		} else {
			return Color.gray
		}
	}

	// NOT YET USED - Delete?
	// TODO: From where could this be called?
	 private func hideKeyboard() {
		 UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	 }
}
/*
#Preview {
	Group {
		VerseItemView(vItem: VItem(owner: <#Chapter#>, itID: 32, chID: 2, vsNum: 1, itTyp: "Heading", itOrd: 100, itTxt: "Heading before verse 1",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
		VerseItemView(vItem: VItem(itID: 31, chID: 2, vsNum: 1, itTyp: "Verse", itOrd: 100, itTxt: "Text of verse 1 of Galatians chapter 1; and here it goes on and on for quite a while. I wonder how many lines we can fill? Let's keep going on and on ... The quick brown fox jumped over the lazy dog.",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: true))
		VerseItemView(vItem: VItem(itID: 33, chID: 2, vsNum: 2, itTyp: "Para", itOrd: 100, itTxt: "",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
		VerseItemView(vItem: VItem(itID: 30, chID: 2, vsNum: 2, itTyp: "Verse", itOrd: 100, itTxt: "Text of verse 2 of Galatians chapter 1; and here it goes on and on for quite a while. I wonder how many lines we can fill? At least one more than this I am sure!",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
	}
}*/
