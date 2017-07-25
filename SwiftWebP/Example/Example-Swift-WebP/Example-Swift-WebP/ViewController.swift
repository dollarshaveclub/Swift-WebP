//
//  ViewController.swift
//  Example-Swift-WebP
//
//  Created by Michael Mork on 6/22/17.
//  Copyright © 2017 Michael Mork. All rights reserved.
//

import UIKit
import SwiftWebP

class ViewController: UIViewController {
    var decoder = ImageDecoder()
    let scrollView = UIScrollView()
    var animatedImage: AnimatedImageView?
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.frame = view.bounds
        view.addSubview(scrollView)
        view.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1.0)
        scrollView.contentSize = CGSize(width: view.bounds.width, height:
            presentImage("anitiger", y: presentImage("cosmic_tiger_a", y: presentImage("red_fox", y: 100) + 20) + 10))
    }

    func presentImage(_ str: String, y: CGFloat) -> CGFloat {
        do {
            let data = try Data(contentsOf: Bundle.main.url(forResource: str, withExtension: "webp")!)
            var h: CGFloat = y
            func x(_ w:CGFloat) -> CGFloat {
                return (view.bounds.width - w)/2
            }
            switch decoder.decode(data: data) {
            case .image(let image):
                let imageView = UIImageView(image: image)
                imageView.frame.origin = CGPoint(x: x(imageView.bounds.width), y: y)
                h += imageView.image?.size.height ?? imageView.bounds.height
                scrollView.addSubview(imageView)
            case .animatedImage(let aniImage):
                let animatedImageView = AnimatedImageView(image: aniImage, frame: .zero)
                let s = animatedImageView.boundedSize
                animatedImageView.frame = CGRect(x: x(s.width), y: y, width: s.width, height: s.height)
                h += s.height
                animatedImage = animatedImageView
                scrollView.addSubview(animatedImageView)
            case .error(let error):
                print("error decoding image: \(error)")
            }
            return h
        } catch {
            print("error with the provided example data")
        }
        return 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
