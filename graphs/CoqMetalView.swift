//
//  CoqMetalView.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-12-01.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

protocol CoqMetalView : MTKView {
    var root: AppRootBase! { get }
    var renderer: Renderer! {get }
    var isTransitioning: Bool { get set }
    /* Juste pour macOS (pause automatique quand on change d'application) */
    var canPauseWhenResignActive: Bool { get set }
    
    /** Le vrai frame de la vue y compris les bords où il ne devrait pas y avoir d'objet importants). */
    var fullFrame: CGSize { get set }
    /** Le frame utilisable un rectangle dans fullFrame, i.e. les dimensions "utiles", sans les bords. */
    var usableFrame: CGRect { get set }
    
    func setBackground(color: Vector3, isDark: Bool)
    
    // Pour la détection du scrolling dans iOS...
    func addScrollingViewIfNeeded(with slidingMenu: SlidingMenu)
    func removeScrollingView()
}

fileprivate let ratioMin: CGFloat = 0.54
fileprivate let ratioMax: CGFloat = 1.85

extension CoqMetalView {
    func getNormalizePositionFrom(_ locationInView: CGPoint, invertedY: Bool) -> Vector2 {
        return Vector2(Float((locationInView.x / bounds.width - 0.5) * fullFrame.width),
                       Float((invertedY ? -1 : 1) * (locationInView.y / bounds.height - 0.5) * fullFrame.height - usableFrame.origin.y))
    }
    func getLocationFrom(_ normalizedPos: Vector2, invertedY: Bool) -> CGPoint {
        return CGPoint(x: (CGFloat(normalizedPos.x) / fullFrame.width + 0.5) * bounds.width,
                       y: ((CGFloat(normalizedPos.y) + usableFrame.origin.y) / (fullFrame.height * (invertedY ? -1 : 1)) + 0.5) * bounds.height)
    }
    func getFrameFrom(_ pos: Vector2, deltas: Vector2, invertedY: Bool) -> CGRect {
        let width = 2 * CGFloat(deltas.x) / fullFrame.width * bounds.width
        let height = 2 * CGFloat(deltas.y) / fullFrame.height * bounds.height
        return CGRect(x: (CGFloat(pos.x - deltas.x) / fullFrame.width + 0.5) * bounds.width,
                      y: ((CGFloat(pos.y - (invertedY ? -1 : 1) * deltas.y) + usableFrame.origin.y) / (fullFrame.height * (invertedY ? -1 : 1)) + 0.5) * bounds.height,
                      width: width,
                      height: height)
    }
    func updateFrame() {
        let realRatio = frame.width / frame.height
        #if os(OSX)
        guard let window = window else {printerror("No window."); return}
        let headerHeight = window.styleMask.contains(.fullScreen) ? 22 : window.frame.height - window.contentLayoutRect.height
        
        let ratioT: CGFloat = headerHeight / window.frame.height + 0.005
        let ratioB: CGFloat = 0.005
        let ratioLR: CGFloat = 0.01
        #else
        let sa = safeAreaInsets
        let ratioT: CGFloat = sa.top / frame.height + 0.01
        let ratioB: CGFloat = sa.bottom / frame.height + 0.01
        let ratioLR: CGFloat = (sa.left + sa.right) / frame.width + 0.015
        #endif
        
        // 1. Full Frame
        if realRatio > 1 { // Landscape
            fullFrame.height = 2 / ( 1 - ratioT - ratioB)
            fullFrame.width = realRatio * fullFrame.height
        }
        else {
            fullFrame.width = 2 / (1 - ratioLR)
            fullFrame.height = fullFrame.width / realRatio
        }
        // 2. Usable Frame
        if realRatio > 1 { // Landscape
            usableFrame.size.width = min((1 - ratioLR) * fullFrame.width, 2 * ratioMax)
            usableFrame.size.height = 2
        }
        else {
            usableFrame.size.width = 2
            usableFrame.size.height = min((1 - ratioT - ratioB) * fullFrame.height, 2 / ratioMin)
        }
        usableFrame.origin.x = 0
        usableFrame.origin.y = (ratioB - ratioT) * fullFrame.height / 2
    }
    #if !os(OSX)
    func updateFrameInTransition() {
        guard let tmpBounds = layer.presentation()?.bounds else {
            printerror("Pas de presentation layer."); return
        }
        let sa = safeAreaInsets
        let ratioT: CGFloat = sa.top / frame.height + 0.01
        let ratioB: CGFloat = sa.bottom / frame.height + 0.01
        let ratioLR: CGFloat = (sa.left + sa.right) / frame.width + 0.015
        
        let realRatio = tmpBounds.width / tmpBounds.height
        // 1. Full Frame
        if realRatio > 1 { // Landscape
            fullFrame.height = 2 / ( 1 - ratioT - ratioB)
            fullFrame.width = realRatio * fullFrame.height
        }
        else {
            fullFrame.width = 2 / (1 - ratioLR)
            fullFrame.height = fullFrame.width / realRatio        }
    }
    #endif
}
