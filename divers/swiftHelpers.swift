//
//  swiftHelpers.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-03-28.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/*-- Console info --*/

func printerror(_ message: String, function: String = #function, file: String = #file) {
	print("❌ Error: \(message) in \(function) of file \((file as NSString).lastPathComponent)")
}

func printwarning(_ message: String, function: String = #function, file: String = #file) {
	print("⚠️ Warn.: \(message) in \(function) of file \((file as NSString).lastPathComponent)")
}

func printdebug(_ message: String, function: String = #function, file: String = #file) {
	#if DEBUG
	print("🐞 Debug.: \(message) in \(function) of file \((file as NSString).lastPathComponent)")
	#endif
}
func printfulldebug(_ message: String) {
    #if DEBUG
    print("🐔 Deb.Info.: \(message).")
    Thread.callStackSymbols.forEach{print($0)}
    #endif
}

func printnoln(_ message: String) {
	print(message, terminator: "")
}

extension UnsignedInteger {
	func toHex() -> String {
		String(format: "0x%02X", UInt64(self))
	}
}

/*-- KeyChain --*/
class KeyChain {
	static func save(key: String, data: Data) -> OSStatus {
		let query = [
			kSecClass as String : kSecClassGenericPassword as String,
			kSecAttrAccount as String : key,
			kSecValueData as String : data
			] as [String : Any]
		SecItemDelete(query as CFDictionary)
		
		return SecItemAdd(query as CFDictionary, nil)
	}
	
	static func load(key: String) -> Data? {
		let query = [
			kSecClass as String : kSecClassGenericPassword as String,
			kSecAttrAccount as String : key,
			kSecReturnData as String : kCFBooleanTrue!,
			kSecMatchLimit as String : kSecMatchLimitOne
			] as [String : Any]
		
		var dataTypeRef: AnyObject? = nil
		let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
		if status == noErr {
			return dataTypeRef as! Data?
		} else {
			return nil
		}
	}
}

/*-- Optional --*/

extension Optional {
	/** Comme ?? mais affiche un message d'avertissement. */
	func or(_ defaultValue: Wrapped, warning: String, function: String = #function, file: String = #file) -> Wrapped {
		switch self {
			case .none:
				printwarning(warning, function: function, file: file)
				return defaultValue
			case .some(let value):
				return value
		}
	}
    func toString(_ defaultValue: String = "∅") -> String {
        switch self {
            case .none:
                return defaultValue
            case .some(let value):
                return "\(value)"
        }
    }
}

/*-- Array/Dictionnary of weak element (evanescent element) --*/

protocol Strippable {
	associatedtype Value: AnyObject
	var value: Value? { get }
}

struct WeakElement<T : AnyObject>: Strippable {
	weak var value: T?
	init(_ value: T) {
		self.value = value
	}
}

extension Dictionary where Value : Strippable {
	mutating func strip() {
		self = self.filter { nil != $0.value.value }
	}
}

extension Dictionary {
	mutating func putIfAbsent(key: Key, value: Value, showWarning: Bool = false) {
		if self[key] == nil {
			self[key] = value
		} else if showWarning {
			printwarning("Entry \(key) already defined.")
		}
	}
}

extension Array where Element : Strippable {
	mutating func strip() {
		self = self.filter { nil != $0.value }
	}
    func forEachNonNil(_ body: (Element.Value)->Void) {
        forEach { el in
            if let value = el.value {
                body(value)
            }
        }
    }
}



/*-- Relatif à l'app / Bundle --*/

extension Bundle {
	var displayName: String {
		get {
			guard let name = object(forInfoDictionaryKey: "CFBundleName") as? String else {
				printerror("No CFBundleName."); return "CoqApp"
			}
			return name
		}
	}
	var version: String {
		get {
			guard let name = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
				printerror("No CFBundleShortVersionString."); return "0.0"
			}
			return name
		}
	}
	var build: String {
		get {
			guard let number = object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
				printerror("No CFBundleVersion."); return "0"
			}
			return number
		}
	}
}

/*-- Kotlin like stuff... --*/

protocol KotlinLikeScope {}

extension KotlinLikeScope {
	@discardableResult
	@inline(__always) func also(_ block: (Self) -> Void) -> Self {
		block(self)
		return self
	}
	@discardableResult
	@inline(__always) func `let`<R>(_ block: (Self) -> R) -> R {
		return block(self)
	}
}

extension Optional where Wrapped: KotlinLikeScope {
    @discardableResult
	@inline(__always) func also(_ block: (Wrapped) -> Void) -> Self? {
		guard let self = self else {return nil}
		block(self)
		return self
	}
	@inline(__always) func `let`<R>(_ block: (Wrapped) -> R) -> R? {
		guard let self = self else {return nil}
		return block(self)
	}
}

