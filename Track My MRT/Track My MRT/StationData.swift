//
//  StationData.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 2/5/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

class StationData
{
    var fromStation:String!
    var toStation:String!
    var fare:String!
    var totalDistance:Double!
    var stationCode:String!
    var stationDirectionId:Int!
    var arrivalTime:String!
    var nxtTrainArrivalTime:String!
    var totalStations:Int!
    var intermediateStations:[String] = [String] ()
}
