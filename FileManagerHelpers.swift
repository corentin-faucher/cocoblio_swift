//
//  FileManagerHelpers.swift
//  AnimalTyping
//
//  Fonctions helpers pour la lecture / écriture de fichiers.
//
//  Created by Corentin Faucher on 2020-05-25.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/*-- Text file helper --*/

/*-- Vérification de l'existence de fichier/folders --*/

enum FileExistence {
	case none
	case file
	case directory
}

extension FileManager {
	/** Permet de vérifier s'il existe un fichier, un dossier ou rien à l'url donnée. */
	func existence(at url: URL) -> FileExistence {
		var isDirectory: ObjCBool = false
		let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectory)
		switch (exists, isDirectory.boolValue) {
			case (false, _): return .none
			case (true, true): return .directory
			case (true, false): return .file
		}
	}
}

extension URL {
	/** Vérifie si le directory existe et est bien un directory.
	S'il s'agit d'un fichier le fichier est effacé.
	Ensuite on crée le directory s'il est manquant.
	Retourne true si OK, false si échec. */
	func checkCreateAsDirectory() -> Bool {
		let fileManager = FileManager.default
		let existence = fileManager.existence(at: self)
		// 1. Case OK (already exists)
		if existence == .directory {
			return true
		}
		// 2. Case file... delete the file.
		if existence == .file {
			printwarning("File exists with the name of the directory \(self).")
			do { try fileManager.removeItem(at: self) }
			catch {
				printerror(error.localizedDescription)
				return false
			}
		}
		// 3. Create the directory
		do {
			try fileManager.createDirectory(at: self, withIntermediateDirectories: true)
		} catch {
			printerror(error.localizedDescription)
			return false
		}
		return true
	}
	/** Permet de vérifier s'il existe un fichier, un dossier ou rien à l'url courante. */
	func getExistence() -> FileExistence {
		return FileManager.default.existence(at: self)
	}
}


extension Array {
	/** Création à partir du ficher. */
	/*init?(contentsOf url: URL) {
		guard let data = try? Data(contentsOf: url) else {
			return nil
		}
		self.init(data.withUnsafeBytes {
			$0.bindMemory(to: Element.self)
		})
	}*/
	
	/** Création à partir d'un fichier encodé. */
	init?(contentsOf url: URL, encodedWith key: UInt32) {
		guard let data = try? Data(contentsOf: url) else {
			return nil
		}
		let uintArr = data.withUnsafeBytes {
			Array<UInt32>($0.bindMemory(to: UInt32.self))
		}
		self.init(uintArr.decoded(key: key).serialized(to: Element.self))
	}
	
	/** Écriture dans un fichier encodé. */
	func write(to url: URL, encodedWith key: UInt32) {
		let encoded = self.serialized(to: UInt32.self).encoded(key: key)
		let size = encoded.count * MemoryLayout<UInt32>.size
		let data = Data(bytes: encoded, count: size)
		do { try data.write(to: url) }
		catch { printerror(error.localizedDescription) }
	}
	
	/*
	func write(to url: URL) {
		let size = count * MemoryLayout<Element>.size
		let data = Data(bytes: self, count: size)
		do {try data.write(to: url)}
		catch {printerror(error.localizedDescription)}
	}*/
}


