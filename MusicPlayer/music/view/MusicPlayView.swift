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
    lazy var subLyricsLabel = UILabel()
    lazy var seekBar = UISlider()
    lazy var playBtn = UIButton()
    lazy var leftTimer = UILabel()
    lazy var rightTimer = UILabel()
    lazy var rewindbtn = UIButton()
    lazy var forwordBtn = UIButton()
    
    override func setup() {
        backgroundColor = .white
        addSubViews(musicTitle, artistName, albumIV, lyricsLabel, subLyricsLabel, seekBar, leftTimer, rightTimer, playBtn, rewindbtn, forwordBtn)
        
        musicTitle.text = "music Title"
        musicTitle.adjustsFontSizeToFitWidth = true
        musicTitle.textAlignment = .center
        musicTitle.font = .systemFont(ofSize: 20)
        musicTitle.snp.makeConstraints { make in
            make.top.equalTo(self).offset(150)
            make.centerX.equalTo(self)
            make.height.equalTo(50)
            make.width.equalTo(300)
        }
        
        artistName.text = "artist Title"
        artistName.textAlignment = .center
        artistName.adjustsFontSizeToFitWidth = true
        artistName.font = .systemFont(ofSize: 18)
        artistName.snp.makeConstraints { make in
            make.top.equalTo(musicTitle).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(40)
            make.width.equalTo(300)
        }
        
        albumIV.backgroundColor = .blue
        albumIV.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.height.equalTo(250)
        }
        
        lyricsLabel.text = "lyrics Title"
        lyricsLabel.adjustsFontSizeToFitWidth = true
        lyricsLabel.font = .systemFont(ofSize: 18)
        lyricsLabel.textAlignment = .center
        lyricsLabel.snp.makeConstraints { make in
            make.top.equalTo(albumIV.snp.bottom).offset(50)
            make.centerX.equalTo(self)
            make.height.equalTo(30)
            make.width.equalTo(200)
        }
        
        subLyricsLabel.text = "subLyrics Title"
        subLyricsLabel.adjustsFontSizeToFitWidth = true
        subLyricsLabel.font = .systemFont(ofSize: 15)
        subLyricsLabel.textAlignment = .center
        subLyricsLabel.snp.makeConstraints { make in
            make.top.equalTo(lyricsLabel.snp.bottom).offset(5)
            make.centerX.equalTo(self)
            make.height.equalTo(30)
            make.width.equalTo(200)
        }
        
        seekBar.minimumTrackTintColor = .black
        seekBar.minimumValue = 0
        seekBar.snp.makeConstraints { make in
            make.top.equalTo(lyricsLabel.snp.bottom).offset(50)
            make.leading.equalTo(self.snp.leading).offset(50)
            make.trailing.equalTo(self.snp.trailing).offset(-50)
            make.height.equalTo(5)
        }
        
        leftTimer.text = "00:00"
        leftTimer.textAlignment = .center
        leftTimer.snp.makeConstraints { make in
            make.top.equalTo(seekBar.snp.bottom).offset(20)
            make.centerX.equalTo(seekBar.snp.leading)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }
        
        rightTimer.text = "00:00"
        rightTimer.textAlignment = .center
        rightTimer.snp.makeConstraints { make in
            make.top.equalTo(seekBar.snp.bottom).offset(20)
            make.centerX.equalTo(seekBar.snp.trailing)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }
        
        playBtn.backgroundColor = .yellow
        playBtn.setTitle("재생", for: .normal)
        playBtn.titleColor(for: .normal)
        playBtn.snp.makeConstraints { make in
            make.top.equalTo(seekBar.snp.bottom).offset(50)
            make.width.height.equalTo(50)
            make.centerX.equalTo(seekBar)
        }
        
        rewindbtn.backgroundColor = .blue
        rewindbtn.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerY.equalTo(playBtn)
            make.trailing.equalTo(playBtn.snp.leading).offset(-30)
        }
        
        forwordBtn.backgroundColor = .blue
        forwordBtn.snp.makeConstraints { make in
            make.width.height.equalTo(50)
            make.centerY.equalTo(playBtn)
            make.leading.equalTo(playBtn.snp.trailing).offset(30)
        }
        
        
    }
    
    
    
}
