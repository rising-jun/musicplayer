//
//  AppDelegate.swift
//  MusicPlayer
//
//  Created by 김동준 on 2021/07/16.
//

import UIKit
import ReactorKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        var musicPlayViewController = MusicPlayViewController()
        var musicPlayReactor = MusicPlayReactor()
        musicPlayViewController.reactor = musicPlayReactor
        window?.rootViewController = musicPlayViewController
        return true
    }
}

