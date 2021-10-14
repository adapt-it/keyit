### What is this repository for? ###

* Development of Key It as an iOS app (referred to in this documentation as kitios) and
  as an Android app (referred to in this documentation as kitand)

### How do I get set up for iOS? ###

* Get Xcode 12 
* Use Xcode's Source Control to clone the repo from Github, and open the Xcode project
* The SQLite database that is included in recent iOS systems is used. The Xcode project
  includes settings to use the bridge from Swift to C for source code that calls the
  C API of SQLite.

### How do I get set up for Android? ###

* Get Android Studio Arctic Fox
* Use Android Studio's Git menu to clone the repo from Github, and open the file build.gradle
* The SQLite database that is included in recent Android systems is used. The kitand sources
  use Android's SQLiteOpenHelper and its API to deal with the SQLite database.

### Contribution guidelines ###

* On iOS all interaction with SQLite is kept inside the file KITDAO.swift - the rest of the
  code is straight Swift code.
  On Android all interaction with SQLite is kept inside the file KITDAO.kt - the rest of the
  code is straight Kotlin code.

* Comments about the software design are contained in comments in the source code.

* There are two design documents that describe and give some details of the app design:

	KIT Design Document.odt
	
	KIT Design Document Popovers.ods

### Whom do I talk to? ###

* Developer of this Github repo is Graeme Costin - graeme_costin@wycliffe.org.au.

* This app will be released as an open source freeware app provided by Wycliffe Bible Translators.
