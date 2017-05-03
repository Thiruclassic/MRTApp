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
    createStationTable()
    createDistanceTable()
    
    //dropTables()
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
    if(openDatabase())
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

func dropTables()
{
    var sql="DROP TABLE MRTSTATION"
    
    executeSql(sql: sql, tableName: MRTSTATION_TABLE)
    
    sql="DROP TABLE DISTANCE"
    
    executeSql(sql: sql, tableName: DISTANCE_TABLE)
    
}


/*func prepareDistanceStatment()
{
    var sqlString : String
    
    sqlString="INSERT INTO DISTANCE (MIN_DISTANCE, MAX_DISTANCE, ADULT_FARE) VALUES (?, ?, ?)"
    
    var cSql = sqlString.cString(using: String.Encoding.utf8)
    
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    sqlString = "SELECT ADULT_FARE FROM DISTANCE WHERE id=?"
    cSql = sqlString.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql!, -1, &selectStatement,nil)
    
   }

func prepareMrtStationStatement()
{
    var sqlString : String
    sqlString="INSERT INTO MRTSTATION (NAME, CODE, DISTANCE) VALUES (?, ?, ?)"
    
    var cSql = sqlString.cString(using: String.Encoding.utf8)
    
    sqlite3_prepare_v2(mrtDb, cSql, -1, &insertStatement, nil)
    
    sqlString = "SELECT CODE,DISTANCE,NAME,ID FROM MRTSTATION WHERE NAME in (?,?)"
    cSql = sqlString.cString(using: String.Encoding.utf8)
    sqlite3_prepare_v2(mrtDb, cSql!, -1, &selectStatement,nil)
    
}*/


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



func createDistanceFareData()
{
    
    prepareDistanceStatment()
    
    let distances:[NSDictionary] = readJSONData(fileName: DISTANCE_FARE_JSON_FILE, fileType: JSON_TYPE, rootElement: DISTANCE_ROOT_ELEMENT)
    
    var count:Int = 0
    for distance in distances
    {
        let minimumDistance=distance[DISTANCE_MINIMUM] as? NSString
        let maximumDistance=distance[DISTANCE_MAXIMUM] as? NSString
        let adultFare=distance[ADULT_FARE] as? NSString
    
        sqlite3_bind_text(insertStatement, 1, minimumDistance!.utf8String, -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 2, maximumDistance!.utf8String , -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(insertStatement, 3, adultFare!.utf8String , -1, SQLITE_TRANSIENT);
       
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
    
    print("Distance Data inserted successfully")


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

