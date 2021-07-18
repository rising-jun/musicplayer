//
//  MusicInfoAPI.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import Foundation
import Moya

public enum MusicInfoAPI{
    case getMusicData
}

extension MusicInfoAPI: TargetType, AccessTokenAuthorizable {
    
    
    public var baseURL: URL { URL(string: "https://grepp-programmers-challenges.s3.ap-northeast-2.amazonaws.com")! }
    
    public var path: String {
        let servicePath = "/2020-flo"
        switch self {
        case .getMusicData:
            return servicePath + "/song.json"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .getMusicData:
            return .get
        }
    }
    
    public var sampleData: Data {
        return Data()
    }
    
    public var task: Task {
        switch self {
        case .getMusicData:
            return .requestParameters(parameters: [:], encoding: URLEncoding.default)
        }
    }
    
    public var headers: [String: String]? {
        return nil
    }
    
    public var authorizationType: AuthorizationType? {
        return .none
    }
    
    
}
