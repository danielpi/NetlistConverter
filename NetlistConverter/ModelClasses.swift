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
}
