//
//  StationModel.swift
//  Track My MRT
//
//  Created by Varun Sam on 06/05/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation


class StationModel{
    
    var stationPrimaryId:Int!
    var stationName:String!
    var stationCode:String!
    var stationDistance:[String] = [String] ()
    var stationLineCodes:[String] = [String] ()
    var stationLaneCodes:[String] = [String] ()
    var stationNumber:String!
    var isIntermediateStation:Bool = false
    var colors:[String] = [String] ()
    
}
