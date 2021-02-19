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

func printnoln(_ message: String) {
	print(message, terminator: "")
}

extension UnsignedInteger {
	func toHex() -> String {
		String(format: "0x%02X", UInt64(self))
	}
}

/*-- Charactere/unicode --*/
extension Character {
	func toUInt32() -> UInt32 {
		guard let us = self.unicodeScalars.first else {printerror("Cannot convert char \(self) to UInt32."); return 0}
		return us.value
	}
	func isAlphaNumeric() -> Bool {
		return String(self).rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil
	}
}
extension UInt32 {
	func toCharacter() -> Character {
		guard let us = Unicode.Scalar(self) else {printerror("Cannot convert UInt32 \(self) to char"); return "?"}
		return Character(us)
	}
}
extension String {
	func substring(lowerIndex: Int, exHighIndex: Int) -> String? {
		guard lowerIndex < count, lowerIndex < exHighIndex else {
			return nil
		}
		let start = index(startIndex, offsetBy: lowerIndex)
		let end = index(start, offsetBy: min(exHighIndex - lowerIndex,
											 count - lowerIndex))
		return String(self[start..<end])
	}
	func substring(atIndex: Int) -> String? {
		return substring(lowerIndex: atIndex, exHighIndex: atIndex+1)
	}
	func char(atIndex: Int) -> Character? {
		return substring(lowerIndex: atIndex, exHighIndex: atIndex+1)?.first
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

