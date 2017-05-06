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

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


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
    
    cSql = CHECKPOINT_SELECT_QUERY.cString(using: String.Encoding.utf8)
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
    
        
        sqlite3_bind_text(insertStatement, 1, checkpointName!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, stationLineID!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, stationNo!.utf8String , -1, SQLITE_TRANSIENT);
        
        
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

func getStationData(fromStation:String,toStation:String) -> StationData
{
    
    

    let stationData:StationData = StationData()
    
    stationData.fromStation=fromStation
    stationData.toStation=toStation
    let fromStr = fromStation as NSString?
    let toStr = toStation as NSString?
    
    var stations:[NSString] = [NSString] ()
    stations.append(fromStr!)
    stations.append(toStr!)
    
    var stationModels:[StationModel] = [StationModel] ()
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
            
            stationModels.append(stationModel)
            print("stationLinecodesstr \(stationLinesStr)")
            sqlite3_reset(selectStatement);
            sqlite3_clear_bindings(selectStatement);
            //codes.append(code)
           // names.append(name)
            
            //distances.append(distance)
        }
    }
    
    print(stationModels.count)
    let fromStationModel:StationModel = stationModels[0]
    let toStationModel:StationModel = stationModels[1]
    
    var isSameLine:Bool = false
    print("reached")
    print("fromstation color \(fromStationModel.colors)")
    print("tostation color \(toStationModel.colors)")
    var lane:String = String()
    for templane in fromStationModel.stationLaneCodes
    {
        if(toStationModel.stationLaneCodes.contains(templane))
        {
            lane = templane
            isSameLine = true
            
            print("Same Lane data")
            
            
            distances.append(fromStationModel.stationDistance[fromStationModel.stationLaneCodes.index(of: lane)!])
            distances.append(toStationModel.stationDistance[toStationModel.stationLaneCodes.index(of: lane)!])
            
            stationData.totalDistance = abs(Double(distances[0])! - Double(distances[1])!)
            
            stationData.fare = getFare(distance: stationData.totalDistance)
            
            print("reached next step")
            
            
            
            
            if(fromStationModel.stationPrimaryId > toStationModel.stationPrimaryId)
            {
                stationData.stationDirectionId=1
            }
            else
            {
                stationData.stationDirectionId=2
            }
            
            stationData.stationCode = fromStationModel.stationCode

            break;
        }
        else
        {
            
       // fromStationModel.stationLineCodes[fromStationModel.stationLaneCodes.index(of: lane)]
      //let connectingStations:[String] = getConnectingLane(lane: fromStationModel.stationLaneCodes.remove(at: fromStationModel.stationLaneCodes.index(of: lane)))
            
           // var connectingLanes:String = [String]()
            var laneArray:[String] = [String] ()
            for stationModel in stationModels
            {
                laneArray.insert(contentsOf: stationModel.stationLaneCodes, at: laneArray.count)
            }
            laneArray = removeDuplicates(array: laneArray)
            
            getConnectingLane(lanes: laneArray)
            
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
    
    
   // stationData.stationCode=codes[names.index(of: fromStation)!]
  
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationData
}


func getStationDirectionsData(fromStationModel:StationModel, toStationModel:StationModel)
{
    
}

func getConnectingLane(lanes: [String]) -> [StationModel]
{
    
    prepareCheckpointStatement()
   
    
    print("intermediate lanes \(lanes)")
    
    //var queryString  =
    
    var intermediateStations:[StationModel] = [StationModel] ()

    
   /* for lane in lanes
    {
    
     let laneStr = lane as NSString?
    
    sqlite3_bind_text(selectStatement, 1, laneStr!.utf8String, -1, SQLITE_TRANSIENT);
    print("lane code \(lane)")
    while(sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        
        let intermediateStation:StationModel = StationModel()
        
        let name_buf = sqlite3_column_text(selectStatement, 0)
        intermediateStation.stationName =  String(cString: name_buf!)

        
        let lineid_buf = sqlite3_column_text(selectStatement, 1)
        let lineid = String(cString: lineid_buf!)
        intermediateStation.stationLineCodes = [lineid]
       // print("checkpoint stations id \(id)")
        
        let lane_buf = sqlite3_column_text(selectStatement, 2)
        let lane_code = String(cString: lane_buf!)
        //intermediateStation.stationLaneCodes = [lane_code]
        //intermediateStations.append(intermediateStation)
        
        
        
        print("checkpoint stations lanecode \(lane_code)")
    }
    }
   /* else
    {
        print(ERROR_CODE, sqlite3_errcode (mrtDb));
        let error = String(cString: sqlite3_errmsg(mrtDb));
        print(ERROR_MESSAGE, error);
    }*/
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);*/

    
    return intermediateStations
    
}

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

