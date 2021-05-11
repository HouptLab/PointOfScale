//
//  ScalePeripheral.swift
//  PointOfScale
//
//  Created by Tom Houpt on 20/11/15.
//

import Foundation
import CoreBluetooth
/*
<CBPeripheral: 0x280ff9b80, identifier = 7DA01CC2-A656-33B5-4F09-783FFCC23DD2, name = TY,

//  from Bluetooth explorer device TY (Renpho scale)
// service uuid: a400
// READ: 180a-2a50-028a2466820100

    public static let scaleServiceUUID = CBUUID.init(string: "a400")
   public static let scaleCharacteristicUUID = CBUUID.init(string: "1910")

device filter: DC:23:4D:11:98:92

uuid 1910

 module->phone:
properties: read, notify
uuid: 2b10

 phone->module
properties: read, write
uuid: 2b11

*/

class RenphoScalePeripheral: NSObject {

   public static let scaleServiceUUID = CBUUID.init(string: "a400")
   public static let scaleCharacteristicUUID = CBUUID.init(string: "1910")


}

/*  device "Etekcity Nutrition Scale" 
Service UUID: 1910

CBPeripheral: 0x2826e8000, identifier = 108E2EFC-3E9C-06B1-9B67-4D893E56F2FF, name = Etekcity Nutrition Scale, state = disconnected>

Handle discovery event ==> [<CBService: 0x28026d780, isPrimary = YES, UUID = 1910>]
<CBCharacteristic: 0x2833c1980, UUID = 2C12, properties = 0x30, value = {length = 12, bytes = 0xfeefc0a2d0050000000001d6}, notifying = NO>
 FE EF C0 A2 D0 05: this is the weight being returned...
<CBCharacteristic: 0x2833c0d80, UUID = 2C11, properties = 0xC, value = (null), notifying = NO>
<CBCharacteristic: 0x2833c0e40, UUID = 2C10, properties = 0x2, value = (null), notifying = NO>

*/
class EtekcityScalePeripheral: NSObject {

   public static let name = "Etekcity Nutrition Scale"

   public static let scaleServiceUUID = CBUUID.init(string: "1910")
   public static let weightServiceUUID = CBUUID.init(string: "1801") // according to hertzg, not sure if correct
   public static let scaleCharacteristicUUID0 = CBUUID.init(string: "2C10") // ??
   public static let scaleCharacteristicUUID1 = CBUUID.init(string: "2C11") // ??
   public static let scaleCharacteristicUUID = CBUUID.init(string: "2C12") // reads the weights

    
   public func weightFromScaleValue( value: Data) -> Double {
        // value = {length = 12, bytes = 0xfeefc0a2d005000a82000162},
        
        /*
    |  0   | FE    |   start of Handle Value:  FEEF C0A2 D005 0007 2600 0103    |
    |  1   | EF    |                                                            |
    |  2   | C0    |                                                            |
    |  3   | A2    |                                                            |
    |  4   | D0    |   packet type: D0 -> weight                                |
    |  5   | 05    |   length of packet: 0x05 -> 5 bytes for weight             |
    |  6   | 00    |   sign: 0x00 positive ; 0x01 negative                      |
    |  7-8 | 0a 82 |   weight, little endian: 0x0a 0x82 --> 2690 --> 269.0 g    |
    |  9   | 00    |   unit: 0x00(g),0x01(lboz),0x02(ml),0x03(floz),0x04(ml milk),0x05(floz milk),0x06(oz) |
    |  10  | 01    |   stable: 0x00 measuring; 0x01 settled                     |
    |  11  | 03    |   signal strength in dB as 1's complement                  |
         */

        var weight : Double = Double(value[7]) * 256.0 + Double(value[8])
        weight /= 10.0
        
        return weight
    }

}
