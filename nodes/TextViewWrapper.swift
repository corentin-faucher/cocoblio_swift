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

class MyTextView : NSTextView, NSTextViewDelegate {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == Modifier.command,
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
                case "z":
                    if NSApp.sendAction(#selector(self.undo), to: nil, from: self) {
                        return true
                    }
                default: break
                }
            } else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue)
                        == Modifier.commandShift {
                if event.characters == "z", NSApp.sendAction(#selector(self.redo), to: nil, from: self) {
                    return true
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
    
    @objc func undo() {
        self.undoManager?.undo()
    }
    @objc func redo() {
        self.undoManager?.redo()
    }
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        undoManager?.beginUndoGrouping()
        return true
    }
    func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
        undoManager?.beginUndoGrouping()
        return true
    }
    override func didChangeText() {
        undoManager?.endUndoGrouping()
    }
}

fileprivate extension NSView {
    func setCorners() {
        wantsLayer = true
        layer?.cornerRadius = 5
    }
}
#else
import UIKit

extension UIColor {
    static var myTextColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { (traits) -> UIColor in
                return traits.userInterfaceStyle == .dark ? .lightText : .darkText
            }
        } else {
            return .darkText
        }
    }
}

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
    var imageRight: Bool = false
    var textRatio: CGFloat
    #if os(OSX)
    private let scrollView: NSScrollView?
    private weak var imageView: NSImageView?
    #else
    private weak var imageView: UIImageView?
    #endif
    private unowned let root: AppRootBase
    
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
//        #warning("check scroll view...")
        if scrollable {
            scrollView = MyTextView.scrollableTextView()// NSTextView.scrollableTextView()
            scrollView?.setCorners()
            textView = scrollView?.documentView as! MyTextView
        } else {
            scrollView = nil
            textView = MyTextView()
            textView.setCorners()
        }
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 20, height: 20)
        textView.delegate = textView
        if Language.currentIsRightToLeft {
            textView.alignment = .right
        } else {
            textView.alignment = .left
        }
        #else
        textView = MyTextView()
        if BuildConfig.phone {
            textView.textContainerInset = UIEdgeInsets(top: 20, left: 7, bottom: 20, right: 7)
        } else {
            textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }
        if Language.currentIsRightToLeft {
            textView.textAlignment = .right
        } else {
            textView.textAlignment = .left
        }
        #endif
        if let string = string {
            textView.string = string // Référence pour resizing...
        }
        textView.isEditable = editable
        textView.isSelectable = true
        // Html ?
        if asHtml, let file_name = string {
            refHtml = String(localizedHtml: file_name)
        } else {
            refHtml = nil
        }
        self.fontname = font
        self.textRatio = textHeightRatio
        self.root = root
        self.imageName = imageName
        super.init(refNode, x, y, width, height)        
        // Cas particulier, il faut être visité lors d'un reshape (dépend de taille absolue).
        addRootFlag(Flag1.reshapableRoot)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    private func updateText(frame: CGRect) {
        let systSize = FontManager.getSystemFontSize()
        let textSize = min(max(min(frame.height * textRatio, frame.width * textRatio), systSize), 2.5*systSize)
        // 0. Placer l'image...
        if let imageName = imageName
        {
            #if os(OSX)
            // Cas déjà une image de créée
            if imageView != nil {
                updateImageView(frame: frame)
            }
            // Cas image non init
            else if let url = Bundle.main.url(forResource: imageName, withExtension: "png", subdirectory: "pngs"),
               let image = NSImage(contentsOf: url)
            {
                let newImageView = NSImageView()
                newImageView.image = image
                textView.addSubview(newImageView)
                self.imageView = newImageView
                updateImageView(frame: frame)
            }
            #else
            // Cas déjà une image de créée
            if imageView != nil {
                updateImageView(frame: frame)
            }
            // Cas image non init
            else if let url = Bundle.main.url(forResource: imageName, withExtension: "png", subdirectory: "pngs"),
                    let image = UIImage(contentsOfFile: url.path)
            {
                let newImageView = UIImageView()
                newImageView.image = image
                textView.addSubview(newImageView)
                self.imageView = newImageView
                updateImageView(frame: frame)
            }
            #endif
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
        #if os(OSX)
        textView.textStorage?.setAttributedString(textAttrStr)
        textView.textColor = .textColor
        #else
        textView.textStorage.setAttributedString(textAttrStr)
        textView.textColor = .myTextColor
        #endif
    }
    
    private func updateImageView(frame: CGRect)
    {
        guard let imageView = imageView, let image = imageView.image else {
            printerror("No image or imageView...")
            return
        }
        let imageWidth = frame.width * imageRatio
        let imageHeight = image.size.height * imageWidth / image.size.width
        #if os(OSX)
        let pathRect = NSRect(x: imageRight ? frame.width - 50 - imageWidth : 10,
                              y: 10,
                              width: imageRight ? imageWidth + 40 : imageWidth + 10,
                              height: imageHeight + 10)
        let imageRect = NSRect(x: imageRight ? frame.width - 20 - imageWidth : 20,
                               y: 20, width: imageWidth, height: imageHeight)
        let imagePath = NSBezierPath(rect: pathRect)
        textView.textContainer?.exclusionPaths = [imagePath]
        imageView.frame = imageRect
        image.size = NSSize(width: imageWidth, height: imageHeight)
        #else
        let pathRect = CGRect(x: imageRight ? frame.width - 50 - imageWidth : 10,
                              y: 10,
                              width: imageRight ? imageWidth + 40 : imageWidth + 10,
                              height: imageHeight + 10)
        let imageRect = CGRect(x: imageRight ? frame.width - 20 - imageWidth : 20,
                               y: 20, width: imageWidth, height: imageHeight)
        let imagePath = UIBezierPath(rect: pathRect)
        textView.textContainer.exclusionPaths = [imagePath]
        imageView.frame = imageRect
//        image.size = CGSize(width: imageWidth, height: imageHeight)
        #endif
    }
    
    override func open() {
        super.open()
        let (pos, delta) = positionAndDeltaAbsolute()
        let frame = root.getFrameFrom(pos, deltas: delta)
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
        updateText(frame: frame)
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
        let (pos, delta) = positionAndDeltaAbsolute()
        let frame = root.getFrameFrom(pos, deltas: delta)
        #if os(OSX)
        if let scrollView = scrollView {
            scrollView.frame = frame
        } else {
            textView.frame = frame
        }
        #else
        textView.frame = frame
        #endif
        updateText(frame: frame)
    }
}


