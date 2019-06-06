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
    
    @IBOutlet weak var playbackStateTitle: UILabel!
    @IBOutlet weak var volTitle: UILabel!
    @IBOutlet weak var playbackState: UILabel!
    
    var filePath = ""
    var collecting = false
    let audioSession = AVAudioSession.sharedInstance()
    var globalPrevVal = 0.0
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var curState = "playing"

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
        playbackState.isHidden = true
        playbackStateTitle.isHidden = true
        
        musicPlayer.prepareToPlay()
        musicPlayer.play()
      /*  musicPlayer.prepareToPlay()
        musicPlayer.play()
        if (musicPlayer.playbackState == .playing){
            print("playing")
        }*/
        
        // ensures reading to same file when application is reactivated
        NotificationCenter.default.addObserver(self, selector: #selector(listenForVolumeButton), name: UIApplication.didBecomeActiveNotification, object: nil)
  //      NotificationCenter.default.addObserver(self, selector: #selector(listenForPlayPause), name: NSNotification.Name.MPMusicPlayerControllerVolumeDidChange, object: nil)
        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(listenForPlayPause), userInfo: nil, repeats: true)
    }
    
 /*  override func viewDidAppear(_ animated: Bool) {
      //  NotificationCenter.default.addObserver(self, selector: #selector(listenForPlayPause), name: NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: self.musicPlayer)
    print("in viewDidAppear")
    musicPlayer.addObserver(self, forKeyPath: "playbackState", options: NSKeyValueObservingOptions.new, context: nil)
    }*/
    
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
    
    func playbackStateAsString() -> String {
        if (musicPlayer.playbackState == .paused) {
            return "paused"
        } else if (musicPlayer.playbackState == .playing){
            return "playing"
        }
        return ""
    }
    
    @objc func listenForPlayPause(){
        var playOrPause = ""
        if (musicPlayer.playbackState == .paused) {
            playOrPause = "paused"
        } else if (musicPlayer.playbackState == .playing){
            playOrPause = "playing"
        }
        if(collecting){
        playbackState.text = playOrPause
        if(curState != playOrPause){
            curState = playOrPause
            let estTimeZoneStr = getCurTime()
            let volWhenPressed = audioSession.outputVolume.description
            let toAppend = estTimeZoneStr + "," + volWhenPressed + "," + playOrPause + "\n"
            
                addToFile(toAppend, filePath)
            }
        }
       /* var playOrPause = playbackStateAsString()
        if(playOrPause != curState){
            playbackState.text = playOrPause
            curState = playOrPause
        }*/
         // musicPlayer.addObserver(self, forKeyPath: "playbackState", options: NSKeyValueObservingOptions.new, context: nil)
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
                let toAppend = estTimeZoneStr + "," + volUpdated.description + "," + "volume\n"
                if(collecting){
                    addToFile(toAppend, filePath)
                    volume.text = volUpdated.description
                    
                }
            }
        }
        /*else if(keyPath == "playbackState") {
            print("keyPath is playbackState" )
            switch (musicPlayer.playbackState){
            case .paused:
                print("paused")
                break
            case .playing:
                print("playing")
                break
            default:
                break
            }
        }*/
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
            let toAppend = estTimeZoneStr + "," + vol.description + "," + "initial\n"
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
        playbackState.isHidden = false
        playbackStateTitle.isHidden = false
        
        let fileName = textField.text!
        
        filePath = getPath(fileName)
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: filePath){
            createFile(filePath)
        }
    }
}
