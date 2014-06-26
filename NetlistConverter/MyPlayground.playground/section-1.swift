// Playground - noun: a place where people can play

import Cocoa

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
            response += "?"
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


let a = ["a","b","c","b"]
find(a,"b")
find(a,"d")
let indexes = filter(a){ $0 == "b" }
println(indexes)

class ConnectionMatrix {
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
    
    func description() -> String {
        // Create the column header
        var response = "\t"
        for label in colHeaders {
            response += "\(label)\t"
        }
        response += "\n"
        
        // Create each row
        for row in rowHeaders {
            response += "\(row):\t"
            for col in colHeaders {
                let status = self[row,col] ? 1 : 0
                response += "\(status)\t"
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
                    let aPad = Pad(pinNumber: sections[1].toInt(), pinName: nil, component: aComponent, net: aNet)
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
    
    func exportConnectionMatrix() -> String {
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
    func exportConnectionMatrix2() -> String {
        let sortedPads = sort(pads) { $0.name < $1.name }
        var matrix: ConnectionMatrix = ConnectionMatrix(rowHeaders: sortedPads, colHeaders: sortedPads)
        return "blah"
    }
}


// Netlist
var aNetlist: Netlist = Netlist()
aNetlist.createComponent(fromString: "[\nR8\nAXIAL-0.4\n4K7\n\n\n\n]")

for component in aNetlist.components {
    //println(component.description())
}

aNetlist.createNet(fromString:"(\nNET14\nIC2-2\nR7-1\nR8-2\n)")

//aNetlist.prettyPrint()

let netlistString = "[\nR1\nAXIAL-0.4\n4K7\n\n\n\n]\n[\nR2\nAXIAL-0.4\n4K7\n\n\n\n]\n(\nNET1\nR1-2\nR2-1\n)\n(\nNET2\nR2-2\n)\n(\nNET3\nR1-1\n)\n"
var anotherNetlist = Netlist(fromString: netlistString)
anotherNetlist.prettyPrint()
println(anotherNetlist.exportConnectionMatrix())


for pad in anotherNetlist.pads {
    println(pad.net!.description())
}

/*
var connections = ConnectionMatrix(rowHeaders: ["a","b","c"], colHeaders: ["a","b","c"])
connections.prettyPrint()
connections["a","a"] = true
connections["b","b"] = true
connections["c","c"] = true
connections["a","b"] = true
connections["b","c"] = true
connections["c","a"] = true
connections.prettyPrint()
// connections["a","d"]


struct Matrix {
let rows: Int, columns: Int
var grid: Double[]
init(rows: Int, columns: Int) {
self.rows = rows
self.columns = columns
grid = Array(count: rows * columns, repeatedValue: 0.0)
}
func indexIsValidForRow(row: Int, column: Int) -> Bool {
return row >= 0 && row < rows && column >= 0 && column < columns
}
subscript(row: Int, column: Int) -> Double {
get {
assert(indexIsValidForRow(row, column: column), "Index out of range")
return grid[(row * columns) + column]
}
set {
assert(indexIsValidForRow(row, column: column), "Index out of range")
grid[(row * columns) + column] = newValue
}
}
}
var matrix = Matrix(rows: 2, columns: 2)
matrix[0, 1] = 1.5
matrix[1, 0] = 3.2
matrix
*/




// TUM exercize
// stddev(latitude)=5.4477688039°⋅10−06
// stddev(longitude)=9.89285349017°⋅10−06

// 1° of latitude corresponds to 111195.38097356868 m
// 1° of longitude corresponds to 74246.69042433369 m

let oneDegreeLat = 111195.38097356868
let oneDegreeLon = 74246.69042433369

let stdDevLat = 5.4477688039e-6
let stdDevlon = 9.89285349017e-6

oneDegreeLat * stdDevLat
oneDegreeLon * stdDevlon





// Components
//let componentA = Component(designator: "R1", footprint: nil, value: nil, pads:nil)
//let componentB = Component(fromString: "[\nR9\nAXIAL-0.4\n4K7\n\n\n\n]")
//componentA.description()

//var components = Component[]()
//components += Component(fromString: "[\nR8\nAXIAL-0.4\n4K7\n\n\n\n]")
//components += Component(fromString: "[\nR9\nAXIAL-0.4\n4K7\n\n\n\n]")

//for component in components {
//    println(component.description())
//}

// Pad
//let aPad = Pad(pinNumber: 1, pinName: nil, component: componentA, net: nil)
//aPad.name

//let padIdentifierString = "R8-2"


// Nets
//let netString14 = "(\nNET14\nIC2-2\nR7-1\nR8-2\n)"


