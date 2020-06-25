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
		// Ancien ordre... pour les pngs et vielles sauvegardes.
        switch value {
            case "fr": id = 0
            case "en": id = 1
            case "ja": id = 2
            case "de": id = 3
			case "zh-Hans": id = 4
            case "it": id = 5
            case "es": id = 6
            case "ar": id = 7
            case "el": id = 8
            case "ru": id = 9
            case "sv": id = 10
            case "zh-Hant": id = 11
            case "pt": id = 12
            case "ko": id = 13
        default: printerror("Language non définie: \(value)"); id = 1
        }
    }
    
    let id: Int
    let iso: String
}

/** Les langues possibles. En ordre alphabétique de l'iso code. */
enum Language : LanguageInfo, CaseIterable {
    case arabic = "ar"
	case german = "de"
	case greek = "el"
	case english = "en"
	case spanish = "es"
	case french = "fr"
    case italian = "it"
    case japanese = "ja"
	case korean = "ko"
    case portuguese = "pt"
    case russian = "ru"
    case swedish = "sv"
    case chinese_simpl = "zh-Hans"
    case chinese_trad = "zh-Hant"
    
	init?(iso: String) {
		self.init(rawValue: LanguageInfo(stringLiteral: iso))
	}
	var iso: String {
		get { rawValue.iso }
	}
	var tileId: Int {
		get { rawValue.id }
	}
	
	
	/*-- Static --*/
    static let defaultLanguage = english
	/// Langue actuel et son setter.
	static var current: Language = getSystemLanguage() {
		didSet {
			guard current != oldValue else {return}
			// (pour l'instant c'est juste l'arabe...)
			currentIsRightToLeft = (current == .arabic)
			currentDirectionFactor = currentIsRightToLeft ? -1 : 1
			currentCharSpacing = evalCharSpacing()
			
			guard let path = Bundle.main.path(forResource: Language.currentIso, ofType: "lproj") else {
				printerror("Ne peut trouver le fichier pour \(Language.currentIso)"); return}
			guard let bundle = Bundle(path: path) else {
				printerror("Ne peut charger le bundle en \(path)"); return}
			currentBundle = bundle
			// ** Après avoir setter le bundle de la langue courante... **
			Texture.updateAllLocStrings()
		}
	}
	/*-- Getter "helpers" pour current language --*/
	/// Helper pour l'id utiliser dans les languageSurface (par exemple)
	static var currentTileId: Int {
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
	/** Langue de l'OS. */
	static func getSystemLanguage() -> Language {
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
	
	static func getLanguageFromOldId(_ oldId: Int) -> Language? {
		switch oldId {
			case 0: return .french
			case 1: return .english
			case 2: return .japanese
			case 3: return .german
			case 4: return .chinese_simpl
			case 5: return .italian
			case 6: return .spanish
			case 7: return .arabic
			case 8: return .greek
			case 9: return .russian
			case 10: return .swedish
			case 11: return .chinese_trad
			case 12: return .portuguese
			case 13: return .korean
			default: return nil
		}
	}
    
	/*-- Private stuff... --*/
	static private(set) var currentBundle: Bundle = Bundle.main
	/** Écriture en arabe. */
	static private(set) var currentIsRightToLeft = (Language.current == .arabic)
	/** +1 si lecture de gauche à droite et -1 si on lit de droite à gauche (arabe). */
	static private(set) var currentDirectionFactor: Float = (Language.current == .arabic) ? -1 : 1
	/** L'espacement entre les Char (différent pour l'arabe) */
	static private(set) var currentCharSpacing: Float = evalCharSpacing()
	static private func evalCharSpacing() -> Float {
		currentIsRightToLeft ? -0.20
			: -0.05
	}
}

/** Extension pour les surfaces de string localisées. */
extension String {
    var localized: String? {
		let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.currentBundle, value: "⁉️", comment: "")
		guard locStr != "⁉️" else {
			return nil
		}
		return locStr
    }
	var localizedOrDucked: String {
		return localized ?? "🦆\(self)"
	}
	var localizedWithMain: String? {
		let locStr = NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "⁉️", comment: "")
		guard locStr != "⁉️" else {
			return nil
		}
		return locStr
	}
}



