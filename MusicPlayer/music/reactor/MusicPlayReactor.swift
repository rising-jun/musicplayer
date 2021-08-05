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
    private var musicPublish = PublishSubject<MusicInfo>()
//    private var lyricsDicPublish = PublishSubject<Dictionary<String, String>>()
//    private var lyricsSeqPublish = PublishSubject<[String]>()
    private var lyricsDic: Dictionary<String, String>!
    private var lyricsSeq: [String]!
    
    
    enum Action {
        case initViewData
        case seekBarValChanged(val: Float)
        case playPauseButton
        case seekDragEnd
        case takeLyrics(lyrics: String)
    }
    
    enum Mutation{
        case initView
        case requestInitData(MusicInfo)
        case changedValReact(Float)
        case changePlayState
        case playPlayState
        case pausePlayState
        case processLyrics
    }
    
    struct State{
        var viewState: MPViewState!
        var musicInfo: MusicInfo!
        var seekVal: Float = -1
        var playState: PlayState = .none
        
        var lyricsSeq: [String] = []
        var lyricsList: Dictionary = [String: String]()
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
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> MusicPlayReactor.State {
        var newState = state
        
        switch mutation {
        case .requestInitData(let musicInfo):
            newState.musicInfo = musicInfo
        case .initView:
            newState.viewState = .initView
            
        case .changedValReact(let val):
            newState.seekVal = val
            newState.playState = .pause
            
        case .changePlayState:
            if newState.playState == .play{
                newState.playState = .pause
            }else{
                newState.playState = .play
            }
            
        case .playPlayState:
            newState.playState = .play
        case .pausePlayState:
            newState.playState = .pause
            
        case .processLyrics:
            newState.lyricsList = self.lyricsDic
            newState.lyricsSeq = self.lyricsSeq
            break
        
        }
        return newState
    }
    
    private func getMusicData(){
        let provider = MoyaProvider<MusicInfoAPI>()
        provider.rx.request(.getMusicData)
            .map(MusicInfo.self)
            .asObservable()
            .observeOn(MainScheduler.instance)
            .bind { [weak self] musicInfo in
            self?.musicPublish.onNext(musicInfo)
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
