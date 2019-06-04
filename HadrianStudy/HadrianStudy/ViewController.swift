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
    var configure = false
    var ranOnce = false
    
    func getPath(_ fileName: String) -> String {
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName).appendingPathExtension("csv").path
        return path
    }
    
    func createFile(_ path: String) {
        FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
        print("creating file")
    }
    
    func addToFile(_ stringToAdd: String, _ fileName: String){
        do {
            let fileHandle = try FileHandle(forUpdating: URL(string: fileName)!)
            fileHandle.seekToEndOfFile()
            let data = stringToAdd.data(using: .utf8)
            fileHandle.write(data!)
            fileHandle.closeFile()
        } catch {
            print("failed to write - error occurred")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        listenForVolumeButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fileNameField.delegate = self
        collection.isHidden = true
        volume.isHidden = true
        volTitle.isHidden = true
    }
    
    
    @IBAction func toggleCollection(_ sender: Any) {
        if (!collecting){
            collecting = true
            configure = true
            collection.setTitle("Stop collecting", for: UIControl.State.normal)
        } else {
            collecting = false
            collection.setTitle("Start collecting", for: UIControl.State.normal)
        }
    }
    
    
    func listenForVolumeButton(){
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            let vol = AVAudioSession.sharedInstance().outputVolume
                volume.text = vol.description
            AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options:
                NSKeyValueObservingOptions.new, context: nil)
            
        } catch {
            print("errored")
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "outputVolume"{
            let volUpdated = (change?[NSKeyValueChangeKey.newKey] as!
                NSNumber).floatValue * 100
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            formatter.timeZone = TimeZone(abbreviation: "EST")
            let estTimeZoneStr = formatter.string(from: date)
            let toAppend = estTimeZoneStr + "," + volUpdated.description + "\n"
            if(collecting){
            addToFile(toAppend, filePath)
            volume.text = volUpdated.description
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let fileName = textField.text!
        filePath = getPath(fileName)
        createFile(filePath)
        collection.isHidden = false
        volume.isHidden = false
        volTitle.isHidden = false
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            let vol = (AVAudioSession.sharedInstance().outputVolume) * 100
            volume.text = vol.description
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            formatter.timeZone = TimeZone(abbreviation: "EST")
            let estTimeZoneStr = formatter.string(from: date)
            let toAppend = estTimeZoneStr + "," + vol.description + "\n"
            addToFile(toAppend, filePath)
        } catch {
            print("errored")
        }
    }
}

