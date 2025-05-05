//
//  ChapterNumberView.swift
//  kitios
//
//  Created by Graeme Costin on 9/1/2024.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct ChapterNumberView: View {
	@EnvironmentObject var bibMod: BibleModel

	var chp: Book.BibChap

    var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 10, style: .continuous)
				.stroke(getTextColour(), lineWidth: CGFloat(getLineWidth()))
				.frame(width: 50, height: 50, alignment: Alignment.top)
			Text("\(chp.chNum)")
				.font(.system(size: 30))
		}
		.foregroundColor(getTextColour())
	}

	func getTextColour() -> Color {
		if chp.selected {
			return Color.red
		} else {
			return Color.gray
		}
	}

	func getLineWidth() -> Int {
		if chp.selected {
			return 3
		} else {
			return 1
		}
	}
}

#Preview {
	Group {
		ChapterNumberView(chp: Book.BibChap(chID: 4, bibID: 1, bkID: 41, chNum: 2, itRCr: true, numVs: 28, numIt: 28, curIt: 1, curVN: 1, selected: false))
		ChapterNumberView(chp: Book.BibChap(chID: 5, bibID: 1, bkID: 41, chNum: 3, itRCr: true, numVs: 22, numIt: 22, curIt: 28, curVN: 1, selected: false))
		ChapterNumberView(chp: Book.BibChap(chID: 6, bibID: 1, bkID: 41, chNum: 4, itRCr: true, numVs: 32, numIt: 32, curIt: 38, curVN: 2, selected: true))
	}
}
