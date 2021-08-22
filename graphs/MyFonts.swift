//
//  MyFonts.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-08-06.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
#else
import UIKit
#endif

typealias FontInfo = (size_y: CGFloat, size_x: CGFloat)

enum FontManager {
    static private(set) var current = getSystemFont(ofSize: 24) {
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
            currentInfo = defaultInfo
            current = getSystemFont(ofSize: current.pointSize)
            return
        }
        guard let font = getFont(name: fontname) else {
            printerror("Cannot generate font \(fontname).")
            currentInfo = defaultInfo
            current = getSystemFont(ofSize: current.pointSize)
            return
        }
        if let info = fontInfoDic[fontname] {
            currentInfo = info
        } else {
            printerror("No info for \(fontname).")
            currentInfo = defaultInfo
        }
        current = font
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
    
    #if os(OSX)
    static func getFont(name: String, size: CGFloat = current.pointSize) -> NSFont? {
        return NSFont(name: name, size: size)
    }
    #else
    static func getFont(name: String, size: CGFloat = current.pointSize) -> UIFont? {
        return UIFont(name: name, size: size)
    }
    #endif
    
    static func getFontNamesForCurrentLanguage() -> [String] {
        if let names = availableFontNamesByLanguage[Language.current] {
            return names
        } else {
            return defaultAvailableFontNames
        }
    }
    
    #if os(OSX)
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
    #else
    static func currentWithSize(_ size: CGFloat) -> UIFont {
        return current.withSize(size)
    }
    #endif
    
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
        "Nanum Gothic": "NanumGothic",
        "Nanum Myeongjo": "NanumMyeongjo",
        "Nanum Pen Script": "Nanum Pen",
        "BM Kirang Haerang": "Kirang",
        "GungSeo": "GungSeo",
        "PilGi": "PilGi",
        "Hiragino Maru Gothic ProN": "Hiragino MGP",
        "Hiragino Mincho ProN": "Hiragino MP",
        "Klee": "Klee",
        "Osaka": "Osaka",
        "Toppan Bunkyu Gothic": "Toppan BG",
        "Toppan Bunkyu Midashi Gothic": "Toppan BMG",
        "Toppan Bunkyu Midashi Mincho": "Toppan BMM",
        "Toppan Bunkyu Mincho": "Toppan BM",
        "Tsukushi A Round Gothic": "Tsukushi A",
        "Tsukushi B Round Gothic": "Tsukushi B",
        "YuKyokasho Yoko": "YuKyokasho",
        "YuMincho": "YuMincho",
        "Apple SD Gothic Neo": "Apple SD Goth.N.",
        "Apple LiSung": "Apple LiSung",
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
    
    #if os(OSX)
    static private func getSystemFont(ofSize size: CGFloat) -> NSFont {
        return NSFont.systemFont(ofSize: size)
    }
    #else
    static private func getSystemFont(ofSize size: CGFloat) -> UIFont {
        return UIFont.systemFont(ofSize: size)
    }
    #endif
    
    static private let fontSizeRatio: CGFloat = 0.065 // Hauteur de string à ~1/15 de la hauteur de l'écran.
    static private let minFontSize: CGFloat = 12
    static private let maxFontSize: CGFloat = 144
    static private let fontInfoDic: [String: FontInfo] = [
        "American Typewriter": (size_y: 1.2, size_x: 1.0),
        "Chalkboard SE": (size_y: 1.25, size_x: 1),
        "Chalkduster": (size_y: 1.55, size_x: 1.2),
        "Courier": (size_y: 1.3, size_x: 0.5),
        "Futura": (size_y: 1.4, size_x: 0.0),
        "Helvetica": (size_y: 1.1, size_x: 0.3),
        "Luciole": (size_y: 1.3, size_x: 0.6),
        "Snell Roundhand": (size_y: 1.85, size_x: 6),
        "Times New Roman": (size_y: 1.3, size_x: 0.8),
        "Verdana": (size_y: 1.2, size_x: 0.5),
        "Nanum Gothic": (size_y: 1.3, size_x: 0.2),
        "Nanum Pen Script": (size_y: 1.3, size_x: 0.2),
        "BM Kirang Haerang": (size_y: 1.3, size_x: 0),
        "GungSeo": (size_y: 1.3, size_x: 0.8),
        "PilGi": (size_y: 1.6, size_x: 0.3),
        "Hiragino Maru Gothic ProN": (size_y: 1.3, size_x: 0.5),
        "Hiragino Mincho ProN": (size_y: 1.3, size_x: 0.5),
        "Klee": (size_y: 1.3, size_x: 0.2),
        "Osaka": (size_y: 1.3, size_x: 0.5),
        "Toppan Bunkyu Gothic": (size_y: 1.3, size_x: 0.5),
        "Toppan Bunkyu Midashi Gothic": (size_y: 1.3, size_x: 0.5),
        "Toppan Bunkyu Midashi Mincho": (size_y: 1.3, size_x: 0.5),
        "Toppan Bunkyu Mincho": (size_y: 1.3, size_x: 0.5),
        "Tsukushi A Round Gothic": (size_y: 1.3, size_x: 0.5),
        "Tsukushi B Round Gothic": (size_y: 1.3, size_x: 0.5),
        "YuKyokasho Yoko": (size_y: 1.3, size_x: 0.5),
        "YuMincho": (size_y: 1.3, size_x: 0.5),
        "Apple SD Gothic Neo": (size_y: 1.3, size_x: 0.5),
        "Apple LiSung": (size_y : 1.3, size_x: 0.8),
        "Baoli SC": (size_y : 1.3, size_x: 0.1),
        "GB18030 Bitmap": (size_y : 1, size_x: 0.5),
        "HanziPen SC": (size_y : 1.3, size_x: 0.5),
        "Hei": (size_y : 1.3, size_x: 0.25),
        "LingWai TC": (size_y : 1.2, size_x: 0.9),
        "AppleMyungjo": (size_y : 1.25, size_x: 0.5),
        "PingFang SC": (size_y : 1.3, size_x: 0.5),
        "Weibei SC": (size_y : 1.3, size_x: 0.5),
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
            "Toppan Bunkyu Gothic",
            "Toppan Bunkyu Midashi Gothic",
            "Toppan Bunkyu Midashi Mincho",
            "Toppan Bunkyu Mincho",
            "Tsukushi A Round Gothic",
            "Tsukushi B Round Gothic",
            "Verdana",
            "YuGothic",
            "YuKyokasho Yoko",
            "YuMincho",
        ],
        .korean : [
            "Apple SD Gothic Neo",
            "AppleMyungjo",
            "BM Jua",
            "BM Kirang Haerang",
            "BM Yeonsung",
            "GungSeo",
            "HeadLineA",
            "Nanum Gothic",
            "Nanum Myeongjo",
            "Nanum Pen Script",
            "PilGi",
        ],
        .chinese_trad : [
            "American Typewriter",
            "Apple LiSung",
            "Baoli SC",
            "Chalkboard SE",
            "Courier",
            "Futura",
            "GB18030 Bitmap",
            "HanziPen SC",
            "Hei",
            "LingWai TC",
            "PilGi",
            "PingFang SC",
            "Times New Roman",
            "Verdana",
            "Weibei SC",
        ],
        .chinese_simpl : [
            "American Typewriter",
            "Apple LiSung",
            "Baoli SC",
            "Chalkboard SE",
            "Courier",
            "Futura",
            "GB18030 Bitmap",
            "HanziPen SC",
            "Hei",
            "LingWai TC",
            "PilGi",
            "PingFang SC",
            "Times New Roman",
            "Verdana",
            "Weibei SC",
        ],
        .russian : [
            "American Typewriter",
            "Chalkboard SE",
            "Helvetica",
            "Snell Roundhand",
            "Times New Roman",
            "Verdana",
        ],
        .greek : [
            "American Typewriter",
            "Chalkboard SE",
            "Helvetica",
            "Luciole",
            "Snell Roundhand",
            "Times New Roman",
            "Verdana",
        ],
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
