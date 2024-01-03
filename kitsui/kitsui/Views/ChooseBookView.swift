//
//  ChooseBookView.swift
//  kitsui
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
//	var bibInst: Bible
	@State private var goChooseChapter = false
	@State private var selectedBook: Bible.bookLst?
	@State private var showOT = false
	@State private var showNT = true

	init(needChooseBook:Bool) {
		self.needChooseBook = needChooseBook
		self._goChooseChapter = State(wrappedValue: !needChooseBook)
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
									HStack {
										Text(bookLst.bookCode)
										Text(bookLst.bookName)
										Spacer()
										Text(bookLst.bookInNT ? "NT" : "OT")
									}
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
									HStack {
										Text(bookLst.bookCode)
										Text(bookLst.bookName)
										Spacer()
										Text(bookLst.bookInNT ? "NT" : "OT")
									}
								}
							},
							label: {
								Text("New Testament")
							}
						)
					}
				}
			}
			.onChange(of: self.selectedBook, perform: {_ in
				print("selectedBook changed to \(selectedBook!.bookName)")
				bibMod.getCurBibInst().setupChosenBook(selectedBook!)
				goChooseChapter = true
			})
		}
		.navigationDestination(isPresented: $goChooseChapter){
			ChooseChapterView(needChooseChapter: (bibMod.getCurBibInst().bookInst!.needChooseChapter)).environmentObject(bibMod)
		}
		.navigationTitle(bibMod.getCurBibName() + " - Choose Book")
	}
}


#Preview {
	ChooseBookView(needChooseBook: true)
}
