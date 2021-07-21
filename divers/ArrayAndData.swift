//
//  ArrayAndData.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-06-30.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/*-- Array helpers --*/


extension Array where Element == UInt32 {
	func encoded(key: UInt32) -> Array<UInt32> {
		var intArray = self
		
		var uA: UInt32 = 0xeafc8f75 ^ key
		var uE: UInt32 = 0
		for index in intArray.indices {
			uE = intArray[index] ^ uA ^ uE
			intArray[index] = uE
			uA = (uA<<1) ^ (uA>>1)
		}
		// 2e passe (laisse le dernier)
		uA = uE
		uE = 0
		for index in (0...(intArray.count-2)) {
			uE = intArray[index] ^ uA ^ uE
			intArray[index] = uE
			uA = (uA<<1) ^ (uA>>1)
		}
		return intArray
	}
	func decoded(key: UInt32) -> Array<UInt32> {
		var intArray = self
		guard var uA: UInt32 = self.last else {
			printerror("Pas d'élément."); return []
		}
		var uD: UInt32
		var uE: UInt32 = 0
		for index in 0...(count-2) {
			uD = intArray[index] ^ uE ^ uA
			uE = intArray[index]
			intArray[index] = uD
			uA = (uA<<1) ^ (uA>>1)
		}
		uA = 0xeafc8f75 ^ key
		uE = 0
		for index in indices {
			uD = intArray[index] ^ uE ^ uA
			uE = intArray[index]
			intArray[index] = uD
			uA = (uA<<1) ^ (uA>>1)
		}
		return intArray
	}
	func toHex() -> String {
		var result: String = "["
		for uint in self {
			result += " " + uint.toHex() + ","
		}
		result.removeLast()
		result += " ]"
		return result
	}
}


extension Array {
	/** Acces array element "safely". */
	subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
	
	/** Convertion de l'array en structure Data. */
	func toData() -> Data {
		let size = count * MemoryLayout<Element>.size
		return Data(bytes: self, count: size)
	}
	
	/** Helper... (un peu superflu) Convert type (for instance as a "UInt32" array to be encoded). */
	func serialized<T>(to type: T.Type) -> [T] {
		let data = toData()
		return data.toArray(type: T.self)
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
	
	/** Création à partir d'un fichier encodé. */
	init?(contentsOf url: URL, encodedWith key: UInt32) {
		guard let data = try? Data(contentsOf: url) else {
			return nil
		}
		let decoded = data.toArray(type: UInt32.self)
			.decoded(key: key)
			.serialized(to: Element.self)
		self.init(decoded)
	}
	
	/** Écriture dans un fichier encodé. */
	func write(to url: URL, encodedWith key: UInt32) {
		let data = self.serialized(to: UInt32.self)
			.encoded(key: key)
			.toData()
		do { try data.write(to: url) }
        catch { printerror(error.localizedDescription) }
	}
}


/*-- Data --*/
extension Data {
	init<T>(fromStruct value: T) {
		var value = value
		self.init(bytes: &value, count: MemoryLayout<T>.size)
	}
	func toStruct<T>(type: T.Type) -> T? {
		guard self.count >= MemoryLayout<T>.size else {
			printerror("Size doesn't match. data \(self.count), target \(MemoryLayout<T>.size).")
			return nil
		}
		return self.withUnsafeBytes { $0.load(as: T.self) }
	}
	init<T>(fromArray array: Array<T>) {
		let size = array.count * MemoryLayout<T>.size
		self.init(bytes: array, count: size)
	}
	func toArray<T>(type: T.Type) -> Array<T> {
		return withUnsafeBytes {
			Array<T>($0.bindMemory(to: T.self))
		}
	}
}
