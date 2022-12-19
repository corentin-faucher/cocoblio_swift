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
typealias Font = NSFont
#else
import UIKit
typealias Font = UIFont
#endif

enum FontManager {
    static private(set) var current = getSystemFont(ofSize: 24) {
        didSet {
            if oldValue.fontName != current.fontName || oldValue.pointSize != current.pointSize {
                Texture.redrawAllStrings()
            }
        }
    }
    static var currentSpreading: CGSize = defaultSpreading
    
    static func setCurrent(to fontname: String) {
        let fontnames = getFontNamesForCurrentLanguage()
        guard fontnames.contains(fontname) else {
            printerror("Font \(fontname) not valid for language \(Language.current).")
            currentSpreading = defaultSpreading
            current = getSystemFont(ofSize: current.pointSize)
            return
        }
        guard let font = getFont(name: fontname) else {
            printerror("Cannot generate font \(fontname).")
            currentSpreading = defaultSpreading
            current = getSystemFont(ofSize: current.pointSize)
            return
        }
        if let spreading = spreadingOfFont[fontname] {
            currentSpreading = spreading
        } else {
            printerror("No spreading for \(fontname).")
            currentSpreading = defaultSpreading
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
    
    static func getFontSpreading(_ fontname: String) -> CGSize {
        return spreadingOfFont[fontname] ?? defaultSpreading
    }
    
    static func getSystemFontSize() -> CGFloat
    {
        #if os(OSX)
        return NSFont.systemFontSize
        #else
        return UIFont.systemFontSize
        #endif
    }
    
    static func printAllAvailableFonts() {
        #if os(OSX)
        for family in NSFontManager.shared.availableFontFamilies {
            print(family)
        }
        #else
        for family in UIFont.familyNames {
            print(family)
        }
        #endif
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
        if let names = availableFontNamesForLanguage[Language.current] {
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
        "Comic Sans MS": "Comic Sans",
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
        "OpenDyslexic3": "Op. Dyslex3",
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
    
    /** Hauteur de string à ~1/15 de la hauteur de l'écran. */
    static private let fontSizeRatio: CGFloat = {
        if #unavailable(iOS 13.0) {
            return 0.045
        } else {
            return 0.065
        }
    }()
    static private let minFontSize: CGFloat = 12
    static private let maxFontSize: CGFloat = 144
    static private let spreadingOfFont: [String: CGSize] = [
        "American Typewriter": CGSize(width: 1.0, height: 1.2),
        "Chalkboard SE": CGSize(width: 1, height: 1.25),
        "Chalkduster": CGSize(width: 1.2, height: 1.55),
        "Comic Sans MS": CGSize(width: 1, height: 1.45),
        "Courier": CGSize(width: 0.5, height: 1.3),
        "Futura": CGSize(width: 0.0, height: 1.4),
        "Helvetica": CGSize(width: 0.3, height: 1.1),
        "Luciole": CGSize(width: 0.6, height: 1.3),
        "Snell Roundhand": CGSize(width: 6, height: 1.85),
        "Times New Roman": CGSize(width: 0.8, height: 1.3),
        "Verdana": CGSize(width: 0.5, height: 1.2),
        "Nanum Gothic": CGSize(width: 0.2, height: 1.3),
        "Nanum Pen Script": CGSize(width: 0.2, height: 1.3),
        "BM Kirang Haerang": CGSize(width: 0, height: 1.3),
        "GungSeo": CGSize(width: 0.8, height: 1.3),
        "PilGi": CGSize(width: 0.3, height: 1.6),
        "Hiragino Maru Gothic ProN": CGSize(width: 0.5, height: 1.3),
        "Hiragino Mincho ProN": CGSize(width: 0.5, height: 1.3),
        "Klee": CGSize(width: 0.2, height: 1.3),
        "OpenDyslexic3": CGSize(width: 1.0, height: 1.4),
        "Osaka": CGSize(width: 0.5, height: 1.3),
        "Toppan Bunkyu Gothic": CGSize(width: 0.5, height: 1.3),
        "Toppan Bunkyu Midashi Gothic": CGSize(width: 0.5, height: 1.3),
        "Toppan Bunkyu Midashi Mincho": CGSize(width: 0.5, height: 1.3),
        "Toppan Bunkyu Mincho": CGSize(width: 0.5, height: 1.3),
        "Tsukushi A Round Gothic": CGSize(width: 0.5, height: 1.3),
        "Tsukushi B Round Gothic": CGSize(width: 0.5, height: 1.3),
        "YuKyokasho Yoko": CGSize(width: 0.5, height: 1.3),
        "YuMincho": CGSize(width: 0.5, height: 1.3),
        "Apple SD Gothic Neo": CGSize(width: 0.5, height: 1.3),
        "Apple LiSung": CGSize(width: 0.8, height: 1.3),
        "Baoli SC": CGSize(width: 0.1, height: 1.3),
        "GB18030 Bitmap": CGSize(width: 0.5, height: 1),
        "HanziPen SC": CGSize(width: 0.5, height: 1.3),
        "Hei": CGSize(width: 0.25, height: 1.3),
        "LingWai TC": CGSize(width: 0.9, height: 1.2),
        "AppleMyungjo": CGSize(width: 0.5, height: 1.25),
        "PingFang SC": CGSize(width: 0.5, height: 1.3),
        "Weibei SC": CGSize(width: 0.5, height: 1.3),
        "Farah": CGSize(width: 0.5, height: 1.3),
    ]
    static private let defaultSpreading = CGSize(width: 1.3, height: 1.0)
    static private let availableFontNamesForLanguage: [Language : [String]] = [
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
            "OpenDyslexic3",
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
            "OpenDyslexic3",
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
            "OpenDyslexic3",
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
        "Comic Sans MS",
        "Courier",
        "Futura",
        "Helvetica",
        "Luciole",
        "OpenDyslexic3",
        "PilGi",
        "Snell Roundhand",
        "Times New Roman",
        "Verdana",
    ]
}
