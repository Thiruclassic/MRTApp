//
//  Constants.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 27/4/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

let FROM_LABEL="FROM"
let TO_LABEL="TO"

//JSON Object Names
let JSON_ROOT_ELEMENT="station"
let STATION_NAME="name"

let MRT_ARRTIVAL_URL="https://mrtapi.com/api/v1.1/getTrainArrival"

let POST_KEY="APIKey=0203098492592377&stnCode="

let DB_PATH = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String


//VIEW IDENTIFIERS


let ROUTEVIEW_CONTROLLER_ID="RouteView"

let FROM_TABLE_CELL_ID="CellFromIdentifier"

let TO_TABLE_CELL_ID="CellToIdentifier"


