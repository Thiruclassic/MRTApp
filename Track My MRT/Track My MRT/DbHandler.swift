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
    //dropTables()
    createStationTable()
    createDistanceTable()
    //createStationLaneTable()
    //createCheckpointTable()
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
        createStationData()
    }
}

func dropTables()
{
    var sql="DROP TABLE MRTSTATION"
    
    executeSql(sql: sql, tableName: MRTSTATION_TABLE)
    
    sql="DROP TABLE DISTANCE"
    
    executeSql(sql: sql, tableName: DISTANCE_TABLE)
    
    sql="DROP TABLE STATIONLANE"
    
    executeSql(sql: sql, tableName: STATIONLANE_TABLE)
    
    sql="DROP TABLE CHECKPOINT"
    
    executeSql(sql: sql, tableName: CHECKPOINT_TABLE)
    
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
        let lineCode=checkpoint[STATION_LINE_CODE] as? NSString
        let totalStations=checkpoint[STATION_LANE_TOTAL_STATIONS] as? NSString
        let totalDistance=checkpoint[STATION_LANE_TOTAL_DISTANCE] as? NSString
        let laneColor=checkpoint[STATION_LANE_COLOR] as? NSString
        
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
    
    print("Checkpoint Data inserted successfully")


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
        
       // print(name!)
        //print(code!)
        //print(distance!)
        
        count = count + 1
        sqlite3_bind_text(insertStatement, 1, name!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, code!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, distance!.utf8String , -1, SQLITE_TRANSIENT);
        
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
    
    prepareMrtStationStatement()

    let stationData:StationData = StationData()
    
    stationData.fromStation=fromStation
    stationData.toStation=toStation
    let fromStr = fromStation as NSString?
    let toStr = toStation as NSString?
    sqlite3_bind_text(selectStatement, 1, fromStr!.utf8String, -1, SQLITE_TRANSIENT);
    
    sqlite3_bind_text(selectStatement, 2, toStr!.utf8String, -1, SQLITE_TRANSIENT);

    var distances = [String]()
    var codes = [String]()
    var names = [String]()
    var idArr = [Int]()
    
    
    while (sqlite3_step(selectStatement) == SQLITE_ROW)
    {
    
        let code_buf = sqlite3_column_text(selectStatement, 0)
        let code = String(cString: code_buf!)
        let dist_buf = sqlite3_column_text(selectStatement, 1)
        let distance = String(cString: dist_buf!)
        let name_buf = sqlite3_column_text(selectStatement, 2)
        let name = String(cString: name_buf!)
        let id_buf = sqlite3_column_text(selectStatement, 3)
        let id:Int! = Int(String(cString: id_buf!))
        idArr.append(id)

        codes.append(code)
        names.append(name)
    
        distances.append(distance)
    }
    stationData.totalDistance = abs(Double(distances[0])! - Double(distances[1])!)
    
    stationData.fare = getFare(distance: stationData.totalDistance)
    
    if(idArr[names.index(of: fromStation)!] > idArr[names.index(of: toStation)!])
    {
     stationData.stationDirectionId=1
    }
    else
    {
        stationData.stationDirectionId=2
    }
    
    
    stationData.stationCode=codes[names.index(of: fromStation)!]
  
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationData
}

