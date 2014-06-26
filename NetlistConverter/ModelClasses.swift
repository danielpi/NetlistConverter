//
//  ModelClasses.swift
//  NetlistConverter
//
//  Created by Daniel Pink on 24/06/2014.
//  Copyright (c) 2014 Electronic Innovations. All rights reserved.
//

import Foundation

struct Pad {
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
    var net: Net?
    
    func description() -> String {
        return self.name
    }
    /*
    - I don't have a reliable way of referring to pads that are not named or numbered.
    - Should the pad have a reference to its net? This makes for a bit of a circular reference that needs to be kept in sync.
    */
}

struct Component {
    var designator: String
    var footprint: String? = nil
    var value: String? = nil
    var pads: Pad[] = []
    
    init(designator: String) {
        self.designator = designator
    }
    
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
    var pads: Pad[] = []
    
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


struct ConnectionMatrix {
    let rowHeaders: String[]
    let colHeaders: String[]
    var grid: Bool[]
    init(rowHeaders: String[], colHeaders: String[]) {
        let rowSet = NSSet(array: rowHeaders)
        let colSet = NSSet(array: colHeaders)
        assert(rowHeaders.count == rowSet.count, "There are duplicate labels in the Row Headers")
        assert(colHeaders.count == colSet.count, "There are duplicate labels in the Column Headers")
        
        self.rowHeaders = rowHeaders
        self.colHeaders = colHeaders
        grid = Array(count:self.rowHeaders.count * self.colHeaders.count, repeatedValue: false)
    }
    
    func indexIsValidForRow(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rowHeaders.count && column >= 0 && column < colHeaders.count
    }
    func indexFor(label: String, inHeader header: String[]) -> Int {
        var index: Int = 0
        if let ind = find(header, label) {
            index = ind
        } else {
            assert(false, "No row with that label")
        }
        return index
    }
    func indexFor(#rowLabel: String) -> Int { return self.indexFor(rowLabel, inHeader: rowHeaders) }
    func indexFor(#colLabel: String) -> Int { return self.indexFor(colLabel, inHeader: colHeaders) }
    
    subscript(rowLabel: String, colLabel: String) -> Bool {
        get {
            let row = indexFor(rowLabel: rowLabel)
            let column = indexFor(colLabel: colLabel)
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * colHeaders.count) + column]
        }
        set {
            let row = indexFor(rowLabel: rowLabel)
            let column = indexFor(colLabel: colLabel)
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * colHeaders.count) + column] = newValue
        }
    }
    subscript(row: Int, column: Int) -> Bool {
        get {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            return grid[(row * colHeaders.count) + column]
        }
        set {
            assert(indexIsValidForRow(row, column: column), "Index out of range")
            grid[(row * colHeaders.count) + column] = newValue
        }
    }
    
    func description() -> String {
        // Create the column header
        var response = "\t\t"
        for label in colHeaders {
            response += "\(label) "
        }
        response += "\n"
        
        /*

for (index, element) in enumerate(list) {
println("Item \(index): \(element)")
}*/

        // Create each row
        for (rowIndex, row) in enumerate(rowHeaders) {
            response += "\(row):\t"
            for (colIndex, col) in enumerate(colHeaders) {
                let status = self[rowIndex, colIndex] ? 1 : 0
                response += "\(status) "
            }
            response += "\n"
        }
        
        return response
    }
    func prettyPrint() {
        print(self.description())
    }
}


class Netlist {
    var components: Component[] = []
    var nets: Net[] = []
    var pads: Pad[] = []
    
    init(){}
    init(fromString string: String) {
        var componentBuffer: String? = nil
        var netBuffer: String? = nil
        for character in string {
            switch character {
            case "[":
                componentBuffer = "["
            case "]":
                componentBuffer = componentBuffer! + "]"
                self.createComponent(fromString: componentBuffer!)
                componentBuffer = nil
            case "(":
                netBuffer = "("
            case ")":
                netBuffer = netBuffer! + "]"
                self.createNet(fromString: netBuffer!)
                netBuffer = nil
            default:
                if componentBuffer {
                    componentBuffer = componentBuffer! + character
                } else if netBuffer {
                    netBuffer = netBuffer! + character
                }
            }
        }
    }
    
    func createComponent(fromString string: String) {
        let fragments = string.componentsSeparatedByString("\r\n")
        if fragments[0] == "[" {
            var aComponent = Component(designator: fragments[1])
            if countElements(fragments[2]) > 0 {
                aComponent.footprint = fragments[2]
            }
            if countElements(fragments[3]) > 0 {
                aComponent.value = fragments[3]
            }
            self.components += aComponent
        }
    }
    
    func createNet(fromString string: String) {
        let fragments = string.componentsSeparatedByString("\r\n")
        if fragments[0] == "(" {
            var aNet = Net(name: fragments[1])
            for padString in fragments[2..fragments.count] {
                let sections = padString.componentsSeparatedByString("-")
                var matchingComponents = self.components.filter { $0.designator == sections[0] }
                if matchingComponents.count > 0 {
                    var aComponent = matchingComponents[0]
                    let name: String? = (sections[1] == "") ? nil : sections[1]
                    let aPad = Pad(pinNumber: sections[1].toInt(), pinName: name, component: aComponent, net: aNet)
                    pads += aPad
                    aComponent.pads += aPad
                    aNet.pads += aPad
                }
            }
            self.nets += aNet
        }
    }
    
    func prettyPrint() {
        for component in components {
            println(component.description())
        }
        for net in nets {
            println(net.description())
        }
    }
    
    func exportConnectionMatrix2() -> String {
        var response: String = ""
        let sortedPads = sort(pads) { $0.name < $1.name }
        
        for pad in sortedPads {
            response += pad.name + ":"
            println(pad.description())
            for secondPad in sortedPads {
                if let net = pad.net {
                    let matchingPads = net.pads.filter { $0.name == secondPad.name }
                    if matchingPads.count > 0 {
                        response += " 1"
                    } else {
                        response += " 0"
                    }
                } else {
                    response += " 0"
                }
            }
            response += "\n"
        }
        return response
    }
    func exportConnectionMatrix() -> String {
        let sortedPads = sort(pads) { $0.name < $1.name }
        let padLabels: String[] = sortedPads.map { $0.name }
        var matrix: ConnectionMatrix = ConnectionMatrix(rowHeaders: padLabels, colHeaders: padLabels)
        
        for net in nets {
            println(net.name)
            for pad in net.pads {
                for secondPad in net.pads {
                    matrix[pad.name, secondPad.name] = true
                }
            }
        }
        
        return matrix.description()
    }
}
/*
let strings = numbers.map {
    (var number) -> String in
    var output = ""
    while number > 0 {
        output = digitNames[number % 10]! + output
        number /= 10
    }
    return output
}
*/