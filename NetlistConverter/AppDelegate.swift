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
    @IBOutlet var progressIndicator : NSProgressIndicator
    @IBOutlet var cancelButton : NSButton


    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        // Insert code here to initialize your application
        self.progressIndicator.hidden = true
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
                    fileNetlist.prettyPrint()
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
                    // Set up a progress object
                    self.progressIndicator.hidden = false
                    let progress = NSProgress(totalUnitCount: 2)
                    let options : NSKeyValueObservingOptions = .New | .Old | .Initial | .Prior
                    progress.addObserver(self, forKeyPath: "fractionCompleted", options: options, context: nil)
                    
                    let queue: dispatch_queue_t = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL)
                    
                    dispatch_async(queue) {
                        progress.becomeCurrentWithPendingUnitCount(1)
                        let connectionMatrix = theNetList.exportConnectionMatrix()
                        progress.resignCurrent()
                        progress.becomeCurrentWithPendingUnitCount(1)
                        let output = connectionMatrix.description()
                        print(output)
                        output.writeToURL(url, atomically: true, encoding: NSMacOSRomanStringEncoding, error: nil)
                        progress.resignCurrent()
                    }
                }
            }
        }
        panel.beginSheetModalForWindow(self.window, completionHandler: completionBlock)
    }
    
    @IBAction func cancelOperation(sender : AnyObject) {
    }
    
    override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafePointer<()>) {
        //println("Observed Something")
        NSOperationQueue.mainQueue().addOperationWithBlock( {
                let progress = object as NSProgress
                self.progressIndicator.doubleValue = progress.fractionCompleted
                //println("\(progress.fractionCompleted)")
            } )
    }
/*
    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
        change:(NSDictionary *)change context:(void *)context
        {
            if (context == ProgressObserverContext)
            {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSProgress *progress = object;
            self.progressBar.progress = progress.fractionCompleted;
            self.progressLabel.text = progress.localizedDescription;
            self.progressAdditionalInfoLabel.text =
            progress.localizedAdditionalDescription;
            }];
            }
            else
            {
            [super observeValueForKeyPath:keyPath ofObject:object
            change:change context:context];
        }
    }
    */




}

