//
//  ShowUSFMView.swift
//  kitsui
//
//  Created by Graeme Costin on 24/5/2024.
//

import SwiftUI

struct ShowUSFMView: View {
	@EnvironmentObject var bibMod: BibleModel

	var body: some View {
		NavigationStack {
			ScrollView {
				Text("\(bibMod.getCurBibInst().bookInst!.chapInst!.USFMText)")
					.font(.system(size: 13))
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.navigationTitle("USFM for \(bibMod.getCurBookName()) \(getChapterName()) \(getChapterNumber())")
	}
/*
 ScrollView {
	 VStack {
		 Text(someString)
			 .fixedSize(horizontal: false, vertical: true)
		 Text(anotherLongString)
			 .fixedSize(horizontal: false, vertical: true)
	 }
 }
 */
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
}

#Preview {
    ShowUSFMView()
}
