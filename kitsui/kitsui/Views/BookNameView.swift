//
//  BookNameView.swift
//  kitsui
//
//  Created by Graeme Costin on 12/2/2024.
//

import SwiftUI

struct BookNameView: View {
	@EnvironmentObject var bibMod: BibleModel

	var bookLst: Bible.bookLst
	
    var body: some View {
		GeometryReader { geometry in
			ZStack {
				if #available(iOS 17.0, *) {
					Rectangle()
						.strokeBorder(selectBorderColour(bookLst), lineWidth: 2)
//						.fill(Color.init(red: 200, green: 200, blue: 200))
						.frame(width: geometry.size.width, height: 30)
				} else {
					Rectangle()
						.stroke(selectBorderColour(bookLst))
						.frame(width: geometry.size.width, height: 30)
				}
				HStack {
					Text(bookLst.bookCode)
					Text(bookLst.bookName)
					Spacer()
					Text(bookLst.bookInNT ? "NT" : "OT")
				}
				.foregroundColor(selectTextColour(bookLst))
			}
			// TODO: Builds but does nothing!
//			.listRowBackground(bookLst.selected ? Color.accentColor : Color(.clear))
		}
    }
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

#Preview {
	Group {
		BookNameView(bookLst: Bible.bookLst(bookID: 41, bookCode: "MAT", bookName: "Matthew", bookInNT: true, selected: false))
		BookNameView(bookLst: Bible.bookLst(bookID: 42, bookCode: "MAR", bookName: "Mark", bookInNT: true, selected: false))
		BookNameView(bookLst: Bible.bookLst(bookID: 43, bookCode: "LUK", bookName: "Luke", bookInNT: true, selected: true))
		BookNameView(bookLst: Bible.bookLst(bookID: 44, bookCode: "JHN", bookName: "John", bookInNT: true, selected: false))
	}
}
