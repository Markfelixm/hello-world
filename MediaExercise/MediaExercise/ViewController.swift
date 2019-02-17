//
//  ViewController.swift
//  MediaExercise
//
//  Created by Mark Felix Müller on 16/12/2018.
//  Copyright © 2018 Mark Felix Müller. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    var authenticated: Bool = false
    var audioFileURL: URL!
    
    
    @IBOutlet weak var transcriptView: UITextView!
    
    @IBAction func startRecording(_ sender: Any) {
        // not recording yet
        if !audioRecorder.isRecording {
            // create audio session
            let audioSession = AVAudioSession.sharedInstance()
            // try to start recording
            do {
                try audioSession.setActive(true)
                audioRecorder.record()
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        if audioRecorder.isRecording {
            audioRecorder.stop()
            
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setActive(false)
            } catch {
                print(error)
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        var message: UIAlertController
        if flag {
            message = UIAlertController(title: "Recording", message: "Audio recording finished succesfully", preferredStyle: .alert)
        } else {
            message = UIAlertController(title: "Recording", message: "Audio recording save error", preferredStyle: .alert)
        }
        message.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(message, animated: true, completion: nil)
    }
    
    @IBAction func play(_ sender: Any) {
        // if application is not recording
        if !audioRecorder.isRecording {
            // get audio player
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else {
                print("AVAudioPlayer initialization failed!")
                return
            }
            // assing player to class variable and start playing
            audioPlayer = player
            audioPlayer?.delegate = self
            audioPlayer?.play()
            
            if authenticated == true {
                let recognizer = SFSpeechRecognizer()
                let request = SFSpeechURLRecognitionRequest(url: audioFileURL)
                recognizer?.recognitionTask(with: request) { result, error in guard error == nil else { print("Error: \(error)"); return }
                    guard let result = result else { print("No result"); return }
                    self.transcriptView.text = result.bestTranscription.formattedString
                }
            }
            
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let message = UIAlertController(title: "AudioPlayer", message: "Finished playing audio.", preferredStyle: .alert)
        message.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(message, animated: true, completion: nil)
    }
    
    @IBAction func stop(_ sender: Any) {
        if (audioPlayer != nil) {
            audioPlayer?.stop()
            let message = UIAlertController(title: "AudioPlayer", message: "Audio stopped playing", preferredStyle: .alert)
            message.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(message, animated: true, completion: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // save audio to document directory, check it first (is it available)
        // -> search document directory with FileManager
        guard let directory = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            let message = UIAlertController(title: "Error", message: "Can't use document directory for recording audio", preferredStyle: .alert)
            message.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(message, animated: true, completion: nil)
            return
        }
        // set audio file
        let audioFile = directory.appendingPathComponent("AudioFile.m4a")
        // set audio session
        let audioSession = AVAudioSession.sharedInstance()
        // define settings
        do {
            // play and record
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            let recordSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
            audioRecorder.delegate = self
            // create audio file and ready for recording
            audioRecorder.prepareToRecord()
        } catch {
            print(error)
        }
    
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            if authStatus == SFSpeechRecognizerAuthorizationStatus.authorized {
                self.authenticated = true
                self.audioFileURL = audioFile
            }
        }
    
    
    }
    
    
}
