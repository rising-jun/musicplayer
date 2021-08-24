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
import RxGesture
import RxCocoa
import MediaPlayer

class MusicPlayViewController: UIViewController, ReactorKit.View{
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
    private let audioSession = AVAudioSession.sharedInstance()
    
    private var playList: [MusicInfo] = []
    private var playSeq: Int = 0
    private var changeMusic = PublishSubject<ChangeMusic>()
    private var playpause = PublishSubject<PlayState>()
    private var playMode: PlayMode = .sequentially
    private var playDidEndPublish = PublishSubject<PlayMode>()
    
    func bind(reactor: MusicPlayReactor) {
        print("bind!")
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let center = MPRemoteCommandCenter.shared()
        
        self.rx.viewDidLoad
            .map{_ in Reactor.Action.initViewData}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.forwordBtn.rx.tap
            .map{_ in Reactor.Action.nextSeq}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.rewindbtn.rx.tap
            .map{_ in Reactor.Action.prevSeq}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.playBtn.rx.tap
            .map{Reactor.Action.playPauseButton}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        v.playModeBtn.rx.tap.map{Reactor.Action.changeMode}
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
        
        v.seekBar.rx.controlEvent(.touchDragInside).bind { _ in
            print("ediitbegin")
            UIView.animate(withDuration: 0.1) {
                self.v.seekBar.transform = CGAffineTransform(scaleX: 1, y: 2)
            }
        }.disposed(by: disposeBag)
        
        v.seekBar.rx.controlEvent(.touchUpInside).bind { _ in
            print("editended")
            UIView.animate(withDuration: 0.1) {
                self.v.seekBar.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }.disposed(by: disposeBag)
        
        v.seekBar.rx.tapGesture().skip(1).bind { [weak self] gs in
            guard let self = self else { return }
            let location = gs.location(in: self.v.seekBar)
            let percent = 0 + Float(location.x / self.v.seekBar.bounds.width)
            self.v.seekBar.setValue(Float(percent), animated: true)
            self.v.seekBar.sendActions(for: .valueChanged)
            self.playpause.onNext(.play)
        }.disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(.AVPlayerItemDidPlayToEndTime).bind { [weak self] _ in
            guard let self = self else { return }
            print("changed play mode")
            switch self.playMode{
            case .sequentially:
                self.playDidEndPublish.onNext(.sequentially)
                break
            case .loop:
                self.playDidEndPublish.onNext(.loop)
                break
            case .random:
                self.playDidEndPublish.onNext(.random)
                break
            default:
                self.playDidEndPublish.onNext(.sequentially)
            }
        }.disposed(by: disposeBag)
        
        playDidEndPublish.map{Reactor.Action.didEndMusic(mode: $0)}.bind(to: reactor.action).disposed(by: disposeBag)
        
        changeMusic.filter{$0 == .next}
            .map{_ in Reactor.Action.nextSeq}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        changeMusic.filter{$0 == .prev}
            .map{_ in Reactor.Action.prevSeq}
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        playpause.filter{$0 != .none}
            .map{_ in Reactor.Action.playPauseButton}
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
                    print("init view ")
                    self.view = self.v
                    self.v.seekBar.value = 0
                    self.v.lyricsLabel.text = ""
                    self.v.subLyricsLabel.text = ""
                    
                    do {
                        try self.audioSession.setCategory(.playback, mode: .default, options: [])
                        
                    } catch
                        let error as NSError {
                        print("audioSession 설정 오류 : \(error.localizedDescription)")
                    }
                    
                    break
                case .willLoad:
                    break
                case .none:
                    break
                }
            }.disposed(by: disposeBag)
        
        reactor.state
            .filter{$0.musicInfo != nil}
            .map{$0.musicInfo}
            .bind {[weak self] musicInfo in
                print("first Set MusicInfo")
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
        
        reactor.state.map{$0.playList}
            .filter{$0.count > 0}
            .take(1)
            .bind { [weak self] playList in
            self?.playList = playList
            self?.setMusicInfo(musicInfo: playList.first!)
            self?.firstTimerStart()
        }.disposed(by: disposeBag)
        
        reactor.state.map{$0.playSeq}
            .distinctUntilChanged()
            .skip(1)
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] seq in
                self?.playSeq = seq
            self?.setMusicInfo(musicInfo: (self?.playList[seq])!)
        }.disposed(by: disposeBag)
        
        reactor.state.map{$0.playMode}
            .distinctUntilChanged()
            .bind { [weak self] mode in
            print("mode changed \(mode)")
            self?.playMode = mode
        }.disposed(by: disposeBag)
        
        reactor.state.map{$0.repeatCheck}
            .distinctUntilChanged()
            .filter{$0 > 0}
            .bind { [weak self] _ in
                guard let self = self else { return }
                if self.playMode == .loop{
                    self.setMusicInfo(musicInfo: self.playList[self.playSeq])
                }
            }.disposed(by: disposeBag)
        
        center.playCommand.addTarget { [weak self] (commandEvent) -> MPRemoteCommandHandlerStatus in
            self?.playpause.onNext(.play)
            return MPRemoteCommandHandlerStatus.success
        }
        
        center.pauseCommand.addTarget { [weak self] (commandEvent) -> MPRemoteCommandHandlerStatus in
            //self.player.pause()
            self?.playpause.onNext(.pause)
            return MPRemoteCommandHandlerStatus.success
        }
        
        center.nextTrackCommand.addTarget{ [weak self] (commandEvent) ->  MPRemoteCommandHandlerStatus in
            self?.changeMusic.onNext(.next)
            return MPRemoteCommandHandlerStatus.success
        }
        
        center.previousTrackCommand.addTarget{ [weak self] (commandEvent) ->  MPRemoteCommandHandlerStatus in
            self?.changeMusic.onNext(.prev)
            return MPRemoteCommandHandlerStatus.success
        }
        
        
    }
    
    
    private func setMusicInfo(musicInfo: MusicInfo){
        self.musicInfo = musicInfo
        
        v.musicTitle.text = musicInfo.title
        v.artistName.text = musicInfo.singer
        v.albumIV.kf.setImage(with: URL(string: musicInfo.image))
        let playerItem = AVPlayerItem(url: URL(string: musicInfo.file)!)
        player = AVPlayer(playerItem: playerItem)
        if playState == .play{
            player.play()
        }
        v.rightTimer.text = convertNSTimeInterval12String(TimeInterval(musicInfo.duration))
        if musicInfo.lyrics == ""{
            v.lyricsLabel.text = ""
            v.subLyricsLabel.text = ""
        }else{
        giveLyrics.onNext(musicInfo.lyrics)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    func firstTimerStart(){
        timer.bind { [weak self] sec in
            guard let self = self else { return }
            if self.playState == .play{
                
                let center = MPNowPlayingInfoCenter.default()
                var nowPlayingInfo = center.nowPlayingInfo ?? [String: Any]()
                nowPlayingInfo[MPMediaItemPropertyTitle] = self.musicInfo.title
                nowPlayingInfo[MPMediaItemPropertyArtist] = self.musicInfo.singer
                
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = self.musicInfo.duration // 콘텐츠 재생 시간에 따른 progressBar 초기화
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate// 콘텐츠 현재 재생시간
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime().seconds
                center.nowPlayingInfo = nowPlayingInfo
                
                var nowTimeText = self.convertNSTimeInterval12String(self.player.currentTime().seconds)
                
                self.v.seekBar.value = Float(self.player.currentTime().seconds/Double(self.musicInfo.duration))
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
    }
    
    func setInitMusicUI(){
        v.seekBar.value = 0
        v.leftTimer.text = ""
        v.lyricsLabel.text = "00:00"
        v.subLyricsLabel.text = ""
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
