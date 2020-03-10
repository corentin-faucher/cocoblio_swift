//
//  coqText.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-28.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

import Foundation

enum Language: Int, CaseIterable {
    case french
    case english
    case japanese
    case german
    case italian
    case spanish
    case arabic
    case greek
    case russian
    case swedish
    case chinese_simpl
    case chinese_trad
    case portuguese
    case korean
    
    static let defaultLanguage = english
    /** Debug... à présenter mieux... ? */
    static let forcedLanguage: Language? = nil
    
    static private var _presentLanguage: Language = loadPresentLanguage()
    static var currentLanguage: Language {
        set {
            _presentLanguage = newValue
            UserDefaults.standard.set(codeList[newValue.rawValue], forKey: "user_language")
            Texture.updateAllLocalizedStrings()
        }
        get {
            return _presentLanguage
        }
    }
    static var currentLanguageID: Int {
        get {
            return _presentLanguage.rawValue
        }
    }
    
    static var currentLanguageCode: String {
        get {
            return codeList[_presentLanguage.rawValue]
        }
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
    private static let codeList = [
        "fr",
        "en",
        "ja",
        "de",
        "it",
        "es",
        "ar",
        "el",
        "ru",
        "sv",
        "zh-Hans",
        "zh-Hant",
        "pt",
        "ko",
        ]
    
    private static func loadPresentLanguage() -> Language {
        if let language = forcedLanguage {
            print("On utilise le language forcé: \(language).")
            return language
        }
        
        if let langID = UserDefaults.standard.string(forKey: "user_language"),
            let language = codeToLang[langID] {
            print("Trouvé langID dans UserDefaults: \(langID)")
            return language
        }
        if var langID = Locale.current.languageCode {
            if langID == "zh" {
                langID = langID + "-" + (Locale.current.scriptCode ?? "")
            }
            if let language = codeToLang[langID] {
                print("langID est pris de Locale.current.languageCode: \(langID)")
                return language
            }
        }
        print("Rien trouvé on prend le défaut: \(defaultLanguage).")
        return defaultLanguage
    }
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

/*
 enum LocalizedTexts {
 static var currentLanguage: Language = .japanese
 static var currentLanguageU8: UInt8 {
 return UInt8(currentLanguage.rawValue)
 }
 static var textsLists: [[String]] = Array(repeating: [], count: Language.allCases.count)
 
 static func initTexts(showWarning: Bool) {
 currentLanguage = Language(languageCode: Locale.current.languageCode ?? "en")
 
 for language in Language.allCases {
 if let url = Bundle.main.url(forResource: "\(language)", withExtension: "txt", subdirectory: "\(language)") {
 do {
 let data = try String(contentsOf: url, encoding: .utf8)
 textsLists[language.rawValue] = data.components(separatedBy: .newlines)
 } catch {
 printerror("Ne peut init pour \(language)")
 }
 } else if showWarning {
 printerror("Ne peut charger \(language)")
 }
 }
 }
 static func getTheString(ofText: Texts) -> String {
 if textsLists[currentLanguage.rawValue].count < ofText.rawValue {
 printerror("Overflow.")
 }
 return textsLists[currentLanguage.rawValue][ofText.rawValue]
 }
 }
 */

