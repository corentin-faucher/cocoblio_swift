//
//  MyFonts.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-08-06.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation
import AppKit

typealias FontInfo = (size_y: CGFloat, size_x: CGFloat)

enum FontManager {
    static var current: NSFont = NSFont.systemFont(ofSize: 24) {
        didSet {
            if oldValue.fontName != current.fontName || oldValue.pointSize != current.pointSize {
                Texture.redrawAllStrings()
            }
        }
    }
    static var currentInfo: FontInfo = defaultInfo
    
    static func setCurrent(to fontname: String) {
        let fontnames = getFontNamesForCurrentLanguage()
        guard fontnames.contains(fontname) else {
            printerror("Font \(fontname) not valid for language \(Language.current).")
            current = NSFont.systemFont(ofSize: current.pointSize)
            currentInfo = defaultInfo
            return
        }
        guard let font = NSFont(name: fontname, size: current.pointSize) else {
            printerror("Cannot generate font \(fontname).")
            current = NSFont.systemFont(ofSize: current.pointSize)
            currentInfo = defaultInfo
            return
        }
        current = font
        guard let info = fontInfoDic[fontname] else {
            printerror("No info for \(fontname).")
            currentInfo = defaultInfo
            return
        }
        currentInfo = info
    }
    
    static func setCurrentToDefault() {
        let name: String
        switch Language.current {
            case .japanese: name = "Hiragino Maru Gothic ProN"
            case .korean: name = "AppleMyungjo"
            default: name = "American Typewriter"
        }
        setCurrent(to: name)
    }
    
    static func getFontInfo(_ fontname: String) -> FontInfo {
        return fontInfoDic[fontname] ?? defaultInfo
    }
    
    static func getFontNamesForCurrentLanguage() -> [String] {
        if let names = availableFontNamesByLanguage[Language.current] {
            return names
        } else {
            return defaultAvailableFontNames
        }
    }
    
    static func currentWithSize(_ size: CGFloat) -> NSFont {
        if #available(macOS 10.15, *) {
            return current.withSize(size)
        } else {
            if let newfont = NSFont(descriptor: current.fontDescriptor, size: size) {
                return newfont
            } else {
                printerror("Error resizing font \(current.fontName).")
                return NSFont.systemFont(ofSize: size)
            }
        }
    }
    
    static func updateCurrentSize(with drawableSize: CGSize) {
        // Calcul de la taille approprié en fonction de la taille de l'écran.
        let candidateFontSize = min(max(fontSizeRatio * min(drawableSize.width, drawableSize.height), minFontSize), maxFontSize)
        // On redesine les strings seulement si un changement significatif.
        guard (candidateFontSize/current.pointSize > 1.25) || (candidateFontSize/current.pointSize < 0.75) else { return }
        
        current = currentWithSize(candidateFontSize)
    }
    
    static let shortNames: [String: String] = [
        "American Typewriter": "Amer. Typ.",
        "Chalkboard SE": "Chalkboard",
        "Chalkduster": "Chalkduster",
        "Courier": "Courier",
        "Futura": "Futura",
        "Helvetica": "Helvetica",
        "Luciole": "Luciole",
        "Snell Roundhand": "Snell Round.",
        "Times New Roman": "Times New R.",
        "Verdana": "Verdana",
        "Nanum Gothic": "Nanum Got.",
        "Nanum Pen Script": "Nanum Pen",
        "BM Kirang Haerang": "Kirang",
        "GungSeo": "GungSeo",
        "PilGi": "PilGi",
        "Hiragino Maru Gothic ProN": "Hira. Maru",
        "Hiragino Mincho ProN": "Hira. Mincho",
        "Klee": "Klee",
        "Osaka": "Osaka",
        "Toppan Bunkyu Gothic": "Toppan",
        "Tsukushi A Round Gothic": "Tsukushi",
        "YuKyokasho Yoko": "YuKyokasho",
        "YuMincho": "YuMincho",
        "Apple LiSung": "LiSung",
        "Baoli SC": "Baoli",
        "GB18030 Bitmap": "Bitmap",
        "HanziPen SC": "HanziPen",
        "Hei": "Hei",
        "LingWai TC": "LingWai",
        "AppleMyungjo": "Myungjo",
        "PingFang SC": "PingFang",
        "Weibei SC": "Weibei",
        "Farah": "Farah",
    ]
    
    static private let fontSizeRatio: CGFloat = 0.065 // Hauteur de string à ~1/15 de la hauteur de l'écran.
    static private let minFontSize: CGFloat = 12
    static private let maxFontSize: CGFloat = 144
    static private let fontInfoDic: [String: FontInfo] = [
        "American Typewriter": (size_y: 1.1, size_x: 1),
        "Chalkboard SE": (size_y: 1.25, size_x: 1),
        "Chalkduster": (size_y: 1.55, size_x: 1.2),
        "Courier": (size_y: 1.30, size_x: 0.5),
        "Futura": (size_y: 1.4, size_x: 0.0),
        "Helvetica": (size_y: 1.1, size_x: 0.3),
        "Luciole": (size_y: 1.3, size_x: 0.6),
        "Snell Roundhand": (size_y: 1.85, size_x: 6),
        "Times New Roman": (size_y: 1.3, size_x: 0.8),
        "Verdana": (size_y: 1.2, size_x: 0.5),
        "Nanum Gothic": (size_y: 1.3, size_x: 0),
        "Nanum Pen Script": (size_y: 1.3, size_x: 0),
        "BM Kirang Haerang": (size_y: 1.3, size_x: 0),
        "GungSeo": (size_y: 1.3, size_x: 0),
        "PilGi": (size_y: 1.6, size_x: 0.3),
        "Hiragino Maru Gothic ProN": (size_y: 1.3, size_x: 0),
        "Hiragino Mincho ProN": (size_y: 1.3, size_x: 0),
        "Klee": (size_y: 1.3, size_x: 0),
        "Osaka": (size_y: 1.3, size_x: 0),
        "Toppan Bunkyu Gothic": (size_y: 1.3, size_x: 0),
        "Tsukushi A Round Gothic": (size_y: 1.3, size_x: 0),
        "YuKyokasho Yoko": (size_y: 1.3, size_x: 0),
        "YuMincho": (size_y: 1.3, size_x: 0),
        "Apple LiSung": (size_y : 1.3, size_x: 0),
        "Baoli SC": (size_y : 1.3, size_x: 0),
        "GB18030 Bitmap": (size_y : 1, size_x: 1),
        "HanziPen SC": (size_y : 1.3, size_x: 0),
        "Hei": (size_y : 1.3, size_x: 0),
        "LingWai TC": (size_y : 1.2, size_x: 0.9),
        "AppleMyungjo": (size_y : 1.25, size_x: 0.5),
        "PingFang SC": (size_y : 1.3, size_x: 0),
        "Weibei SC": (size_y : 1.3, size_x: 0),
        "Farah": (size_y: 1.3, size_x: 0.5),
    ]
    static private let defaultInfo: FontInfo = (1.3, 1.0)
    static private let availableFontNamesByLanguage: [Language : [String]] = [
        .arabic : [
            "American Typewriter",
            "Courier",
            "Farah",
        ],
        .japanese : [
            "American Typewriter",
            "Chalkboard SE",
            "Courier",
            "Futura",
            "Helvetica",
            "Hiragino Maru Gothic ProN",
            "Klee",
            "LingWai TC",
            "Osaka",
            "PilGi",
            "Toppan Bunkyu Gothic",
            "Tsukushi A Round Gothic",
            "Verdana",
            "YuKyokasho Yoko",
            "YuMincho",
        ],
        .korean : [
            "AppleMyungjo",
            "GungSeo",
            "Nanum Gothic",
            "PilGi",
//            "BM Jua",
            "Nanum Pen Script",
            "BM Kirang Haerang",
        ],
        .chinese_trad : [
            "American Typewriter",
            "Baoli SC",
            "GB18030 Bitmap",
            "Chalkboard SE",
            "Courier",
            "Futura",
            "HanziPen SC",
            "Hei",
            "LingWai TC",
            "Apple LiSung",
            "PilGi",
            "PingFang SC",
            "Verdana",
            "Weibei SC",
        ],
        .chinese_simpl : [
            "American Typewriter",
            "Baoli SC",
            "GB18030 Bitmap",
            "Chalkboard SE",
            "Courier",
            "Futura",
            "HanziPen SC",
            "Hei",
            "LingWai TC",
            "Apple LiSung",
            "PilGi",
            "PingFang SC",
            "Verdana",
            "Weibei SC",
        ]
    ]
    static private let defaultAvailableFontNames: [String] = [
        "American Typewriter",
        "Chalkboard SE",
        "Chalkduster",
        "Courier",
        "Futura",
        "Helvetica",
        "Luciole",
        "PilGi",
        "Snell Roundhand",
        "Times New Roman",
        "Verdana",
    ]
}
