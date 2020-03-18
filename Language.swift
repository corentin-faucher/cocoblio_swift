//
//  coqText.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-28.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation


struct LanguageInfo : Equatable, ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
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
    
    let id: Int
    let iso: String
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
    
    static let defaultLanguage = english
    /** Pour Debugging... à présenter mieux... ? */
    static let forcedLanguage: Language? = nil
    
    /// Langue actuel et son setter.
    static var currentLanguage: Language = loadPresentLanguage() {
            didSet {
                UserDefaults.standard.set(currentLanguageCode, forKey: "user_language")
                Texture.updateAllLocalizedStrings()
            }
        }
    
    /*-- Fonctions "helpers" --*/
	/// Helper pour l'id utiliser dans les languageSurface (par exemple)
    static var currentLanguageID: Int {
        get {
            return currentLanguage.rawValue.id
        }
    }
    /// Helper pour le code iso (i.e. "en", "fr", ...)
    static var currentLanguageCode: String {
        get {
            return currentLanguage.rawValue.iso
        }
    }
    static func currentIs(_ language: Language) -> Bool {
        return currentLanguage == language
    }
    
    private static func loadPresentLanguage() -> Language {
        if let language = forcedLanguage {
            printwarning("On utilise le language forcé: \(language).")
            return language
        }
        
        if let langISO = UserDefaults.standard.string(forKey: "user_language"),
            let language = codeToLang[langISO]
        {
            print("Trouvé langISO dans UserDefaults: \(langISO)")
            return language
        }
        if var langISO = Locale.current.languageCode {
            if langISO == "zh" {
                langISO = langISO + "-" + (Locale.current.scriptCode ?? "")
            }
            if let language = codeToLang[langISO] {
                print("langID est pris de Locale.current.languageCode: \(langISO)")
                return language
            }
        }
        print("Rien trouvé on prend le défaut: \(defaultLanguage).")
        return defaultLanguage
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
}

/** Extension pour les surfaces de string localisées. */
extension String {
    var localized: String? {
        guard let path = Bundle.main.path(forResource: Language.currentLanguageCode, ofType: "lproj") else {
            printerror("Ne peut trouver le fichier pour \(Language.currentLanguageCode)"); return nil}
        guard let bundle = Bundle(path: path) else {
            printerror("Ne peut charger le bundle en \(path)"); return nil}
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
}


