//
//  EditChapterView.swift
//  kitsui
//
//  Created by Graeme Costin on 31/12/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct EditChapterView: View {
	@EnvironmentObject var bibMod: BibleModel

//	@State var saveCurrTxt = false
	@ObservedObject var chInst: Chapter
	@State var currItOfst: Int
	@State var showUSFM = false
	
	var body: some View {
		NavigationStack {
			VStack {
				Text("Edit \(getChapterName()) \(getChapterNumber()), \(getNumVerses()) Verses, \(getNumExtras()) Extras")
					.font(.system(size: 15))
				ScrollViewReader { proxy in
					List {
						ForEach(chInst.BibItems, id: \.self) { vItem in
							VerseItemView(vItem: vItem).environmentObject(bibMod)
						}
					}
					.onAppear {
						print("EditChapterView appeared")
						withAnimation {
							proxy.scrollTo(getChapInst().BibItems[currItOfst], anchor: .topLeading)
						}
					}
				}
			}
		}
		.navigationTitle(bibMod.getCurBibName() + ": " + bibMod.getCurBookName())
		.toolbar {
			ToolbarItem() {
				Button ("USFM") {
					print("USFM tapped")
//					saveCurrTxt = true
// This is called before the latest edited text has been saved to its VItem
//					bibMod.getCurBibInst().bookInst!.chapInst!.calcUSFMExportText()
					showUSFM = true
				}
			}
		}
		.navigationDestination(isPresented: $showUSFM){
			ShowUSFMView(chInst: getChapInst()).environmentObject(bibMod)
		}
	}

	func getChapInst() -> Chapter {
		return bibMod.getCurBibInst().bookInst!.chapInst!
	}

	func onAppear() {
		// Get the offset of the current VerseItem
		currItOfst = bibMod.getCurBibInst().bookInst!.chapInst!.goCurrentItem()
	}

	func onDisappear() {
		print("EditView is disappearing")
	}

	func getChapterName() -> String {
		if let bkInst = bibMod.getCurBibInst().bookInst {
			return bkInst.chapName!
		} else {
			return "ERR: Book not yet chosen"
		}
	}
	
	func getChapterNumber() -> Int {
		if let bkInst = bibMod.getCurBibInst().bookInst {
			return bkInst.curChNum
		} else {
			return 999
		}
	}

	func getNumVerses() -> Int {
		if let chInst = bibMod.getCurBibInst().bookInst?.chapInst {
			return chInst.numVs
		} else {
			return 999
		}
	}

	func getNumExtras() -> Int {
		if let chInst = bibMod.getCurBibInst().bookInst?.chapInst {
			return (chInst.numIt - chInst.numVs)
		} else {
			return 999
		}
	}
}
/*
#Preview {
	EditChapterView(currItOfst: 0)
}
*/
