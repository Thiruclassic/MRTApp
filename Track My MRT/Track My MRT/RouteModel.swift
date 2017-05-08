//
//  RouteModel.swift
//  Track My MRT
//
//  Created by Mridul Agarwal on 3/5/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

class RouteModel {
    
    var fromStation : String
    var toStation : String
    var coordinates : [String]!
    
    
    init() {
        fromStation = "";
        toStation = "";
        coordinates = [String]()
    }
}
