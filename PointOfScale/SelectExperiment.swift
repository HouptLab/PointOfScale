//
//  SelectExperiment.swift
//  PointOfScale
//
//  Created by Tom Houpt on 5/25/23.
//

import UIKit
import CoreBluetooth
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import SafariServices

/*
1 ask firebase for list of experiments 
2 display in a list or dropdown menu
3 allow user to either 
    a) select exisiting experiment 
    b) enter new experiment code
    c) enter experiment code (i.e. by typing or scanning barcode)
    
*/

class SelectExperiment : UIViewController, UITableViewDelegate, UITableViewDataSource  {

        @IBOutlet weak var exptCodeField: UITextField!
        
        @IBOutlet weak var exptDescriptionLabel: UITextView!
        
        @IBOutlet weak var startWeighing:UIButton!
        
        @IBOutlet weak var viewExptData:UIButton!
        
        @IBOutlet weak var tableController:UITableViewController!
        
        @IBOutlet weak var tableView: UITableView!
        
        @IBOutlet weak var loadingLabel: UILabel!
        

    
    // cell reuse id (cells that scroll out of view can be reused)
    let cellReuseIdentifier = "cell"
    
        // Data model: These strings will be the data for the table view cells
    var expts: [BartenderExpt] = []
    //["Horse", "Cow", "Camel", "Sheep", "Goat"]
    
    // firebase

var fbRef: DatabaseReference!

// ---------------------------------------------------------------------


    required init?(coder: NSCoder) {
        super.init(coder:coder);
        //fatalError("init(coder:) has not been implemented")
        
    }
    
// ---------------------------------------------------------------------


    
    override func viewDidLoad() {
        super.viewDidLoad()
        
                
        // Register the table view cell class and its reuse id
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        
        // (optional) include this line if you want to remove the extra empty cell divider lines
        // self.tableView.tableFooterView = UIView()

        // This view controller itself will provide the delegate methods and row data for the table view.
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.layer.borderWidth = 2.0;
        
            startWeighing.isEnabled = false
        
        exptCodeField.placeholder = "Select Expt"
        
        connectToFirebase()
        getCurrentExperimentsFromFirebase()
        
    }
    
    // number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.expts.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = (self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as UITableViewCell?)!
        
        // set the text from the data model
        cell.textLabel?.text = String(format:"%@ %@ %@",self.expts[indexPath.row].id, self.expts[indexPath.row].name, self.expts[indexPath.row].last_updated)
        
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
        
        exptCodeField.text = self.expts[indexPath.row].id 
        exptDescriptionLabel.text =  self.expts[indexPath.row].name
        
        startWeighing.isEnabled = true
        viewExptData.isEnabled = true
    }
    
    
func connectToFirebase() {


    fbRef = Database.database(url: "https://bartenderdata.firebaseio.com" ).reference()
    // https://bartenderdata.firebaseio.com
    print("firebase")
}

func getFirebaseExperimentsDataPath() -> String {

    let dataPath = "expts"
     
    return dataPath

}

func getCurrentExperimentsFromFirebase() {

    loadingLabel.isHidden = false
    startWeighing.isEnabled = false
    
    let dataPath = getFirebaseExperimentsDataPath()
    
    expts = []
        
    fbRef.child(dataPath).getData(completion:  { [self] error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return;
            }
            if (nil == snapshot) {
                // there is no expt here 
            }
            else {
            
                print(snapshot!.childrenCount) 
             
                 for expt_child in (snapshot!.children) {
                    
                    let expt_snap = expt_child as! DataSnapshot
                 
                     let snapshotExptCode = expt_snap.key 
                    
                    let dict = expt_snap.value as! [String: Any?]
                    let snapshotName =  dict["name"] as! String
                    print("snapshotExptCode: ",snapshotExptCode, " ", snapshotName)
                    
                     let snapshotUpdated =  dict["last_updated"] as! String
                     
                     let snapshotArchived =  dict["archived"] as? [String:String]
                    
                    if (nil == snapshotArchived) {
                        expts.append(BartenderExpt(archived: nil, id:snapshotExptCode, name: snapshotName, last_updated: snapshotUpdated ))
                    }
                }
                
                loadingLabel.isHidden = true
                self.tableView.reloadData()
            }
    });
    
}    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let weightsViewController = segue.destination as? WeightsViewController {

            let code = exptCodeField.text!
            // TODO: validate exptCode to make sure it's one of our firebase experiments

            weightsViewController.setExptCode(code:code)
        
            // TODO: pass in experiment description, or can weightsViewController get that from firebase too?
        }
    }
    
    @IBAction func showExptInSafari() {
    
    let code = exptCodeField.text
            // TODO: validate exptCode to make sure it's one of our firebase experiments
            
        if (nil == code || 0 == code?.count) {
            return
        }

        let urlString:String = "https://www.houptlab.org/bartab/expt/?id=" + code!;
        let url : URL = URL(string:urlString)!
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true, completion: nil)
    
    }
}
