//
//  AnimatedImage.swift
//  SwiftWebP̨
//
//  Created by Michael Mork on 1/29/17.
//  Copyright © 2017 Dollar Shave Club. All rights reserved.
//

import Foundation

public struct ImageFrame {
    
    //the frame of this image
    var frame: CGRect
    
    //should the we canvas be cleared before drawing this image?
    //dispose == YES don't draw anything but this image. NO means to draw the previous frames.
    var dispose: Bool
    
    //should only the last drawing rect have transparent pixels or solid background?
    //Blend == YES means it should be transparent and NO means the background color.
    var blend: Bool
    
    //how long should this image frame be display (in milliseconds)?
    var displayDuration: NSInteger
    
    //the image object to display for this frame
    public var image: UIImage
    
    init(frame: CGRect, image: UIImage, dispose: Bool, blend: Bool, duration: NSInteger) {
        self.frame = frame
        self.image = image
        self.dispose = dispose
        self.blend = blend
        self.displayDuration = duration
    }
}

open class AnimatedImageView: UIView {
    var image: AnimatedImage
    private var link: CADisplayLink!
    private var refIndex = 0
    private var refTime: CFTimeInterval = 0.0

    public init(image: AnimatedImage, frame: CGRect) {
        self.image = image
        super.init(frame: frame)
        if image.frames?.count ?? 0 > 0 {
            refTime = CACurrentMediaTime()
            link = CADisplayLink(target: self, selector: #selector(AnimatedImageView.refresh(_:)))
            link.add(to: RunLoop.main, forMode: .defaultRunLoopMode)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func draw(_ layer: CALayer, in ctx: CGContext) {
        super.draw(layer, in: ctx)
        let frame = image.frames![refIndex]
        if frame.dispose {
            ctx.clear(bounds)
        }
        UIGraphicsPushContext(ctx)
        let rect = CGRect(x: (bounds.width - frame.image.size.width)/2, y: (bounds.height - frame.image.size.height)/2, width: frame.image.size.width, height: frame.image.size.height)
        frame.image.draw(in: rect)
        UIGraphicsPopContext()
    }
    deinit {
        link.remove(from: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    func refresh(_ link: CADisplayLink) {
        if (CACurrentMediaTime() - refTime) > Double(image.frames![refIndex].displayDuration)/1000
            || refIndex == 0 {
            layer.setNeedsDisplay()
            refIndex += 1
            refTime = CACurrentMediaTime()
            if refIndex > image.frames!.count - 1 {
                refIndex = 0
            }
        }
    }

}

open class AnimatedImage {
    var size: CGSize = .zero
    public var frames: [ImageFrame]?
    var isDecoded: Bool = false
    var hasAlpha: Bool = false
    var backgroundColor: UIColor = .clear
    
    init(frame: CGRect) {
        size = frame.size
    }
}

