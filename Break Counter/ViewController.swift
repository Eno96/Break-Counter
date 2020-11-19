//
//  ViewController.swift
//  Break Counter
//  By Enes Dedic :)
//
//  Created by WWT Dev on 15/11/2019.
//  Copyright © 2019 WWT Dev. All rights reserved.
//

import UIKit
import SQLite

class ViewController: UIViewController {
    
    var database: Connection!
    
    let datesTable = Table("dates")
    let id = Expression<Int>("id")
    let date = Expression<String?>("date")
    let start_work_time = Expression<String?>("start_work_time")
    let start_time = Expression<String?>("start_time")
    let end_time = Expression<String?>("end_time")
    let save_counter = Expression<Int?>("save_counter")
    
    @IBOutlet var labelOutlet: UILabel!
    @IBOutlet weak var startButtonOutlet: UIButton!
    @IBOutlet weak var pauseButtonOutlet: UIButton!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    @IBOutlet weak var startWorkTimeOutlet: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var startBreakTime: UILabel!
    
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var remainingTime: UILabel!
    @IBOutlet weak var breakTime: UILabel!
    @IBOutlet weak var startTime: UILabel!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    var myTimer = Timer()
    var Seconds: Int = 0;
    var Minutes: Int = 0;
    var Hours: Int = 0;
    var Counter: Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButtonOutlet.isEnabled = false
        
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("dates").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }
        print("CREATED TABLE")
        let createTable = self.datesTable.create { (table) in
            table.column(self.id, primaryKey: true)
            table.column(self.date)
            table.column(self.start_work_time)
            table.column(self.start_time)
            table.column(self.end_time)
            table.column(self.save_counter)
        }

        do {
            try self.database.run(createTable)
            print("Created Table")
        } catch {
            print(error)
        }
        countBreakTime()
        showCurrentAndRemainingTime()
        
    }
    
    func runIT(){
        Counter += 1
        Seconds += 1
        if(Seconds == 60){
            Minutes += 1
            Seconds = 0
        }
        if(Minutes == 60){
            Hours += 1
            Minutes = 0
        }
        
        labelOutlet.text = String(format: "%02d:%02d:%02d", Hours, Minutes, Seconds)
    }
    
    func countBreakTime(){
        var countbreakseconds = 0;
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY"
        let currentDate = formatter.string(from: date)
        formatter.dateFormat = "YYYY-MM-dd"
        let currentDateFormated = formatter.string(from: date)
        
        do {
            let dates = try self.database.prepare(self.datesTable)
            
            for date in dates {
                if(date[self.date] == currentDate){
                    if(date[self.start_time] != nil && date[self.end_time] != nil){
                        let timestart = String("\(currentDateFormated) \(date[self.start_time]!)")
                        let timeend = String("\(currentDateFormated) \(date[self.end_time]!)")
                        
                        let dateDiff = findDateDiff(time1Str: timestart, time2Str: timeend)
                        countbreakseconds += dateDiff
                    }
                    if(date[self.start_work_time] != nil){
                        startTime.text = String(date[self.start_work_time]!)
                        startWorkTimeOutlet.isEnabled = false
                    }
                }
            }
        } catch {
            print(error)
        }
    
        let second = countbreakseconds%60;
        let minute = countbreakseconds/60;
        let trenutne_minute = minute%60;
        let hour =  minute/60;
        
        breakTime.text = String(format: "%02d:%02d:%02d", hour, trenutne_minute, second)
    }
    
    func findDateDiff(time1Str: String, time2Str: String) -> Int {
        let timeformatter = DateFormatter()
        timeformatter.dateFormat = "YYYY-MM-dd HH:mm:ss"

        guard let time1 = timeformatter.date(from: time1Str),
            let time2 = timeformatter.date(from: time2Str) else { return 0 }
        //You can directly use from here if you have two dates
  
        let interval = time2.timeIntervalSince(time1)
        return Int(interval)
    }
    
    func showCurrentAndRemainingTime(){
        progressView.transform = progressView.transform.scaledBy(x: 1, y: 3)
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
    
        currentTime.text = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
        
        
        if(hour < 17){
            let remaining_hour = 16 - hour
            let remaining_minutes = 60 - minutes
            let remaining_seconds = 60 - seconds
            
            remainingTime.text = String(format: "%02d:%02d:%02d", remaining_hour, remaining_minutes, remaining_seconds)
            
            
            let totalprogres_count = Float((465-(remaining_hour*60 + remaining_minutes + remaining_seconds/60)))
            
            progressView.progress = totalprogres_count/465;
        }else{
            progressView.progress = 1;
            remainingTime.text = String("Tomorrow is a new day :)")
        }
    }
    
    
    @IBAction func startButton(_ sender: UIButton) {
        setBreakStartTime()
        var bgTask : UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            UIApplication.shared.endBackgroundTask(bgTask)
        })
        myTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in self.runIT() })
        RunLoop.current.add(myTimer, forMode: RunLoop.Mode.default)
        startButtonOutlet.isHidden = false
    }
    
    func setBreakStartTime(){
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        startBreakTime.text = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
    }
    
    @IBAction func pauseButton(_ sender: UIButton) {
        myTimer.invalidate()
        startButtonOutlet.isEnabled = true
        saveButtonOutlet.isEnabled = true
    }

    
    @IBAction func startWorkTime(_ sender: UIButton) {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY"
        let currentDate = formatter.string(from: date)
        
        
        let startWorkTime = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
        let insertBreak = self.datesTable.insert(self.date <- currentDate, self.start_work_time <- startWorkTime)
        
        do {
            try self.database.run(insertBreak)
            startWorkTimeOutlet.isEnabled = false
            Counter = 0
            print("INSERTED WORK TIME")
            countBreakTime()
        } catch {
            print(error)
        }
    }
    
    
    
    @IBAction func saveBreakTime(_ sender: UIButton) {
        myTimer.invalidate()
        Seconds = 0
        Minutes = 0
        Hours = 0
        labelOutlet.text = String(format: "%02d:%02d:%02d", Seconds, Minutes, Hours)
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY"
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let currentDate = formatter.string(from: date)
        let currentTime = String(format: "%02d:%02d:%02d", hour, minutes, seconds)
        
        let insertBreak = self.datesTable.insert(self.date <- currentDate,self.date <- currentDate,self.start_time <- startBreakTime.text, self.end_time <- currentTime)
        
        do {
            try self.database.run(insertBreak)
            saveButtonOutlet.isEnabled = false
            Counter = 0
            print("INSERTED BREAK")
            startBreakTime.text = String(format: "%02d:%02d:%02d", Seconds, Minutes, Hours)
            countBreakTime()
        } catch {
            print(error)
        }
        
    }
    
    @IBAction func changeDate(_ sender: UIDatePicker) {
    }
    
    
}


/* LIST OF DATES
do {
    let users = try self.database.prepare(self.usersTable)
    for user in users {
        print("userId: \(user[self.id]), name: \(user[self.name]), email: \(user[self.email])")
    }
} catch {
    print(error)
}
*/

/*
print("CREATED TABLE")
let createTable = self.datesTable.create { (table) in
    table.column(self.id, primaryKey: true)
    table.column(self.date)
    table.column(self.save_counter)
}

do {
    try self.database.run(createTable)
    print("Created Table")
} catch {
    print(error)
}
*/
