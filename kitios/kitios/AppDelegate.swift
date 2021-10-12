//
//  AppDelegate.swift
//
//	GDLC 27JUL21 Started adding ReportError()
//	GDLC 23JUL21 Cleaned out print commands (were used in early stages of development)
//
//  Created by Graeme Costin on 4MAY20.
//
// In place of a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?		// This UIWindow property must be implemented for AppDelegate
								// to use a storyboard file.

	// A reference to the one and only KITDAO instance is kept in the AppDelegate
	// so that all parts of the app can use it. The KITDAO instance is needed for
	// the entire duration of the run of kitios. It is used in the instances of
	// Bible, Book, and Chapter - only these modules interact with the SQLite database.
	var dao: KITDAO?				// This is a strong ref to keep the instance of KITDAO for the life of the run of the app
		
	var bibInst: Bible?				// During the launch of KIT an instance of the class Bible will be created
									// This is the strong ref to bibInst which lasts for the entire run of the app
	weak var bookInst: Book?		// Once launching is complete there will be an instance of the current Book
									// Weak ref; the strong ref is in the Bible instance
	weak var chapInst: Chapter?		// Once launching is complete there will be an instance of the current Chapter
									// Weak ref; the strong ref is in Book instance
	weak var VTVCtrl: VersesTableViewController?
			// Once a Chapter of a Book is opened there will be a VersesTableViewController
			// Weak ref; the strong ref is just itself, and the various references to it are weak refs

	// May be used by the function ReportError()
	var errorNum: Int = 0		// Error number to report to the developers; see list in ErrorNumbers.swift

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		dao = KITDAO()	// create an instance of the Data Access Object and keep reference to it

		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		// Save the current VerseItem if necessary
		if VTVCtrl != nil {
			VTVCtrl!.saveCurrentItemText()
		}
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		// KIT does not do background execution so nothing to do here.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		
		// KIT does not enter background execution so nothing to do here.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		
		// KIT needs to delete its instance of the class Bible and all the instances that are owned by it,
		// including the instance of KITDAO (which closes the kdb.sqlite database)
		bibInst = nil
	}

	// Function for reporting error conditions to the user and exiting the app
	func ReportError (_ errNo:Int) {
		var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
		topWindow?.rootViewController = UIViewController()
		topWindow?.windowLevel = UIWindow.Level.alert + 1

		let alert = UIAlertController(title: "Fatal Error", message: "Please report Error No. \(errNo) to the developers", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
			// At present only fatal errors are considered; if non-fatal errors are handled
			// additional code can be put in here so that KIT continues after the user has
			// clicked OK to the warning
			exit(0)

			// Next two lines hide the window if KIT is to continue running
			// and also keeps a reference to the window until the action is invoked.
			topWindow?.isHidden = true	// Hide the window
			topWindow = nil				// Delete the topwindow
		 })
		
		topWindow?.makeKeyAndVisible()
		topWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}

	// Function for reporting and error warning to the user and allowing app to proceed
	func ReportWarning (_ errNo:Int) {
		var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
		topWindow?.rootViewController = UIViewController()
		topWindow?.windowLevel = UIWindow.Level.alert + 1

		let alert = UIAlertController(title: "Warning", message: "Error No. \(errNo) occurred", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
			// At present only fatal errors are considered; if non-fatal errors are handled
			// additional code can be put in here so that KIT continues after the user has
			// clicked OK to the warning

			// Next two lines hide the window if KIT is to continue running
			// and also keeps a reference to the window until the action is invoked.
			topWindow?.isHidden = true	// Hide the window
			topWindow = nil				// Delete the topwindow
		 })
		
		topWindow?.makeKeyAndVisible()
		topWindow?.rootViewController?.present(alert, animated: true, completion: nil)
	}
}
