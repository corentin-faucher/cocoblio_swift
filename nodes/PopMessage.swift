//
//  PopMessage.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-05-13.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//
import Foundation

/** Message temporaire (s'autodédruit) */
final class PopMessage : Node {
    private var abort: Bool = false
    
    @discardableResult
    init?(parent: ScreenBase,
          strTex: Texture, frameTex: Texture,
          _ x: Float, _ y: Float, _ height: Float,
          appearTime: Double, disappearTime: Double, ceiledWidth: Float? = nil,
          fadeInY: Float? = nil
    ) {
        guard disappearTime > appearTime + 0.1 else {
            printerror("disappear < appear")
            return nil
        }
        super.init(parent, x, y, height, height, lambda: (fadeInY == nil) ? 0 : 5, flags: Flag1.hidden | Flag1.notToAlign)
        if let fadeInY = fadeInY {
            self.y.fadeIn(delta: fadeInY)
        }
        
        fillWithFramedString(strTex: strTex, frameTex: frameTex,
                             ceiledWidth: ceiledWidth ?? parent.width.realPos, relDelta: 0.2)
        
        Timer.scheduledTimer(withTimeInterval: appearTime, repeats: false) { [weak self] (_) in
            guard let self = self, !self.abort, let parent = self.parent, parent.containsAFlag(Flag1.show) else { return }
            self.addFlags(Flag1.show)
            self.openBranch()
        }
        Timer.scheduledTimer(withTimeInterval: disappearTime, repeats: false) { [weak self] (_) in
            self?.closeBranch()
        }
        Timer.scheduledTimer(withTimeInterval: disappearTime + 1, repeats: false) { [weak self] (_) in
            self?.disconnect()
        }
    }
    
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func close() {
        abort = true
    }
}
