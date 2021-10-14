# README #

### What is this repository for? ###

* Development of Key It as an Android app

### How do I get set up for Android? ###

* Get Android Studio Arctic Fox
* Use Android Studio's Git menu to clone the repo from Github, and open the file build.gradle
* The SQLite database that is included in recent Android systems is used. The kitand sources
  use Android's SQLiteOpenHelper and its API to deal with the SQLite database.

### Contribution guidelines ###

* On Android all interaction with SQLite is kept inside the file KITDAO.kt - the rest of the
  code is straight Kotlin code.

* Comments about the software design are contained in comments in the source code.

* There are two design documents that describe and give some details of the app design:

	KIT Design Document.odt
	
	KIT Design Document Popovers.ods

### To whom do I talk? ###

Graeme Costin	graeme_costin@wycliffe.org.au

Erik Brommers	erik_brommers@sil.org

Bruce Waters	bruce_waters@sil.org
