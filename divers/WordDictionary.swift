//
//  WordDictionary.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2022-03-11.
//  Copyright © 2022 Corentin Faucher. All rights reserved.
//

import Foundation

enum WordDictionaryScanMethod {
    case standard
    case with_roman // Pour les langue asiatique où on a le vrai mot et sa romanisation.
    case as_kana    // Cas particulier d'usage direct des kanas en japonais.
}

protocol WordDictionaryDelegate : AnyObject {
    func displayScan(wordsFound: [String])
}

class WordDictionary {
    var scanMethod: WordDictionaryScanMethod
    weak var delegate: WordDictionaryDelegate? = nil
    
    private var words: Set<String> = []
    private var wordToRoman: [String : String] = [:]
    private let url: URL
    private let separator: Character  // Pour le cas "with_roman".
    
    static let dictionaryDirName = "_dictionary"
    static private let dictQueue = DispatchQueue(label: "dictionary.queue")
    static private var dictOfLanguage: [Language: WordDictionary] = [:]
    
    static func getDictionnaryForLanguage(_ language: Language) -> WordDictionary?
    {
        if let dict = dictOfLanguage[language] {
            return dict
        }
        guard let newDict = WordDictionary(language: language) else {
            return nil
        }
        dictOfLanguage[language] = newDict
        return newDict
    }
    
    private init?(language: Language) {
        // Init de l'url du dict.
        self.separator = language == .vietnamese ? "\t" : " "
        switch language {
                // Cas dictionnaire  "roman - mot ref".
            case .japanese, .chinese_trad, .chinese_simpl, .vietnamese, .korean:
                self.scanMethod = .with_roman
            default:
                // Cas normal, juste une liste de mots.
                self.scanMethod = .standard
        }
        // Essayer de prendre le dictionnaire dans iCloud en priorité.
        var url_tmp = FileManager.default.iCloudDocuments?
            .appendingPathComponent(WordDictionary.dictionaryDirName, isDirectory: true)
            .appendingPathComponent("\(language.iso).txt", isDirectory: false)
        if let url = url_tmp, FileManager.default.existence(at: url) == .file {
            self.url = url
            return
        }
        // Essuite essayer dans les assets.
        url_tmp = Bundle.main.resourceURL?
            .appendingPathComponent("assets/dict", isDirectory: true)
            .appendingPathComponent("\(language.iso).txt", isDirectory: false)
        if let url = url_tmp, FileManager.default.existence(at: url) == .file {
            self.url = url
            return
        }
        // Rien trouvé...
        printwarning("No dictionary file found for \(language).")
        return nil
        // Français : Ok je suppose...
        //   License free : https://github.com/hbenbel/French-Dictionary/blob/master/dictionary/dictionary.txt
        // Japonais : ok
        // English : ok (avec mit header) https://github.com/derekchuank/high-frequency-vocabulary
        // Korean : ? à finir. Attribution de https://github.com/uniglot/korean-word-ipa-dictionary
        // Chinese : ?
        // Allemand : ?
        // Viet : ?
    }
    
    /** Vérifier si un mot existe (lourd). Première utilisation encore plus lourde. (A utiliser dans une thread.) */
    func contains(_ word: String) -> Bool
    {
        if words.isEmpty {
            loadWords()
        }
        return words.contains(word)
    }
    
    /** Scan le dictionnaire pour trouver des mots pour les leçons. Est fait en parallèle dans la thread dictQueue.
     Il faut avoir définit le delegate qui fera l'affichage du résultat un peu plus tard. */
    func scan(allowed: String, required: String, maxCount: Int, showRomans: Bool)
    {
        guard delegate != nil else {
            printerror("Cannot use scan function without delegate.")
            return
        }
        // Processus un peu long (scanner un dictionnaire)
        WordDictionary.dictQueue.async { [self] in
            let results: [String]
            switch scanMethod {
                case .standard:
                    results = scanDefault(allowed: allowed, required: required, maxCount: maxCount)
//                    results = scanFromFile(allowed: allowed, required: required, maxCount: maxCount)
                case .with_roman:
                    results = scanWithRoman(allowed: allowed, required: required, maxCount: maxCount,
                                            showRomans: showRomans)
                case .as_kana:
                    results = scanAsKana(allowed: allowed, required: required, maxCount: maxCount)
            }
            // Rendre les résultats dans la main thread.
            // On prende le strong ref ici, car delegate pourrait être parti entre temps...
            if let delegate = delegate {
                DispatchQueue.main.async {
                    delegate.displayScan(wordsFound: results)
                }
            }
            
        }
    }
    
    // (Init du dictionnaire, load les mots dans le fichier txt)
    private func loadWords()
    {
        // 0. Check, init file.
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path, "r") else {
            printerror("Could not open \(url).")
            return
        }
        defer {
            fclose(filePointer)
        }
        words.removeAll()
        // Boucle de lecture du dictionnaire
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        while bytesRead > 0 {
            // Lire le mot de la ligne présente, et se placer sur la ligne suivante.
            let word = String.init(cString: lineByteArrayPointer!).trimmingCharacters(in: .newlines)
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
            // Sauter l'entête
            if word.first == "#" {
                continue
            }
            // Ajout
            words.insert(word)
        }
    }
    private func loadWordsAndWordToRoman()
    {
        // 0. Check, init file.
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path, "r") else {
            printerror("Could not open \(url).")
            return
        }
        defer {
            fclose(filePointer)
        }
        wordToRoman.removeAll()
        words.removeAll()
        // Boucle de lecture du dictionnaire
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        while bytesRead > 0 {
            // Lire la ligne présente, et se placer sur la ligne suivante.
            let line = String.init(cString: lineByteArrayPointer!).trimmingCharacters(in: .newlines)
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
            // Sauter l'entête
            if line.first == "#" {
                continue
            }
            // Obtenir la partie jamos/pinyin et hangul/hanzi
            guard let sepIndex = line.firstIndex(of: separator) else {
                continue
            }
            // Les romans/jamos
            let chars = String(line.prefix(upTo: sepIndex))
            let afterSepIndex = line.index(after: sepIndex)
            // Le mot original
            let word = String(line.suffix(from: afterSepIndex))
            // Ajout
            wordToRoman[word] = chars
            words.insert(word)
        }
    }
    private func scanDefault(allowed: String, required: String, maxCount: Int) -> [String]
    {
        // 0. Vérifier que les mots on été chargés en utiliser un set pour allowed.
        if words.isEmpty {
            loadWords()
        }
        let setAllowed = Set(allowed)
        var results: [String] = []
        var count = 0
        // 1. Scanner le dictionnaire
        dict_loop: for word in words {
            // Vérifier que le mot ne contient que des lettres autorisées
            for char in word {
                if !setAllowed.contains(char) {
                    continue dict_loop
                }
            }
            // Vérifier que le mot contienne au moins une fois chacune des lettres requises
            for char in required {
                if !word.contains(char) {
                    continue dict_loop
                }
            }
            // Trouvé !
            results.append(word)
            count += 1
            if count > maxCount * 5 {
                break
            }
        }
        // 2. Remettre en ordre pour garder en priorité les mots plus courts.
        results = results.sorted {
            $0.count < $1.count
        }
        if results.count > maxCount {
            results.removeLast(results.count - maxCount)
        }
        return results
    }
    // Juste pour tester... (plus rapide la première fois, puis ~3 fois plus lent...
    private func scanFromFile(allowed: String, required: String, maxCount: Int) -> [String]
    {
        // 0. Check, init file.
        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path, "r") else {
            printerror("Could not open \(url).")
            return []
        }
        defer {
            fclose(filePointer)
        }
        let setAllowed = Set(allowed)
        var results: [String] = []
        var count = 0
        // 1. Boucle de lecture du dictionnaire
        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
        var lineCap: Int = 0
        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
        dict_loop: while bytesRead > 0 {
            // Lire le mot de la ligne présente, et se placer sur la ligne suivante.
            let word = String.init(cString: lineByteArrayPointer!).trimmingCharacters(in: .newlines)
            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
            // Sauter l'entête
            if word.first == "#" {
                continue
            }
            // Vérifier que le mot ne contient que des lettres autorisées
            for char in word {
                if !setAllowed.contains(char) {
                    continue dict_loop
                }
            }
            // Vérifier que le mot contienne au moins une fois chacune des lettres requises
            for char in required {
                if !word.contains(char) {
                    continue dict_loop
                }
            }
            // Trouvé !
            results.append(word)
            count += 1
            if count > maxCount * 5 {
                break
            }
        }
        // 2. Remettre en ordre pour garder en priorité les mots plus courts.
        results = results.sorted {
            $0.count < $1.count
        }
        if results.count > maxCount {
            results.removeLast(results.count - maxCount)
        }
        return results
    }
    private func scanWithRoman(allowed: String, required: String, maxCount: Int, showRomans: Bool) -> [String]
    {
        if wordToRoman.isEmpty {
            loadWordsAndWordToRoman()
        }
        let setAllowed = Set(allowed)
        var results: [String] = []
        var count = 0
        // 1. Scanner le dictionnaire
        dict_loop: for (ref, romans) in wordToRoman {
            // Vérifier que le mot ne contient que des lettres autorisées
            for char in romans {
                if !setAllowed.contains(char) {
                    continue dict_loop
                }
            }
            // Vérifier que le mot contienne au moins une fois chacune des lettres requises
            for char in required {
                if !romans.contains(char) {
                    continue dict_loop
                }
            }
            // Trouvé !
            if showRomans {
                results.append("\(ref) / \(romans)")
            } else {
                results.append(ref)
            }
            count += 1
            if count > maxCount * 5 {
                break
            }
        }
        // 2. Remettre en ordre pour garder en priorité les mots plus courts.
        results = results.sorted {
            $0.count < $1.count
        }
        if results.count > maxCount {
            results.removeLast(results.count - maxCount)
        }
        return results
    }
    private func scanAsKana(allowed: String, required: String, maxCount: Int) -> [String]
    {
        if words.isEmpty {
            loadWordsAndWordToRoman()
        }
        let setAllowed = Set(allowed)
        var results: [String] = []
        var count = 0
        // 1. Scanner le dictionnaire
        dict_loop: for word in words {
            // Vérifier que le mot ne contient que des lettres autorisées
            for char in word {
                if !char.isKana {
                    continue
                }
                if !setAllowed.contains(char) {
                    continue dict_loop
                }
            }
            // Vérifier que le mot contienne au moins une fois chacune des lettres requises
            for char in required {
                if !word.contains(char) {
                    continue dict_loop
                }
            }
            // Trouvé !
            results.append(word)
            count += 1
            if count > maxCount * 5 {
                break
            }
        }
        // 2. Remettre en ordre pour garder en priorité les mots plus courts.
        results = results.sorted {
            $0.count < $1.count
        }
        if results.count > maxCount {
            results.removeLast(results.count - maxCount)
        }
        return results
    }
}

