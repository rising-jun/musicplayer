//
//  MusicPlayView.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import UIKit
import SnapKit

class MusicPlayView: BaseView{

    lazy var musicTitle = UILabel()
    lazy var artistName = UILabel()
    lazy var albumIV = UIImageView()
    lazy var lyricsLabel = UILabel()
    
    lazy var seekBar = UISlider()
    
    override func setup() {
        backgroundColor = .white
        addSubViews(musicTitle, artistName, albumIV, lyricsLabel, seekBar)
        
        musicTitle.text = "music Title"
        musicTitle.adjustsFontSizeToFitWidth = true
        musicTitle.font = .systemFont(ofSize: 20)
        musicTitle.snp.makeConstraints { make in
            make.top.equalTo(self).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(50)
            make.width.equalTo(100)
        }
        
        artistName.text = "artist Title"
        artistName.adjustsFontSizeToFitWidth = true
        artistName.font = .systemFont(ofSize: 18)
        artistName.snp.makeConstraints { make in
            make.top.equalTo(musicTitle).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(40)
            make.width.equalTo(80)
        }
        
        albumIV.backgroundColor = .blue
        albumIV.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.height.equalTo(250)
        }
        
        lyricsLabel.backgroundColor = .yellow
        lyricsLabel.text = "artist Title"
        lyricsLabel.adjustsFontSizeToFitWidth = true
        lyricsLabel.font = .systemFont(ofSize: 18)
        lyricsLabel.textAlignment = .center
        lyricsLabel.snp.makeConstraints { make in
            make.top.equalTo(musicTitle).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(40)
            make.width.equalTo(200)
        }
        
        seekBar.snp.makeConstraints { make in
            make.top.equalTo(albumIV.snp.bottom).offset(50)
            make.leading.equalTo(self.snp.leading).offset(30)
            make.trailing.equalTo(self.snp.trailing).offset(-30)
            make.height.equalTo(20)
        }
        
        
    }
    
    
    
}
