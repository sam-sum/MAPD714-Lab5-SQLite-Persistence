//
//  ViewController.swift
//  SQLite Persistence
//
//  Created by Samuel Sum on 2022-11-15.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var lineFields:[UITextField]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var database:OpaquePointer? = nil
        var result = sqlite3_open(dataFilePath(), &database)
        if result != SQLITE_OK {
            sqlite3_close(database)
            print("Failed to open database")
            return
        }
        let createSQL = "CREATE TABLE IF NOT EXISTS FIELDS " +
            "(ROW INTEGER PRIMARY KEY, FIELD_DATA TEXT);"
        var errMsg:UnsafeMutablePointer<Int8>? = nil
        result = sqlite3_exec(database, createSQL, nil, nil, &errMsg)
        if (result != SQLITE_OK) {
            sqlite3_close(database)
            print("Failed to create table")
            return
        }
        let query = "SELECT ROW, FIELD_DATA FROM FIELDS ORDER BY ROW"
        var statement:OpaquePointer? = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let row = Int(sqlite3_column_int(statement, 0))
                let rowData = sqlite3_column_text(statement, 1)
                let fieldValue = String.init(cString: rowData!)
                lineFields[row].text = fieldValue
            }
            sqlite3_finalize(statement)
        }
        sqlite3_close(database)
        
        let app = UIApplication.shared
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: app)
    }

    func dataFilePath() -> String {
        let urls = FileManager.default.urls(for:
            .documentDirectory, in: .userDomainMask)
        var url:String?
        url = urls.first?.appendingPathComponent("data.sqlite").path
        return url!
    }
    
    @objc func applicationWillResignActive(notification:NSNotification) {
        print("Running func applicationWillResignActive")
        
        var database:OpaquePointer? = nil
        let result = sqlite3_open(dataFilePath(), &database)
        if result != SQLITE_OK {
            sqlite3_close(database)
            print("Failed to open database")
            return
        }
        for i in 0..<lineFields.count  {
            let field = lineFields[i]
            let update = "INSERT OR REPLACE INTO FIELDS (ROW, FIELD_DATA) " +
            "VALUES (?, ?);"
            var statement:OpaquePointer? = nil
            if sqlite3_prepare_v2(database, update, -1, &statement, nil) == SQLITE_OK {
                let text: NSString = field.text! as NSString
                print("row \(i), \(text)")
                sqlite3_bind_int(statement, 1, Int32(i))
                sqlite3_bind_text(statement, 2, text.utf8String, -1, nil)
            }
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error updating table")
                sqlite3_close(database)
                return
            }
            
            sqlite3_finalize(statement)
        }
        sqlite3_close(database)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
