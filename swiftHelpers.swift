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
	print("❌ Error: \(message) in \(function) of file \(file)")
}

func printwarning(_ message: String, function: String = #function, file: String = #file) {
	print("⚠️ Warn.: \(message) in \(function) of file \(file)")
}

func printdebug(_ message: String, function: String = #function, file: String = #file) {
	#if DEBUG
	print("🐞 Debug.: \(message) in \(function) of file \(file)")
	#endif
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

/*-- Text file helper --*/

func getContentOfTextFile(_ textFileName: String, withExtension ext: String = "txt", subdir: String?, showError: Bool = true) -> String?
{
	guard let url = Bundle.main.url(forResource: textFileName,
									withExtension: ext,
									subdirectory: subdir) else {
		if showError {
			printerror("Cannot load \(textFileName).txt in \(subdir ?? "\"\"").")
		}
		return nil
	}
	guard let fileContent = try? String(contentsOf: url) else {
		if showError {
			printerror("Cannot put content of \(textFileName).txt in string.")
		}
		return nil
	}
	return fileContent
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
	mutating func addIfAbsent(key: Key, value: Value, showWarning: Bool = false) {
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

/*-- Array helpers --*/

extension Array {
	/** Acces array element "safely". */
	subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
	
	/** Divide an array into "chunck". Doesn't keep the remaining. */
	func chunked(by chunkSize: Int, showWarning: Bool = true) -> [[Element]] {
		if showWarning, self.count % chunkSize != 0 {
			printwarning("array.count not divisible by \(chunkSize).")
		}
		return stride(from: 0, to: (self.count/chunkSize)*chunkSize, by: chunkSize).map {
			Array(self[$0..<Swift.min($0+chunkSize, self.count)])
		}
	}
	
	/** Convert type (for instance as a "data" array to be encoded). */
	func serialized<T>(to type: T.Type) -> [T] {
		let size = count * MemoryLayout.size(ofValue: self[0])
		let data = Data(bytes: self, count: size)
		let intArr: [T] = data.withUnsafeBytes {
			Array<T>($0.bindMemory(to: T.self))
		}
		return intArr
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

