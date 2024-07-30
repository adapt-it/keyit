//
//  ChooseChapterView.swift
//  kitsui
//
//  Created by Graeme Costin on 22/12/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct ChooseChapterView: View {
	@EnvironmentObject var bibMod: BibleModel

	@ObservedObject var bkInst: Book
	var needChooseChapter: Bool
	
	@State var goEditChapter = false
	@State var selectedChapter: Book.BibChap?

	init(bkInst: Book, needChooseChapter: Bool) {
		self.needChooseChapter = needChooseChapter
		self.bkInst = bkInst
	}
// GDLC 6FEB24 Removed this setting of goEditChapter so that it is not set true until
// onAppear(), by which time all initialisations will have been done.
//		self._goEditChapter = State(wrappedValue: !needChooseChapter)
//	}

	private var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 1), count: 5)
	
	var body: some View {
		NavigationStack {
			VStack {
				Text("Choose \(getChapterName())")
				// 5 column flexible horizontal grid layout
				ScrollView(.vertical) {
					LazyVGrid(columns: gridItemLayout, spacing: 10) {
						ForEach(bkInst.BibChaps, id: \.self) { chap in
							ChapterNumberView(chp: chap).environmentObject(bibMod)
							.onTapGesture {
								selectedChapter = chap
								print("Tapped \(chap.chNum) _ \(chap.selected)")
								setupChosenChapter(selectedChapter!)
								print("selectedChapter changed to \(String(describing: selectedChapter?.chNum))")
								goEditChapter = true
							}
						}
					}
				}
			}
		}
		.navigationDestination(isPresented: $goEditChapter){
            EditChapterView(chInst: (bibMod.getCurBibInst().bookInst?.chapInst ?? bibMod.getDefaultChapterInst())!, currItOfst: 0).environmentObject(bibMod)
		}
		.navigationTitle(bibMod.getCurBibName() + ": " + bibMod.getCurBookName())
		.onAppear() {
			if !needChooseChapter {
				goEditChapter = true
			}
		}
		.onDisappear() {
			selectedChapter = nil
		}
    }
	
	func getChapterName() -> String {
		if let bkInst = bibMod.getCurBibInst().bookInst {
			return bkInst.chapName!
		} else {
			return "ERR: Book not yet chosen"
		}
	}
	
	func setupChosenChapter(_ selectedChapter:Book.BibChap) {
		if let bkInst = bibMod.getCurBibInst().bookInst {
			bkInst.setupChosenChapter(selectedChapter)
		} else {
			print("ERR: Book not yet chosen")
		}
	}
	
}
/*
#Preview {
	ChooseChapterView(needChooseChapter: true)
}
*/
