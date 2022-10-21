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


class ViewController:  UIViewController,CBPeripheralDelegate,CBCentralManagerDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {


// links to UI
        @IBOutlet weak var weightLabel: UILabel!
    
        @IBOutlet weak var dateLabel: UILabel!
        
        @IBOutlet weak var timeLabel: UILabel!

        @IBOutlet weak var exptCodeLabel: UILabel!
        
        @IBOutlet weak var exptDescriptionLabel: UILabel!

        @IBOutlet weak var subjectsCollection: UICollectionView!

        @IBOutlet weak var currentSubjectLabel: UILabel!

        @IBOutlet weak var switchWidth:UISegmentedControl!

        @IBOutlet weak var acceptWeight:UIButton!
        
        @IBOutlet weak var averageLabel:UILabel!
        
        @IBOutlet weak var resetAverage:UIButton!

static let k4AcrossSpacing:CGFloat = 36
static let k5AcrossSpacing:CGFloat  = 24

// handling scale weights
    private var tareVal: Double = 0 // applied to the weight to zero it
    private var tareHelper: Double = 0 //used to make the tareVal

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var discoveredPeripheral: CBPeripheral!
    private var weightService: CBService!

    private var data: Data!
    

    
    private var count : Int = 0 // number of times weight characteristic discovered//why do we care about this?
    
    private var num_readings: Double = 0
    
    private var cumulativeAverage: Double = 0
    
    private var currentWeight: (value:Double, stability: Bool ) = (-32000,false)
    private var previousWeight :  (value:Double, stability:Bool )  = (-32000,false)
    
// handling time
    
    private var timeLabelTimer: Timer!
    
    private var dateFormatter: DateFormatter!
    
    private var timeFormatter: DateFormatter!
    
// handling subjects

  var subjects:  [BartenderSubject] = []
    private var currentSubject: BartenderSubject!
    
    
// ---------------------------------------------------------------------
    
    override func viewDidLoad() {
        
        centralManager = CBCentralManager(delegate:self, queue:nil)
        super.viewDidLoad()
        
        // set up for periodically updating the date and time on the screen
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, yyyy"
        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "H:mm"
        
        timeLabelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(dateTimeToScreen), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
//        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
//

        switchWidth.addTarget(self, action: #selector(updateWidth), for: .valueChanged)
        
        acceptWeight.addTarget(self, action: #selector(acceptCurrentWeight), for: .primaryActionTriggered)

         resetAverage.addTarget(self, action: #selector(resetAverageWeight), for: .primaryActionTriggered) 

        // set up subjects
        for index in 1...30{
            subjects.append(BartenderSubject(id: String(format: "DMF%02d",index), 
                                             weight: -32000.0, 
                                             initial_weight: 300.00,
                                             indexPath:nil))}
                                             
                                             
        // set up the collection view
        
        subjectsCollection.register(UINib(nibName: "SubjectCollectionViewCell", bundle: nil), //.main 
                                    forCellWithReuseIdentifier: "subjectCell")



        // initialize everything to nil or -32000
        setCurrentSubject(theSubject: nil)

    } // viewDidLoad
    
    @objc func updateWidth(_ sender: UISegmentedControl?) {
    
        subjectsCollection.collectionViewLayout.invalidateLayout()
     
     }
//
//    @objc func update(){
//        //don't call anyhting that will cuase a stack overflow
//        //check if connected
//        //get weight
//        //apply weight to label
//    }
    

func resetWeights() {
        currentWeight = (value:-32000,stability:false)
        previousWeight = (value:-32000,stability:false)
        num_readings = 0;
        cumulativeAverage = -32000
        weightToScreen(input:currentWeight)
}

@objc func resetAverageWeight(_ sender:UIButton?) {
        num_readings = 0;
        cumulativeAverage = -32000  
        weightToScreen(input:currentWeight)
}

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

func weightFromScaleValue( value: Data) -> (value: Double, stability: Bool) {
        // value = {length = 12, bytes = 0xfeefc0a2d005000a82000162},
        
        /*
    |  0   | FE    |   start of Handle Value:  FEEF C0A2 D005 0007 2600 0103    |
    |  1   | EF    |                                                            |
    |  2   | C0    |                                                            |
    |  3   | A2    |                                                            |
    |  4   | D0    |   packet type: D0 -> weight                                |
    |  5   | 05    |   length of packet: 0x05 -> 5 bytes for weight             |
    |  6   | 00    |   sign: 0x00 positive ; 0x01 negative                      |
    |  7-8 | 0a 82 |   weight, big endian: 0x0a 0x82 --> 2690 --> 269.0 g    |
    |  9   | 00    |   unit: 0x00(g),0x01(lboz),0x02(ml),0x03(floz),0x04(ml milk),0x05(floz milk),0x06(oz) |
    |  10  | 01    |   stable: 0x00 measuring; 0x01 settled                     |
    |  11  | 03    |   signal strength in dB as 1's complement                  |
         */
         
    var stableReading = false
    if (value[4] == 0xD0 && value[5] == 0x05 ){
        var weight = Double(value[7]) * 256.0 + Double(value[8])
        
        if (value[6] == 0x01){
            weight = weight * -1
        }
        weight /= 10.0
        
        if (value[10] == 0x01) {
            stableReading = true;
        }
        return (value: weight,stability: stableReading)
    }
    return (value: -32000.0,stability: stableReading)
}

    func weightToScreen(input: (value: Double,stability: Bool)){
        if (input.value == -32000.0) {
            weightLabel.text = "––"
            weightLabel.font = UIFont.systemFont(ofSize: 72)
        }
        else {
            let weight = input.value + Double(tareVal)
            weightLabel.text = String(format: "%.1f", weight)

            if (input.stability) {
                weightLabel.font = UIFont.boldSystemFont(ofSize: 108)
            }
            else {
                weightLabel.font = UIFont.systemFont(ofSize: 72)
            }
            
        }
         if (cumulativeAverage == -32000.0) {
            averageLabel.text = "––"
            }
        else {
            averageLabel.text = String(format: "%.1f (%.0f)", cumulativeAverage,num_readings)
        }
    }
    
    @objc func acceptCurrentWeight(_ sender:UIButton) {
        updateCurrentSubjectWeight(weight: currentWeight.value)
        resetWeights()    
        
    }
    
    @objc  func dateTimeToScreen(_ sender: Timer?) {
        let date = Date()
        dateLabel.text = dateFormatter.string(from: date)        
        timeLabel.text = timeFormatter.string(from: date)
    }

    @IBAction func Tare(_ sender: Any) {
        tareVal = tareHelper
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
                        print(weightChar!)
                        peripheral.setNotifyValue(true, for: weightChar!)
                        
                    } else {
                        currentWeight = weightFromScaleValue(value: Data(weightChar!.value ?? data))
                        tareHelper = 0 - currentWeight.value
                                                
                        
                        
                          //  if (self.count % 5000 == 0) {
                        if (previousWeight.value != currentWeight.value && currentWeight.value != -32000.0) {
                            print ("9. ", self.count, "characteristic 2c12: ", weightChar!)
                            print ("old weight: ", previousWeight.value, " new weight: ", currentWeight.value)
                           
                            
                            // Display the weight
                            // Dispatch the text view update to the main queue for updating the UI, because
                            // we don't know which thread this method will be called back on.
                            //        DispatchQueue.main.async() {
                            //            self.textView.text = String(weight)
                            //        } 
                            
                            if (currentWeight.value == -32000.0) {
                                cumulativeAverage = currentWeight.value 
                                num_readings = 1
                            }
                            else {
                                cumulativeAverage = (currentWeight.value + num_readings * cumulativeAverage) / (num_readings + 1)
                                num_readings = num_readings + 1
                            }


                            

//                            num_readings = num_readings + 1
//                            let a = 1/num_readings
//                            let b = 1 - a
//                            cumulativeAverage = a * weight.value + b * cumulativeAverage

                             previousWeight = currentWeight
                                       
                        }               
                        
                        weightToScreen(input:currentWeight)
                        
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
    
    
// MARK: Handling Current Subject

func setCurrentSubject(theSubject:BartenderSubject!) {

    resetWeights()
    
    if (nil != theSubject) {
    currentSubjectLabel.text = theSubject.id
    
    // TODO: save old subject data?
    currentSubject = theSubject;
    }
    else {
        currentSubjectLabel.text = "NONE"
        currentSubject = nil;
    }
}

func updateCurrentSubjectWeight(weight:Double) {

    if (nil == currentSubject) {
        return
    }
    
    currentSubject.weight = weight
    
    let currentSubjectCell = subjectsCollection.cellForItem(at: currentSubject.indexPath) as! SubjectCollectionViewCell?
     
    currentSubjectCell?.setSubject(theSubject: currentSubject)
    
    subjectsCollection.deselectItem(at: currentSubject.indexPath, animated: true)
    currentSubject = nil
    
    setCurrentSubject(theSubject:nil)
      
//    currentSubjectCell?.weightLabel.text = String(format: "%.1f", currentSubject.weight)
//
//    currentSubjectCell?.percentLabel.text = String(format: "%.0f/%", 100 * currentSubject.weight/currentSubject.initial_weight)
//    
//    if (currentSubject.weight < (currentSubject.initial_weight * 0.85)){
//            currentSubjectCell?.percentLabel.textColor = UIColor.red
//            currentSubjectCell?.percentLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
//    }
//    else {
//        currentSubjectCell?.percentLabel.textColor = UIColor.black
//         currentSubjectCell?.percentLabel.font = UIFont.systemFont(ofSize: 16.0)
//    }

}

// MARK: UICollectionViewDataSource

//  // defaults to 1
//   func numberOfSections(in: UICollectionView) -> Int {
//    
//        return 1
//    
//    }

//https://stackoverflow.com/questions/47183879/xib-with-uicollectionview-not-key-value-coding-compliant

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
        return  subjects.count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt: IndexPath) -> Bool {
    
        return false;
    }

    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
    let cell:SubjectCollectionViewCell = subjectsCollection.dequeueReusableCell(withReuseIdentifier: "subjectCell", for: indexPath) as! SubjectCollectionViewCell
    
    cell.setSubject(theSubject:subjects[indexPath.item])
    
    return cell
   }
   
//   @IBAction  func selectSubject(_ sender: SubjectCollectionViewCell) {
//        currentSubjectLabel.text = sender.nameLabel.text
//    }
    
    // MARK: UICollectionVeiw Delegate methods
    
    func collectionView(_: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    // Asks the delegate if the specified item should be selected.
        return true;
    }
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //  Tells the delegate that the item at the specified index path was selected.
        let cell =  subjectsCollection.cellForItem(at: indexPath) as! SubjectCollectionViewCell
        
        cell.backgroundView?.backgroundColor = UIColor.lightGray
        cell.subject.indexPath = indexPath
        setCurrentSubject(theSubject: cell.subject)
    }
    func collectionView(_: UICollectionView, shouldDeselectItemAt: IndexPath) -> Bool {
        // Asks the delegate if the specified item should be deselected.
        return true
    }
    func collectionView(_: UICollectionView, didDeselectItemAt: IndexPath) {
        //  Tells the delegate that the item at the specified path was deselected.
    }
    func collectionView(_: UICollectionView, shouldBeginMultipleSelectionInteractionAt: IndexPath) -> Bool {
        return false
        // Asks the delegate whether the user can select multiple items using a two-finger pan gesture in a collection view.
    }

// MARK: UICollectionViewLayout Delegate methods
    
func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumInteritemSpacingForSectionAt section: Int
) -> CGFloat {
        
        if (switchWidth.selectedSegmentIndex == 0) {
            // 4 across
           return 36.0
        }
        else {
            // 5 across
            return 24.0
        }
 }
} // ViewController
