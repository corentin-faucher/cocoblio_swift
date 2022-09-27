//
//  MyTextView.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-05-19.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

#if os(OSX)
import AppKit
fileprivate let text_relative_height: CGFloat = 0.65

class MyTextField : NSTextField {
    init() {
        super.init(frame: NSRect())
//        cell = MyTextFieldCell()
        maximumNumberOfLines = 0
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
fileprivate let text_relative_height: CGFloat = 0.65

class MyTextField : UITextField {
    init() {
        super.init(frame: CGRect())
        if #available(iOS 13.0, *) {
            backgroundColor = .systemBackground
        }
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
    fileprivate unowned let root: AppRootBase
    private let placeHolder: String
    
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
    
    #if os(OSX)
    @discardableResult
    init(_ refNode: Node?, root: AppRootBase, string: String?, placeHolder: String,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, flags: Int = 0, delegate: NSTextFieldDelegate? = nil)
    {
        self.placeHolder = placeHolder
        self.root = root
        super.init(refNode, x, y, width, height, flags: flags)
        textField = MyTextField()
        textField.delegate = delegate
        if let string = string {
            textField.string = string
        }
        if Language.currentIsRightToLeft {
            textField.alignment = .right
        } else {
            textField.alignment = .left
        }
        // Cas particulier, il faut être visité lors d'un reshape (dépend de taille absolue).
        addRootFlag(Flag1.reshapableRoot)
    }
    #else
    @discardableResult
    init(_ refNode: Node?, root: AppRoot, string: String?, placeHolder: String,
         _ x: Float, _ y: Float, _ width: Float, _ height: Float, flags: Int = 0, delegate: UITextFieldDelegate? = nil)
    {
        self.placeHolder = placeHolder
        self.root = root
        super.init(refNode, x, y, width, height, flags: flags)
        textField = MyTextField()
        textField.delegate = delegate
        if let string = string {
            textField.string = string
        }
        if Language.currentIsRightToLeft {
            textField.textAlignment = .right
        } else {
            textField.textAlignment = .left
        }
        // Cas particulier, il faut être visité lors d'un reshape (dépend de taille absolue).
        addRootFlag(Flag1.reshapableRoot)
    }
    #endif
    required init(other: Node) {
        fatalError("init(other:) has not been implemented")
    }
    
    override func open() {
        super.open()
        let (pos, delta) = getPosAndDeltaAbsolute()
        
        #if os(OSX)
        textField.placeholderString = placeHolder
        #else
        textField.placeholder = placeHolder
        #endif
        let frame = root.getFrameFrom(pos, deltas: delta)
        textField.font = FontManager.currentWithSize(text_relative_height * frame.height)
        textField.frame = frame
        
        root.metalView.addSubview(textField)
    }
    override func close() {
        super.close()
        textField.removeFromSuperview()
    }
    override func reshape() {
        let (pos, delta) = getPosAndDeltaAbsolute()
        let frame = root.getFrameFrom(pos, deltas: delta)
        textField.font = FontManager.currentWithSize(text_relative_height * frame.height)
        textField.frame = frame
    }
}


