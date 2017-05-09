//
//  DbHandler.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 2/5/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

var mrtDb:OpaquePointer?=nil
var insertStatement:OpaquePointer?=nil
var selectStatement:OpaquePointer?=nil

var interLinkStations:[String] = [String] ()

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

var isIntermediateLineFound:Bool = false

func createTables()
{
    if(openDatabase())
    {
    createStationTable()
    createDistanceTable()
    createStationLaneTable()
    createCheckpointTable()
    }
    
   
}

func openDatabase() -> Bool
{
    let dbDir = DB_PATH + "?trackmymrt.sqllite"
    
    let returnCode=sqlite3_open(dbDir, &mrtDb)
   
    if(returnCode == SQLITE_OK)
    {
        return true
    }
    
    return false
    
}

func executeSql(sql:String,tableName:String) -> Bool
{
    
        if(sqlite3_exec(mrtDb, sql, nil,nil,nil) != SQLITE_OK)
        {
            print("Failed to create table \(tableName)")
            print(sqlite3_errmsg(mrtDb))
            let error = String(cString: sqlite3_errmsg(mrtDb));
            print(ERROR_MESSAGE, error);
            return false
        }
        else
        {
            print("table \(tableName) created successfully")
        }

    return true
}

func createDistanceTable()
{
    if(executeSql(sql: DISTANCE_CREATE_SQL, tableName: DISTANCE_TABLE))
    {
       createDistanceFareData()	
    }

    
}

func createStationTable()
{
    if(executeSql(sql: MRTSTATION_CREATE_SQL, tableName: MRTSTATION_TABLE))
    {
       createStationData()
    }
    
    
}

func createStationLaneTable()
{
    if(executeSql(sql: STATIONLANE_CREATE_QUERY, tableName: STATIONLANE_TABLE))
    {
        createStationData()
    }
}
func createCheckpointTable()
{
    if(executeSql(sql: CHECKPOINT_CREATE_QUERY, tableName: CHECKPOINT_TABLE))
    {
        createCheckpointData()
    }
}

func dropTables()
{
    
    if(openDatabase())
    {
    var sql="DROP TABLE MRTSTATION"
    
    executeSql(sql: sql, tableName: MRTSTATION_TABLE)
    
    sql="DROP TABLE DISTANCE"
    
    executeSql(sql: sql, tableName: DISTANCE_TABLE)
    
    sql="DROP TABLE STATIONLANE"
    
    executeSql(sql: sql, tableName: STATIONLANE_TABLE)
    
    sql="DROP TABLE CHECKPOINTSTATION"
    
    executeSql(sql: sql, tableName: CHECKPOINT_TABLE)
    }
    
}

func prepareMrtStationStatement()
{
    
    var cSql = MRTSTATION_INSERT_SQL.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    cSql = MRTSTATION_SELECT_SQL.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &selectStatement, nil)
    
   
}

func prepareDistanceStatment()
{
    
    var cSql = DISTANCE_INSERT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    cSql = DISTANCE_SELECT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &selectStatement, nil)
}

func prepareStationLaneStatement()
{
    var cSql = STATIONLANE_INSERT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    cSql = STATIONLANE_SELECT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &selectStatement, nil)
}

func prepareCheckpointStatement()
{
    var cSql = CHECKPOINT_INSERT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    cSql = CHECKPOINT_CONNECTION_SELECT_QUERY.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql, -1, &selectStatement, nil)
}



func createStationLaneData()
{
    prepareStationLaneStatement()
    
    let lanes:[NSDictionary] = readJSONData(fileName: STATION_LANE_JSON_FILE, fileType: JSON_TYPE, rootElement: STATION_LANE_ROOT_ELEMENT)
    
    var count:Int = 0
    for lane in lanes
    {
        let lineCode=lane[STATION_LINE_CODE] as? NSString
        let totalStations=lane[STATION_LANE_TOTAL_STATIONS] as? NSString
        let totalDistance=lane[STATION_LANE_TOTAL_DISTANCE] as? NSString
        let laneColor=lane[STATION_LANE_COLOR] as? NSString
        
        sqlite3_bind_text(insertStatement, 1, lineCode!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, totalStations!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, totalDistance!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 4, laneColor!.utf8String , -1, SQLITE_TRANSIENT);
        
        count=count+1
        let returnCode=sqlite3_step(insertStatement)
        if (returnCode != SQLITE_DONE)
        {
            print(INSERTION_ERROR, count)
            print(ERROR_CODE, sqlite3_errcode (mrtDb));
            let error = String(cString: sqlite3_errmsg(mrtDb));
            print(ERROR_MESSAGE, error);
            print(RETURN_CODE, returnCode)
        }
        
        
        sqlite3_reset(insertStatement);
        sqlite3_clear_bindings(insertStatement);
    }
    
    print("Station Lane Data inserted successfully")
    
    
}

func createCheckpointData()
{
    prepareCheckpointStatement()
    
    let checkpoints:[NSDictionary] = readJSONData(fileName: CHECKPOINT_JSON_FILE, fileType: JSON_TYPE, rootElement: CHECKPOINT_ROOT_ELEMENT)
    
    var count:Int = 0
    for checkpoint in checkpoints
    {
        let checkpointName=checkpoint[CHECKPOINT_NAME] as? NSString
        let stationLineID=checkpoint[CHECKPOINT_STATION_LINE_ID] as? NSString
        let stationNo=checkpoint[CHECKPOINT_STATION_ID] as? NSString
        let totalDistance=checkpoint[CHECKPOINT_DISTANCE] as? NSString
    
        
        sqlite3_bind_text(insertStatement, 1, checkpointName!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, stationLineID!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, stationNo!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 4, totalDistance!.utf8String , -1, SQLITE_TRANSIENT);
        
        
        count=count+1
        let returnCode=sqlite3_step(insertStatement)
        if (returnCode != SQLITE_DONE)
        {
            print(INSERTION_ERROR, count)
            print(ERROR_CODE, sqlite3_errcode (mrtDb));
            let error = String(cString: sqlite3_errmsg(mrtDb));
            print(ERROR_MESSAGE, error);
            print(RETURN_CODE, returnCode)
        }
        
        
        sqlite3_reset(insertStatement);
        sqlite3_clear_bindings(insertStatement);
    }
    
    print("\(CHECKPOINT_TABLE) Data inserted successfully")

    
}

func createDistanceFareData()
{
    
    prepareDistanceStatment()
    
    let distances:[NSDictionary] = readJSONData(fileName: DISTANCE_FARE_JSON_FILE, fileType: JSON_TYPE, rootElement: DISTANCE_ROOT_ELEMENT)
    
    var count:Int = 0
    for distance in distances
    {
        let min_distance=distance[DISTANCE_MINIMUM] as? NSString
        let max_distance=distance[DISTANCE_MAXIMUM] as? NSString
        let adult_fare=distance[ADULT_FARE] as? NSString
    
        sqlite3_bind_text(insertStatement, 1, min_distance!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, max_distance!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, adult_fare!.utf8String , -1, SQLITE_TRANSIENT);
       
        count=count+1
        let returnCode=sqlite3_step(insertStatement)
        if (returnCode != SQLITE_DONE)
        {
            print(INSERTION_ERROR, count)
            print(ERROR_CODE, sqlite3_errcode (mrtDb));
            let error = String(cString: sqlite3_errmsg(mrtDb));
            print(ERROR_MESSAGE, error);
            print(RETURN_CODE, returnCode)
        }
       
       
    sqlite3_reset(insertStatement);
    sqlite3_clear_bindings(insertStatement);
    }
    
    print("Distance Fare Data inserted successfully")


}

func getFare(distance:Double) -> String
{
    let fareId:Int = computeFareId(distance: distance)
   
   // print(fareId)
    prepareDistanceStatment()
    let distanceStr = String(fareId) as NSString?
    sqlite3_bind_text(selectStatement, 1, distanceStr!.utf8String, -1, SQLITE_TRANSIENT);
    var fare:String! = ""

    
    if(sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        let fare_buf = sqlite3_column_text(selectStatement, 0)
        fare = String(cString: fare_buf!)
    }
    else
    {
        print(ERROR_CODE, sqlite3_errcode (mrtDb));
        let error = String(cString: sqlite3_errmsg(mrtDb));
        print(ERROR_MESSAGE, error);
    }
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    return fare!;
}

func computeFareId(distance:Double) -> Int
{
    var fareId:Int = 1
    if(distance>=3.3)
    {
        var tempId = 1
        let tempDistance:Double=distance-3.3
        tempId=tempId + Int(tempDistance / 1.0)
        fareId=fareId + tempId
    }
    return fareId
}

func createStationData()
{
    
    prepareMrtStationStatement()

    let stations:[NSDictionary] = readJSONData(fileName:STATION_JSON_FILE,fileType:JSON_TYPE,rootElement:STATION_ROOT_ELEMENT)
    var count:Int = 0

    for station:NSDictionary in stations
    {
        let name = station[STATION_NAME] as? NSString
        let code=station[STATION_CODE] as? NSString
        let distance=station[STATION_DISTANCE] as? NSString
        let longitude=station[LONGITUDE] as? NSString
        let latitude=station[LATITUDE] as? NSString
        let stationLaneCodes=station[STATION_LANE_CODES] as? NSString
        var stationLineCodes=station[STATION_LINE_CODES] as? NSString
        let travelTime=station[TRAVELTIME] as? NSString
        let color=station[COLOR] as? NSString
        stationLineCodes = stationLineCodes!.trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        
       // print(name!)
        //print(code!)
        //print(distance!)
        
        count = count + 1
        sqlite3_bind_text(insertStatement, 1, name!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, code!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, distance!.utf8String , -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(insertStatement, 4, longitude!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 5, latitude!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 6, stationLaneCodes!.utf8String , -1, SQLITE_TRANSIENT);
        
        sqlite3_bind_text(insertStatement, 7, stationLineCodes!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 8, travelTime!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 9, color!.utf8String , -1, SQLITE_TRANSIENT);
        
        let returnCode=sqlite3_step(insertStatement)
        if (returnCode != SQLITE_DONE)
        {
            print(INSERTION_ERROR, count)
            print(ERROR_CODE, sqlite3_errcode (mrtDb));
            let error = String(cString: sqlite3_errmsg(mrtDb));
            print(ERROR_MESSAGE, error);
            print(RETURN_CODE, returnCode)
        }
        sqlite3_reset(insertStatement);
        sqlite3_clear_bindings(insertStatement);
    }
   print("Station Data inserted successfully")
    
    
}


/*func getsampleRouteDetails(fromStation:String,toStation:String,isIntermediate:Bool) -> StationData
{
    
    

    let stationData:StationData = StationData()
    
    stationData.fromStation=fromStation
    stationData.toStation=toStation
    stationData.totalStations = 0
    stationData.totalDistance = 0
    
    let fromStr = fromStation as NSString?
    let toStr = toStation as NSString?
    
    var stations:[NSString] = [NSString] ()
    stations.append(fromStr!)
    stations.append(toStr!)
    
   // var stationModels:[StationModel] = [StationModel] ()
    print(stations.count)
    var distances = [String]()
    var codes = [String]()
    var names = [String]()
    var idArr = [Int]()
    

    for station in stations{
        
        
        print("enter \(station)")
        prepareMrtStationStatement()
        sqlite3_bind_text(selectStatement, 1, station.utf8String, -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(selectStatement) == SQLITE_ROW)
        {
            
            print("enter inside")
            let stationModel:StationModel = StationModel()
            
            // stationModel.stationName
            
            // stationModel.stationCode
            
            let code_buf = sqlite3_column_text(selectStatement, 0)
            stationModel.stationCode = String(cString: code_buf!)
            let dist_buf = sqlite3_column_text(selectStatement, 1)
            let distanceStr = String(cString: dist_buf!)
            stationModel.stationDistance = distanceStr.components(separatedBy: ",")
            
            
            
            let name_buf = sqlite3_column_text(selectStatement, 2)
            stationModel.stationName = String(cString: name_buf!)
            let id_buf = sqlite3_column_text(selectStatement, 8)
            
            stationModel.stationPrimaryId = Int(String(cString: id_buf!))
            print(stationModel.stationPrimaryId)
            
            
            let color_buf = sqlite3_column_text(selectStatement, 3)
            let colors = String(cString: color_buf!)
            
            print(colors)
            
            stationModel.colors = colors.components(separatedBy: ",")
            
            print("station colors \(stationModel.colors)")
            
            let station_line_ids = sqlite3_column_text(selectStatement, 4)
            let stationLinesStr = String(cString: station_line_ids!)
            print("stationLinecodesstr \(stationLinesStr)")
            stationModel.stationLineCodes = stationLinesStr.components(separatedBy: " ")
            
            print("stationLinecodesarr \(stationModel.stationLineCodes)")
            
            
            
            let stationCodes = sqlite3_column_text(selectStatement, 5)
            let stationCodesStr = String(cString: stationCodes!)
            stationModel.stationLaneCodes = stationCodesStr.components(separatedBy: ",")
            print("stationLinecodesstr \(stationModel.stationLaneCodes)")
            
            //stationModels.append(stationModel)
            print("stationLinecodesstr \(stationLinesStr)")
            sqlite3_reset(selectStatement);
            sqlite3_clear_bindings(selectStatement);
            //codes.append(code)
           // names.append(name)
            
            //distances.append(distance)
        }
    }
    
    //print(stationModels.count)
    //let fromStationModel:StationModel = stationModels[0]
    //let toStationModel:StationModel = stationModels[1]
    
        
   // print(stationModels.count)
    let fromStationModel:StationModel = getStation(stationName: fromStation)
    let toStationModel:StationModel = getStation(stationName: toStation)
    stationData.stationCode = fromStationModel.stationCode
    var isSameLine:Bool = false
    print("reached")
    print("fromstation color \(fromStationModel.colors)")
    print("tostation color \(toStationModel.colors)")
    
    var lane:String = String()

    var isDirectLane:Bool = false
    for templane in fromStationModel.stationLaneCodes
    {
         if(toStationModel.stationLaneCodes.contains(templane))
         {
            lane = templane
            isDirectLane = true
            break
        }
    }
    
    if(isIntermediate)
    {
        isIntermediateLineFound = true
    }
        if(isDirectLane)
        {
            isSameLine = true
            
            print("Same Lane data \(lane)")
            
            //isIntermediateLineFound = true
            
            
            interLinkStations.append(fromStation)
            
            if(isIntermediate)
            {
                print("Need to get down at \(fromStation)")
            }
            
            print(fromStationModel.stationLaneCodes)
            print(toStationModel.stationLaneCodes)
            
            let fromStationNumber:Int! = Int(fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: lane)!].replacingOccurrences(of: lane, with: ""))!
            
            let toStationNumber:Int! = Int(toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: lane)!].replacingOccurrences(of: lane, with: ""))!
            
            
            distances.append(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: lane)!])
            distances.append(toStationModel.stationDistance[toStationModel.stationLaneCodes.index(of: lane)!])
            
            stationData.totalDistance = abs(Double(distances[0])! - Double(distances[1])!)
            
            
            
            print("reached next step")
            
            print(fromStationNumber)
            print(toStationNumber)
            stationData.totalStations = abs(fromStationNumber - toStationNumber)
            
            print("total stations \(stationData.totalStations!)")
            
            
            if(fromStationModel.stationPrimaryId > toStationModel.stationPrimaryId)
            {
                stationData.stationDirectionId=1
            }
            else
            {
                stationData.stationDirectionId=2
            }
            
            stationData.stationCode = fromStationModel.stationCode

        }
        else
        {
            
            
       if(!isIntermediateLineFound)
            {
       // fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: lane)]
      //let connectingStations:[String] = getConnectingLane(lane: fromStationModel.stationLaneCodes.remove(at: fromStationModel.stationLaneCodes.index(of: lane)))
            
           // var connectingLanes:String = [String]()
            var laneArray:[String] = [String] ()
            laneArray.insert(contentsOf: fromStationModel.stationLaneCodes, at: laneArray.count)
           // laneArray.insert(contentsOf: toStationModel.stationLaneCodes, at: laneArray.count)
            //laneArray = removeDuplicates(array: laneArray)
            
            let intermediateStations = getConnectingLane(lanes: laneArray)
            
            var interStations:[StationData] = [StationData] ()
            
            var isLineFound:Bool = false
            
            for intermediateStation in intermediateStations
            {
                let stationModel:StationModel = getStation(stationName: intermediateStation)
                
                
                print("intermediate station lane codes\(stationModel.stationLaneCodes)")
                print("intermediate station line codes\(stationModel.stationLineCodes)")

                for stationLane in fromStationModel.stationLaneCodes
                {
                    print("iterating station Lanes \(stationLane)")
                    
                    if(stationModel.stationLaneCodes.contains(stationLane))
                    {
                        let intermediateStationLineCode:String = stationModel.stationLineCodes[stationModel.stationLaneCodes.index(of: stationLane)!]
                        let fromStationLineCode:String = fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: stationLane)!]
                        // let toStationLineCode:String = toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: stationLane)!]
                        print("intermediate station \(intermediateStationLineCode)")
                        
                        let intermediateStationNumber:Int! = Int(intermediateStationLineCode.replacingOccurrences(of: stationLane, with: ""))
                        let fromStationNumber:Int! = Int(fromStationLineCode.replacingOccurrences(of: stationLane, with: ""))
                        
                        //let toStationNumber:Int! = Int(toStationLineCode.replacingOccurrences(of: stationLane, with: ""))
                        
                        distances.append(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: stationLane)!])
                        distances.append(stationModel.stationDistance[stationModel.stationLaneCodes.index(of:stationLane)!])
                        print("error checkind \(distances)")
                        stationData.totalDistance = stationData.totalDistance + abs(Double(distances[0])! - Double(distances[1])!)
                        
                        print("total station before recursive \(stationData.totalStations)")
                        print("station number \(intermediateStationNumber!)")
                        
                      //  print("get down at \(stationModel.stationName)")
                        
                        stationData.totalStations = stationData.totalStations + abs(fromStationNumber - intermediateStationNumber)
                        let interStationData:StationData = getRouteDetails(fromStation: intermediateStation, toStation: toStation,isIntermediate: true)
                        
                       // stationData.totalStations = stationData.totalStations + interStationData.totalStations
                       //stationData.totalDistance = stationData.totalDistance + interStationData.totalDistance
                        isLineFound = true
                        interStations.append(interStationData)
                    }
                }
            }
                
            
        
            
           // getConnectingLane(lanes: fromStationModel.stationLaneCodes)
            
            var totalStations:Int = 100
            var totalDistance:Double = 0
                
            var tempStationData:StationData = StationData()
            for interStationData in interStations
            {
                if(interStationData.totalStations < totalStations && interLinkStations.contains(interStationData.fromStation))
                {
                    totalStations = interStationData.totalStations
                    totalDistance = interStationData.totalDistance
                    tempStationData = interStationData
                }
            }
            stationData.totalStations = totalStations
            stationData.totalDistance = totalDistance
                 print("get down actually at \(tempStationData.fromStation)")
            }
           
        }
    
    
       /*if(idArr[names.index(of: fromStation)!] > idArr[names.index(of: toStation)!])
    {
     stationData.stationDirectionId=1
    }
    else
    {
        stationData.stationDirectionId=2
    }*/
   
    
    if(stationData.stationDirectionId == nil)
    {
        stationData.stationDirectionId = 1
    }
    print("final total stations \(stationData.totalStations)")
    
    print("final total distance \(stationData.totalDistance)")

    stationData.fare = getFare(distance: stationData.totalDistance)
   // stationData.stationCode=codes[names.index(of: fromStation)!]
  
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationData
}


func getStationlocationData(fromStation:String,toStation:String) -> RouteModel
{
    
    let fromStr = fromStation as NSString?
    let toStr = toStation as NSString?
    
    var stations:[NSString] = [NSString] ()
    stations.append(fromStr!)
    stations.append(toStr!)

    let selectedStationsData = RouteModel()
    var index = 0;

    
    for station in stations
    {
     prepareMrtStationStatement()
               sqlite3_bind_text(selectStatement, 1, station.utf8String, -1, SQLITE_TRANSIENT);
        
        let returncode=sqlite3_step(selectStatement)
        if ( returncode == SQLITE_ROW)
        {
            
            let longitude_buf = sqlite3_column_text(selectStatement, 6)
            selectedStationsData.coordinates.insert(String(cString: longitude_buf!), at: index)
            index += 1
            let latitude_buf = sqlite3_column_text(selectStatement, 7)
            selectedStationsData.coordinates.insert(String(cString: latitude_buf!), at: index)
        }
        index += 1
    }


    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    selectedStationsData.fromStation = fromStation
    selectedStationsData.toStation = toStation
    
    return selectedStationsData
}


func getStationDirectionsData(fromStationModel:StationModel, toStationModel:StationModel)
{
    
}

func getConnectingLane(lanes: [String]) -> [String]
{
    print("intermediate lanes \(lanes)")
    
    //var queryString  =
    var intermediateStations:[String] = [String] ()
    
 /*
    var replaceStr:String = ""
    var count:Int = 0
   for lane in lanes
    {
        
        replaceStr = replaceStr + "'" + lane + "'"
        if(count != lanes.count - 1)
        {
         replaceStr = replaceStr + ","
        }
        count = count + 1
       
    }
    print("\(replaceStr)")*/
  //  CHECKPOINT_SELECT_QUERY = CHECKPOINT_SELECT_QUERY.replacingOccurrences(of: "replaceString", with: replaceStr)
    
    prepareCheckpointStatement()
    
    for lane in lanes
    {
     let laneStr = lane as NSString?
    
    
    
    sqlite3_bind_text(selectStatement, 1, laneStr!.utf8String, -1, SQLITE_TRANSIENT);
    print("checkpoint lane code \(lane)")
    while(sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        
        let name_buf = sqlite3_column_text(selectStatement, 0)
        let intermediateStation =  String(cString: name_buf!)
        print("checkpoint station name \(String(cString:name_buf!))")
        
      
        intermediateStations.append(intermediateStation)
        
        
       // print("checkpoint stations lanecode \(lane_code)")
    }
    }
   /* else
    {
        print(ERROR_CODE, sqlite3_errcode (mrtDb));
        let error = String(cString: sqlite3_errmsg(mrtDb));
        print(ERROR_MESSAGE, error);
    }*/
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);

    
    return intermediateStations
    
}
*/
func removeDuplicates(array:[String]) -> [String]
{
    var items:[String] = [String] ()
    for item in array
    {
        if(!items.contains(item))
        {
            items.append(item)
        }
    }
    
    return items
}

func getStation(stationName:String) -> StationModel
{
    prepareMrtStationStatement()

    let stationModel:StationModel = StationModel()
    
    let station = stationName as NSString?
    
    sqlite3_bind_text(selectStatement, 1, station!.utf8String, -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        
        print("enter inside")
        
        // stationModel.stationName
        
        // stationModel.stationCode
        
        let code_buf = sqlite3_column_text(selectStatement, 0)
        stationModel.stationCode = String(cString: code_buf!)
        let dist_buf = sqlite3_column_text(selectStatement, 1)
        let distanceStr = String(cString: dist_buf!)
        stationModel.stationDistance = distanceStr.components(separatedBy: ",")
        
        let name_buf = sqlite3_column_text(selectStatement, 2)
        stationModel.stationName = String(cString: name_buf!)
        let id_buf = sqlite3_column_text(selectStatement, 8)
        
        stationModel.stationPrimaryId = Int(String(cString: id_buf!))
        print(stationModel.stationPrimaryId)
        
        
        let color_buf = sqlite3_column_text(selectStatement, 3)
        let colors = String(cString: color_buf!)
        
        print(colors)
        
        stationModel.colors = colors.components(separatedBy: ",")
        
        print("station colors \(stationModel.colors)")
        
        let station_line_ids = sqlite3_column_text(selectStatement, 4)
        let stationLinesStr = String(cString: station_line_ids!)
        print("stationLinecodesstr \(stationLinesStr)")
        stationModel.stationLineCodes = stationLinesStr.components(separatedBy: ",")
        
        print("stationLinecodesarr \(stationModel.stationLineCodes)")
        
        
        
        let stationCodes = sqlite3_column_text(selectStatement, 5)
        let stationCodesStr = String(cString: stationCodes!)
        stationModel.stationLaneCodes = stationCodesStr.components(separatedBy: ",")
        print("stationLinecodesstr \(stationModel.stationLaneCodes)")
        
        print("stationLinecodesstr \(stationLinesStr)")
       
        //codes.append(code)
        // names.append(name)
        
        //distances.append(distance)
    }
    
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationModel
}



func getConnectingStations(fromStationModel:StationModel, toStationModel:StationModel) -> [StationModel]
{
    
    
    
    prepareCheckpointStatement()
    
           //let laneStr = lane as NSString?
    var checkPointStations:[StationModel] = [StationModel] ()
    

        
        
        //sqlite3_bind_text(selectStatement, 1, laneStr!.utf8String, -1, SQLITE_TRANSIENT);
        //print("checkpoint lane code \(lane)")
        while(sqlite3_step(selectStatement) == SQLITE_ROW)
        {
            
            let checkPointStation:StationModel = StationModel()
            let name_buf = sqlite3_column_text(selectStatement, 0)
            let name = String(cString: name_buf!)
            checkPointStation.stationName = name
            
            
            let stnid_buf = sqlite3_column_text(selectStatement, 1)
            let stnId = String(cString: stnid_buf!)
            let stnIDarr:[String] = stnId.components(separatedBy: ",")
            checkPointStation.stationLineCodes = stnIDarr
            
            //print("checkpoint station id \(stnId)")
            
            let laneid_buf = sqlite3_column_text(selectStatement, 2)
            let laneId = String(cString: laneid_buf!)
            let lanearr:[String] = laneId.components(separatedBy: ",")
            checkPointStation.stationLaneCodes = lanearr
            //print("checkpoint laneid \(laneId)")
            
            let distance_buf = sqlite3_column_text(selectStatement, 3)
            let distance = String(cString: distance_buf!)
            let distArr:[String] = distance.components(separatedBy: ",")
            checkPointStation.stationDistance = distArr
            
            checkPointStations.append(checkPointStation)
            
            
            
            //intermediateStations.append(intermediateStation)
            
            
            // print("checkpoint stations lanecode \(lane_code)")
        }
    
    print("returning checkpoints ")
    
    /* else
     {
     print(ERROR_CODE, sqlite3_errcode (mrtDb));
     let error = String(cString: sqlite3_errmsg(mrtDb));
     print(ERROR_MESSAGE, error);
     }*/
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    
    return checkPointStations
    
}
func findOneIntersectinLanes(fromStationModel:StationModel, toStationModel:StationModel,checkpointStations:[StationModel]) -> [StationData]
{
    var stationDatas:[StationData] = [StationData] ()

    
    for checkpointStation in checkpointStations
    {
    for fromlane in fromStationModel.stationLaneCodes
    {
        for toLane in toStationModel.stationLaneCodes
        {
            if(checkpointStation.stationLaneCodes.contains(fromlane) && checkpointStation.stationLaneCodes.contains(toLane))
            {
                
                
                
                let stationData:StationData = StationData()
                stationData.fromStation = fromStationModel.stationName
                //print(checkpointStation.stationLaneCodes)
                
                
                let fromLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: fromlane)!]
                let toLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: toLane)!]
                
                let fromCheckpointNo:Int! = Int(fromLaneId.replacingOccurrences(of: fromlane, with: ""))
                let toCheckpointNo:Int! = Int(toLaneId.replacingOccurrences(of: toLane, with: ""))
                
                let fromStationNo:Int! = Int(fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: fromlane)!].replacingOccurrences(of: fromlane, with: ""))
                
                let toStationNo:Int! = Int(toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: toLane)!].replacingOccurrences(of: toLane, with: ""))
                
                var totalStations:Int = 0
                stationData.intermediateStations.append(checkpointStation.stationName)
                totalStations = totalStations + abs(fromCheckpointNo - fromStationNo)
                totalStations = totalStations + abs(toCheckpointNo - toStationNo)
                stationData.totalStations = totalStations
               
                let fromStationDistance:Double! = Double(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: fromlane)!])
                
                print(checkpointStation.stationLaneCodes)
                print(checkpointStation.stationDistance)
                let checkpointFromDistance:Double! = Double(checkpointStation.stationDistance[checkpointStation.stationLaneCodes.index(of: fromlane)!])
                
                let checkpointToDistance:Double! = Double(checkpointStation.stationDistance[checkpointStation.stationLaneCodes.index(of: toLane)!])
                
                let toDistance:Double! = Double(toStationModel.stationDistance[toStationModel.stationLaneCodes.index(of: toLane)!])
                
                stationData.totalDistance = abs(fromStationDistance - checkpointFromDistance) + abs(toDistance - checkpointToDistance)
                print("checkpoint station name \(checkpointStation.stationName)  \(totalStations)")
                stationDatas.append(stationData)
                
                
            }
        }
    }
    }
    
    return stationDatas

}


func findTwoIntersectinLanes(fromStationModel:StationModel, toStationModel:StationModel,checkpointStations:[StationModel]) -> [StationData]

{
    var stationDatas:[StationData] = [StationData] ()
    
    
    for checkpointStation in checkpointStations
    {
      
        for fromlane in fromStationModel.stationLaneCodes
        {
            if(checkpointStation.stationLaneCodes.contains(fromlane))
            {
                
                                print(checkpointStation.stationLaneCodes)
                
                print("before remove \(checkpointStation.stationLaneCodes)")
                //checkpointStation.stationLaneCodes.remove(at: checkpointStation.stationLaneCodes.index(of: fromlane)!)
                
                
                print("after remove \(checkpointStation.stationLaneCodes)")
                
                 let fromLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: fromlane)!]
                
                for subLane in checkpointStation.stationLaneCodes
                {
            
                    if(subLane != fromlane)
                    {
            for toLane in toStationModel.stationLaneCodes
            {
                for subcheckpoint in checkpointStations
                {
                    if(checkpointStation.stationName != subcheckpoint.stationName)
                    {
                        
                    if(subcheckpoint.stationLaneCodes.contains(subLane) && subcheckpoint.stationLaneCodes.contains(toLane))
                        {
                    
                       let stationData:StationData = StationData()
                       stationData.fromStation = fromStationModel.stationName

               
                let toLaneId:String = subcheckpoint.stationLineCodes[subcheckpoint.stationLaneCodes.index(of: toLane)!]
                
                let fromSubLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: subLane)!]
                            
                            let fromMidLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: fromlane)!]
                            
                            let toMidLaneId:String = subcheckpoint.stationLineCodes[subcheckpoint.stationLaneCodes.index(of: subLane)!]
                        
                            print("lanes \(toLaneId) \(fromSubLaneId) \(fromMidLaneId) \(toMidLaneId)")
                        //let toSublane:String = subcheckpoint.stationLaneCodes
                
                let fromsubCheckpointNo:Int! = Int(fromSubLaneId.replacingOccurrences(of: subLane, with: ""))
                let toCheckpointNo:Int! = Int(toLaneId.replacingOccurrences(of: toLane, with: ""))
                            
                let toSubCheckpointNo:Int! = Int(toMidLaneId.replacingOccurrences(of: subLane, with: ""))
                        
                        //let fromSubCheckpointNo:Int! = Int()
                
                let fromStationNo:Int! = Int(fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: fromlane)!].replacingOccurrences(of: fromlane, with: ""))
                            
                let fromSubStationNo:Int! = Int(fromMidLaneId.replacingOccurrences(of: fromlane, with: ""))
                
                let toStationNo:Int! = Int(toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: toLane)!].replacingOccurrences(of: toLane, with: ""))
                            
                            
                            
                
                var totalStations:Int = 0
                stationData.intermediateStations.append(checkpointStation.stationName)
                stationData.intermediateStations.append(subcheckpoint.stationName)
                totalStations = totalStations + abs(fromSubStationNo - fromStationNo) + abs (fromsubCheckpointNo - toSubCheckpointNo)
                totalStations = totalStations + abs(toCheckpointNo - toStationNo)
                stationData.totalStations = totalStations
                            
                            
                            
                let fromStnDistance:Double! = Double(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: fromlane)!])
                            
                let checkpointFromDistance:Double! = Double(checkpointStation.stationDistance[checkpointStation.stationLaneCodes.index(of: fromlane)!])
                            
                let subcheckpointFromDistance:Double! = Double(checkpointStation.stationDistance[checkpointStation.stationLaneCodes.index(of: subLane)!])

                let subcheckpointtoDistance:Double! = Double(subcheckpoint.stationDistance[subcheckpoint.stationLaneCodes.index(of: subLane)!])

                            
                let checkpointToDistance:Double! = Double(subcheckpoint.stationDistance[subcheckpoint.stationLaneCodes.index(of: toLane)!])
                            
                let toStnDistance:Double! = Double(toStationModel.stationDistance[toStationModel.stationLaneCodes.index(of: toLane)!])
                            
                print("\(fromStnDistance) \(checkpointFromDistance) \(subcheckpointFromDistance) \(subcheckpointtoDistance) \(checkpointToDistance) \(toStnDistance)")
                            
                stationData.totalDistance = abs(fromStnDistance - checkpointFromDistance)
                stationData.totalDistance = stationData.totalDistance + abs(subcheckpointtoDistance - subcheckpointFromDistance)
                //stationData.totalDistance = stationData.totalDistance + abs(subcheckpointtoDistance - checkpointToDistance)
                stationData.totalDistance = stationData.totalDistance + abs(toStnDistance - checkpointToDistance)
                            
            
                print("checkpoint station name \(checkpointStation.stationName)  \(subcheckpoint.stationName) \(totalStations)")
                stationDatas.append(stationData)
                        }
                    }
                }
            }
                    
                    }
                    
                }
            }
        }
    }
       /* for fromlane in fromStationModel.stationLaneCodes
        {
            for toLane in toStationModel.stationLaneCodes
            {
                if(checkpointStation.stationLaneCodes.contains(fromlane) && checkpointStation.stationLaneCodes.contains(toLane))
                {
                    
                    let stationData:StationData = StationData()
                    stationData.fromStation = fromStationModel.stationName
                    print(checkpointStation.stationLaneCodes)
                    
                    
                    let fromLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: fromlane)!]
                    let toLaneId:String = checkpointStation.stationLineCodes[checkpointStation.stationLaneCodes.index(of: toLane)!]
                    
                    let fromCheckpointNo:Int! = Int(fromLaneId.replacingOccurrences(of: fromlane, with: ""))
                    let toCheckpointNo:Int! = Int(toLaneId.replacingOccurrences(of: toLane, with: ""))
                    
                    let fromStationNo:Int! = Int(fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: fromlane)!].replacingOccurrences(of: fromlane, with: ""))
                    
                    let toStationNo:Int! = Int(toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: toLane)!].replacingOccurrences(of: toLane, with: ""))
                    
                    var totalStations:Int = 0
                    stationData.intermediateStations.append(checkpointStation.stationName)
                    totalStations = totalStations + abs(fromCheckpointNo - fromStationNo)
                    totalStations = totalStations + abs(toCheckpointNo - toStationNo)
                    stationData.totalStations = totalStations
                    print("checkpoint station name \(checkpointStation.stationName)  \(totalStations)")
                    st``ationDatas.append(stationData)
                    
                    
                }*/
    
    return stationDatas
}

func getRouteDetails(fromStation:String,toStation:String,isIntermediate:Bool) -> StationData
{
    let stationData:StationData = StationData()
    
    stationData.fromStation=fromStation
    stationData.toStation=toStation
    stationData.totalStations = 0
    stationData.totalDistance = 0
    
    let fromStr = fromStation as NSString?
    let toStr = toStation as NSString?
    
    var stations:[NSString] = [NSString] ()
    stations.append(fromStr!)
    stations.append(toStr!)
    
    // var stationModels:[StationModel] = [StationModel] ()
    print(stations.count)
    var distances = [String]()
    var codes = [String]()
    var names = [String]()
    var idArr = [Int]()
    
    
    
    // print(stationModels.count)
    let fromStationModel:StationModel = getStation(stationName: fromStation)
    let toStationModel:StationModel = getStation(stationName: toStation)
    stationData.stationCode = fromStationModel.stationCode
    var isSameLine:Bool = false
    
    var lane:String = String()
    
    var isDirectLane:Bool = false
    for templane in fromStationModel.stationLaneCodes
    {
        if(toStationModel.stationLaneCodes.contains(templane))
        {
            lane = templane
            isDirectLane = true
            break
        }
    }
    
    if(isDirectLane)
    {
        isSameLine = true
        
        print("Same Lane data \(lane)")
        
        //isIntermediateLineFound = true
        
        
        interLinkStations.append(fromStation)
        
        if(isIntermediate)
        {
            print("Need to get down at \(fromStation)")
        }
        
        print(fromStationModel.stationLaneCodes)
        print(toStationModel.stationLaneCodes)
        
        let fromStationNumber:Int! = Int(fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: lane)!].replacingOccurrences(of: lane, with: ""))!
        
        let toStationNumber:Int! = Int(toStationModel.stationLineCodes[toStationModel.stationLaneCodes.index(of: lane)!].replacingOccurrences(of: lane, with: ""))!
        
        
        distances.append(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: lane)!])
        distances.append(toStationModel.stationDistance[toStationModel.stationLaneCodes.index(of: lane)!])
        
        stationData.totalDistance = abs(Double(distances[0])! - Double(distances[1])!)
        
        print(fromStationNumber)
        print(toStationNumber)
        stationData.totalStations = abs(fromStationNumber - toStationNumber)
        
        print("total stations \(stationData.totalStations!)")
        
        
        if(fromStationModel.stationPrimaryId > toStationModel.stationPrimaryId)
        {
            stationData.stationDirectionId=1
        }
        else
        {
            stationData.stationDirectionId=2
        }
        
        stationData.stationCode = fromStationModel.stationCode
        
    }
    
    else
    {
        let checkpoints:[StationModel] = getConnectingStations(fromStationModel: fromStationModel, toStationModel: toStationModel)
        var stationDatas:[StationData] = findOneIntersectinLanes(fromStationModel: fromStationModel, toStationModel: toStationModel,checkpointStations: checkpoints)
        
        
        var stationDataTwo:[StationData] = findTwoIntersectinLanes(fromStationModel: fromStationModel, toStationModel: toStationModel,checkpointStations: checkpoints)
        
        stationDatas.insert(contentsOf: stationDataTwo, at: stationDatas.count)
        
        var totalstations:Int = 100
        var finalStationData:StationData = StationData()
        for stationData in stationDatas
        {
            if (stationData.totalStations < totalstations)
            {
                finalStationData=stationData
                totalstations = stationData.totalStations
            }
        }
        stationData.intermediateStations = finalStationData.intermediateStations
        stationData.totalDistance = finalStationData.totalDistance
        print("finalstation distance \(stationData.totalDistance)")
        print("final station data: \(finalStationData.intermediateStations)")

    }
    

    if(stationData.stationDirectionId == nil)
    {
        stationData.stationDirectionId = 1
    }
    print("final total stations \(stationData.totalStations)")
    
    print("final total distance \(stationData.totalDistance)")
    
    stationData.fare = getFare(distance: stationData.totalDistance)
    // stationData.stationCode=codes[names.index(of: fromStation)!]
    
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationData
    
    
}




