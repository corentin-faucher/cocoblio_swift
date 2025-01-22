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
            case "fr":
                id = 0
                bcp_47 = ["fr-FR", "fr-CA"]
            case "en":
                id = 1
                bcp_47 = ["en-US", "en-GB", "en-AU", "en-IE", "en-ZA", "en-IN"]
            case "ja":
                id = 2
                bcp_47 = ["ja-JP"]
            case "de":
                id = 3
                bcp_47 = ["de-DE"]
			case "zh-Hans":
                id = 4
                bcp_47 = ["zh-CN", "zh-HK", "zh-TW"]
            case "it":
                id = 5
                bcp_47 = ["it-IT"]
            case "es":
                id = 6
                bcp_47 = ["es-ES", "es-MX", "es-AR"]
            case "ar":
                id = 7
                bcp_47 = ["ar-SA"]
            case "el":
                id = 8
                bcp_47 = ["el-GR"]
            case "ru":
                id = 9
                bcp_47 = ["ru-RU"]
            case "sv":
                id = 10
                bcp_47 = ["sv-SE"]
            case "zh-Hant":
                id = 11
                bcp_47 = ["zh-HK", "zh-TW", "zh-CN"]
            case "pt":
                id = 12
                bcp_47 = ["pt-PT", "pt-BR"]
            case "ko":
                id = 13
                bcp_47 = ["ko-KR"]
            case "vi":
                id = 14
                bcp_47 = ["en-US"] // Pas de vietnamien ? vi-VN...
            case "nb":
                id = 15
                bcp_47 = ["en-US"]
            default:
                printerror("Language non définie: \(value)")
                id = 1
                bcp_47 = ["en-US"]
        }
    }
    
    let id: Int
    let iso: String
    let bcp_47: [String]
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
    case norwegian = "nb"
    case portuguese = "pt"
    case russian = "ru"
    case swedish = "sv"
    case vietnamese = "vi"
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
    /** Action supplémentaire lors du chagement de langue. */
    static var changeLanguageAction: (()->Void)? = nil
    /// Langue actuel et son setter.
	static var current: Language = getSystemLanguage() {
		didSet {
			guard current != oldValue else {return}
			// Lecture de droite à gauche (pour l'instant c'est juste l'arabe...)
			currentIsRightToLeft = (current == .arabic)
			currentDirectionFactor = currentIsRightToLeft ? -1 : 1
            currentUseMaruCheck = (Language.current == .japanese) || (Language.current == .korean)
            let bcp_tmp = "\(Locale.current.languageCode ?? "en")-\(Locale.current.regionCode ?? "US")"
            if current.rawValue.bcp_47.contains(bcp_tmp) {
                currentBCP_47 = bcp_tmp
            } else {
//                printwarning("No bcp-47 for locale \(Locale.current.identifier): no \(bcp_tmp) in \(current.rawValue.bcp_47).")
                currentBCP_47 = current.rawValue.bcp_47[0]
            }
			
			guard let path = Bundle.main.path(forResource: Language.currentIso, ofType: "lproj") else {
				printerror("Ne peut trouver le fichier pour \(Language.currentIso)"); return}
			guard let bundle = Bundle(path: path) else {
				printerror("Ne peut charger le bundle en \(path)"); return}
			currentBundle = bundle
			// ** Après avoir setter le bundle de la langue courante... **
			Texture.updateAllLocStrings()
            changeLanguageAction?()
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
    /** Écriture en arabe. */
    static private(set) var currentIsRightToLeft = (Language.current == .arabic)
    /// Utilise un maru `◯` au lieu du check `✓` pour une bonne réponse (japonaise et corréen).
    static private(set) var currentUseMaruCheck = (Language.current == .japanese) || (Language.current == .korean)
    /** +1 si lecture de gauche à droite et -1 si on lit de droite à gauche (arabe). */
    static private(set) var currentDirectionFactor: Float = (Language.current == .arabic) ? -1 : 1
    static private(set) var currentBCP_47: String = Language.current.rawValue.bcp_47[0]
    /** Langue de l'OS. */
	static func getSystemLanguage() -> Language {
		if let language = BuildConfig.forcedLanguage {
			printwarning("Using fored language \(language).")
			return language
		}
        guard var langISO = Locale.current.languageCode else {
            printerror("Locale language not defined. Taking default: \(defaultLanguage).")
            return defaultLanguage
        }
        // Cas du chinois
        if langISO == "zh" {
            langISO = langISO + "-" + (Locale.current.scriptCode ?? "Hans")
            if let language = Language(iso: langISO) {
                return language
            }
            printwarning("Not finding locale chinese \(langISO).")
            return .chinese_simpl
        }
        // Sinon vérifier si définie parmis les 13 autres langues...
        guard let language = Language(iso: langISO) else {
            printwarning("Language \(langISO) not implemented. Taking default: \(defaultLanguage).")
            return defaultLanguage
        }
        return language
	}
    
	/*-- Private stuff... --*/
    static fileprivate let englishBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: Language.english.iso, ofType: "lproj") else {
            printerror("Ne peut trouver le fichier pour \(Language.english.iso)"); return Bundle.main }
        guard let bundle = Bundle(path: path) else {
            printerror("Ne peut charger le bundle en \(path)"); return Bundle.main }
        return bundle
    }()
    static fileprivate let frenchBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: Language.french.iso, ofType: "lproj") else {
            printerror("Ne peut trouver le fichier pour \(Language.french.iso)"); return Bundle.main }
        guard let bundle = Bundle(path: path) else {
            printerror("Ne peut charger le bundle en \(path)"); return Bundle.main }
        return bundle
    }()
    static private(set) var currentBundle: Bundle = {
        guard let path = Bundle.main.path(forResource: Language.currentIso, ofType: "lproj") else {
            printerror("Ne peut trouver le fichier pour \(Language.currentIso)"); return Bundle.main }
        guard let bundle = Bundle(path: path) else {
            printerror("Ne peut charger le bundle en \(path)"); return Bundle.main
        }
        return bundle
    }()
}

/** Extension pour les surfaces de string localisées. */
extension String {
    init?(localizedHtml file_name: String)
    {
        // 1. Essaie avec langue courant
        if let url = Language.currentBundle.url(forResource: file_name, withExtension: "html") {
            do {
                try self.init(contentsOf: url)
                return
            } catch {
                printerror("Could not open html at \(url)")
            }
        }
        // 2. Réessaie avec langue par defaut
        guard let url = Language.englishBundle.url(forResource: file_name, withExtension: "html") else {
            printerror("No default html for \(file_name)")
            return nil
        }
        do {
            try self.init(contentsOf: url)
        } catch {
            printerror("Could not open html at \(url)")
            return nil
        }
    }    
    
    var localized: String {
        // ("Localizable" est la "table" utilisée par défaut...)
        let locStr = Language.currentBundle.localizedString(forKey: self, value: "⁉️", table: nil)
//        let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.currentBundle, value: "⁉️", comment: "")
        if locStr != "⁉️" {
            return locStr
		}
        // Essayer avec le default bundle (english).
        if Language.currentBundle !== Language.englishBundle {
            let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.englishBundle, value: "⁉️", comment: "")
            if locStr != "⁉️" {
                return locStr
            }
        }
		return "🦆\(self)"
    }
    var localizedOrNil: String? {
        let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.currentBundle, value: "⁉️", comment: "")
        if locStr != "⁉️" {
            return locStr
        } else {
            return nil
        }
    }
    /// Localisation par défaut (english).
	var localizedEnglish: String? {
        let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.englishBundle, value: "⁉️", comment: "")
		guard locStr != "⁉️" else {
			return nil
		}
		return locStr
	}
    /// Seconde localization par défaut (français)
    var localizedFrench: String? {
        let locStr = NSLocalizedString(self, tableName: nil, bundle: Language.frenchBundle, value: "⁉️", comment: "")
        guard locStr != "⁉️" else {
            return nil
        }
        return locStr
    }
    
}

