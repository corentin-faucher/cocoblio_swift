//
//  CharacterAndString.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-10-19.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation
import CoreGraphics
#if os(OSX)
import AppKit
import Carbon
import Carbon.HIToolbox
#endif

extension Character {
    func toUInt32() -> UInt32 {
        guard let us = self.unicodeScalars.first else {printerror("Cannot convert char \(self) to UInt32."); return 0}
        return us.value
    }
    var isAlphaNumeric: Bool {
        return String(self).rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
    }
    var isDigit: Bool {
        return digitCharacters.contains(self)
    }
    var isLatin: Bool {
        return String(self).rangeOfCharacter(from: CharacterSet.uppercaseLetters.union(.lowercaseLetters)) != nil
    }
    // Hanzi / Kanji
    var isIdeogram: Bool {
        let unicode = self.toUInt32()
        // Commence aux 0x3400 CJK Unified Ideographs Extension A
        // Finit avant les 0xA000 "Yi Syllables" (pas de ponctuations chinoises)
        return (unicode >= 0x3400) && (unicode < 0xA000)
    }
    /** Retourne la version standard d'un charactère. e.g. « -> " ou ？ -> ?.  */
    func toNormalized(forceLower: Bool) -> Character {
        if isNewline {
            return SpChar.return_
        }
        if self == "、" {
            if Language.currentIs(.japanese) {
                return ","
            } else {
                return "\\"
            }
        }
        if let normalized = normalizedCharOf[self] {
            return normalized
        }
        if forceLower {
            return Character(self.lowercased())
        }
        return self
    }
    
    /** Version simplifié de toNormalized. (pas pour langue asiatique) */
    var loweredAndNormalized: Character {
        if isNewline {
            return SpChar.return_
        }
        if let normalized = limitedNormalizedCharOf[self] {
            return normalized
        }
        return Character(self.lowercased())
    }
    
//    var isEmoji: Bool {
//        guard let firstScalar = self.unicodeScalars.first else { return false }
//        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
//    }
//    func isLetter() -> Bool {
//        return String(self).rangeOfCharacter(from: CharacterSet.letters)
//    }
}

fileprivate let digitCharacters: [Character] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
fileprivate let normalizedCharOf: [Character: Character] = [
    SpChar.ideographicSpace : SpChar.space,
    SpChar.nobreakSpace : SpChar.space,
    "，" : ",",
    "。" : ".",
    "；" : ";",
    "：" : ":",
    "—" : "-",  // "EM Dash"
    "–" : "-",  // "EN Dash"
    "ー" : "-", // (Prolongation pour Katakana)
    "・" : "/",
    "！" : "!",
    "？" : "?",
    "’" : "'",
    "«" : "\"",
    "»" : "\"",
    "“" : "\"", // Left double quotation mark
    "”" : "\"", // Right double quotation mark (ça paraît pas mais ils sont différents...)
    "（" : "(",
    "）" : ")",
    "「" : "[",
    "」" : "]",
    "『" : "{",
    "』" : "}",
    "《" : "<",
    "》" : ">",
    "［" : "[",
    "］" : "]",
    "｛" : "{",
    "｝" : "}",
    "【" : "[",
    "】" : "]",
    "％" : "%",
    "＊" : "*",
    "／" : "/",
    "｜" : "|",
    "＝" : "=",
    "－" : "-",  // Tiret chinois, different du katakana "ー" plus haut.
]


fileprivate let limitedNormalizedCharOf: [Character: Character] = [
    SpChar.nobreakSpace : SpChar.space,
    "’" : "'",
    "«" : "\"",
    "»" : "\"",
    "“" : "\"", // Left double quotation mark
    "”" : "\"", // Right double quotation mark (ça paraît pas mais ils sont différents...)
    "—" : "-",  // "EM Dash"
    "–" : "-",  // "EN Dash"
    // Le reste est pour le chinois et japonais...
//    SpChar.ideographicSpace : SpChar.space,
//    "，" : ",",
//    "。" : ".",
//    "；" : ";",
//    "：" : ":",
//    "ー" : "-", // (Prolongation pour Katakana)
//    "・" : "/",
//    "！" : "!",
//    "？" : "?",
//    "（" : "(",
//    "）" : ")",
//    "「" : "[",
//    "」" : "]",
//    "『" : "{",
//    "』" : "}",
//    "《" : "<",
//    "》" : ">",
//    "［" : "[",
//    "］" : "]",
//    "｛" : "{",
//    "｝" : "}",
//    "【" : "[",
//    "】" : "]",
//    "％" : "%",
//    "＊" : "*",
//    "／" : "/",
//    "｜" : "|",
//    "＝" : "=",
//    "－" : "-",  // Tiret chinois, different du katakana "ー" plus haut.
]


extension UInt32 {
    func toCharacter() -> Character {
        guard let us = Unicode.Scalar(self) else {printerror("Cannot convert UInt32 \(self) to char"); return "?"}
        return Character(us)
    }
}

/*
extension NSMutableAttributedString {
    func resizeFont(to size: CGFloat)
    {
        let scaling = size / FontManager.getSystemFontSize()
        printdebug("Resizing AttrStr syst, scaling \(scaling)")
        
        beginEditing()
        #if os(OSX)
        enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { (value, range, stop) in
            if let font = value as? NSFont {
                let descr = font.fontDescriptor.withFamily(font.familyName!).withSymbolicTraits(font.fontDescriptor.symbolicTraits)
                printdebug("el size: \(descr.pointSize)")
                if let newFont = NSFont(descriptor: descr, size: size) {
                    removeAttribute(.font, range: range)
                    addAttribute(.font, value: newFont, range: range)
                }                
            }
        }
        #else
        ...
        #endif
        endEditing()
    }
}
*/

extension String {
    func fromHtmlToAttributedString(size: CGFloat) -> NSAttributedString?
    {
        let size_pt = size * 0.75
        let strWithFont = String(format:
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="author" content="Corentin Faucher">
            <!-- <title>Titre</title> -->
            <!-- <style> p {    line-height: 1.5; }</style> -->
        </head>
        <body style="font-family: '-apple-system', 'HelveticaNeue'; font-size: \(size_pt)pt;
            text-align: justify; line-height:1.7">
            %@
        </body>
        </html>
        """, self)
        guard let data = strWithFont.data(using: .utf8) else {
            printerror("Cannot convert string to data.")
            return nil
        }
        guard let attrStr = try? NSAttributedString(
            data: data,
            options: [
             .documentType: NSAttributedString.DocumentType.html,
             .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil)
        else {
            printerror("Cannot create attributed string from data.")
            return nil
        }
        return attrStr
    }
    
    func substring(lowerIndex: Int, exHighIndex: Int) -> String? {
        guard lowerIndex < count, lowerIndex < exHighIndex else {
            return nil
        }
        let start = index(startIndex, offsetBy: lowerIndex)
        let end = index(start, offsetBy: min(exHighIndex - lowerIndex,
                                             count - lowerIndex))
        return String(self[start..<end])
    }
    func substring(atIndex: Int) -> String? {
        return substring(lowerIndex: atIndex, exHighIndex: atIndex+1)
    }
    func char(atIndex: Int) -> Character? {
        return substring(lowerIndex: atIndex, exHighIndex: atIndex+1)?.first
    }
    func firstLetterCapitalized() -> String {
        guard let first = self.first else { return self }
        return String(first).capitalized + self.dropFirst()
    }
    func isLessThan(_ other: String) -> Bool {
        return self.localizedStandardCompare(other) == .orderedAscending
    }
    /** Une petite string d'emoji (choisir blanc pour l'affichage). */
    var isShortEmoji: Bool {
        guard count < 3, let first = first, let firstScalar = first.unicodeScalars.first else { return false }
        return firstScalar.properties.isEmoji && firstScalar.value > 0x238C
    }
}

protocol KeyboardKey {
    var keycode: UInt16 { get }
    var keymod: UInt { get }
    var isVirtual: Bool { get }
    var char: Character? { get }
}

struct KeyData : KeyboardKey {
    var keycode: UInt16
    var keymod: UInt
    var isVirtual: Bool
    var char: Character?
}

/** Les char spéciaux et "importans" */
enum SpChar {
    static let delete: Character = "\u{8}"
    static let tab: Character = "\t"
    static let return_: Character = "\r"
//    static let newline: Character = "\n"
    static let space: Character = " "
    static let nobreakSpace: Character = " "
    static let ideographicSpace: Character = "　"
    static let thinSpace: Character = "\u{2009}"
    static let bottomBracket: Character = "⎵"
    static let spaceSymbol: Character = "␠"
    static let underscore: Character = "_"
    static let openBox: Character = "␣"
    static let interpunct: Character = "·"
    static let dot: Character = "•"
    static let butterfly: Character = "🦋"
    static let dodo: Character = "🦤"
}

/** MyKeyCode... */
enum MKC {
    static let space = 51 // (Fait parti des Keycode "ordinaire")
    // Keycodes spéciaux ayant une string associable
    static let delete = 52
    static let return_ = 53
    static let tab = 54
    // Keycodes de contrôle
    static let capsLock = 60
    static let control = 61
    static let shift = 62
    static let option = 63
    static let command = 64
    static let rightControl = 65
    static let rightShift = 66
    static let rightOption = 67
    static let rightCommand = 68
    // Autre Keycodes Spéciaux
    static let escape = 70
    static let eisu = 71
    static let kana = 72
    // Pour les "autres" non définie (e.g. fn, kana...)
    static let empty = 99
}

enum Keycode {
    #if os(OSX)
    // Voir hitoolbox events.h...
    // Touches modifier
    static let command: UInt16 = 0x37
    static let shift: UInt16 = 0x38
    static let capsLock: UInt16 = 0x39
    static let option: UInt16 = 0x3A
    static let control: UInt16 = 0x3B
    static let rightCommand: UInt16 = 0x36
    static let rightShift: UInt16 = 0x3C
    static let rightOption: UInt16 = 0x3D
    static let rightControl: UInt16 = 0x3E
    // Touche "importantes"
    static let return_: UInt16 = 0x24
    static let keypadEnter: UInt16 = 0x4C
    static let tab: UInt16 = 0x30
    static let space: UInt16 = 0x31
    static let delete: UInt16 = 0x33
    static let forwardDelete: UInt16 = 0x75
    static let escape: UInt16 = 0x35
    // Touches de directions
    static let leftArrow : UInt16 = 0x7B
    static let rightArrow: UInt16 = 0x7C
    static let downArrow: UInt16 = 0x7D
    static let upArrow: UInt16 = 0x7E
    // Touches spéciales ANSI, ISO, JIS
    static let ANSI_Backslash: UInt16 = 0x2A
    static let ANSI_Grave = 0x32
    static let ISO_section: UInt16 = 0x0A
    static let JIS_Yen: UInt16 = 0x5D
    static let JIS_Underscore: UInt16 = 0x5E
    static let JIS_kana: UInt16 = 0x68
    static let JIS_Eisu: UInt16 = 0x66 // 英数
    #else
    // Touches modifier
    static let capsLock: UInt16 = 0x39
    static let control: UInt16 = 0xE0
    static let shift: UInt16 = 0xE1
    static let option: UInt16 = 0xE2
    static let command: UInt16 = 0xE3
    static let rightControl: UInt16 = 0xE4
    static let rightShift: UInt16 = 0xE5
    static let rightOption: UInt16 = 0xE6
    static let rightCommand: UInt16 = 0xE7
    // Touche "importantes"
    static let return_: UInt16 = 0x28
    static let keypadEnter: UInt16 = 0x58
    static let tab: UInt16 = 0x2B
    static let space: UInt16 = 0x2C
    static let delete: UInt16 = 0x2A
    static let forwardDelete: UInt16 = 0x4C
    static let escape: UInt16 = 0x29
    // Touches de directions
    static let leftArrow : UInt16 = 0x50
    static let rightArrow: UInt16 = 0x4F
    static let downArrow: UInt16 = 0x51
    static let upArrow: UInt16 = 0x52
    // Touches spéciales ANSI, ISO, JIS
    static let ANSI_Backslash: UInt16 = 0x31
    static let ANSI_Grave = 0x35
    static let ISO_Backslash: UInt16 = 0x32
    static let ISO_section: UInt16 = 0x64
    static let JIS_Yen: UInt16 = 0x89
    static let JIS_Underscore: UInt16 = 0x87
    static let JIS_kana: UInt16 = 0x90
    static let JIS_Eisu: UInt16 = 0x91 // 英数
    #endif
    // Dummy "empty" (touche "vide" ne faisant rien)
    static let empty: UInt16 = 0xFF
}

enum Modifier {
    #if os(OSX)
    static let command: UInt = NSEvent.ModifierFlags.command.rawValue
    static let shift: UInt = NSEvent.ModifierFlags.shift.rawValue
    static let capsLock: UInt = NSEvent.ModifierFlags.capsLock.rawValue
    static let option: UInt = NSEvent.ModifierFlags.option.rawValue
    static let control: UInt = NSEvent.ModifierFlags.control.rawValue
    #else
    static let command: UInt =  0x100000
    static let shift: UInt =    0x020000
    static let capsLock: UInt = 0x010000
    static let option: UInt =   0x080000
    static let control: UInt =  0x040000
    #endif
    static let optionShift = shift | option
    static let commandShift = command | shift
}

let charOfKeypadKeycode: [UInt16:Character] = [
    0x41 : ".",
    0x43 : "*",
    0x45 : "+",
    0x4B : "/",
    0x4C : SpChar.return_,
    0x4E : "-",
    0x51 : "=",
    0x52 : "0",
    0x53 : "1",
    0x54 : "2",
    0x55 : "3",
    0x56 : "4",
    0x57 : "5",
    0x58 : "6",
    0x59 : "7",
    0x5B : "8",
    0x5C : "9"
]
