//
//  VerseItemView.swift
//  kitsui
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

	@ObservedObject var vItem: VItem
	@State var editedTxt: String
	@FocusState var isFocused: Bool
 
	init(vItem: VItem) {
		self.vItem = vItem
		self._editedTxt = State(wrappedValue: vItem.itTxt)
	}

	var body: some View {
		VStack {
			HStack {
				Button(getItemTypText(vItem)) {
					
				}
				.padding([.leading], 2)
				.font(.system(size: 11, weight: (isFocused || vItem.isCurVsItem ? .bold : .regular)))
				Spacer()
			}
			if vItem.itTyp != "Para" {
				TextEditor(text: $editedTxt)
					.font(.system(size: 12))
					.multilineTextAlignment(.leading)
					.lineSpacing(2)
					.autocorrectionDisabled(true)
					.autocapitalization(.none)
					.frame(maxHeight: .infinity)
					.padding(.vertical, -8)
					.onTapGesture {
						beginEditing()
					}
					.focused($isFocused)
					.foregroundColor(selectTextColour())
					.onChange(of: isFocused) { isFocused in
						saveEditedTxt()
					}
			}
		}
		.onAppear(perform: {
			if vItem.isCurVsItem {
				beginEditing()
			}
			print("Verse \(vItem.vsNum) now shown")
		})
		.onDisappear(perform: {
			saveEditedTxt()
			print("Verse \(vItem.vsNum) now off screen")
		})
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

	func beginEditing() {
		bibMod.getCurBibInst().bookInst!.chapInst!.makeVItemCurrent(vItem)
		vItem.isCurVsItem = true
		isFocused = true
		print("vs \(vItem.vsNum), itID \(vItem.itID), itTyp \(vItem.itTyp) is now current item")
	}

	func selectTextColour() -> Color {
		if isFocused || vItem.isCurVsItem {
			return Color.black
		} else {
			return Color.gray
		}
	}

	 private func hideKeyboard() {
		 UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
	 }


	func saveEditedTxt() {
		// If the text has been changed then save it to vItem, BibItems and SQLite
		let newText = editedTxt
		if newText != vItem.itTxt {
			vItem.itTxt = editedTxt
			bibMod.getCurBibInst().bookInst!.chapInst!.copyAndSaveVItem(vItem.itID, editedTxt)
		}
	}
}

#Preview {
	Group {
		VerseItemView(vItem: VItem(itID: 32, chID: 2, vsNum: 1, itTyp: "Heading", itOrd: 100, itTxt: "Heading before verse 1",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
		VerseItemView(vItem: VItem(itID: 31, chID: 2, vsNum: 1, itTyp: "Verse", itOrd: 100, itTxt: "Text of verse 1 of Galatians chapter 1; and here it goes on and on for quite a while. I wonder how many lines we can fill? Let's keep going on and on ... The quick brown fox jumped over the lazy dog.",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: true))
		VerseItemView(vItem: VItem(itID: 33, chID: 2, vsNum: 2, itTyp: "Para", itOrd: 100, itTxt: "",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
		VerseItemView(vItem: VItem(itID: 30, chID: 2, vsNum: 2, itTyp: "Verse", itOrd: 100, itTxt: "Text of verse 2 of Galatians chapter 1; and here it goes on and on for quite a while. I wonder how many lines we can fill? At least one more than this I am sure!",
								   intSeq: 0, isBrg: false, lvBrg: 0, isCurVsItem: false))
	}
}
