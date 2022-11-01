//
//  ViewController.swift
//  AudioPOC
//
//  Created by Vitor Bryan on 17/03/22.
//

import UIKit
import AVFoundation
import CoreMotion

class ViewController: UIViewController {
    
    var recordButton: UIButton = {
        let button = UIButton()
        button.setTitle("Tap to record", for: .normal)
        button.tintColor = .blue
        button.backgroundColor = .red
        button.isEnabled = false
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(recordTap), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "play.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .blue
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(play), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var pauseButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .blue
        button.layer.cornerRadius = 4
        button.clipsToBounds = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(pause), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var overalDurationLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.text = "0:00"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var playbackSlider: UISlider = {
        var slider = UISlider()
        slider.minimumValue = 0
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(playbackSliderValueChanged), for: .valueChanged)
        return slider
    }()
    
    var soundURL = ""
    var device = UIDevice()
    let deviceListener = DeviceRaisedToEarListener()
    
    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVPlayer?
    var playerItem: AVPlayerItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check microphone Authorization
        setupPermission()
        setupAudio()
        
        // MARK: - Setup UI
        view.backgroundColor = .white
        view.addSubview(recordButton)
        view.addSubview(playButton)
        view.addSubview(pauseButton)
        view.addSubview(playbackSlider)
        view.addSubview(overalDurationLabel)
        
        setupConstraints()
    }
    
    // MARK: - Utilities
    
    func setupPermission() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            recordingSession?.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.recordButton.isEnabled = true
                    } else {
                        print("Error")
                    }
                }
            }
        } catch {
            print("Error")
        }
    }
    
    func setupRaiseListener() {
        deviceListener.stateChanged = { [weak self] isRaisedToEar in
            if isRaisedToEar {
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playAndRecord,
                                                 mode: .default)
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.none)
                } catch _ {}
            } else {
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setCategory(.playAndRecord,
                                                 mode: .default)
                    try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                } catch _ {
                
                }
            }
        }
        deviceListener.startListening()
    }
    
    func setupAudio() {
        let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in:
                    FileManager.SearchPathDomainMask.userDomainMask).first
                
        let audioFileName = UUID().uuidString + ".m4a"
        let audioFileURL = directoryURL?.appendingPathComponent(audioFileName)
        soundURL = audioFileName       // Sound URL to be stored
        
        guard let audioFileURL = audioFileURL else {
            return
        }
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord,
                                         mode: .default)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch _ {
        
        }
        
        // Define the recorder setting
        let recorderSetting = [AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                               AVSampleRateKey: 44100.0,
                               AVNumberOfChannelsKey: 2 ]
        
        audioRecorder = try? AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
        
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            recordButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5),
            
            playButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            playButton.leadingAnchor.constraint(equalTo: recordButton.leadingAnchor),
            playButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            
            pauseButton.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 20),
            pauseButton.trailingAnchor.constraint(equalTo: recordButton.trailingAnchor),
            pauseButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.2),
            
            playbackSlider.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            playbackSlider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            playbackSlider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            overalDurationLabel.topAnchor.constraint(equalTo: playbackSlider.bottomAnchor, constant: 5),
            overalDurationLabel.trailingAnchor.constraint(equalTo: playbackSlider.trailingAnchor)
        
        ])
    }
    
    func startRecording() {
       // Stop the audio player before recording
            if let player = audioPlayer {
                if player.timeControlStatus == .playing {
                    
                    // To Stop AVPlayer
                    player.seek(to: CMTime.zero)
                    player.pause()
                }
            }
            
            if let recorder = audioRecorder {
                if !recorder.isRecording {
                    let audioSession = AVAudioSession.sharedInstance()
                    
                    do {
                        try audioSession.setActive(true)
                    } catch _ {
                    }
                    
                    // Start recording
                    recorder.record()
                    recordButton.setTitle("Tap to Stop", for: .normal)
                    print("Recording")
                    
                } else {
                    // Pause recording
                    recorder.pause()
                    
                    print("paused")
                    
                }
            }
        
    }
    
    func stopRecording() {
        if let recorder = audioRecorder {
            if recorder.isRecording {
                audioRecorder?.stop()
                recordButton.setTitle("Tap to Record", for: .normal)
                
                let audioSession = AVAudioSession.sharedInstance()
                do {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                } catch _ {
                }
            }
        }
        
        // Stop the audio player if playing
        if let player = audioPlayer {
            if player.timeControlStatus == .playing {
                
                player.seek(to: CMTime.zero)
                player.pause()
            }
        }
    }
    
    // MARK: Actions
    
    @objc
    func recordTap() {
        if let recorder = audioRecorder {
            if recorder.isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }
    }
    
    @objc
    func play() {
        if let recorder = audioRecorder {
            if !recorder.isRecording && !(audioPlayer?.timeControlStatus == .playing) {
                
                // Check if device is raised to ear
                setupRaiseListener()
                
                playerItem = AVPlayerItem(url: recorder.url)
                audioPlayer = AVPlayer(playerItem: playerItem)
                
                NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
                
                guard let playerItem = playerItem,
                      let player = audioPlayer else {
                    return
                }
                let duration: CMTime = playerItem.asset.duration
                let seconds = CMTimeGetSeconds(duration)
                overalDurationLabel.text = stringFromTimeInterval(interval: seconds)
                
                playbackSlider.maximumValue = Float(seconds)
                playbackSlider.isContinuous = true
                
                player.play()
                print("playing")
                
                // to update
                player.addPeriodicTimeObserver(forInterval: CMTime(value: CMTimeValue(1), timescale: 2), queue: DispatchQueue.main) { (CMTime) -> Void in
                    if player.currentItem?.status == .readyToPlay {
                        let time: Float64 = CMTimeGetSeconds(player.currentTime())
                        self.playbackSlider.value = Float(time)
//                        self.labelCurrentTime.text = self.stringFromTimeInterval(interval: time)
                    }
                    let playbackLikelyToKeepUp = player.currentItem?.isPlaybackLikelyToKeepUp
                    if playbackLikelyToKeepUp == false {
                        print("IsBuffering")
                        self.playButton.isHidden = true
                    } else {
                        print("Buffering completed")
                        self.playButton.isHidden = false
                    }
                }
                
            }
        }
        
    }
    
    @objc
    func pause() {
        if let recorder = audioRecorder,
           let player = audioPlayer {
            if !recorder.isRecording && player.timeControlStatus == .playing {
                audioPlayer?.pause()
                print("playing")
            } else if player.timeControlStatus == .paused {
                audioPlayer?.play()
            }
        }
    }
    @objc
    func playerDidFinishPlaying(notifation: Notification) {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print ("setActive(false) ERROR : \(error)")
        }
        deviceListener.stopListening()
            
    }
    
    @objc
    func playbackSliderValueChanged(_ playbackSlider: UISlider) {
        let seconds: Int64 = Int64(playbackSlider.value)
        let targetTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        audioPlayer?.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
        if audioPlayer?.rate == 0 {
            audioPlayer?.play()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> String {
        let interval = Int(interval)
        let seconds = interval % 60
        let secondsString = seconds < 10 ? "0\(seconds)" : "\(seconds)"
        let minutes = (interval / 60) % 60
//        let hours = (interval / 3600)
        
        return "\(minutes):" + secondsString
    }
    
}
extension ViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            playButton.isEnabled = true
            pauseButton.isEnabled = true
        }
    }
    
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        if flag {
//            do {
//                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
//            } catch {
//                print ("setActive(false) ERROR : \(error)")
//            }
//            deviceListener.stopListening()
//
//        }
//    }
}
