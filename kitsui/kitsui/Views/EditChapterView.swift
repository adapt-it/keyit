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
	
	@State var currItOfst: Int
	
	var body: some View {
		NavigationStack {
			VStack {
				Text("Edit \(getChapterName()) \(getChapterNumber()), \(getNumItems()) VerseItems")
				ScrollViewReader { proxy in
					List {
						ForEach(getChapInst().BibItems, id: \.self) { vItem in
							VerseItemView(vItem: vItem).environmentObject(bibMod)
						}
					}
					.onAppear {
						print("view appeared")
//						withAnimation {
							proxy.scrollTo(getChapInst().BibItems[currItOfst], anchor: .topLeading)
//						}
					}
				}
			}
		}
		.navigationTitle(bibMod.getCurBibName() + ": " + bibMod.getCurBookName())
	}

	func getChapInst() -> Chapter {
		return bibMod.getCurBibInst().bookInst!.chapInst!
	}

	func onAppear() {
		// Get the offset of the current VerseItem
		currItOfst = bibMod.getCurBibInst().bookInst!.chapInst!.goCurrentItem()
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
	
	func getNumItems() -> Int {
		if let chInst = bibMod.getCurBibInst().bookInst?.chapInst {
			return chInst.BibItems.count
		} else {
			return 999
		}
	}
}

#Preview {
	EditChapterView(currItOfst: 0)
}
