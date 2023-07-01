//
//  WeightsViewController.swift
//  PointOfScale
//
//  Created by Tom Houpt on 20/11/15.
//
// based on https://www.freecodecamp.org/news/ultimate-how-to-bluetooth-swift-with-hardware-in-20-minutes/
// and on parts of https://www.raywenderlich.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor

// https://developer.apple.com/documentation/corebluetooth/transferring_data_between_bluetooth_low_energy_devices/

import UIKit
import CoreBluetooth
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth


let kMissingWeightValue : Double = -32000.0

class WeightsViewController:  UIViewController,CBPeripheralDelegate,CBCentralManagerDelegate,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    
    var exptCode : String = "???"
    
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
    
    @IBOutlet weak var cancelWeighing:UIButton!
    
    
    let k4AcrossSpacing:CGFloat = 24 // 36
    let k5AcrossSpacing:CGFloat  = 10 //24
    
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
    
    private var currentWeight: (value:Double, stability: Bool ) = (kMissingWeightValue,false)
    private var previousWeight :  (value:Double, stability:Bool )  = (kMissingWeightValue,false)
    
    // handling time
    
    private var timeLabelTimer: Timer!
    
    private var dateFormatter: DateFormatter!
    
    private var timeFormatter: DateFormatter!
    
    // handling subjects
    
    var subjects:  [BartenderSubject] = []
    private var currentSubjectIndex: Int  = -1
    
    var numSubjects:UInt = 0
    
    var numSubjectsDownloaded:UInt = 0
    
    
    var groups: [BartenderGroupMean] = []
    
    // firebase
    
    var fbRef: DatabaseReference!
    
    private var timeStampFormatter:  DateFormatter!
    
    
    // ---------------------------------------------------------------------
    
    override func viewDidLoad() {
        
        centralManager = CBCentralManager(delegate:self, queue:nil)
        super.viewDidLoad()
        
        // set up for periodically updating the date and time on the screen
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM d, yyyy"
        timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        // timeStampFormatter for firebase key
        timeStampFormatter = DateFormatter()
        timeStampFormatter.dateFormat = "yyyy-MM-dd HH:mm"   
        
        
        timeLabelTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(dateTimeToScreen), userInfo: nil, repeats: true)
        // Do any additional setup after loading the view.
        //        let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        //
        
        switchWidth.addTarget(self, action: #selector(updateWidth), for: .valueChanged)
        
        acceptWeight.addTarget(self, action: #selector(acceptCurrentWeight), for: .primaryActionTriggered)
        
        resetAverage.addTarget(self, action: #selector(resetAverageWeight), for: .primaryActionTriggered) 
        
     //   testGroupMeans()
        
        exptCodeLabel.text = exptCode
        
        // no subject selected, so show weight in red
        weightLabel.textColor = UIColor.purple
        acceptWeight.isEnabled = false
        
        // set up the collection view
        
        subjectsCollection.register(UINib(nibName: "SubjectCollectionViewCell", bundle: nil), //.main 
                                    forCellWithReuseIdentifier: "subjectCell")
        
        connectToFirebase()
        getSubjectsFromFirebase()
        
        
        // TODO: make sure we have gotten all the subjects before setting current subjects
        
        // initialize everything to nil or kMissingWeightValue
        
        
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
        currentWeight = (value:kMissingWeightValue,stability:false)
        previousWeight = (value:kMissingWeightValue,stability:false)
        num_readings = 0;
        cumulativeAverage = kMissingWeightValue
        weightToScreen(input:currentWeight)
    }
    
    @objc func resetAverageWeight(_ sender:UIButton?) {
        num_readings = 0;
        cumulativeAverage = kMissingWeightValue  
        weightToScreen(input:currentWeight)
    }
    
    // ---------------------------------------------------------------------
    // ---------------------------------------------------------------------
    // MARK: CBCentralManager Delegate Methods
    
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
        return (value: kMissingWeightValue,stability: stableReading)
    }
    
    func weightToScreen(input: (value: Double,stability: Bool)){
        if (input.value == kMissingWeightValue) {
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
        if (cumulativeAverage == kMissingWeightValue) {
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
                    if (previousWeight.value != currentWeight.value && currentWeight.value != kMissingWeightValue) {
                        print ("9. ", self.count, "characteristic 2c12: ", weightChar!)
                        print ("old weight: ", previousWeight.value, " new weight: ", currentWeight.value)
                        
                        
                        // Display the weight
                        // Dispatch the text view update to the main queue for updating the UI, because
                        // we don't know which thread this method will be called back on.
                        //        DispatchQueue.main.async() {
                        //            self.textView.text = String(weight)
                        //        } 
                        
                        if (currentWeight.value == kMissingWeightValue) {
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
    
    func setCurrentSubject(theSubject:BartenderSubject?) {
        
        resetWeights()
        
        if (nil != theSubject) {
            currentSubjectLabel.text = theSubject?.id
            currentSubjectLabel.textColor = UIColor.black
            currentSubjectIndex = indexOfSubject(theSubject)
        }
        else {
            currentSubjectLabel.text = "NONE"
            currentSubjectLabel.textColor = UIColor.lightGray
            currentSubjectIndex = -1
        }
    }
    
    func indexOfSubject(_ theSubject:BartenderSubject!) -> Int {
        
       for index in subjects.indices {
       
            if (subjects[index].id == theSubject.id) {
                return index
            }
       }
    
        return -1
    }
    
    func connectToFirebase() {
        
        fbRef = Database.database(url: "https://bartenderdata.firebaseio.com" ).reference()
        // https://bartenderdata.firebaseio.com
        print("firebase")
    }
    
    func getFirebaseSubjectsDataPath(subjectID:String) -> String {
        
        let subjectsPath = getFirebaseSubjectsPath()
        
        let dataPath = subjectsPath + "/" + subjectID + "/data"
        
        return dataPath
        
    }
    func getFirebaseSubjectsGroupPath(subjectID:String) -> String {
        
        let subjectsPath = getFirebaseSubjectsPath()
        
        let dataPath = subjectsPath + "/" + subjectID + "/group"
        
        return dataPath
        
    }
    func getFirebaseSubjectsPath() -> String {
        
        let subjectsPath = "expts/" + exptCodeLabel.text! + "/subjects"
        
        return subjectsPath
        
    }
    
    func getSubjectsFromFirebase() {
        
        subjects.removeAll()
        numSubjects = 0
        numSubjectsDownloaded = 0
        
        let subjectsPath = getFirebaseSubjectsPath() 
        
        fbRef.child(subjectsPath).getData(completion:  { [self] error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return;
            }
            if (nil == snapshot ||  snapshot?.value is NSNull ) {
                
                // no subjects found
                // TODO: post some error that can't find subjects
            }
            else {
                self.numSubjects = snapshot!.childrenCount
                // set up subjects
                for index in 0..<self.numSubjects {
                    
                    let subjectID = String(format: "%@%02d",exptCode,(index + 1))
                    let theSubject = BartenderSubject(id: subjectID, 
                                                      weight: kMissingWeightValue, 
                                                      last_weight: kMissingWeightValue, 
                                                      initial_weight: kMissingWeightValue,
                                                      group: "Unassigned",
                                                      indexPath:IndexPath(row: Int(index), section: 0))
                    
                    subjects.append(theSubject)
                    getSubjectWeightsFromFirebase(subjectID:subjectID,subjectIndex:Int(index)) 
                }
                
                setCurrentSubject(theSubject: nil)
                
            }
        })
        
        // TODO: is there a way to monitor self.numSubjectsDownloaded, and when it reaches self.numSubjects
        // TODO: call this after numSubjectsDownloaded == numSubjects

        // then call self.subjectsCollection.reloadData()
    }
    
    func getSubjectWeightsFromFirebase(subjectID:String,subjectIndex:Int) {
        
        // expts/<expt_code>/subjects/<subject_code>/groups/<group>:"<name>"
        // get subject groups
        let groupPath = getFirebaseSubjectsGroupPath(subjectID:subjectID)
        
        fbRef.child(groupPath).getData(completion:  { [self] error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return;
            }
            
            if ((snapshot?.exists())!) {
                
                self.subjects[subjectIndex].group = snapshot?.value as! String
                
            }
            
        });
        
        // get subject weights
        let dataPath = getFirebaseSubjectsDataPath(subjectID:subjectID)
        let bodyWeightPath = dataPath + "/Body Weight"
        
        fbRef.child(bodyWeightPath).getData(completion:  { [self] error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return;
            }
            
            if ((snapshot?.exists())!) {
                
                let timestampedWeights =  snapshot?.value as! [String: NSNumber]
                
                //            for (timestamp,weight) in timestampedWeights {
                //                print(timestamp,weight)
                //            }
                // TODO: sort weights based on timestamps, get the most last value as last_weight
                // get the first non-missing value as initial weight
                let sortedDates = Array(timestampedWeights.keys).sorted(by:<)
                
                self.subjects[subjectIndex].initial_weight = kMissingWeightValue
                for first_weight_index in sortedDates.indices {
                    let weight_number = timestampedWeights[sortedDates[first_weight_index]] 
                    self.subjects[subjectIndex].initial_weight = weight_number?.doubleValue ?? kMissingWeightValue
                    if (kMissingWeightValue != self.subjects[subjectIndex].initial_weight) {
                        break
                    }
                }
            
                for last_weight_index in sortedDates.indices.reversed() {
                    let weight_number = timestampedWeights[sortedDates[last_weight_index]] 
                    self.subjects[subjectIndex].last_weight = weight_number?.doubleValue ?? kMissingWeightValue
                    if (kMissingWeightValue != self.subjects[subjectIndex].last_weight) {
                        break
                    }
                }
                
                
            }
            else {
                
                print("no weights yet for ",subjectID);
            }
            
            self.numSubjectsDownloaded = self.numSubjectsDownloaded + 1
            
            self.subjectsCollection.reloadData()
            
        });
        
    }
    
    func saveSubjectToFirebase(theSubject:BartenderSubject, timeStamp:String) {
        /*
         expts/<expt_code>/subjects/<subject_code>/data/"Body Weight"/"YYYY-MM-DD HH:mm"/<weight-as-float>

         expts/<expt_code>/Measures/"Body Weight"/"Body Weight (g)"
         
         */
        
        // TODO: cache results on firebase until we are done weighing everyone, then put into final data structure,
        // and update group means and update "last_updated field on firebase 
        
        let dataPath = getFirebaseSubjectsDataPath(subjectID: theSubject.id ) 
        
        let bodyWeightPath = dataPath + "/Body Weight"
        
        //  let timeStamp =  timeStampFormatter.string(from: Date())
        
        let timeStampPath = bodyWeightPath + "/" + timeStamp
        
        fbRef.child(timeStampPath).setValue(theSubject.weight)
        
    }
    
    func updateCurrentSubjectWeight(weight:Double) {
        
        if (-1 == currentSubjectIndex) {
            return
        }
        
        subjects[currentSubjectIndex].weight = weight
        
        
        let currentSubjectCell = subjectsCollection.cellForItem(at: subjects[currentSubjectIndex].indexPath) as! SubjectCollectionViewCell?
        
        currentSubjectCell?.setSubject(theSubject: subjects[currentSubjectIndex])
        
        subjectsCollection.deselectItem(at: subjects[currentSubjectIndex].indexPath, animated: true)
        subjectsCollection.delegate?.collectionView?(subjectsCollection, didDeselectItemAt: subjects[currentSubjectIndex].indexPath)
        
        setCurrentSubject(theSubject:nil)
        
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
        
        return  Int(numSubjectsDownloaded) // subjects.count
        
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
        print(cell.frame)
        print(cell.backgroundView?.frame)
        cell.subject.indexPath = indexPath
        cell.weightLabel.textColor = UIColor.white
        cell.percentLabel.textColor = UIColor.white
        cell.initialLabel.textColor = UIColor.white
         cell.lastLabel.textColor = UIColor.white

        
        setCurrentSubject(theSubject: cell.subject)
         weightLabel.textColor = UIColor.white
         acceptWeight.isEnabled = true
    }
    func collectionView(_: UICollectionView, shouldDeselectItemAt: IndexPath) -> Bool {
        // Asks the delegate if the specified item should be deselected.
        return true
    }
    func collectionView(_: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        //  Tells the delegate that the item at the specified path was deselected.
        
         let cell =  subjectsCollection.cellForItem(at: indexPath) as! SubjectCollectionViewCell
        
        cell.updateCellFromSubject()
        
        weightLabel.textColor = UIColor.purple
        acceptWeight.isEnabled = false
        
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
            return k4AcrossSpacing 
        }
        else {
            // 5 across
            return k5AcrossSpacing
        }
    }
    
    // MARK: Prepare for segue
    
    func setExptCode(code:String) {
        
        exptCode = code
        
        // TODO: refresh connection to firebase
        
    }
    
    func indexOfGroup( _ name:String) -> Int {
    
        for index in groups.indices {
            if (groups[index].id == name) {
                return index
            }
        }
        
        groups.append(BartenderGroupMean(id: name, mean:0,n:0,sem:0, m2: 0))
        
        return groups.count - 1
    
    }
    
    func getFirebaseGroupMeansPath(group:String,timestamp:String) -> String {
        
        let groupMeansPath = "expts/" + exptCodeLabel.text! + "/group_means/" + group + "/Body Weight/" + timestamp
        
        return groupMeansPath
        
    }
    
    
    
    func calcGroupMeans() {
    
    for subject in subjects {
          
            let groupIndex = indexOfGroup(subject.group);
            groups[groupIndex].n = groups[groupIndex].n + 1
            let delta = subject.weight - groups[groupIndex].mean
            groups[groupIndex].mean = groups[groupIndex].mean + delta / Double(groups[groupIndex].n)
            let delta2 = subject.weight - groups[groupIndex].mean
            groups[groupIndex].m2 =  groups[groupIndex].m2 + delta * delta2
            
        }
        
        
        // finalize means and sem
         for index in groups.indices {
                if (0 == groups[index].n) {
                    groups[index].sem  = 0
                }
                else {
                    groups[index].sem = sqrt(groups[index].m2 / Double(groups[index].n - 1)) / sqrt(Double(groups[index].n))
                }
        }
        
    }
    
    func testGroupMeans() {
    
        subjects.removeAll()
    
        for i in 0..<6 {
                
            let subject = BartenderSubject(id: "SU\(i)", weight:Double(i*20),  last_weight: Double(i*20), initial_weight: Double(i*20), group: "GROUP1")
        
            subjects.append(subject)
        }
         for i in 6..<12 {
                
            let subject = BartenderSubject(id: "SU\(i)", weight:Double(i*23),  last_weight: Double(i*23), initial_weight: Double(i*23), group: "GROUP2")
        
            subjects.append(subject)
        }
         for i in 12..<18 {
                
            let subject = BartenderSubject(id: "SU\(i)", weight:Double(i*19),  last_weight: Double(i*19), initial_weight: Double(i*19), group: "GROUP3")
        
            subjects.append(subject)
        }
        
        calcGroupMeans()
        
        // should be exact, but check with a tolerance
        assert(0.01 > groups[0].mean - 50)
        assert(0.01 > groups[0].sem - 15.2752523165195)
 
        assert(0.01 >  groups[1].mean - 195.5)
        assert(0.01 > groups[1].sem - 17.5665401639974)

       assert(0.01 > groups[2].mean - 275.5)
       assert(0.01 > groups[2].sem - 14.5114897006935)
       
        print(groups)
    
    }
    func updateGroupMeans(timeStamp:String)  {
        // expts/<expt_code>/subjects/<subject_code>/group_means/<group>/<measure>/<timestamp>/[mean|n|sem]/double
        
        // set up groups array
        
        calcGroupMeans()
        
        
        // update on firebase
        for group in groups {
        
            let groupMeansPath = getFirebaseGroupMeansPath(group:group.id,timestamp:timeStamp)
            let meanPath = groupMeansPath + "/mean"
            let nPath = groupMeansPath + "/n"
            let semPath = groupMeansPath + "/sem"
            
            fbRef.child(meanPath).setValue(group.mean)
            fbRef.child(nPath).setValue(group.n)
            fbRef.child(semPath).setValue(group.sem)
            
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        let senderButton = sender as! UIButton
        if senderButton == cancelWeighing {
            return
        }
        
        // TODO: finished weighing, so clean up i.e. make sure saved to firebase, timestamped 
        // TODO: cache results on firebase until we are done weighing everyone, then put into final data structure,
        // TODO: and update group means and update "last_updated field on firebase 
        if let selectExperimentController = segue.destination as? SelectExperiment {
            
            let timeStamp =  timeStampFormatter.string(from: Date())
            
            for theSubject in subjects {
                print("\(theSubject.id) \(theSubject.weight)" )
                saveSubjectToFirebase(theSubject:theSubject, timeStamp:timeStamp)
            }
            updateGroupMeans(timeStamp:timeStamp);
            
            
            var updatedFormatter = DateFormatter()
 
            
            updatedFormatter.dateFormat = "E yyyy-MM-dd HH:mm"   
            
            let nowDate = Date()
            let lastUpdated =  updatedFormatter.string(from: nowDate)
            let lastUpdatedMs = UInt(nowDate.timeIntervalSince1970 * 1000)
            
            let lastUpdatedPath = "expts/" + exptCodeLabel.text! + "/last_updated"
            fbRef.child(lastUpdatedPath).setValue(lastUpdated)
            let lastUpdatedMSPath = "expts/" + exptCodeLabel.text! + "/last_updated_ms"
            fbRef.child(lastUpdatedMSPath).setValue(lastUpdatedMs)
            
        }
    }
    
} // ViewController
