//
//  iCloudDocumentsManager.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-07-02.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

protocol ICloudDriveDependent: ScreenBase {
    func driveIsOK()
    func driveIsUpdating()
	func driveDidUpdate()
    func iCloudDriveStatusChanged(isOn: Bool)
}

fileprivate func getQuery() -> NSMetadataQuery {
    let query = NSMetadataQuery()
    query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    query.predicate = NSPredicate(format: "NOT %K.pathExtension = '.'", NSMetadataItemFSNameKey)
    return query
}

class ICloudDriveManager {
	// Enregistre s'il fallait mettre à jour...
	private var wasUpdating = false
	private unowned let dependent: ICloudDriveDependent
	private var metadataquery: NSMetadataQuery? = nil
    
	
	init(dependent: ICloudDriveDependent) {
		self.dependent = dependent
	}
    private func startQuery() {
        guard metadataquery == nil else { return }
        metadataquery = getQuery()
        metadataquery?.start()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdate),
                                               name: NSNotification.Name.NSMetadataQueryDidUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdate),
                                               name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                               object: nil)
    }
    private func stopQuery() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSMetadataQueryDidUpdate,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSMetadataQueryDidFinishGathering,
                                                  object: nil)
        metadataquery?.stop()
        metadataquery = nil
    }
    
    func startWatching() {
        if FileManager.default.iCloudDocumentsIsActivated {
            startQuery()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(iCloudChange),
                                               name: NSNotification.Name.NSUbiquityIdentityDidChange,
                                               object: nil)
    }
    func stopWatching() {
        NotificationCenter.default.removeObserver(self)
        metadataquery?.stop()
        metadataquery = nil
    }
    
    @objc func iCloudChange() {
        if FileManager.default.iCloudDocumentsIsActivated {
            startQuery()
            dependent.iCloudDriveStatusChanged(isOn: true)
        } else {
            dependent.iCloudDriveStatusChanged(isOn: false)
        }
        
    }
	
	@objc func didUpdate() {
		var isUpdating = false       
		metadataquery?.enumerateResults { (item: Any, index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
			guard let metadataItem = item as? NSMetadataItem else { return }
			guard let url = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL else { return }
			switch metadataItem.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String {
				case NSMetadataUbiquitousItemDownloadingStatusCurrent:
					// Cas "OK".
					break
				case NSMetadataUbiquitousItemDownloadingStatusDownloaded:
					// Cas "de trop" sera effacé...
					isUpdating = true
				case NSMetadataUbiquitousItemDownloadingStatusNotDownloaded:
					// Cas "manquant"
					isUpdating = true
                    // Demande de téléchargement...
					do { try FileManager.default.startDownloadingUbiquitousItem(at: url) }
					catch { printerror(error.localizedDescription) }
				default: print("undefined.")
			}
		}
        switch (isUpdating, wasUpdating) {
            case (false, false):
                dependent.driveIsOK()
            case (true, false):
                dependent.driveIsUpdating() // (début de l'update)
            case (true, true):
                break // (pass) pas fini d'updater...
            case (false, true):
                dependent.driveDidUpdate()
        }
		wasUpdating = isUpdating
	}
}
