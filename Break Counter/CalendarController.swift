//
//  CalendarController.swift
//  Break Counter
//
//  Created by WWT Dev on 21/11/2019.
//  Copyright © 2019 WWT Dev. All rights reserved.
//

import UIKit
import SQLite

class CalendarController: UIViewController {

    @IBOutlet weak var breakTime: UILabel!
    @IBOutlet weak var startWorkTime: UILabel!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var currentLabelYPosition : CGFloat = 390 // set to first y position
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height

    
    var database: Connection!
    
    let datesTable = Table("dates")
    let id = Expression<Int>("id")
    let date = Expression<String?>("date")
    let start_work_time = Expression<String?>("start_work_time")
    let start_time = Expression<String?>("start_time")
    let end_time = Expression<String?>("end_time")
    let save_counter = Expression<Int?>("save_counter")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do {
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = documentDirectory.appendingPathComponent("dates").appendingPathExtension("sqlite3")
            let database = try Connection(fileUrl.path)
            self.database = database
        } catch {
            print(error)
        }

    }
    
 
    @IBAction func dateChanged(_ sender: Any) {
        var countbreakseconds = 0;
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.YYYY"
        let choosedDate = formatter.string(from: datePicker.date)
        formatter.dateFormat = "YYYY-MM-dd"
        let choosedDateFormated = formatter.string(from: datePicker.date)
        startWorkTime.text = String(format: "%02d:%02d:%02d", 0, 0, 0)
        do {
            let dates = try self.database.prepare(self.datesTable)
            
            for date in dates {
                if(date[self.date] == choosedDate){
                    if(date[self.start_time] != nil && date[self.end_time] != nil){
                        let timestart = String("\(choosedDateFormated) \(date[self.start_time]!)")
                        let timeend = String("\(choosedDateFormated) \(date[self.end_time]!)")
                        showLoopedBreaks(time1Str: timestart, time2Str: timeend)
                        let dateDiff = findDateDiff(time1Str: timestart, time2Str: timeend)
                        countbreakseconds += dateDiff
                    }
                    print(date[self.start_work_time] ?? 120)
                    if(date[self.start_work_time] != nil){
                        startWorkTime.text = String(date[self.start_work_time]!)
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
    
    
        func showLoopedBreaks(time1Str: String, time2Str: String){

   
        }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
