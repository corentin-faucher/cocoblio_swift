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
	var applicationSupportDirectory: URL {
		return try! url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
	}
    var iCloudDocuments: URL? {
        guard let iCloudContainer = url(forUbiquityContainerIdentifier: nil) else { return nil }
        let iCloudDocUrl = iCloudContainer.appendingPathComponent("Documents", isDirectory: true)
        if !self.fileExists(atPath: iCloudDocUrl.path) {
            do { try createDirectory(at: iCloudDocUrl,
                                     withIntermediateDirectories: true, attributes: nil) }
            catch {
                printerror(error.localizedDescription)
                return nil
            }
        }
        return iCloudDocUrl
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



