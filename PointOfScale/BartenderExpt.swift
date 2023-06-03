//
//  BartenderExpt.swift
//  PointOfScale
//
//  Created by Tom Houpt on 5/25/23.
//

import Foundation

struct BartenderExpt : Identifiable {

    var archived: String? // date when experiment was ended in "E MM-dd-YYYY at HH:MM [Z]" format 
                        // experiments WITHOUT archived are still in progress...
                        
    var id: String // called code in firebase and BarTender
    
    var name: String // long name/description
    
    var last_updated: String // date in "E MM-dd-YYYY at HH:MM [Z]" format

    /*
    var contacts : [String:Any?] // dictonary keyed by contact name; values are ["email": "<email>","phone":"<phone_number>"]
    
    var group_means: [String:Any?] // dictionary keyed by group code; values are dictionarys of mean group values keyed by measurement date/time
    
    var groups: [String:String] // dictionary of subject groups in experiments, key is short name, value as description, e.g. "FNL":"Female NaCl LiCl"
    
    var investigators: String // comma separated list of investigators
    
 
    var last_uploaded: String // date in "E MM-dd-YYYY at HH:MM [Z]" format
    
    var measures: [String:String] // dictionary of variables measured, key is short name, value as description, e.g. "CS+":"flavor paired with 8% glucose"
    
    var num_subjects: Int
    
    var project_code: String
    
    var project_name: String
    
    var rb_protocol: String   // can't call it protocol
    
    var subjects: [String:BartenderSubject] // dictionary of subject data values, keys = <exptCode><nn>
    
    var wikipage: String
    
    */
//    var indexPath: IndexPath!

}
