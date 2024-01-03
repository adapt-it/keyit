# README #

### What is the kitios repository for? ###

* Development of Key It as an iOS app

### How do I get set up for iOS? ###

* Get Xcode 12 or later
* Use Xcode's Source Control to clone the repo from Github, and open the Xcode project
* The SQLite database that is included in recent iOS systems is used. The Xcode project
  includes settings to use the bridge from Swift to C for source code that calls the
  C API of SQLite.

### Contribution guidelines ###

* On iOS all interaction with SQLite is kept inside the file KITDAO.swift - the rest of the
  code is straight Swift code.

* Comments about the software design are contained in comments in the source code.

* There are two design documents that describe and give some details of the app design:

	KIT Design Document.odt
	
	KIT Design Document Popovers.ods

### To whom do I talk? ###

Graeme Costin	graeme_costin@wycliffe.org.au

Erik Brommers	erik_brommers@sil.org

Bruce Waters	bruce_waters@sil.org
