//
//  ContentView.swift
//  kitsui
//
//  Created by Graeme Costin on 15/11/2023.
//
//	In place of a legal notice, here is a blessing:
//
//	May you do good and not evil.
//	May you find forgiveness for yourself and forgive others.
//	May you share freely, never taking more than you give.

import SwiftUI

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
		self._goChooseBook = State(wrappedValue: !needSetup)
	}

	func getBibleName () -> String {
		@EnvironmentObject var bibMod: BibleModel
		return bibMod.getCurBibName()
	}

    var body: some View {
        NavigationStack {
            VStack {
                RoundedRectImage(roundRect: Image("KITLogoD"))
                Form {
                    Section {
                        TextField("Bible Name", text: $editedName, onEditingChanged: {
                            (changed) in
                            if changed {
                                print("Bible Name edit has begun")
                            } else {
                                print("Editing Bible Name")
                            }
                        })
                        .textFieldStyle(.roundedBorder)
                        .font(.title)
                    } header: {
                        Text("Name of Bible")
                    }
                }
                Spacer()
                Button("Go to Choose Book") {
					bibMod.bibleUpdateName(editedName)
                    goChooseBook = true
                }
                Spacer()
            }
			.navigationDestination(isPresented: $goChooseBook){
				ChooseBookView(needChooseBook: (bibMod.getCurBibInst().currBk == 0)).environmentObject(bibMod)
			}
		}
		.padding()
    }
}

#Preview {
	SetupView(bibleName: "Bible", needSetup: true)
}
