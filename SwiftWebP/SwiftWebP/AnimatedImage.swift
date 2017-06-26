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
