//
//  MusicInfo.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import Foundation

public struct MusicInfo: Codable {
    let singer: String
    let album: String
    let title: String
    let duration: String
    let file: String
    let lyrics: String
    
}
