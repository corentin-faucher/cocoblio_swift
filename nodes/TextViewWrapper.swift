//
//  WrapperTextView.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-06-18.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation

#if os(OSX)
import AppKit

class MyTextView : NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown,
           (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey,
           let char = event.charactersIgnoringModifiers
        {
            switch char {
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self) {
                        return true
                    }
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self) {
                        return true
                    }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self) {
                        return true
                    }
                case "a":
                    if NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self) {
                        return true
                    }
                default: break
            }
            
        }
        return super.performKeyEquivalent(with: event)
    }
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    
}


fileprivate extension NSView {
    func setCorners() {
        wantsLayer = true
        layer?.cornerRadius = 5
    }
}
#else
import UIKit

class MyTextView : UITextView {
    init() {
        super.init(frame: CGRect(), textContainer: nil)
        
        layer.cornerRadius = 5
        autocorrectionType = .no
        autocapitalizationType = .none
        inputAccessoryView = nil
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var string: String {
        set {
            self.text = newValue
        }
        get {
            return self.text
        }
    }
}
#endif

/** Wrapper pour UITextView ou NSTextView. Un TextView est un "grand" champ pour une longue string à éditer/afficher. */
class TextViewWrapper : Node {
    let textView: MyTextView
    #if os(OSX)
    let scrollView: NSScrollView?
    #endif
    private unowned let root: AppRoot
    private let textRatio: CGFloat
    
    @discardableResult
    init(_ refNode: Node?, root: AppRoot, string: String?, editable: Bool, scrollable: Bool,
         // linkSubString: String? = nil,
         _ x: Float, _ y: Float, _
            width: Float, _ height: Float, textHeightRatio: CGFloat)
    {
        // 0. Init textView, scrollView
        #if os(OSX)
        if scrollable {
            scrollView = MyTextView.scrollableTextView()// NSTextView.scrollableTextView()
            scrollView?.setCorners()
            textView = scrollView?.documentView as! MyTextView
        } else {
            scrollView = nil
            textView = MyTextView()
            textView.setCorners()
        }
        #else
        textView = MyTextView()
        #endif
        
        self.textRatio = textHeightRatio
        self.root = root
        super.init(refNode, x, y, width, height)
        if let string = string {
            textView.string = string
        }
        textView.isEditable = editable
        
        textView.isSelectable = true
        // Cas particulier, il faut être visité lors d'un reshape (dépend de taille absolue).
        addRootFlag(Flag1.reshapableRoot)
        
        
//        if let string = string, let link = linkSubString, !editable {
//            let attrStr = NSMutableAttributedString(string: string)
//            let nsstring = NSString(string: string)
//            let range = nsstring.range(of: link)
//            guard range.location != NSNotFound else {
//                printwarning("link \(link) not in textview string.")
//                return
//            }
//            let url = URL(string: link)!
//
//            attrStr.setAttributes([.link: url], range: range)
//            textView.textStorage?.setAttributedString(attrStr)
//            textView.linkTextAttributes = [
//                .foregroundColor: NSColor.blue,
//                .underlineStyle: NSUnderlineStyle.single.rawValue
//            ]
//        }
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func open() {
        super.open()
        let (pos, delta) = getAbsPosAndDelta()
        let frame = root.getFrameFrom(pos, deltas: delta)
        textView.font = Texture.getAppleFont(size: max(frame.height * textRatio, 14))
        #if os(OSX)
        if let scrollView = scrollView {
            root.metalView.addSubview(scrollView)
            scrollView.frame = frame
        } else {
            root.metalView.addSubview(textView)
            textView.frame = frame
        }
        #else
        root.metalView.addSubview(textView)
        textView.frame = frame
        #endif
    }
    override func close() {
        super.close()
        #if os(OSX)
        if let scrollView = scrollView {
            scrollView.removeFromSuperview()
        } else {
            textView.removeFromSuperview()
        }
        #else
        textView.removeFromSuperview()
        #endif
    }
    
    override func reshape() {
        let (pos, delta) = getAbsPosAndDelta()
        let frame = root.getFrameFrom(pos, deltas: delta)
        textView.font = Texture.getAppleFont(size: max(frame.height * textRatio, 14))
        #if os(OSX)
        if let scrollView = scrollView {
            scrollView.frame = frame
        } else {
            textView.frame = frame
        }
        #else
        textView.frame = frame
        #endif
    }
}


