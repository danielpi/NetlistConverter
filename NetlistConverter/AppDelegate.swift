//
//  AppDelegate.swift
//  NetlistConverter
//
//  Created by Daniel Pink on 24/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow
    var netlist: Netlist? = nil


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification?) {
        // Insert code here to tear down your application
    }

    @IBAction func loadNetlist(sender : AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a Netlist file"
        panel.allowedFileTypes = ["net", "NET"]
        
        let completionBlock: (Int) -> Void = {
            result in
            if result == NSFileHandlingPanelOKButton {
                let urls = panel.URLs as NSArray
                let url = urls.firstObject as NSURL
                let fileContents = String.stringWithContentsOfURL(url, encoding: NSUTF8StringEncoding, error: nil)
                if let contents = fileContents {
                    let fileNetlist = Netlist(fromString: contents)
                    self.netlist = fileNetlist
                } else {
                    
                }
                
            }
        }
        
        panel.beginSheetModalForWindow(self.window, completionHandler: completionBlock)
    }

    @IBAction func exportMatrix(sender : AnyObject) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["txt"]
        panel.message = "Where do you want to save the connection matrix to?"
        panel.nameFieldStringValue = "ConnectionMatrix"
        let completionBlock: (Int) -> Void = {
            result in
            if result == NSFileHandlingPanelOKButton {
                let url = panel.URL
                if let theNetList = self.netlist {
                    let outputString = theNetList.exportConnectionMatrix()
                    outputString.writeToURL(url, atomically: true, encoding: NSMacOSRomanStringEncoding, error: nil)
                }
                
            }
        }
        panel.beginSheetModalForWindow(self.window, completionHandler: completionBlock)
    }
}

