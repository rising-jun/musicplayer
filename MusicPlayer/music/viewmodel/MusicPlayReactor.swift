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
    enum Action {
        case getInitData
    }
    
    enum Mutation{
        case requestInitData
    }
    
    struct State{
    
    }
    
    let initialState: State = State()
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .getInitData:
            return Observable.just(Mutation.requestInitData)
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        switch mutation {
            
        case .requestInitData:
                getData()
            break
        }
        return newState
    }
    
    func getData(){
        let provider = MoyaProvider<MusicInfoAPI>()
        provider.request(.getMusicData, completion: {result in
            switch result{
            case .success(let response):
                print("respose : \(response)")
                let data = response.data
                let json = String.init(data: data, encoding: .utf8)
                
                break
                
            case .failure(let error):
                print("error : \(error)")
                break
            }
        })
    }
    
}
