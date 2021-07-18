//
//  ViewController.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import UIKit
import ReactorKit
import RxViewController

class MusicPlayViewController: UIViewController, View{
    lazy var vMain = MusicPlayView(frame: view.bounds)
    var disposeBag: DisposeBag = DisposeBag()
    
    func bind(reactor: MusicPlayReactor) {
        view = vMain
        
        self.rx.viewWillAppear.asSignal().map{_ in Reactor.Action.getInitData}.emit(to: reactor.action).disposed(by: disposeBag)
        
        
        
    }

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        print("ViewDidLoad")
        
    }


}

