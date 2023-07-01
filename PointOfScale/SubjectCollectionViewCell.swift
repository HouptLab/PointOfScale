//
//  SubjectCellCollectionViewCell.swift
//  PointOfScale
//
//  Created by Tom Houpt on 22/10/14.
//

import UIKit

let kWaitingColor = UIColor.black
let kCompletedColor = UIColor.gray

// be sure to also set cell size in the SubjectCollectionView
let kSubjectCellWidth = 124
let kSubjectCellHeight = 108

class SubjectCollectionViewCell: UICollectionViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!   
    @IBOutlet weak var lastLabel: UILabel!   
    @IBOutlet weak var initialLabel: UILabel!   
    
    var subject: BartenderSubject!

    init(theSubject: BartenderSubject) {
        let frame = CGRect(x: 0,y: 0,width: kSubjectCellWidth,height: kSubjectCellHeight)
        subject = theSubject
        super.init(frame: frame)
        
        self.layer.cornerRadius = 16
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
        nameLabel.textColor = UIColor.black
        
         weightLabel.text = "– –"
         
         lastLabel.text = "– –"
         lastLabel.textColor = kCompletedColor
         lastLabel.font = UIFont.systemFont(ofSize: 16.0)
         
         initialLabel.text = "– –"
         initialLabel.textColor = kCompletedColor
         initialLabel.font = UIFont.systemFont(ofSize: 16.0)
         
         percentLabel.text = "– –%"
         percentLabel.textColor = kCompletedColor
         percentLabel.font = UIFont.systemFont(ofSize: 16.0)
         
         if (kMissingWeightValue != subject.last_weight) {
                lastLabel.text = String(format:"%.1lf",subject.last_weight)
         }
         else {
            lastLabel.text = "– –"
         }
         if (kMissingWeightValue != subject.initial_weight) {
                initialLabel.text = String(format:"%.1lf",subject.initial_weight)
         }
        
                
        if (kMissingWeightValue != subject.weight) {
        
            nameLabel.font = UIFont.systemFont(ofSize: 12.0)
            
            weightLabel.text = String(format:"%.1lf",subject.weight)
            weightLabel.textColor = kCompletedColor
            weightLabel.font = UIFont.systemFont(ofSize: 28.0)
            
            
           if (kMissingWeightValue != subject.initial_weight) {
                initialLabel.textColor = kCompletedColor
                
                percentLabel.text = String(format:"%.0lf%%",100 * subject.weight/subject.initial_weight)
                if (subject.weight < (subject.initial_weight * 0.85)){
                    percentLabel.textColor = UIColor.red
                    percentLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
                }
           
            }
        }
        
        else { // subject.weight is missing
        
            nameLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
            
            weightLabel.textColor = kWaitingColor
            weightLabel.font = UIFont.italicSystemFont(ofSize: 28.0)
            weightLabel.text = "– –"
            weightLabel.textColor = kWaitingColor
            
            lastLabel.textColor = kWaitingColor
            initialLabel.textColor = kWaitingColor
            
        
            if (kMissingWeightValue != subject.last_weight && kMissingWeightValue != subject.initial_weight) {
                percentLabel.text = String(format:"%.0lf%%",100 * subject.last_weight/subject.initial_weight)
                
                if (subject.last_weight < (subject.initial_weight * 0.85)){
                    percentLabel.textColor = UIColor.systemPink
                    percentLabel.font = UIFont.boldSystemFont(ofSize: 18.0)
                }
                else {
                    percentLabel.textColor = kWaitingColor
                    percentLabel.font = UIFont.italicSystemFont(ofSize: 16.0)
                }
            }
            else {
                
                percentLabel.text = "– –%"
                percentLabel.textColor = kWaitingColor
                percentLabel.font = UIFont.systemFont(ofSize: 16.0)
            }
            
        } // kMissingWeightValue == subject.weight
        
    }
    
    override func draw(_ rect: CGRect) {
        
         self.layer.cornerRadius = 16
        
        let ctx: CGContext = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        var roundRect = UIBezierPath(roundedRect: rect.inset(by:UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)), byRoundingCorners:.allCorners, cornerRadii: CGSize(width: 16.0, height: 16.0)).cgPath
        ctx.addPath(roundRect);
        
        if (kMissingWeightValue == subject.weight) {
            ctx.setStrokeColor(UIColor.purple.cgColor)
        }
        else {
             ctx.setStrokeColor(UIColor.gray.cgColor)
        }
        ctx.setLineWidth(2)
        ctx.strokePath()
        super.draw(rect)
        ctx.restoreGState()


    }

}
