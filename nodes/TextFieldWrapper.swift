//
//  MyTextView.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-05-19.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

#if os(OSX)
import AppKit

fileprivate class MyTextField : NSTextField {
    init() {
        super.init(frame: NSRect())
        wantsLayer = true
        layer?.cornerRadius = 7
        layer?.borderWidth = 1
        // Bogue de font "noir" transparent...?
        layer?.backgroundColor = NSColor.black.cgColor
    }
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
    var string: String? {
        set {
            self.stringValue = newValue ?? ""
        }
        get {
            return self.stringValue
        }
    }
}
#else
import UIKit

class MyTextField : UITextField {
    init() {
        super.init(frame: CGRect())
        backgroundColor = .systemBackground
        borderStyle = .roundedRect
        autocorrectionType = .no
        autocapitalizationType = .none
        inputAccessoryView = nil
        inputAssistantItem.leadingBarButtonGroups = []
        inputAssistantItem.trailingBarButtonGroups = []
        
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    var string: String? {
        set {
            self.text = newValue
        }
        get {
            return self.text
        }
    }
}
#endif

/** Wrapper pour UITextField ou NSTextField. Un TextField est un petit champ pour une simple string à entrer. */
class TextFieldWrapper : Node {
    private var textField: MyTextField!
    fileprivate unowned let root: AppRoot
    private let placeHolder: LocalizedString
    
    var string: String? {
        set {
            textField.string = newValue
        }
        get {
            return textField.string
        }
    }
    var number: Int? {
        return Int(textField.string ?? "")
    }
    
    @discardableResult
    init(_ refNode: Node?, root: AppRoot, string: String?, placeHolder: LocalizedString,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, flags: Int = 0)
    {
        self.placeHolder = placeHolder
        self.root = root
        super.init(refNode, x, y, width, height, flags: flags)
        textField = MyTextField()
        if let string = string {
            textField.string = string
        }
        // Cas particulier, il faut être visité lors d'un reshape (dépend de taille absolue).
        addRootFlag(Flag1.reshapableRoot)
    }
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func open() {
        super.open()
        let (pos, delta) = getAbsPosAndDelta()
        
        #if os(OSX)
        textField.placeholderString = placeHolder.localized
        #else
        textField.placeholder = placeHolder.localized
        #endif
        let frame = root.getFrameFrom(pos, deltas: delta)
        textField.font = FontManager.currentWithSize(frame.height * 0.7)
        textField.frame = frame
        
        root.metalView.addSubview(textField)
    }
    override func close() {
        super.close()
        textField.removeFromSuperview()
    }
    override func reshape() {
        let (pos, delta) = getAbsPosAndDelta()
        let frame = root.getFrameFrom(pos, deltas: delta)
        textField.font = FontManager.currentWithSize(frame.height * 0.7)
        textField.frame = frame
    }
}


