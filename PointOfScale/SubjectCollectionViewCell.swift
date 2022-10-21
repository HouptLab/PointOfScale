//
//  SubjectCellCollectionViewCell.swift
//  PointOfScale
//
//  Created by Tom Houpt on 22/10/14.
//

import UIKit

class SubjectCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!   
    
    var subject: BartenderSubject!

    init(theSubject: BartenderSubject) {
        let frame = CGRect(x: 0,y: 0,width: 96,height: 72)
        subject = theSubject
        super.init(frame: frame)
    }
    
    
    required init?(coder aCoder: NSCoder) {
        super.init(coder: aCoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
       // updateCellFromSubject()
    }


    
    func setSubject(theSubject: BartenderSubject) {
        subject = theSubject
        updateCellFromSubject()
        // identifier = subject.id
    }
    
    func updateCellFromSubject() {
    
        nameLabel.text = subject.id
        if (-32000.0 != subject.weight) {
            weightLabel.text = String(format:"%.1lf",subject.weight)
            percentLabel.text = String(format:"%.0lf%%",100 * subject.weight/subject.initial_weight)
            
            weightLabel.textColor = UIColor.black
            if (subject.weight < (subject.initial_weight * 0.85)){
                percentLabel.textColor = UIColor.red
                percentLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
            }
            else {
                percentLabel.textColor = UIColor.black
                percentLabel.font = UIFont.systemFont(ofSize: 16.0)
            }
        }
        else {
            weightLabel.text = "––"
            percentLabel.text = "––%"
            weightLabel.textColor = UIColor.gray
            percentLabel.textColor = UIColor.gray
            percentLabel.font = UIFont.systemFont(ofSize: 16.0)
        }
        
        
        
    }

}
