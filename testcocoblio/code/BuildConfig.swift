//
//  BuildConfig.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-05-05.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation
#if !os(OSX)
import UIKit
#endif

enum BuildConfig {
    static func setUp() {
        // (pass)
    }
    
    /*-- Config de deboguage (safe to edit...) --*/
    #if DEBUG
    /** Le mode "photo", cache également le "home bar" et le "status bar". */
    static let fixedWindowRatio: Bool = true
    static let forcedLanguage: Language? = nil
    #if os(OSX)
    static let phone: Bool = false
    static let smallPad: Bool = false
    #else
    /** Petit écran de téléphone... */
    static let phone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    /** Trop petit pour avoir le clavier standard à l'écran, i.e. on affiche le clavier "tablette". */
    static let smallPad: Bool = UIScreen.main.nativeBounds.height < 2400
    #endif
    
    #else
    /*-- DON'T TOUCH (RELEASE CONFIG) --*/
    static let fixedWindowRatio: Bool = true
    static let forcedLanguage: Language? = nil
    #if os(OSX)
    static let phone: Bool = false
    static let smallPad: Bool = false
    #else
    /** Petit écran de téléphone... */
    static let phone: Bool = UIDevice.current.userInterfaceIdiom == .phone
    /** Trop petit pour avoir le clavier standard à l'écran, i.e. on affiche le clavier "tablette". */
    static let smallPad: Bool = UIScreen.main.nativeBounds.height < 2400
    #endif
    /*-- DON'T TOUCH (RELEASE CONFIG) --*/
    #endif
    
    
    /*-- Config de l'OS/target indépendant du build. --*/
    #if os(OSX)
    static let appIdFull: String = "796608673"
    static let appIdLite: String = "896411742"
    static let alwaysHasHardwareKeyboard: Bool = true
    #else
    static let appIdFull: String = "912022264"
    static let appIdLite: String = "925341131"
    static let alwaysHasHardwareKeyboard: Bool = false
    #endif
    
    /*-- Config version lite/full --*/
    #if LITE
    static let appId: String = appIdLite
    #else
    static let appId: String = appIdFull
    #endif
}
