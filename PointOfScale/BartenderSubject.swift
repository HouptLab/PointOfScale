//
//  BartenderSubject.swift
//  PointOfScale
//
//  Created by Tom Houpt on 22/10/13.
//

import Foundation

struct BartenderSubject : Identifiable {

    var id: String
    
    var weight: Double 
    
    
    var last_weight: Double
    
    var initial_weight: Double
    
    var group: String
    
/*
    var data: [String:Any?] // dictonary of measures keyed by measure name; values are dictionary of measurements keyed by measurement date/time
    
    var group: String // each subject belongs to an experimental group, or is "Unassigned"
*/
    var indexPath: IndexPath!

}
