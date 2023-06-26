//
//  BartenderGroupMean.swift
//  PointOfScale
//
//  Created by Tom Houpt on 6/25/23.
//

import Foundation

import Foundation

struct BartenderGroupMean : Identifiable {

    var id: String
    
    var mean: Double
    
    var n: Int
    
    var sem: Double
    
    var m2: Double // for single pass calculation
    
}
