//
//  ViewController.swift
//  PryntTrimmerView
//
//  Created by Henry on 27/03/2017.
//  Copyright © 2017 Prynt. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import PryntTrimmerView
import Combine

/// A view controller to demonstrate the trimming of a video. Make sure the scene is selected as the initial
// view controller in the storyboard
class VideoTrimmerViewController: AssetSelectionViewController {
    
    private var cancellables: [AnyCancellable] = []

    @IBOutlet weak var selectAssetButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var trimmerView: TrimmerView!
    @IBOutlet weak var setStartTime: UIButton!

    var player: AVPlayer?
    var playbackTimeCheckerTimer: Timer?
    var trimmerPositionChangedTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        defaultTrimmerView()
        noTrimmerView()
    }
    
    private func defaultTrimmerView() {
        trimmerView.handleColor = UIColor.white
        trimmerView.mainColor = UIColor.darkGray
        trimmerView.handleWidth = 100
    }
    
    private func noTrimmerView() {
        view.backgroundColor = .systemPink
        
        // trimerViewのスタイル設定
        trimmerView.borderWidth = 0
        trimmerView.cornerRadius = 0
        trimmerView.mainColor = UIColor.white
        trimmerView.maskColor = .clear
        
        // ハンドラ（時間指定するための両側ビュー）設定
        trimmerView.handleWidth = 0
        trimmerView.handleColor = UIColor.white
        trimmerView.isHiddenHandle = true
        
        // アセットプレビュー（スナップショット）のスタイル設定
        trimmerView.assetPreviewMargin = 10.0
        trimmerView.assetPreviewBorderWidth = 4.0
        trimmerView.assetPreviewCornerRadius = 4.0
        
        //ポジションバーの設定
        trimmerView.positionBarColor = .clear
        trimmerView.positionBarWidth = 24.0
        trimmerView.customPositionBar = customPositionBar
        trimmerView.isMovePositionBar = true
        
        // タイムラベル（ポジションバーの上部に表示される）の設定
        trimmerView.isShowTimeLabel = true
        trimmerView.fps = 120
    }
    
    deinit {
        cancellables.forEach { cancellable in
            cancellable.cancel()
        }
    }

    @IBAction func selectAsset(_ sender: Any) {
        loadAssetRandomly()
        trimmerView.resetAssetPreviews()
    }

    @IBAction func play(_ sender: Any) {

        guard let player = player else { return }

        if !player.isPlaying {
            player.play()
            startPlaybackTimeChecker()
        } else {
            player.pause()
            stopPlaybackTimeChecker()
        }
    }
    
    @IBAction func setStartTime(_ sender: Any) {
        let startTime = CMTime(seconds: 3, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        trimmerView.setStartTime(startTime)
    }

    override func loadAsset(_ asset: AVAsset) {

        trimmerView.asset = asset
        trimmerView.delegate = self
        addVideoPlayer(with: asset, playerView: playerView)
    }

    private func addVideoPlayer(with asset: AVAsset, playerView: UIView) {
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)

        NotificationCenter.default.addObserver(self, selector: #selector(VideoTrimmerViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)

        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: playerView.frame.width, height: playerView.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerView.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        playerView.layer.addSublayer(layer)
    }

    @objc func itemDidFinishPlaying(_ notification: Notification) {
        if let startTime = trimmerView.startTime {
            player?.seek(to: startTime)
            if (player?.isPlaying != true) {
                player?.play()
            }
        }
    }

    func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(VideoTrimmerViewController.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }

    func stopPlaybackTimeChecker() {

        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }

    @objc func onPlaybackTimeChecker() {

        guard let startTime = trimmerView.startTime, let endTime = trimmerView.endTime, let player = player else {
            return
        }

        let playBackTime = player.currentTime()
        trimmerView.seek(to: playBackTime)

        if playBackTime >= endTime {
            player.seek(to: startTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
            trimmerView.seek(to: startTime)
        }
    }
}

extension VideoTrimmerViewController {
    var customLeftHandleView: UIView {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: 25, height: 10)))
        view.backgroundColor = .green
        return view
    }
    
    var customRightHandleView: UIView {
        let view = UIView(frame: .init(origin: .zero, size: .init(width: 25, height: 10)))
        view.backgroundColor = .cyan
        return view
    }
    
    var customPositionBar: UIView {
        let view = customPositionBarView
        view.addSubview(customPositionBarKnobView)
        return view
    }
    
    var customPositionBarView: UIView {
        let containerHeight: CGFloat = 60.0
        let containerY: CGFloat = (containerHeight - trimmerView.frame.height) / 2
        let containerView = UIView(frame: .init(origin: .init(x: 0, y: -containerY), size: .init(width: trimmerView.positionBarWidth, height: containerHeight)))
        containerView.backgroundColor = .clear
        
        let barWidth: CGFloat = 4.0
        let barView = UIView(frame: .init(origin: .init(x: (trimmerView.positionBarWidth - barWidth) / 2, y: 0), size: .init(width: barWidth, height: containerHeight)))
        barView.backgroundColor = UIColor(red: (31 / 255), green: (255 / 255), blue: (242 / 255), alpha: 1.0)
        barView.layer.shadowOffset = CGSize(width: 0.0, height: 0.0)
        barView.layer.shadowColor = UIColor.black.cgColor
        barView.layer.shadowOpacity = 0.5
        barView.layer.shadowRadius = 4.0
        barView.layer.cornerRadius = 2.0
        
        containerView.addSubview(barView)
        
        return containerView
    }
    
    var customPositionBarKnobView: UIView {
        let knobSize: CGFloat = 24
        let knobX: CGFloat = (customPositionBarView.frame.width - knobSize) / 2
        let knobY: CGFloat = (customPositionBarView.frame.height - knobSize) / 2
        
        let knobPoint = CGPoint(x: knobX, y: knobY)
        
        let knobView = UIView(frame: .init(origin: knobPoint, size: .init(width: knobSize, height: knobSize)))
        knobView.backgroundColor = UIColor(red: (0 / 255), green: (204 / 255), blue: (192 / 255), alpha: 1.0)
        knobView.layer.cornerRadius = knobSize / 2
        knobView.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        knobView.layer.shadowColor = UIColor.black.cgColor
        knobView.layer.shadowOpacity = 0.16
        knobView.layer.shadowRadius = 4
        knobView.layer.borderWidth = 3.0
        knobView.layer.borderColor = UIColor.white.cgColor
        return knobView
    }
}

extension VideoTrimmerViewController: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        player?.play()
        startPlaybackTimeChecker()
    }

    func didChangePositionBar(_ playerTime: CMTime) {
        stopPlaybackTimeChecker()
        player?.pause()
        player?.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        let duration = (trimmerView.endTime! - trimmerView.startTime!).seconds
        print(duration)
    }
}
