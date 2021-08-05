//
//  ViewController.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import UIKit
import ReactorKit
import RxViewController
import Kingfisher
import AVFoundation
//import RxGesture
import RxCocoa

class MusicPlayViewController: UIViewController, View{
    lazy var v = MusicPlayView(frame: view.bounds)
    var disposeBag: DisposeBag = DisposeBag()
    private var musicInfo: MusicInfo!
    private var player = AVPlayer()
    private var progressTimer : Timer!
    private var playState: PlayState!
    private var timer = Observable<Int>.interval(.milliseconds(100), scheduler: MainScheduler.instance)
    
    private var giveLyrics = PublishSubject<String>()
    private var lyricsSeq: [String]!
    private var lyricsList: Dictionary<String, String>!
    
    func bind(reactor: MusicPlayReactor) {
        print("bind!")
        
        self.rx.viewDidLoad
            .map{_ in Reactor.Action.initViewData}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.forwordBtn.rx.tap.bind { [weak self] _ in
            print("forword Button")
        }
        
        v.rewindbtn.rx.tap.bind { [weak self] in
            print("rewind Button")
        }
        
        v.playBtn.rx.tap
            .map{Reactor.Action.playPauseButton}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.seekBar.rx.value
            .changed
            .map{Reactor.Action.seekBarValChanged(val: $0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.seekBar.rx.controlEvent(.touchUpInside)
            .map{Reactor.Action.seekDragEnd}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        giveLyrics.filter{$0 != ""}
            .observeOn(MainScheduler.instance)
            .map{Reactor.Action.takeLyrics(lyrics: $0)}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map{$0.playState}
            .filter{$0 != .none}
            .distinctUntilChanged()
            .bind { state in
                print("play button tap \(state)")
                self.playState = state
                if state == .play{
                    self.player.play()
                }else{
                    self.player.pause()
                    self.v.leftTimer.text = self.convertNSTimeInterval12String(self.player.currentTime().seconds)

                }
            }.disposed(by: disposeBag)
        
        
        reactor.state
            .map{$0.viewState}
            .distinctUntilChanged()
            .filter{$0 != .willLoad}
            .bind { [weak self] state in
                guard let self = self else { return }
                switch state{
                case .initView:
                    self.view = self.v
                    self.v.seekBar.value = 0
                    self.v.lyricsLabel.text = ""
                    self.v.subLyricsLabel.text = ""
                    break
                case .willLoad:
                    break
                case .none:
                    break
                }
            }.disposed(by: disposeBag)
        
        reactor.state
            .filter{$0.musicInfo != nil}
            .take(1)
            .map{$0.musicInfo}
            .bind {[weak self] musicInfo in
                self?.setMusicInfo(musicInfo: musicInfo!)
            }.disposed(by: disposeBag)
        
        reactor.state.map{$0.seekVal}
            .filter{$0 != -1}
            .distinctUntilChanged()
            .bind { [weak self] val in
                guard let self = self else { return }
                self.player.automaticallyWaitsToMinimizeStalling = false
                self.v.leftTimer.text = self.convertSecToMin(time: Int(val * Float(self.musicInfo.duration)))
                self.player.seek(to: CMTimeMakeWithSeconds(Float64(val * Float(self.musicInfo.duration)), preferredTimescale: Int32(NSEC_PER_SEC)))
                self.player.pause()
            }.disposed(by: disposeBag)
        
        reactor.state.map{$0.lyricsSeq}
            .distinctUntilChanged()
            .bind { [weak self] lyricsSeq in
                self?.lyricsSeq = lyricsSeq
            }.disposed(by: disposeBag)
        
        reactor.state.map{$0.lyricsList}
            .distinctUntilChanged()
            .bind { [weak self] lyricsList in
                self?.lyricsList = lyricsList
            }.disposed(by: disposeBag)
        
    }
    
    
    private func setMusicInfo(musicInfo: MusicInfo){
        self.musicInfo = musicInfo
        v.musicTitle.text = musicInfo.title
        v.artistName.text = musicInfo.singer
        v.albumIV.kf.setImage(with: URL(string: musicInfo.image))
        let playerItem = AVPlayerItem(url: URL(string: musicInfo.file)!)
        player = AVPlayer(playerItem: playerItem)
        
        v.rightTimer.text = convertNSTimeInterval12String(TimeInterval(musicInfo.duration))
        
        timer.bind { [weak self] sec in
            guard let self = self else { return }
            if self.playState == .play{
                var nowTimeText = self.convertNSTimeInterval12String(self.player.currentTime().seconds)
                
                self.v.seekBar.value = Float(self.player.currentTime().seconds/Double(musicInfo.duration))
                self.v.leftTimer.text = nowTimeText
                var playTime = Int(self.player.currentTime().seconds * 10)
                playTime %= 10
                //if let lyricsTime = self.player.currentTime().seconds * 10
                //var playTimeString = String(format: "%.1f",(self.player.currentTime().seconds))
                var lyricsTime = nowTimeText + ":\(playTime)"
                guard let lyrics = self.lyricsList[lyricsTime] else {
                    return
                }
                
                if self.lyricsSeq.firstIndex(of: lyricsTime)! < self.lyricsSeq.count - 1{
                guard let nextLyrics = self.lyricsList[self.lyricsSeq[self.lyricsSeq.firstIndex(of: lyricsTime)! + 1]] else{
                    return
                }
                    self.v.lyricsLabel.text = lyrics
                    self.v.subLyricsLabel.text = nextLyrics
                }else{
                    self.v.lyricsLabel.text = lyrics
                    self.v.subLyricsLabel.text = ""
                }
                
                
            }
        }.disposed(by: disposeBag)
        
        giveLyrics.onNext(musicInfo.lyrics)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
    }
    
    func convertNSTimeInterval12String(_ time:TimeInterval) -> String {
        let min = Int(time/60)
        let sec = Int(time.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        return strTime
    }
    
    func convertSecToMin(time: Int) -> String{
        var min = time / 60
        var sec = time % 60
        
        if sec < 10{
            return "0\(min):0\(sec)"
        }
        return "0\(min):\(sec)"
    }
    
    
}

extension MusicPlayViewController: AVAudioPlayerDelegate, AVAudioRecorderDelegate{
    
}

