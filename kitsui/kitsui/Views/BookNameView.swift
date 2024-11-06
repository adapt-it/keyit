//
//  BookNameView.swift
//  kitsui
//
//  Created by Graeme Costin on 12/2/2024.
//	02NOV24 Removed attempts at drawing a border around the Book name
//

import SwiftUI

struct BookNameView: View {
	@EnvironmentObject var bibMod: BibleModel
	
	var bookLst: Bible.bookLst
	
	var body: some View {
//GDLC 02NOV24 removed code for border
//		GeometryReader { geometry in
			//			ZStack {
			//				if #available(iOS 17.0, *) {
			//					Rectangle()
			//						.strokeBorder(selectBorderColour(bookLst), lineWidth: 2)
			//						.fill(Color.init(red: 200, green: 200, blue: 200))
			//						.frame(width: geometry.size.width, height: 30)
			//				} else {
			//					Rectangle()
			//						.stroke(selectBorderColour(bookLst))
			//						.frame(width: geometry.size.width, height: 30)
			//				}
			HStack {
				Text(bookLst.bookCode)
				Text(bookLst.bookName)
				Spacer()
				Text(description(bookLst))
			}
			.foregroundColor(selectTextColour(bookLst))
			//			}
			// TODO: Builds but does nothing!
			//			.listRowBackground(bookLst.selected ? Color.accentColor : Color(.clear))
//		}
	}
	
	func description (_ bookLst:Bible.bookLst) -> String {
		var descrTxt = ""
		if bookLst.numChaps > 0 {
			descrTxt = "\(bookLst.numChaps) "
			if bookLst.bookCode == "PSA" {
				descrTxt = descrTxt + "Ps"
			} else {
				descrTxt = descrTxt + "Ch"
			}
		}
		return descrTxt
	}
	
	func selectTextColour(_ bookLst:Bible.bookLst) -> Color {
		if bookLst.selected {
			return Color.red
		} else {
			return Color.black
		}
	}
	
	func selectBorderColour(_ bookLst:Bible.bookLst) -> Color {
		if bookLst.selected {
			return Color.init(red: 200, green: 200, blue: 200)
		} else {
			return Color.clear
		}
	}
}

#Preview {
	Group {
		BookNameView(bookLst: Bible.bookLst(bookID: 41, bookCode: "MAT", bookName: "Matthew", numChaps: 28, bookInNT: true, selected: false))
		BookNameView(bookLst: Bible.bookLst(bookID: 42, bookCode: "MAR", bookName: "Mark", numChaps: 16, bookInNT: true, selected: false))
		BookNameView(bookLst: Bible.bookLst(bookID: 43, bookCode: "LUK", bookName: "Luke", numChaps: 24, bookInNT: true, selected: true))
		BookNameView(bookLst: Bible.bookLst(bookID: 19, bookCode: "PSA", bookName: "Psalms", numChaps: 150, bookInNT: false, selected: false))
	}
}
