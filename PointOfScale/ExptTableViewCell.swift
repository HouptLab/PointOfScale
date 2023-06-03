//
//  ExptTableViewCell.swift
//  PointOfScale
//
//  Created by Tom Houpt on 5/25/23.
//

import UIKit

class ExptTableViewCell: UITableViewCell {

    
    @IBOutlet weak var codeLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!   
    
    var expt: BartenderExpt!

    init(theExpt: BartenderExpt) {
        let frame = CGRect(x: 0,y: 0,width: 1000,height: 48)
        expt = theExpt
        super.init(style: .value2, reuseIdentifier: expt.id)
    }
    
    
    required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
       // updateCellFromSubject()
    }


    
    func setExpt(theExpt: BartenderExpt) {
        expt = theExpt
        updateCellFromExpt()
        // identifier = subject.id
    }
    
    func updateCellFromExpt() {
    
        codeLabel.text = expt.id
        descriptionLabel.text = expt.description
        
        let timeStampFormatter = DateFormatter()
        timeStampFormatter.dateFormat = "E yyyy-MM-dd HH:mm"   
        
        lastUpdateLabel.text  = timeStampFormatter.string(from:expt.lastUpdated)
        
        
    }

}
