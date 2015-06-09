//
//  AppDelegate.swift
//  NetlistConverter
//
//  Created by Daniel Pink on 24/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {
                            
    @IBOutlet var window: NSWindow!
    var netlist: Netlist? = nil
    @IBOutlet var progressIndicator : NSProgressIndicator!
    @IBOutlet var cancelButton : NSButton!
    
    var numericOrder = false

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        self.progressIndicator.hidden = true
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func loadNetlist(sender : AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a Netlist file"
        panel.allowedFileTypes = ["net", "NET", "repnl", "REPNL"]
        
        let completionBlock: (Int) -> Void = {
            result in
            if result == NSFileHandlingPanelOKButton {
                let urls = panel.URLs as NSArray
                let url = urls.firstObject as! NSURL
                let fileContents: NSString?
                do {
                    fileContents = try NSString(contentsOfURL: url, encoding: NSUTF8StringEncoding)
                } catch _ {
                    fileContents = nil
                }
                if let contents = fileContents, let pathExt = url.pathExtension {
                    switch pathExt {
                    case "net", "NET":
                        self.numericOrder = false
                        let fileNetlist = Netlist(fromString: contents as String)
                        self.netlist = Netlist(fromString: contents as String)
                        fileNetlist.prettyPrint()
                    case "repnl", "REPNL":
                        self.numericOrder = true
                        //let fileNetlist = Netlist(REPNLFromString as REPNLString: contents)
                        let fileNetlist = Netlist(REPNLFromString: contents as REPNLString)
                        self.netlist = fileNetlist
                        fileNetlist.prettyPrint()
                    default:
                        print("Tried to use a txt file")
                    }
                    
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
        let completionBlock: (Int) -> Void = { result in
            if result == NSFileHandlingPanelOKButton {
                if let url = panel.URL {
                    if let theNetList = self.netlist {
                        // Set up a progress object
                        self.progressIndicator.hidden = false
                        let progress = NSProgress(totalUnitCount: 2)
                        let options : NSKeyValueObservingOptions = [.New, .Old, .Initial, .Prior]
                        progress.addObserver(self, forKeyPath: "fractionCompleted", options: options, context: nil)
                        
                        let queue: dispatch_queue_t = dispatch_queue_create("My Queue", DISPATCH_QUEUE_SERIAL)
                        
                        dispatch_async(queue) {
                            progress.becomeCurrentWithPendingUnitCount(1)
                            let connectionMatrix = theNetList.exportConnectionMatrix(self.numericOrder)
                            progress.resignCurrent()
                            progress.becomeCurrentWithPendingUnitCount(1)
                            let output = connectionMatrix.description(!(self.numericOrder))
                            do {
                                //print(output)
                                try output.writeToURL(url, atomically: true, encoding: NSMacOSRomanStringEncoding)
                            } catch _ {
                            }
                            progress.resignCurrent()
                        }
                    }
                }
            }
        }
        panel.beginSheetModalForWindow(self.window, completionHandler: completionBlock)
    }
    
    @IBAction func cancelOperation(sender : AnyObject) {
    }
    
    //override func observeValueForKeyPath(keyPath: String!, ofObject object: AnyObject!, change: [NSObject : AnyObject]!, context: UnsafePointer<()>) {
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [NSObject : AnyObject]?, context: UnsafeMutablePointer<()>) {
        NSOperationQueue.mainQueue().addOperationWithBlock( {
                let progress = object as! NSProgress
                self.progressIndicator.doubleValue = ceil(progress.fractionCompleted * 100.0) / 100.0
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

