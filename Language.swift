//
//  coqText.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-28.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation


struct LanguageInfo : Equatable, ExpressibleByStringLiteral {
	typealias StringLiteralType = String
	init(stringLiteral value: StringLiteralType) {
        iso = value
        switch value {
            case "fr": id = 0
            case "en": id = 1
            case "ja": id = 2
            case "de": id = 3
            case "it": id = 4
            case "es": id = 5
            case "ar": id = 6
            case "el": id = 7
            case "ru": id = 8
            case "sv": id = 9
            case "zh-Hans": id = 10
            case "zh-Hant": id = 11
            case "pt": id = 12
            case "ko": id = 13
        default: printerror("Language non définie: \(value)"); id = 1
        }
    }
    
    fileprivate let id: Int
    fileprivate let iso: String
}

enum Language : LanguageInfo, CaseIterable {
    case french = "fr"
    case english = "en"
    case japanese = "ja"
    case german = "de"
    case italian = "it"
    case spanish = "es"
    case arabic = "ar"
    case greek = "el"
    case russian = "ru"
    case swedish = "sv"
    case chinese_simpl = "zh-Hans"
    case chinese_trad = "zh-Hant"
    case portuguese = "pt"
    case korean = "ko"
    
	init?(iso: String) {
		self.init(rawValue: LanguageInfo(stringLiteral: iso))
	}
	
	var iso: String {
		get { rawValue.iso }
	}
	
    static let defaultLanguage = english
	
	static var actionAfterLanguageChanged: (() -> Void)? = nil
    
    /// Langue actuel et son setter.
	static var current: Language = loadPresentLanguage() {
		didSet {
			printdebug("change current Language \(current), with action: \(actionAfterLanguageChanged != nil)")
			guard let action = actionAfterLanguageChanged else {return}
			action()
		}
	}
	/** Écriture en arabe. */
	static private(set) var currentIsRightToLeft = false {
		didSet {
			if currentIsRightToLeft {
				currentDirectionFactor = -1
				currentCharSpacing = -0.12
			} else {
				currentDirectionFactor = 1
				currentCharSpacing = -0.07
			}
		}
	}
	/** +1 si lecture de gauche à droite et -1 si on lit de droite à gauche (arabe). */
	static private(set) var currentDirectionFactor: Float = 1
	/** L'espacement entre les Char (différent pour l'arabe) */
	static private(set) var currentCharSpacing: Float = -0.07
	
    
    /*-- Fonctions "helpers" --*/
	/// Helper pour l'id utiliser dans les languageSurface (par exemple)
    static var currentId: Int {
        get {
            return current.rawValue.id
        }
    }
    /// Helper pour le code iso (i.e. "en", "fr", ...)
    static var currentIso: String {
        get {
            return current.rawValue.iso
        }
    }
    static func currentIs(_ language: Language) -> Bool {
        return current == language
    }
	
	private static func loadPresentLanguage() -> Language {
		if let language = BuildConfig.forcedLanguage {
            printwarning("Using fored language \(language).")
            return language
        }
        if var langISO = Locale.current.languageCode {
            if langISO == "zh" {
                langISO = langISO + "-" + (Locale.current.scriptCode ?? "")
            }
			if let language = Language(iso: langISO) {
                return language
            }
        }
        printwarning("Language not found. Taking default: \(defaultLanguage).")
        return defaultLanguage
    }
	
}

/** Extension pour les surfaces de string localisées. */
extension String {
    var localized: String? {
        guard let path = Bundle.main.path(forResource: Language.currentIso, ofType: "lproj") else {
            printerror("Ne peut trouver le fichier pour \(Language.currentIso)"); return nil}
        guard let bundle = Bundle(path: path) else {
            printerror("Ne peut charger le bundle en \(path)"); return nil}
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}



/*
static func getLanguageFrom(iso: String) -> Language {

guard let language = codeToLang[iso] else {
printerror("\(iso) language undefined")
return english
}
return language
}

private static let codeToLang = [
"fr" :  french,
"en" :  english,
"ja" :  japanese,
"de" :  german,
"it" :  italian,
"es" :  spanish,
"ar" :  arabic,
"el" :  greek,
"ru" :  russian,
"sv" :    swedish,
"zh-Hans": chinese_simpl,
"zh-Hant": chinese_trad,
"pt" :    portuguese,
"ko" :    korean,
]
*/

