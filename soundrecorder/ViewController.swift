//
//  ViewController.swift
//  soundrecorder
//
//  Created by Haruu Kim on 26/02/2019.
//  Copyright © 2019 Haruu Kim. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var DB_array = [Double]()
    var class_array = [Int]()
    var classNumHash = [Int : Int]()
    var resultHash = [String : Double]()
    
    var isRecording: Bool = false
    var isRecorded: Bool = false
    var recorder: AVAudioRecorder? = nil
    
    @IBOutlet weak var class1_ratio_txt: UILabel!
    @IBOutlet weak var class2_ratio_txt: UILabel!
    @IBOutlet weak var class3_ratio_txt: UILabel!
    @IBOutlet weak var class4_ratio_txt: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func onClickRecordBtn(_ sender: Any) {
        isRecording = true
        
        if recorder == nil {
            // HACK media recorder (not equal audio format)
            /**
             final MediaRecorder recorder = new MediaRecorder();
             recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
             recorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
             recorder.setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT);
             recorder.setOutputFile("/dev/null");
             */
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let url = dir.appendingPathComponent("recordFile.m4a")
            let setting = [
                AVFormatIDKey: NSNumber(value: Int32(kAudioFormatAppleLossless)),
                AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue,
                AVEncoderBitRateKey: 192000,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVSampleRateKey: 44100.0] as [String : Any]
            do {
                try recorder = AVAudioRecorder(url: url, settings: setting)
            } catch let e as NSError {
                print("AVAudioRecorder : \(e)")
                return
            }
            
            if let recorder = recorder {
                recorder.isMeteringEnabled = true
                recorder.prepareToRecord()
                
                let session = AVAudioSession.sharedInstance()
                do {
                    try session.setCategory(AVAudioSessionCategoryRecord)
                    //                    try session.setCategory(AVAudioSession.Category.record, mode: .default, options: [])
                    try session.setActive(true)
                } catch let e as NSError {
                    print("Session : \(e)")
                    return
                }
            }
        }
        
        if let recorder = recorder {
            recorder.record()
            
            if !isRecorded {
                // HACK timer (need test)
                /**
                 Timer timer = new Timer();
                 timer.schedule(new RecorderTask(recorder), 0, 1000);
                 */
                _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ViewController.recorderTask), userInfo: nil, repeats: true)
            }
        }
    }
    
    @IBAction func onClickStopBtn(_ sender: Any) {
        if let recorder = recorder {
            isRecording = false
            isRecorded = true
            
            var stringBuilder = ""
            for db in DB_array {
                stringBuilder += "\(String(db)),"
            }
            
            UserDefaults.standard.set(stringBuilder, forKey: "sample")
            UserDefaults.standard.synchronize()
            
            recorder.stop()
        }
    }
    
    @IBAction func onClickLoadBtn(_ sender: Any) {
        DB_array = [Double]()
        class_array = [Int]()
        
        if let db_string = UserDefaults.standard.string(forKey: "sample") {
            let db_array_string = db_string.split(separator: ",")
            for db_str in db_array_string {
                if let db = Double(db_str) {
                    DB_array.append(db)
                }
            }
        }
        
        convertDBArrayToClassArray()
        classNumHash = getClassNumHash()
        resultHash = getResultHash()
        setTextView()
    }
    
    private func convertDBArrayToClassArray() {
        for db in DB_array {
            let classValue = getClass(db)
            class_array.append(classValue)
        }
    }
    
    private func getClass(_ db: Double) -> Int {
        if db < 65 {
            return 1
        } else if db < 75 {
            return 2
        } else if db < 85 {
            return 3
        } else {
            return 4
        }
    }
    
    private func getClassNumHash() -> [Int : Int] {
        var num_CL1 = 0
        var num_CL2 = 0
        var num_CL3 = 0
        var num_CL4 = 0
        
        for CL in class_array {
            switch CL {
            case 1:
                num_CL1 += 1
            case 2:
                num_CL2 += 1
            case 3:
                num_CL3 += 1
            default:
                num_CL4 += 1
            }
        }
        classNumHash[1] = num_CL1
        classNumHash[2] = num_CL2
        classNumHash[3] = num_CL3
        classNumHash[4] = num_CL4
        
        return classNumHash
    }
    
    private func getResultHash() -> [String : Double] {
        var key_list = [String]()
        key_list.append("class1_ratio")
        key_list.append("class2_ratio")
        key_list.append("class3_ratio")
        key_list.append("class4_ratio")
        let total_size = class_array.count
        for i in 0 ..< key_list.count + 1 {
            if let classNum = classNumHash[i] {
                let ratio: Double = Double(classNum) / Double(total_size) * 100
                resultHash[key_list[i-1]] = ratio
            }
        }
        return resultHash
    }
    
    private func setTextView() {
        
        class1_ratio_txt.text = "숙면 비율: \(resultHash["class1_ratio"]!)%"
        class2_ratio_txt.text = "저강도 코골이 비율: \(resultHash["class2_ratio"]!)%"
        class3_ratio_txt.text = "고강도 코골이 비율: \(resultHash["class3_ratio"]!)%"
        class4_ratio_txt.text = "심한 코골이 비율: \(resultHash["class4_ratio"]!)%"
    }
    
    @objc func recorderTask() {
        if isRecording {
            if let recorder = recorder {
                recorder.updateMeters()
                let power = recorder.peakPower(forChannel: 0) // -160 ~ 0 dB
                if let dB = Double(String(format: "%.2f", power + 90)) {
                    DB_array.append(dB)
                    print("power=\(power) dB=\(dB)")
                }
            }
        }
    }
}
