//
//  LottieRefreshControl.swift
//  Basin
//
//  Created by Justin Cook on 4/24/22.
//

import UIKit
import Lottie

/** Custom refresh control object that incorporates lottie animation views into its subview hierarchy*/

class LottieRefreshControl: UIRefreshControl {
fileprivate let animationView = Lottie.AnimationView(name: "Basin RC Lottie")
fileprivate var isAnimating = false

fileprivate let maxPullDistance: CGFloat = 150

override init() {
    super.init(frame: .zero)
    setupView()
    setupLayout()
}

required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
}

func updateProgress(with offsetY: CGFloat) {
    guard !isAnimating else { return }
    let progress = min(abs(offsetY / maxPullDistance), 1)
    
    /** Don't complete the animation*/
    animationView.currentProgress = progress * 0.75
}

override func beginRefreshing() {
    super.beginRefreshing()
    isAnimating = true
    animationView.animationSpeed = 2
    /** Start the animation from the middle*/
    animationView.currentProgress = 0.75
    animationView.play()
}

override func endRefreshing() {
    super.endRefreshing()
    animationView.stop()
    isAnimating = false
}
}

private extension LottieRefreshControl {
func setupView() {
    ///hide default indicator view
    tintColor = .clear
    animationView.loopMode = .loop
    addSubview(animationView)

    addTarget(self, action: #selector(beginRefreshing), for: .valueChanged)
}

func setupLayout() {
    animationView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        animationView.centerXAnchor.constraint(equalTo: centerXAnchor),
        animationView.centerYAnchor.constraint(equalTo: centerYAnchor),
        animationView.widthAnchor.constraint(equalToConstant: 60),
        animationView.heightAnchor.constraint(equalToConstant: 60)
    ])
}
}
