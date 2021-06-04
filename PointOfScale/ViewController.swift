//
//  ViewController.swift
//  PointOfScale
//
//  Created by Tom Houpt on 20/11/15.
//
// based on https://www.freecodecamp.org/news/ultimate-how-to-bluetooth-swift-with-hardware-in-20-minutes/
// and on parts of https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor

// https://developer.apple.com/documentation/corebluetooth/transferring_data_between_bluetooth_low_energy_devices/

import UIKit
import CoreBluetooth

class ViewController:  UIViewController,CBPeripheralDelegate,CBCentralManagerDelegate {

    @IBOutlet weak var weightLabel: UILabel!
    private var tareVal: Double = 0

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var discoveredPeripheral: CBPeripheral!
    private var weightService: CBService!

    private var data: Data!
    
    private var old_weight : Double = -32000 // initial prior weight reading
    
    private var count : Int = 0 // number of times weight characteristic discovered
    
    
// ---------------------------------------------------------------------
    
    override func viewDidLoad() {
        
        centralManager = CBCentralManager(delegate:self, queue:nil)
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    } // viewDidLoad
    
// ---------------------------------------------------------------------
// ---------------------------------------------------------------------
// CBCentralManager Delegate Methods
        
// ---------------------------------------------------------------------
// If we're powered on, start scanning

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("1. Central state update")
        
        if central.state != .poweredOn {
            print("1b. Central is not powered on")
        } else {
        
            // TODO: why scan for scaleServices, maybe use scale and weight
            print("2. Central scanning for", EtekcityScalePeripheral.scaleServiceUUID);
            centralManager.scanForPeripherals(withServices: [EtekcityScalePeripheral.scaleServiceUUID,
                                                             EtekcityScalePeripheral.weightServiceUUID,], // or set withServices to nil
                                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
           // if peripheral is found, then centralManager(_:didDiscover:advertisementData:rssi:) will be called
        }
        
        switch central.state {
        
        case .unknown:
            print("Central is unknown")
        case .resetting:
            print("Central is resetting")
        case .unsupported:
            print("Central is unsupported")
        case .unauthorized:
            print("Central is unauthorized")
        case .poweredOff:
            print("Central is powered off")
        case .poweredOn:
            print("Central is powered on")
            print("Central scanning for", EtekcityScalePeripheral.scaleServiceUUID);
            centralManager.scanForPeripherals(withServices: [EtekcityScalePeripheral.scaleServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        @unknown default:
            print("Central is unknown default")
        }
        
    } // centralManagerDidUpdateState
    
// ---------------------------------------------------------------------        
// Handles the result of the scan

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Reject if the signal strength is too low to attempt data transfer.
        // Change the minimum RSSI value depending on your app’s use case.
        guard RSSI.intValue >= -100
        else {
            print("3err.Discovered perhiperal not in expected range, at ", RSSI.intValue)
            return
        }
        
        print("3. Discovered ", String(describing: peripheral.name), " at ", RSSI.intValue)
        print("4. peripheral: ", peripheral)
        
        if (!(peripheral.name?.contains(EtekcityScalePeripheral.name) ?? false)) {
            return;
        }
        
        //TODO: put in timer to give up on scan?
        
        // We've found it so stop scan
        self.centralManager.stopScan()
        
        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // Connect!
        print("5. Trying to Connecting to perhiperal", peripheral.name!)
        self.centralManager.connect(self.peripheral, options:nil)
        // if connect succeeds, centralManager(_:didConnect:) will be called
        // if connect fails, centralManager(_:didFailToConnect:error:) 
        // centralManager.connect does not time out, so have to call cancelPeripheralConnection to cancel explicitly
                
    } // centralManager didDiscoverPeripheral
    
    
// ---------------------------------------------------------------------        
// The handler if we do connect succesfully

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("6. Connected to peripheral: ", peripheral.name!)
            // look for scaleService
            peripheral.discoverServices([EtekcityScalePeripheral.scaleServiceUUID]) 
            // if successful, peripheral(_:didDiscoverServices:):  will be called
        }
    } // centralManager didConnect peripheral    
    
// ---------------------------------------------------------------------
// Handles discovery event

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        if let services = peripheral.services {
            for service in services {
               
                if service.uuid == EtekcityScalePeripheral.scaleServiceUUID {
                    print("7a. Scale service found")

              }
              
                //Now kick off discovery of characteristics
                peripheral.discoverCharacteristics(nil, for: service) 
                 // if succesfull peripheral(_:didDiscoverCharacteristicsFor:error:) will be called
            }
        }
    } // peripheral didDiscoverServices
    
// --------------------------------------------------------------------- 

/**
    | index | value | description                                                |
    | :--:  | :--:  | :----                                                      |
    |  0    | FE    |   start of Handle Value:  FEEF C0A2 D005 0007 2600 0103    |
    |  1    | EF    |                                                            |
    |  2    | C0    |                                                            |
    |  3    | A2    |                                                            |
    |  4    | D0    |   packet type: D0 -> weight                                |
    |  5    | 05    |   length of packet: 0x05 -> 5 bytes for weight             |
    |  6    | 00    |   sign: 0x00 positive ; 0x01 negative                      |
    |  7-8  | 0a 82 |   weight, big endian: 0x0a 0x82 --> 2690 --> 269.0 g       |
    |  9    | 00    |   unit: 0x00(g),0x01(lboz),0x02(ml),0x03(floz),
                             0x04(ml milk),0x05(floz milk),0x06(oz)              |
    |  10   | 01    |   stable: 0x00 measuring; 0x01 settled                     |
    |  11   | 03    |   signal strength in dB as 1's complement                  |
*/

func weightFromScaleValue( value: Data) -> Double {
        // value = {length = 12, bytes = 0xfeefc0a2d005000a82000162},
        


        var weight = Double(value[7]) * 256.0 + Double(value[8])
        weight /= 10.0
    weight = weight + Double(tareVal)
        weightLabel.text = String(format: "%.1f", weight)
        return weight
    }

    @IBAction func Tare(_ sender: Any) {
        tareVal = 0 - Double(weightLabel.text!)!
    }
    // ---------------------------------------------------------------------
// Handling discovery of characteristics
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
    
          //   print ("8. Discovered Characteristics for Service ",service.uuid )
        
        if (nil != service.characteristics) {
           // print ("8. Discovered Service ",service.uuid  ," characteristics ",service.characteristics)
                if (service.uuid == EtekcityScalePeripheral.scaleServiceUUID) {
                    // uuid == 1910
                
                    let weightChar = service.characteristics!.first(where: { $0.uuid == EtekcityScalePeripheral.scaleCharacteristicUUID})
                   // characteristic uuid 2c12
                   
                    if (!weightChar!.isNotifying) {
                        print ("Weight NOT notifying")
                        peripheral.setNotifyValue(true, for: weightChar!)
                        
                    } else {
                    
                        let weight = weightFromScaleValue(value: Data(weightChar!.value!))
                          //  if (self.count % 5000 == 0) {
                        if (self.old_weight != weight) {                       
                            print ("9. ", self.count, "characteristic 2c12: ", weightChar!)
                            print ("old weight: ", self.old_weight, " new weight: ", weight)
                            self.old_weight = weight
                            
                            // Display the weight
                            // Dispatch the text view update to the main queue for updating the UI, because
                            // we don't know which thread this method will be called back on.
                            //        DispatchQueue.main.async() {
                            //            self.textView.text = String(weight)
                            //        }            
                        }               
                    } // weightChar is notifying
                     
                    self.count += 1
                     
                  // run again to get next notify
                  peripheral.discoverCharacteristics([EtekcityScalePeripheral.scaleCharacteristicUUID], for: service) 
                } // discovered scaleServiceUUID characteritic
                
            }
            
//  left over code for handling all characeristics
//            for characteristic in service.characteristics {
//                if characteristic.uuid == EtekcityScalePeripheral.scaleCharacteristicUUID {
//                    print("8a. Scale characteristic found")
//                    print("8b. Scale value: ", characteristic.value!)
//                } 
//                
//               // print("9. Try readValue for ", characteristic.uuid)
//              //  peripheral.readValue(for: characteristic)
        
    } // peripheral didDiscoverCharacteristicsFor
    
// ---------------------------------------------------------------------       

   
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
         // NOTE: not used when reading EtekcityScale
         
        // Deal with errors (if any)
        if let error = error {
            print("9err. Characteristic uuid: ", characteristic.uuid, " Error discovering characteristics: ", error.localizedDescription)
            //cleanup()
            return
        } 
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        
        print("9. Received %d bytes: %s", characteristicData.count, stringFromData)
        
        // Have we received the end-of-message token? "EOM" == 0x45 4f 4d
        if stringFromData == "EOM" {
            // End-of-message case: show the data.
            // Dispatch the text view update to the main queue for updating the UI, because
            // we don't know which thread this method will be called back on.
            //        DispatchQueue.main.async() {
            //            self.textView.text = String(data: self.data, encoding: .utf8)
            //        }
            
            
            
            // Write test data
            // writeData()
        } else {
            // Otherwise, just append the data to what we have previously received.
            data.append(characteristicData)
        }
    } // peripheral didUpdateValueFor
    
} // ViewController

