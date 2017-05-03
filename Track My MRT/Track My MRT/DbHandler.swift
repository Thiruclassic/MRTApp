//
//  DbHandler.swift
//  Track My MRT
//
//  Created by Thirumal Dhanasekaran on 2/5/17.
//  Copyright © 2017 Team-FT03. All rights reserved.
//

import Foundation

var stationDb:OpaquePointer?=nil
var distanceDb:OpaquePointer?=nil




func createStationTable()
{
    
    let dbDir = DB_PATH + "?trackmymrt.sqllite"
    
    if(sqlite3_open(dbDir, &stationDb) == SQLITE_OK)
    {
        //let sql="CREATE TABLE IF NOT EXISTS CONTACTS (ID INTEGER PRIMARY KEY AUTOINCREMENT, NAME TEXT,ADDRESS TEXT, PHONE TEXT)"
        
        let sql="CREATE TABLE IF NOT EXISTS DISTANCE (ID INTEGER PRIMARY KEY AUTOINCREMENT, MIN_DISTANCE REAL,MAX_DISTANCE REAL, ADULT_FARE REAL)"
        
        if(sqlite3_exec(stationDb, sql, nil,nil,nil) != SQLITE_OK)
        {
            print("Failed to create table")
            print(sqlite3_errmsg(stationDb))
        }
        else
        {
            print("table created successfully")
        }
        
    }
    else
    {
        print("Failed to open database")
        print(sqlite3_errmsg(stationDb));
    }
    
    
}
