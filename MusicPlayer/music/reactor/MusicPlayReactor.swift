//
//  MusicPlayReactor.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import Foundation
import ReactorKit
import Moya

class MusicPlayReactor: Reactor{
    private var disposeBag = DisposeBag()
    private var musicPublish = PublishSubject<[MusicInfo]>()
//    private var lyricsDicPublish = PublishSubject<Dictionary<String, String>>()
//    private var lyricsSeqPublish = PublishSubject<[String]>()
    private var lyricsDic: Dictionary<String, String>!
    private var lyricsSeq: [String]!
    private var playList: [MusicInfo] = []
    private var musicSeq: Int = 0
    private var playMode: PlayMode = .sequentially
    private var repeatCheck: Int = 0
    
    enum Action {
        case initViewData
        case prevSeq
        case nextSeq
        case seekBarValChanged(val: Float)
        case playPauseButton
        case seekDragEnd
        case takeLyrics(lyrics: String)
        case changeMode
        case didEndMusic(mode: PlayMode)
    }
    
    enum Mutation{
        case initView
        case requestInitData([MusicInfo])
        case changedValReact(Float)
        case changePlayState
        case playPlayState
        case pausePlayState
        case processLyrics
        case changedSeqState(Int)
        case changePlayMode(PlayMode)
    }
    
    struct State{
        var viewState: MPViewState!
        var musicInfo: MusicInfo!
        var playList: [MusicInfo] = []
        var playSeq: Int = 0
        var seekVal: Float = -1
        var playState: PlayState = .none
        var lyricsSeq: [String] = []
        var lyricsList: Dictionary = [String: String]()
        var playMode: PlayMode = .sequentially
        var repeatCheck: Int = 0
    }
    
    let initialState: State = State()
    
    func mutate(action: Action) -> Observable<MusicPlayReactor.Mutation> {
        // process logic only here
        switch action {
        case .initViewData:
            getMusicData()
            return Observable.concat([
                Observable.just(Mutation.initView),
                musicPublish.map{Mutation.requestInitData($0)}
                ])
        case .seekBarValChanged(val: let val):
            return Observable.concat([
                Observable.just(Mutation.changedValReact(val)),
                Observable.just(Mutation.pausePlayState)
            ])
                
            
        case .playPauseButton:
            return Observable.just(Mutation.changePlayState)

            
        case .seekDragEnd:
            return Observable.just(Mutation.playPlayState)

        case .takeLyrics(let lyrics):
            processLyrics(lyrics: lyrics)
            return Observable.just(Mutation.processLyrics)
        case .prevSeq:
            if playMode == .random{
                var random = randomNum(seq: musicSeq)
                print("randomNum \(random)")
                self.musicSeq = random
                return Observable.just(Mutation.changedSeqState(random))
            }
            
            if musicSeq == 0{
                musicSeq = playList.count - 1
            }else{
                musicSeq -= 1
            }
            
            return Observable.just(Mutation.changedSeqState(musicSeq))
            
        case .nextSeq:
            if playMode == .random{
                var random = randomNum(seq: musicSeq)
                print("randomNum \(random)")
                self.musicSeq = random
                return Observable.just(Mutation.changedSeqState(random))
            }
            
            if musicSeq == playList.count - 1{
                musicSeq = 0
            }else{
                musicSeq += 1
            }
            return Observable.just(Mutation.changedSeqState(musicSeq))
        case .changeMode:
            if playMode == .sequentially{
                playMode = .random
            }else if playMode == .random{
                playMode = .loop
            }else if playMode == .loop{
                playMode = .sequentially
            }
            return Observable.just(Mutation.changePlayMode(playMode))
        case .didEndMusic(let mode):
            switch mode {
            case .sequentially:
                
                if musicSeq == playList.count - 1{
                    musicSeq = 0
                }else{
                    musicSeq += 1
                }
                
                return Observable.just(Mutation.changedSeqState(musicSeq))
            case .random:
                var random = randomNum(seq: musicSeq)
                print("randomNum \(random)")
                self.musicSeq = random
                return Observable.just(Mutation.changedSeqState(random))
                
            case .loop:
                repeatCheck += 1
                return Observable.just(Mutation.changedSeqState(musicSeq))
            }
            
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> MusicPlayReactor.State {
        var newState = state
        
        switch mutation {
        case .requestInitData(let playList):
            print("requestInitData")
            newState.playList = playList
            break
        case .initView:
            newState.viewState = .initView
            break
        case .changedValReact(let val):
            newState.seekVal = val
            newState.playState = .pause
            break
        case .changePlayState:
            if newState.playState == .play{
                newState.playState = .pause
            }else{
                newState.playState = .play
            }
            break
        case .playPlayState:
            newState.playState = .play
        case .pausePlayState:
            newState.playState = .pause
            break
        case .processLyrics:
            newState.lyricsList = self.lyricsDic
            newState.lyricsSeq = self.lyricsSeq
            break
        
        case .changedSeqState(let seq):
            print("print seq \(seq) playmode \(playMode)")
            
            
            newState.playSeq = seq
            newState.repeatCheck = repeatCheck
            break
        case .changePlayMode(let playMode):
            newState.playMode = playMode
            break
        }
        return newState
    }
    
    private func getMusicData(){
        let provider = MoyaProvider<MusicInfoAPI>()
        let observe = provider.rx.request(.getMusicData)
            .map(MusicInfo.self)
            .asObservable()
            .observeOn(MainScheduler.instance)
            .bind { [weak self] musicInfo in
                var musicInfo2 = MusicInfo(singer: "장범준", album: "첫 번째 '고백'", title: "고백", duration: 210, image: "", file: "https://witch-dev.s3.ap-northeast-2.amazonaws.com/%EC%9E%A5%EB%B2%94%EC%A4%80-01-%EA%B3%A0%EB%B0%B1-%EC%B2%AB+%EB%B2%88%EC%A7%B8+'%EA%B3%A0%EB%B0%B1'-320.mp3", lyrics: "")
                var musicInfo3 = MusicInfo(singer: "pH-1, Kid Milli, Loopy", album: "쇼미더머니 777", title: "Good Day", duration: 267, image: "", file: "https://witch-dev.s3.ap-northeast-2.amazonaws.com/pH-1-04-Good+Day+(Feat.+%ED%8C%94%EB%A1%9C%EC%95%8C%ED%86%A0)+(Prod.+%EC%BD%94%EB%93%9C+%EC%BF%A4%EC%8A%A4%ED%8A%B8)-%EC%87%BC%EB%AF%B8%EB%8D%94%EB%A8%B8%EB%8B%88+777+Episode+1-320.mp3", lyrics: "")
                
            self?.playList.append(musicInfo)
            self?.playList.append(musicInfo2)
            self?.playList.append(musicInfo3)
            self?.musicPublish.onNext(self!.playList)
        }.disposed(by: disposeBag)

    }
    
    private func processLyrics(lyrics: String){
        var keyList:[String] = []
        var lyricsList: Dictionary = [String: String]()
        
        var lyricsSeq: [String] = []
        
        keyList = lyrics.components(separatedBy: "\n")
        guard let s: String = keyList.first else { return }
        let timeStartIdx: String.Index = s.index(s.startIndex, offsetBy: 1)
        let timeEndIdx: String.Index = s.index(s.startIndex, offsetBy: 7)
        
        let lyricsStartIndex = s.index(s.startIndex, offsetBy: 11)
        for s in keyList{
            lyricsList[String(s[timeStartIdx...timeEndIdx])] = String(s[lyricsStartIndex...])
        }
        //lyricsDicPublish.onNext(lyricsList)
        self.lyricsDic = lyricsList
        
        for i in 0 ..< keyList.count{
            lyricsSeq.append(String(keyList[i][timeStartIdx...timeEndIdx]))
        }
        //lyricsSeqPublish.onNext(lyricsSeq)
        self.lyricsSeq = lyricsSeq
    }
    
    private func randomNum(seq: Int) -> Int{
        let randomNo: Int = Int(arc4random_uniform(UInt32(playList.count)))
        print("randomNo!! \(randomNo)  \(playList.count - 1)")
        if (randomNo) != seq{
            return Int(randomNo)
        }else{
            return randomNum(seq: seq)
        }
    }
    
}

enum MPViewState{
    case willLoad
    case initView
    
}

enum PlayState{
    case none
    case play
    case pause
}

enum ChangeMusic{
    case next
    case prev
    case none
}

enum PlayMode{
    case sequentially
    case loop
    case random
}
