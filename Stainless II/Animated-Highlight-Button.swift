//
//  Animated-Highlight-Button.swift
//
//
//  Created by Grant Goodman on 8/25/15.
//
//

import UIKit

class AHB: UIButton
{
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        super.touchesBegan(touches, withEvent: event)
        
        UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
            {() in
                self.highlighted = true
                self.imageView!.image = UIImage(named: "refresh@2x~highlighted.png")
                self.imageView!.alpha = 0.5
            },
            completion: nil)
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        UIView.animateWithDuration(0.2, delay: 0, options:UIViewAnimationOptions.CurveEaseOut, animations:
            {() in
                self.highlighted = false
                self.imageView!.image = UIImage(named: "refresh@2x.png")
                self.imageView!.alpha = 1
            },
            completion: nil)
        
        super.touchesEnded(touches, withEvent: event)
    }
}
