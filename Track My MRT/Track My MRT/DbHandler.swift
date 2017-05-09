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

func dropTables() -> Bool
{
    var isQueryExecuted:Bool = false
    if(openDatabase())
    {
    var sql="DROP TABLE MRTSTATION"
    
    isQueryExecuted = executeSql(sql: sql, tableName: MRTSTATION_TABLE)
    
    sql="DROP TABLE DISTANCE"
    
    isQueryExecuted = executeSql(sql: sql, tableName: DISTANCE_TABLE)
    
    sql="DROP TABLE STATIONLANE"
    
    isQueryExecuted = executeSql(sql: sql, tableName: STATIONLANE_TABLE)
    
    sql="DROP TABLE CHECKPOINTSTATION"
    
    isQueryExecuted = executeSql(sql: sql, tableName: CHECKPOINT_TABLE)
    }
    
    return isQueryExecuted
    
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



func getConnectingLane(lanes: [String]) -> [String]
{

    var intermediateStations:[String] = [String] ()
    
    prepareCheckpointStatement()
    
    for lane in lanes
    {
     let laneStr = lane as NSString?
    
    
    
    sqlite3_bind_text(selectStatement, 1, laneStr!.utf8String, -1, SQLITE_TRANSIENT);
   
    while(sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        
        let name_buf = sqlite3_column_text(selectStatement, 0)
        let intermediateStation =  String(cString: name_buf!)
        intermediateStations.append(intermediateStation)
        
        
    }
    }
  
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);

    
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

func getStation(stationName:String) -> StationModel
{
    prepareMrtStationStatement()

    let stationModel:StationModel = StationModel()
    
    let station = stationName as NSString?
    
    sqlite3_bind_text(selectStatement, 1, station!.utf8String, -1, SQLITE_TRANSIENT);
    
    if (sqlite3_step(selectStatement) == SQLITE_ROW)
    {
        let code_buf = sqlite3_column_text(selectStatement, 0)
        stationModel.stationCode = String(cString: code_buf!)
        let dist_buf = sqlite3_column_text(selectStatement, 1)
        let distanceStr = String(cString: dist_buf!)
        stationModel.stationDistance = distanceStr.components(separatedBy: ",")
        
        let name_buf = sqlite3_column_text(selectStatement, 2)
        stationModel.stationName = String(cString: name_buf!)
        let id_buf = sqlite3_column_text(selectStatement, 8)
        
        stationModel.stationPrimaryId = Int(String(cString: id_buf!))
        
        
        let color_buf = sqlite3_column_text(selectStatement, 3)
        let colors = String(cString: color_buf!)
        
        
        stationModel.colors = colors.components(separatedBy: ",")
        
        let station_line_ids = sqlite3_column_text(selectStatement, 4)
        let stationLinesStr = String(cString: station_line_ids!)
        
        stationModel.stationLineCodes = stationLinesStr.components(separatedBy: ",")
        
        
        
        
        
        let stationCodes = sqlite3_column_text(selectStatement, 5)
        let stationCodesStr = String(cString: stationCodes!)
        stationModel.stationLaneCodes = stationCodesStr.components(separatedBy: ",")
       
        
    
          }
    
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationModel
}



func getConnectingStations(fromStationModel:StationModel, toStationModel:StationModel) -> [StationModel]
{
    
    
    
    prepareCheckpointStatement()
    
    var checkPointStations:[StationModel] = [StationModel] ()
    
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
            
          
            
            let laneid_buf = sqlite3_column_text(selectStatement, 2)
            let laneId = String(cString: laneid_buf!)
            let lanearr:[String] = laneId.components(separatedBy: ",")
            checkPointStation.stationLaneCodes = lanearr
            
            let distance_buf = sqlite3_column_text(selectStatement, 3)
            let distance = String(cString: distance_buf!)
            let distArr:[String] = distance.components(separatedBy: ",")
            checkPointStation.stationDistance = distArr
            
            checkPointStations.append(checkPointStation)
            
        }
    
 
    
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
                
                stationDatas.append(stationData)
                
                stationData.intermediateLines.append(fromlane)
                stationData.intermediateLines.append(toLane)
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
                        
                
                let fromsubCheckpointNo:Int! = Int(fromSubLaneId.replacingOccurrences(of: subLane, with: ""))
                let toCheckpointNo:Int! = Int(toLaneId.replacingOccurrences(of: toLane, with: ""))
                            
                let toSubCheckpointNo:Int! = Int(toMidLaneId.replacingOccurrences(of: subLane, with: ""))
                        
            
                
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
                            
                stationData.totalDistance = stationData.totalDistance + abs(toStnDistance - checkpointToDistance)
                            
                stationData.intermediateLines.append(fromlane)
                stationData.intermediateLines.append(subLane)
                stationData.intermediateLines.append(toLane)
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
    
    var distances = [String]()

    

    let fromStationModel:StationModel = getStation(stationName: fromStation)
    let toStationModel:StationModel = getStation(stationName: toStation)
    stationData.stationCode = fromStationModel.stationCode
    
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
    
        //isIntermediateLineFound = true
        
        stationData.intermediateLines.append(lane)
        interLinkStations.append(fromStation)
        
        
        
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
        
        
        let
        stationDataTwo:[StationData] = findTwoIntersectinLanes(fromStationModel: fromStationModel, toStationModel: toStationModel,checkpointStations: checkpoints)
        
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
        stationData.intermediateLines = finalStationData.intermediateLines

    }
    

    if(stationData.stationDirectionId == nil)
    {
        stationData.stationDirectionId = 1
    }

    stationData.fare = getFare(distance: stationData.totalDistance)
  
    
    sqlite3_reset(selectStatement);
    sqlite3_clear_bindings(selectStatement);
    
    return stationData
    
    
}




