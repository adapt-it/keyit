//
//	RoundedRectImage.swift
//	kitsui
//
//	Created by Graeme Costin on 16/11/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

struct RoundedRectImage: View {
	var roundRect: Image
    
	var body: some View {
		roundRect
		.clipShape(RoundedRectangle(cornerRadius: 25))
		.imageScale(.small)
    }
}

struct RoundRectImage_Previews: PreviewProvider {
    static var previews: some View {
        RoundedRectImage(roundRect: Image("KITLogoD"))
    }
}
