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
	var needChooseChapter: Bool
	@State var goEditChapter = false
	
	init(needChooseChapter:Bool) {
		self.needChooseChapter = needChooseChapter
		self._goEditChapter = State(wrappedValue: !needChooseChapter)
	}

	private var gridItemLayout = Array(repeating: GridItem(.flexible(), spacing: 40), count: 5)
	
	var body: some View {
		NavigationStack {
			// 5 column flexible horizontal grid layout
			ScrollView(.horizontal) {
				LazyVGrid(columns: gridItemLayout, spacing: 10) {
					ForEach(bibMod.getCurBibInst().bookInst!.chapsInBk, id: \.self) { chapLst in
						Text("\(chapLst.chapNum)")
							.font(.title)
					}
				}
			}
		}
		.navigationDestination(isPresented: $goEditChapter){
			EditChapterView().environmentObject(bibMod)
		}
		.navigationTitle(bibMod.getCurBibName() + " - Choose Chapter")
    }
}

#Preview {
	ChooseChapterView(needChooseChapter: true)
}
