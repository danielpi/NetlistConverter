# Netlist Converter
A program to convert a Protel netlist into a connection matrix. Written in Swift.

Here is an example of the key parts of a netlist file. The sile starts off with a list of all of the components on in the schematic. A designator, footprint name and description are typically included. Then there is a list of all of the nets from the circuit.

    [
    ZD1
    0805A DIODE
    6V2
    ]
    [
    ZD2
    0805A DIODE
    3V9
    ]
    (
    NetC24_2
    C24-2
    R13-2
    R14-2
    )
    (
    NetC26_1
    C26-1
    R14-1
    U16-6
    )

This program will read in a netlist file and output a connection matrix. A portion of a connection matrix is shown below. It is a square matrix with a row and column for every pad in the circuit. The data then shows a value of 1 for every two pads that are connected to each other. The connection matrix can be used with the Matlab find command to efficiently work with this sort of data.


		    BR1-1 BR1-2 BR1-3 BR1-4 C1-1 C1-2 C10-1 C10-2 C11-1 C11-2 C12-1
    BR1-1:	1 0 0 0 0 0 0 0 0 0 0
    BR1-2:	0 1 0 0 0 0 0 0 0 0 0
    BR1-3:	0 0 1 0 0 0 0 0 0 0 0
    BR1-4:	0 0 0 1 0 1 0 1 0 1 0
    C1-1:	0 0 0 0 1 0 1 0 0 0 0
    C1-2:	0 0 0 1 0 1 0 1 0 1 0
    C10-1:	0 0 0 0 1 0 1 0 0 0 0
    C10-2:	0 0 0 1 0 1 0 1 0 1 0
    C11-1:	0 0 0 0 0 0 0 0 1 0 0
    C11-2:	0 0 0 1 0 1 0 1 0 1 0
    C12-1:	0 0 0 0 0 0 0 0 0 0 1
