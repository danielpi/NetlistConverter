//
//  ModelClasses.swift
//  NetlistConverter
//
//  Created by Daniel Pink on 24/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

import Foundation
import Cocoa

class Pad: Printable {
    let pinNumber: Int?
    let pinName: String?
    let component: Component
    var name: String {
    var response = component.designator + "-"
    if let num = pinNumber {
        response += "\(num)"
    } else {
        if let nam = pinName {
            response += nam
        } else {
            response += "?"
        }
    }
    return response
    }
    var description: String {
    return self.name
    }
    
    init(pinNumber: Int?, pinName: String?, component: Component) {
        self.pinNumber = pinNumber
        self.pinName = pinName
        self.component = component
    }
    
    /*
    - I don't have a reliable way of referring to pads that are not named or numbered.
    - Should the pad have a reference to its net? This makes for a bit of a circular reference that needs to be kept in sync.
    */
}

class Component {
    var designator: String
    var footprint: String? = nil
    var value: String? = nil
    var pads: [Pad] = []
    
    init(designator: String) {
        self.designator = designator
    }
    /*deinit() {
        // Somehow we need to get rid of all the pads.
    }*/
    
    func description() -> String {
        var response = designator
        if let foot = footprint {
            response += " " + foot
        }
        if let val = value {
            response += " " + val
        }
        
        return response
    }
    /*
    - There should be a library of footprints. If there is then does the footprint contain the pads? Does the Component have a reference to pins?
    */
}

class Net {
    var name: String
    var pads: [Pad] = []
    
    init(name: String) {
        self.name = name
    }
    
    func description() -> String {
        var response = name + ":"
        for pad in pads {
            response += " " + pad.name
        }
        return response
    }
}


public class ConnectionMatrix {
    var rowHeaders: [String] {
        var orderedRowHeaders: [String] = Array(count:rowHeaderDictionary.count, repeatedValue: "")
        for (key, value) in rowHeaderDictionary {
            orderedRowHeaders[value] = key
        }
        return orderedRowHeaders
    }
    var colHeaders: [String] {
        var orderedColHeaders: [String] = Array(count:colHeaderDictionary.count, repeatedValue: "")
        for (key, value) in colHeaderDictionary {
            orderedColHeaders[value] = key
        }
        return orderedColHeaders
    }
    var rowHeaderDictionary: Dictionary<String, Int> = Dictionary()
    var colHeaderDictionary: Dictionary<String, Int> = Dictionary()
    var grid: [Bool]
    
    init(rowHeaders: [String], colHeaders: [String]) {
        let rowSet = NSSet(array: rowHeaders)
        let colSet = NSSet(array: colHeaders)
        assert(rowHeaders.count == rowSet.count, "There are duplicate labels in the Row Headers")
        assert(colHeaders.count == colSet.count, "There are duplicate labels in the Column Headers")
        
        for (index, row) in enumerate(rowHeaders) {
            self.rowHeaderDictionary[row] = index
        }
        for (index, col) in enumerate(colHeaders) {
            self.colHeaderDictionary[col] = index
        }
        grid = Array(count:self.rowHeaderDictionary.count * self.colHeaderDictionary.count, repeatedValue: false)
    }
    convenience init(nets: [Net]) {
        var headers: NSMutableSet = NSMutableSet()
        for net in nets {
            for pad in net.pads {
                headers.addObject(pad.name)
            }
        }
        let padLabels: [String] = headers.allObjects as [String]
        let sortedLabels = sorted(padLabels)
        self.init(rowHeaders: sortedLabels, colHeaders: sortedLabels)
        
        for net in nets {
            println(net.name)
            for pad in net.pads {
                for secondPad in net.pads {
                    self[pad.name, secondPad.name] = true
                }
            }
        }
    }
    
    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rowHeaderDictionary.count && column >= 0 && column < colHeaderDictionary.count
    }

    subscript(rowLabel: String, colLabel: String) -> Bool {
        get {
            let row = rowHeaderDictionary[rowLabel]
            let column = colHeaderDictionary[colLabel]
            assert(indexIsValidForRow(row!, column: column!), "Index out of range")
            return grid[(row! * colHeaderDictionary.count) + column!]
        }
        set {
            let row = rowHeaderDictionary[rowLabel]
            let column = colHeaderDictionary[colLabel]
            assert(indexIsValidForRow(row!, column: column!), "Index out of range")
            grid[(row! * colHeaderDictionary.count) + column!] = newValue
        }
    }
    subscript(row: Int, column: Int) -> Bool {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * colHeaderDictionary.count) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * colHeaderDictionary.count) + column] = newValue
        }
    }
    
    func connectNet(aNet: Net) {
        var connectionRow: [Bool] = Array(count: self.colHeaderDictionary.count, repeatedValue: false)
        for pad in aNet.pads {
            if let column = colHeaderDictionary[pad.name] {
                connectionRow[column] = true
            }
        }
        for pad in aNet.pads {
            if let row = rowHeaderDictionary[pad.name] {
                let startIndex: Int = row * colHeaderDictionary.count
                let finishIndex: Int = (row + 1) * colHeaderDictionary.count
                let aRange: Range = Range(start: startIndex, end: finishIndex)
                grid.replaceRange(aRange, with: connectionRow)
                //grid[subRange: aRange] = connectionRow
            }
        }
    }
    
    func description() -> String {
        var computationLength: Int64 = Int64(rowHeaderDictionary.count)
        var progress: NSProgress = NSProgress(totalUnitCount: computationLength)
        
        // Create the column header
        var response = "\t\t"
        for label in colHeaders {
            response += "\(label) "
        }
        response += "\n"
        
        // Create each row
        for (rowIndex, row) in enumerate(rowHeaders) {
            response += "\(row):\t"
            for (colIndex, col) in enumerate(colHeaders) {
                //let status = self[rowIndex, colIndex] ? 1 : 0
                //response += "\(status) "
                response += self[rowIndex, colIndex] ? "1 " : "0 "
            }
            response += "\n"
            progress.completedUnitCount++
        }
        return response
    }
    func prettyPrint() {
        print(self.description())
    }
}


public class Netlist {
    var components: [Component] = []
    var nets: [Net] = []
    var pads: [Pad] {
    get {
        var listOfPads: [Pad] = []
        for component in components {
            //println("\(component.description()) has \(component.pads.count) pads")
            for aPad in component.pads {
                listOfPads += [aPad]
            }
        }
        return listOfPads
    }
    }
    
    public init(){}
    public init(fromString string: String) {
        var componentBuffer: String? = nil
        var netBuffer: String? = nil
        
        for character in string {
            switch character {
            case "[":
                componentBuffer = "["
            case "]":
                let componentBufferCopy = componentBuffer! + "]"
                dispatch_async(dispatch_get_main_queue()) { self.parseComponent(fromString: componentBufferCopy) }
                componentBuffer = nil
            case "(":
                netBuffer = "("
            case ")":
                let netBufferCopy = netBuffer! + ")"
                dispatch_async(dispatch_get_main_queue()) { self.parseNet(fromString: netBufferCopy) }
                netBuffer = nil
            default:
                if (componentBuffer != nil) {
                    componentBuffer!.append(character)
                } else if (netBuffer != nil) {
                    netBuffer!.append(character)
                }
            }
        }
    }
    
    func parseComponent(fromString string: String) {
        let fragments = string.componentsSeparatedByString("\r\n")
        if fragments[0] == "[" {
            var aComponent = Component(designator: fragments[1])
            if countElements(fragments[2]) > 0 {
                aComponent.footprint = fragments[2]
            }
            if countElements(fragments[3]) > 0 {
                aComponent.value = fragments[3]
            }
            self.components += [aComponent]
        }
    }
    
    func parseNet(fromString string: String) {
        let fragments = string.componentsSeparatedByString("\r\n")
        //println(fragments)
        if fragments[0] == "(" {
            var aNet = Net(name: fragments[1])
            for padString in fragments[2..<(fragments.count - 1)] {
                let sections = padString.componentsSeparatedByString("-")
                var matchingComponents = self.components.filter { $0.designator == sections[0] }
                if matchingComponents.count > 0 {
                    var aComponent = matchingComponents[0]
                    let name: String? = (sections[1] == "") ? nil : sections[1]
                    let aPad = Pad(pinNumber: sections[1].toInt(), pinName: name, component: aComponent)
                    //pads += aPad
                    aComponent.pads += [aPad]
                    //println("added \(aPad.description()) to \(aComponent.description())")
                    aNet.pads += [aPad]
                } else {
                    println("\(padString) not found in the list of components")
                }
            }
            self.nets += [aNet]
        }
    }
    
    func net(forPad pad: Pad) -> Net? {
        // Search through the nets to see if the pad is present
        return nil
    }
    func connect(#pad: Pad, toPad: Pad) {
        // Find if either pad is a part of a net. 
        // if one or the other is but not both then add one to the net of the other
        // if both are in nets combine the two nets
        // if neither are in nets, create a new net and add them both
    }
    func connect(#net: Net, toNet: Net) {
        // Combine two nets
    }
    func connect(#pad: Pad, toNet: Net) {
        
    }
    
    
    func prettyPrint() {
        for component in components {
            println(component.description())
        }
        for net in nets {
            println(net.description())
        }
    }
    
    // Should this be a calculated property???
    public func exportConnectionMatrix() -> ConnectionMatrix {
        //let matrix: ConnectionMatrix = ConnectionMatrix(nets: nets)
        let sortedPads = sorted(pads){ $0.name < $1.name }
        let padLabels: [String] = sortedPads.map { $0.name }
        var matrix: ConnectionMatrix = ConnectionMatrix(rowHeaders: padLabels, colHeaders: padLabels)
        var computationLength: Int64 = Int64(self.nets.count)
        var progress: NSProgress = NSProgress(totalUnitCount: computationLength)
        
        netLoop: for net in self.nets {
            print(net.name + " ")
            if progress.cancelled {
                break //netLoop
            } else {
                matrix.connectNet(net)
            }
            ++progress.completedUnitCount
        }
        //println("exportConnectionMatrix complete: \(progress.fractionCompleted)")
        return matrix
    }
}
