//
//  SetupView.swift
//  kitsui
//
//	GDLC 20FEB25 Added use of Bible.launching
//
//  Created by Graeme Costin on 15/11/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI
import Foundation

struct SetupView: View {
    @EnvironmentObject var bibMod: BibleModel
	var bibleName: String
	var needSetup: Bool
	@State var goChooseBook = false
	@State var editedName: String
	
	init(bibleName:String, needSetup:Bool) {
		self.bibleName = bibleName
		self._editedName = State(wrappedValue: bibleName)
		self.needSetup = needSetup
// GDLC 6FEB24 Removed this setting of goChooseBook so that it is not set true until
// onAppear(), by which time all initialisations will have been done.
//		self._goChooseBook = State(wrappedValue: !needSetup)
	}

	var body: some View {
        NavigationStack {
            VStack {
                RoundedRectImage(roundRect: Image("KITLogoD"))
				Text(bibMod.getCurBibName() + " Set Up")
					.font(.system(size: 20.0))
				Spacer()
                Form {
                    Section {
                        TextField("Bible Name", text: $editedName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title)
                    } header: {
                        Text("Name of Bible")
                    }
                }
                Spacer()
                Button("Go to Choose Book") {
					bibMod.bibleUpdateName(editedName)
					bibMod.needSetup = false
                    goChooseBook = true
                }
                Spacer()
				Text("\(getAppVersion())")
					.font(.system(size: 10.0))
            }
			.navigationDestination(isPresented: $goChooseBook){
				ChooseBookView(needChooseBook: bibMod.getCurBibInst().needChooseBook).environmentObject(bibMod)
			}
		}
		.padding()
		.onAppear() {
			if !needSetup && bibMod.getCurBibInst().launching {
				goChooseBook = true
			}
		}
    }

	func getAppVersion() -> String {
		var appVerText: String
		if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
			appVerText = "App version: \(appVersion)"
			if let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
				appVerText = appVerText + " (" + buildNumber + ")"
			}
		} else {
			appVerText = "App version not available."
		}
		return appVerText
	}
}

#Preview {
	SetupView(bibleName: "Bible", needSetup: true)
}
