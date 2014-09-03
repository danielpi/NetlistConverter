//
//  NetlistConverterTests.swift
//  NetlistConverter
//
//  Created by Daniel Pink on 16/07/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

//import Cocoa
import XCTest
import NetlistConverter

class NetlistConverterTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func loadNetlistToString(fileName: String) -> String? {
        let testBundle = NSBundle(forClass: NetlistConverterTests.classForKeyedArchiver())
        //println("fileName \(fileName)")
        let testDataPath = testBundle.pathForResource(fileName, ofType:"NET")
        //println(testDataPath)
        if let validTestDataPath = testDataPath {
            let testDataURL = NSURL(fileURLWithPath: validTestDataPath, isDirectory: false)
            let fileContents = String.stringWithContentsOfURL(testDataURL, encoding: NSUTF8StringEncoding, error: nil)
            return fileContents
        } else {
            return nil
        }
    }
    

    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testPerformanceOfNetlistRead() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
            //if let contents = self.fileContents {
            //    let fileNetlist = Netlist(fromString: contents)
            //}
        }
    }
    
    func performanceOfConversionMatrixCreationForFileNamed(fileName: String) {
        if let contents = loadNetlistToString(fileName) {
            let fileNetlist = Netlist(fromString: contents)
            
            self.measureBlock() {
                let conversionMatrix = fileNetlist.exportConnectionMatrix()
            }
        }
    }
    
    func testPerformanceOfSmallNetlist() {
        performanceOfConversionMatrixCreationForFileNamed("EI-385 Main")
    }
    
    func testPerformanceOfMediumNetlist() {
        performanceOfConversionMatrixCreationForFileNamed("EI-411 Project")
    }
    
    func testPerformanceOfSecondMediumNetlist() {
        performanceOfConversionMatrixCreationForFileNamed("EI-387 Main")
    }
    
    func testPerformanceOfLargeNetlist() {
        performanceOfConversionMatrixCreationForFileNamed("EI-360")
    }


}
