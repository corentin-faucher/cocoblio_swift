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
           let char = event.characters
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
    private let textView: MyTextView
    private let fontname: String?
    private let refHtml: String?
    private let imageName: String?
    var imageRatio: CGFloat = 0.5
    #if os(OSX)
    private let scrollView: NSScrollView?
    private weak var imageView: NSImageView?
    #else
    private weak var imageView: UIImageView?
    #endif
    private unowned let root: AppRootBase
    private var textRatio: CGFloat
    
    var string: String {
        set {
            textView.string = newValue
        }
        get {
            textView.string
        }
    }
    
    @discardableResult
    init(_ refNode: Node?, root: AppRootBase, string: String?,
         editable: Bool, scrollable: Bool, asHtml: Bool,
         _ x: Float, _ y: Float,
         _ width: Float, _ height: Float, textHeightRatio: CGFloat,
         font: String? = nil, imageName: String? = nil)
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
        textView.textContainerInset = NSSize(width: 10, height: 10)
        if Language.currentIsRightToLeft {
            textView.alignment = .right
        } else {
            textView.alignment = .left
        }
        #else
        textView = MyTextView()
        if Language.currentIsRightToLeft {
            textView.textAlignment = .right
        } else {
            textView.textAlignment = .left
        }
        #endif
        
        self.fontname = font
        self.textRatio = textHeightRatio
        self.root = root
        self.refHtml = asHtml ? string : nil
        self.imageName = imageName
        super.init(refNode, x, y, width, height)
        if let string = string {
            textView.string = string // Référence pour resizing...
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
//
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
    
    /// Ne fait que changer la variable textRation, faire une "reshape" pour mettre à jour le textview.
    func changeTextRatio(_ newTextRatio: CGFloat) {
        textRatio = newTextRatio
    }
    
    private func updateText(frame: CGRect) {
        let systSize = FontManager.getSystemFontSize()
        let textSize = min(max(frame.height * textRatio, systSize), 2.5*systSize)
        let imageWidth = frame.width * imageRatio
        // 0. Placer l'image...
        if let imageName = imageName
        {
            // Cas déjà une image de créée
            if let imageView = imageView, let image = imageView.image {
                let size = NSSize(width: imageWidth, height: image.size.height * imageWidth / image.size.width)
                let rect = NSRect(origin: CGPoint(x: 10, y: 10), size: size)
                imageView.frame = rect
                image.size = size
                let imagePath = NSBezierPath(rect: rect)
                textView.textContainer?.exclusionPaths = [imagePath]
            }
            // Cas image non init
            else if let url = Bundle.main.url(forResource: imageName, withExtension: "png", subdirectory: "pngs"),
               let image = NSImage(contentsOf: url)
            {
                image.size = NSSize(width: imageWidth, height: image.size.height * imageWidth / image.size.width)
                let rect = NSRect(origin: CGPoint(x: 10, y: 10), size: image.size)
                let imagePath = NSBezierPath(rect: rect)
                textView.textContainer?.exclusionPaths = [imagePath]
                let newImageView = NSImageView(frame: rect)
                newImageView.image = image
                textView.addSubview(newImageView)
                self.imageView = newImageView
            }
        }
        // 1. Cas string ordinaire (pas html), juste mettre à jour le font.
        guard let textAttrStr = refHtml?.fromHtmlToAttributedString(size: textSize) else {
            if let fontname = fontname,
               let font = FontManager.getFont(name: fontname, size: textSize) {
                textView.font = font
            } else {
                textView.font = FontManager.currentWithSize(textSize)
            }
            return
        }
        textView.textStorage?.setAttributedString(textAttrStr)
    }
    
    override func open() {
        super.open()
        let (pos, delta) = getAbsPosAndDelta()
        let frame = root.getFrameFrom(pos, deltas: delta)
        updateText(frame: frame)
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
        updateText(frame: frame)
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


