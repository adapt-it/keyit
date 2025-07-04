//
//  ChooseBookView.swift
//  kitios
//
//	ChooseBookView lets the user choose a Book of the current Bible instance.
//
//  Created by Graeme Costin on 17/11/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct ChooseBookView: View {
	@EnvironmentObject var bibMod: BibleModel
	var needChooseBook: Bool

	@State var goChooseChapter = false
	@State var selectedBook: Bible.bookLst?
	@State var showOT = false
	@State var showNT = false

	init(needChooseBook:Bool) {
		self.needChooseBook = needChooseBook
// GDLC 6FEB24 Removed this setting of goChooseChapter so that it is not set true until
// onAppear(), by which time all initialisations will have been done.
//		self._goChooseChapter = State(wrappedValue: !needChooseBook)
	}
 
	var body: some View {
		NavigationStack {
			VStack {
				List(selection: $selectedBook) {
					Section {
						DisclosureGroup(
							isExpanded: $showOT,
							content: {
								ForEach (bibMod.getCurBibInst().booksOT, id: \.self) { bookLst in
									BookNameView(bookLst: bookLst)
								}
							},
							label: {
								Text("Old Testament")
							}
						)
					}
					Section {
						DisclosureGroup(
							isExpanded: $showNT,
							content: {
								ForEach (bibMod.getCurBibInst().booksNT, id: \.self) { bookLst in
									BookNameView(bookLst: bookLst)
								}
							},
							label: {
								Text("New Testament")
							}
						)
					}
				}
			}
			.onChange(of: selectedBook) {
				onSelectBook()
			}
		}
		.navigationDestination(isPresented: $goChooseChapter){
			ChooseChapterView(
				bkInst: (bibMod.getCurBibInst().bookInst ?? bibMod.getDefaultBookInst())!,
				needChooseChapter: getNeedChooseChapter()
			).environmentObject(bibMod)
		}
        .navigationTitle(bibMod.getCurBibName() + ": Choose Book")
		.toolbarRole(.editor)
		.onAppear() {
			// If a Book has been chosen and Bible is being launched, go straight to Choose Chapter
			if !needChooseBook && bibMod.getCurBibInst().launching {
				bibMod.getCurBibInst().goCurrentBook()	// <- not needed? goCurrentBook() was called earlier
				goChooseChapter = true
			}
		}
		.onDisappear() {
			selectedBook = nil
		}
	}

// TODO: check whether this has enough actions to avoid the odd selection problem with Chapter change
	func onSelectBook () {
		if selectedBook != nil {
			print("selectedBook changed to \(selectedBook!.bookName)")
			bibMod.getCurBibInst().setupChosenBook(selectedBook!)
// GDLC 1MAR25 We are now finished with selectedBook, so no need for this update.
//					selectedBook!.selected = true
			goChooseChapter = true
		}
	}

	func getNeedChooseChapter() -> Bool {
		if let bkInst = bibMod.getCurBibInst().bookInst {
			return bkInst.needChooseChapter
		} else {
			// By the time ChooseBookView is shown ???
			return true
		}
	}
}

#Preview {
	ChooseBookView(needChooseBook: true)
}
