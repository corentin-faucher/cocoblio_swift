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

func toHex(_ n: UInt) -> String {
	String(format: "0x%02X", n)
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

