//
//  PopMessage.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-05-13.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//
import Foundation

/** Noeud temporaire qui s'autodétruit.
 Si parent == nil, alors le PopOver est directement dans le screen. */
class PopOver : Node {
    private var abort: Bool = false
    private let fadePos: Vector2
    private let fadeScale: Vector2
    private let appearTime: Double
    private let disappearTime: Double
    
    // PopOver directement dans le "front" screen.
    @discardableResult
    init?(_ x: Float, _ y: Float, width: Float, height: Float,
          fadePos: Vector2, fadeScale: Vector2,
          appearTime: Double, disappearTime: Double)
    {
        guard disappearTime > appearTime + 0.1 else {
            printwarning("disappear < appear")
            return nil
        }
        self.fadePos = fadePos
        self.fadeScale = fadeScale
        self.appearTime = appearTime
        self.disappearTime = disappearTime
        
        super.init(PopOver.screen, x, y, width, height,
                   lambda: 4, flags: Flag1.hidden | Flag1.notToAlign)
        
        startTimer()
    }
    
    // PopOver situé sur un noeud de référence. Si inScreen, seulement la position est prise du refNode.
    // Toutes les dimensions sont dens le référentiel de ref.
    @discardableResult
    init?(over ref: Node, inScreen: Bool,
          _ x: Float, _ y: Float,
          width: Float, height: Float,
          fadePos: Vector2, fadeScale: Vector2,
          appearTime: Double, disappearTime: Double)
    {
        guard disappearTime > appearTime + 0.1 else {
            printwarning("disappear < appear")
            return nil
        }
        self.appearTime = appearTime
        self.disappearTime = disappearTime
        if inScreen {
            let sq = Squirrel(at: ref,
                              relPos: Vector2(ref.x.realPos + x, ref.y.realPos + y),
                              scaleInit: .ones)
            while sq.goUpPS() {}
            self.fadePos = fadePos * sq.vS
            self.fadeScale = fadeScale * sq.vS
            super.init(PopOver.screen,
                       sq.v.x, sq.v.y,
                       sq.vS.x * width, sq.vS.y * height,
                       lambda: 4, flags: Flag1.hidden | Flag1.notToAlign)
        } else {
            self.fadePos = fadePos
            self.fadeScale = fadeScale
            super.init(ref, x, y, width, height,
                       lambda: 4, flags: Flag1.hidden | Flag1.notToAlign)
        }
                
        startTimer()
    }
    required init(other: Node) {
        fatalError("init(other:) not available for PopOver nodes.")
    }
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: appearTime, repeats: false) { [weak self] (_) in
            guard let self = self, !self.abort else { return }
            self.addFlags(Flag1.show)
            self.openAndShowBranch()
            // Dépassement ? -> Ajustement
            let dim = self.getAbsPosAndDelta()
            let x_over_left = dim.pos.x - dim.deltas.x + 0.5*PopOver.screen.width.realPos
            let x_over_right = dim.pos.x + dim.deltas.x - 0.5*PopOver.screen.width.realPos
            let x_adj: Float = min(x_over_left, max(x_over_right, 0)) * self.deltaX / dim.deltas.x
            let y_over_bottom = dim.pos.y - dim.deltas.y + 0.5*PopOver.screen.height.realPos
            let y_over_top    = dim.pos.y + dim.deltas.y - 0.5*PopOver.screen.height.realPos
            let y_adj: Float = min(y_over_bottom, max(y_over_top, 0)) * self.deltaY / dim.deltas.y
            
            // Effet d'apparition
            self.x.setRelToDef(shift: self.fadePos.x, fix: true)
            self.x.setRelToDef(shift: -x_adj, fix: false)
            self.y.setRelToDef(shift: self.fadePos.y, fix: true)
            self.y.setRelToDef(shift: -y_adj, fix: false)
            self.scaleX.fadeIn(delta: self.fadeScale.x)
            self.scaleY.fadeIn(delta: self.fadeScale.y)
        }
        Timer.scheduledTimer(withTimeInterval: disappearTime, repeats: false) { [weak self] (_) in
            // Close va disconnecter...
            self?.closeBranch()
        }
    }
    override func close() {
        abort = true
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] (_) in
            self?.disconnect()
        }
    }
    
    //-- Static --
    static func setScreenAndDefaultFrame(_ toScreen: ScreenBase, _ frameTex: Texture)
    {
        screen = toScreen
        defaultFrameTex = frameTex
    }
    static var maxWidth: Float {
        return screen.width.realPos * 0.95
    }
    fileprivate static var defaultFrameTex: Texture!
    fileprivate static var screen: ScreenBase!
    
}


/** Message temporaire (s'autodédruit) */
final class PopMessage : PopOver {
    @discardableResult
    init?(strTex: Texture, frameTex: Texture?,
        _ x: Float, _ y: Float, width: Float, height: Float,
        fadePos: Vector2, fadeScale: Vector2,
        appearTime: Double, disappearTime: Double)
    {
        let frame: Texture
        if let frameTex = frameTex {
            frame = frameTex
        } else {
            guard let frameTex = PopOver.defaultFrameTex else {
                printerror("default frame texture not init.")
                return nil
            }
            frame = frameTex
        }
        super.init(x, y, width: width, height: height,
                   fadePos: fadePos, fadeScale: fadeScale,
                   appearTime: appearTime, disappearTime: disappearTime)
        
        fillWithFrameAndString(frameTex: frame, deltaRatio: 0.2, strTex: strTex)
    }
    
    @discardableResult
    init?(over ref: Node, inScreen: Bool,
          strTex: Texture, frameTex: Texture?,
          _ x: Float, _ y: Float, width: Float, height: Float,
          fadePos: Vector2, fadeScale: Vector2,
          appearTime: Double, disappearTime: Double)
    {
        let frame: Texture
        if let frameTex = frameTex {
            frame = frameTex
        } else {
            guard let frameTex = PopOver.defaultFrameTex else {
                printerror("default frame texture not init.")
                return nil
            }
            frame = frameTex
        }
        
        super.init(over: ref, inScreen: inScreen,
                   x, y, width: width, height: height,
                   fadePos: fadePos, fadeScale: fadeScale,
                   appearTime: appearTime, disappearTime: disappearTime)
        
        fillWithFrameAndString(frameTex: frame, deltaRatio: 0.2, strTex: strTex)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    @discardableResult
    convenience init?(string: String)
    {
        self.init(strTex: Texture.getConstantString(string), frameTex: nil,
                  0, 0, width: PopOver.maxWidth, height: 0.2,
                  fadePos: Vector2(0, -0.1), fadeScale: Vector2(-0.5, -0.5),
                  appearTime: 0.1, disappearTime: 2.5)
    }
}

/*
final class PopMessage : Node {
    static var defaultFrameTex: Texture? = nil
    static var defaultScreen: ScreenBase? = nil
    
    private var abort: Bool = false
    
    @discardableResult
    init?(parent: ScreenBase,
          strTex: Texture, frameTex: Texture,
          _ x: Float, _ y: Float, _ height: Float,
          appearTime: Double, disappearTime: Double, ceiledWidth: Float? = nil,
          fadeY: Float? = nil
    )
    {
        guard disappearTime > appearTime + 0.1 else {
            printerror("disappear < appear")
            return nil
        }
        super.init(parent, x, y, height, height,
                   lambda: 4,flags: Flag1.hidden | Flag1.notToAlign)
        self.width.set(ceiledWidth ?? parent.width.realPos * 0.97)
        
        fillWithFrameAndString(frameTex: frameTex, deltaRatio: 0.2, strTex: strTex)
        
        Timer.scheduledTimer(withTimeInterval: appearTime, repeats: false) { [weak self] (_) in
            guard let self = self, !self.abort, let theParent = self.parent, theParent.containsAFlag(Flag1.show) else { return }
            self.addFlags(Flag1.show)
            self.openBranch()
            if let fadeY = fadeY {
                self.y.fadeInFromDef(delta: fadeY)
            }
            // Dépassement à droite de l'écran ?
            var x_over = self.x.realPos + self.deltaX - theParent.width.realPos / 2
            if x_over > 0 {
                self.x.fadeInFromDef(delta: -x_over)
            }
            // Dépassement à gauche ?
            x_over = self.x.realPos - self.deltaX + theParent.width.realPos / 2
            if x_over < 0 {
                self.x.fadeInFromDef(delta: -x_over)
            }
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
    
    @discardableResult
    convenience init?(_ string: String, _ x: Float = 0, _ y: Float = 0, height: Float = 0.2,
                      appearTime: Double = 0.2, disappearTime: Double = 2.5, ceiledWidth: Float? = nil,
                     fadeY: Float? = nil)
    {
        guard let screen = PopMessage.defaultScreen, let frameTex = PopMessage.defaultFrameTex else {
            printerror("PopMessages statics not init.")
            return nil
        }
        let strTex = Texture.getConstantString(string)
        self.init(parent: screen, strTex: strTex, frameTex: frameTex, x, y, height, appearTime: appearTime, disappearTime: disappearTime,
                  ceiledWidth: ceiledWidth, fadeY: fadeY)
    }
    
    @discardableResult
    convenience init?(strTex: Texture, _ x: Float = 0, _ y: Float = 0, height: Float = 0.2,
                      appearTime: Double = 0.2, disappearTime: Double = 2.5, ceiledWidth: Float? = nil,
                     fadeY: Float? = nil)
    {
        guard let screen = PopMessage.defaultScreen, let frameTex = PopMessage.defaultFrameTex else {
            printerror("PopMessages statics not init.")
            return nil
        }
        self.init(parent: screen, strTex: strTex, frameTex: frameTex, x, y, height, appearTime: appearTime, disappearTime: disappearTime,
                  ceiledWidth: ceiledWidth, fadeY: fadeY)
    }
    
    @discardableResult
    convenience init?(over node: Node, message strTex: Texture, frameTex: Texture? = nil)
    {
        guard let screen = PopMessage.defaultScreen else {
            printerror("No default screen.")
            return nil
        }
        let frameTexture: Texture
        if let ft = frameTex {
            frameTexture = ft
        } else {
            guard let ft = PopMessage.defaultFrameTex else {
                printerror("No default frame texture.")
                return nil
            }
            frameTexture = ft
        }        
        let (pos, delta) = node.getAbsPosAndDelta()
        self.init(parent: screen, strTex: strTex, frameTex: frameTexture,
                  pos.x, pos.y, 1.1*delta.y,
                  appearTime: 0.1, disappearTime: 2.5, fadeY: 1.5*delta.y)
    }
}

*/
