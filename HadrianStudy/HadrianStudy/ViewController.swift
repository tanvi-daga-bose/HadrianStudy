//
//  ViewController.swift
//  HadrianStudy
//
//  Created by Tanvi Daga on 5/30/19.
//  Copyright © 2019 Tanvi Daga. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController {

    @IBOutlet weak var volume: UILabel!
    @IBOutlet weak var fileNameField: UITextField!
    @IBOutlet weak var collection: UIButton!
    
    @IBOutlet weak var volTitle: UILabel!
    
    var filePath = ""
    var collecting = false
    let audioSession = AVAudioSession.sharedInstance()
    var globalPrevVal = 0.0
    
    // file creation
    func getPath(_ fileName: String) -> String {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName).appendingPathExtension("csv").path
        return path
    }
    
    func createFile(_ path: String) {
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
    }
    
    // adding to file
    func addToFile(_ stringToAdd: String, _ fileName: String){
        do {
            let fileHandle = try FileHandle(forUpdating: URL(string: fileName)!)
            fileHandle.seekToEndOfFile()
            let data = stringToAdd.data(using: .utf8)
            fileHandle.write(data!)
            fileHandle.closeFile()
            print(stringToAdd)
        } catch {
            print("failed to write - error occurred")
        }
    }
    
    // getting the current time
    func getCurTime() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(abbreviation: "EST")
        let estTimeZoneStr = formatter.string(from: date)
        return estTimeZoneStr
    }
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        fileNameField.delegate = self
        collection.isHidden = true
        volTitle.isHidden = true
        volume.isHidden = true
        
        // ensures reading to same file when application is reactivated
        NotificationCenter.default.addObserver(self, selector: #selector(listenForVolumeButton), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @IBAction func toggleCollection(_ sender: Any) {
        if (!collecting){
            collecting = true
            getVolumeInitially()
            collection.setTitle("Stop collecting", for: UIControl.State.normal)
        } else {
            collecting = false
            collection.setTitle("Start collecting", for: UIControl.State.normal)
        }
    }
    
    
    @objc func listenForVolumeButton(){
        do {
            try audioSession.setCategory(AVAudioSession.Category.ambient)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("errored")
        }
        audioSession.addObserver(self, forKeyPath: "outputVolume", options:
            NSKeyValueObservingOptions.new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume"{
            let volUpdated = (change?[NSKeyValueChangeKey.newKey] as!
                NSNumber).floatValue
            if(Double(volUpdated) != globalPrevVal){
                globalPrevVal = Double(volUpdated)
                let estTimeZoneStr = getCurTime()
                let toAppend = estTimeZoneStr + "," + volUpdated.description + "\n"
                if(collecting){
                    addToFile(toAppend, filePath)
                    volume.text = volUpdated.description
                }
            }
        }
        
    }
    
    override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        audioSession.removeObserver(self, forKeyPath: "outputVolume")
    }
    
    func getVolumeInitially(){
        do {
            try audioSession.setCategory(AVAudioSession.Category.ambient)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let vol = audioSession.outputVolume
            volume.text = vol.description
            
            let estTimeZoneStr = getCurTime()
            let toAppend = estTimeZoneStr + "," + vol.description + "\n"
            addToFile(toAppend, filePath)
        } catch {
            print("errored")
        }
    }
}

extension ViewController: UITextFieldDelegate {
   
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        collection.isHidden = false
        volume.isHidden = false
        volTitle.isHidden = false
        let fileName = textField.text!
        
        filePath = getPath(fileName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath){
            createFile(filePath)
        }
    }
}
