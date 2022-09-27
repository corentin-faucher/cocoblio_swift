//
//  ScreenBase.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

protocol Escapable : ScreenBase {
	func escapeAction()
}
protocol Enterable : ScreenBase {
	func enterAction()
}
protocol KeyResponder : ScreenBase {
	func keyDown(key: KeyboardKey)
	func keyUp(key: KeyboardKey)
	func modifiersChangedTo(_ newModifiers: UInt)
}
protocol CharResponder : ScreenBase {
    func charAction(_ char: Character)
}

class ScreenBase : Node
{
    var compactAlign: Bool = false
    var landscapePortraitThreshold: Float = 1
    var icloudManager: ICloudDriveManager? = nil
    
    /** Les écrans sont toujours ajoutés juste après l'ainé.
    * add 1 : 0->1,  add 2 : 0->{1,2},  add 3 : 0->{1,3,2},  add 4 : 0->{1,4,3,2}, ...
    * i.e. les deux premiers écrans sont le back et le front respectivement,
    * les autres sont au milieu. */
    required init(_ root: AppRootBase) {
        if let bigBro = root.firstChild as? ScreenBase {
            super.init(bigBro, 0, 0, 4, 4, lambda: 0, flags: Flag1.reshapableRoot,
                       asParent: false, asElderBigbro: false)
        } else {
            super.init(root, 0, 0, 4, 4, lambda: 0, flags: Flag1.reshapableRoot)
        }
    }
	required init(other: Node) {
		let theOther = other as! ScreenBase
		super.init(other: theOther)
	}
    
    func getScreenRatio() -> Float {
        guard let parent = parent else {
            printerror("No parent.")
            return 1
        }
        return parent.width.realPos / parent.height.realPos
    }
	
    override func open() {
		alignScreenElements(isOpening: true)
        icloudManager?.startWatching()
	}
    
    override func close() {
        icloudManager?.stopWatching()
    }
	
    override func reshape() {
		alignScreenElements(isOpening: false)
	}
	
	func alignScreenElements(isOpening: Bool) {
		guard let theParent = parent else {printerror("Pas de parent."); return}
		if !containsAFlag(Flag1.dontAlignScreenElements) {
            let screenRatio = getScreenRatio()
            var alignOpt = AlignOpt.setSecondaryToDefPos
            if !compactAlign {
                alignOpt |= AlignOpt.respectRatio
            }
            if screenRatio < landscapePortraitThreshold {
				alignOpt |= AlignOpt.vertically
			}
			if (isOpening) {
				alignOpt |= AlignOpt.fixPos
			}
			
			self.alignTheChildren(alignOpt: alignOpt, ratio: screenRatio)
			
			let scale = min(theParent.width.realPos / width.realPos,
							theParent.height.realPos / height.realPos)
			scaleX.set(scale, isOpening)
			scaleY.set(scale, isOpening)
		} else {
			scaleX.set(1, isOpening)
			scaleY.set(1, isOpening)
			width.set(theParent.width.realPos, isOpening)
			height.set(theParent.height.realPos, isOpening)
		}
	}
}


/*
/** PersistentScreen stay in the root structure after usage.
 * To be used with frequently used screen, e.g. MainMenu, backscreen... */
class PersistentScreen : Node, Screenable, Openable {
	let escapeAction: (()->Void)?
	let enterAction: (()->Void)?
	
	/** Les écrans sont toujours ajoutés juste après l'ainé.
	* add 1 : 0->1,  add 2 : 0->{1,2},  add 3 : 0->{1,3,2},  add 4 : 0->{1,4,3,2}, ...
	* i.e. les deux premiers écrans sont le back et le front respectivement,
	* les autres sont au milieu. */
	init(_ refNode: Node,
		 escapeAction: (()->Void)?,
		 enterAction: (()->Void)?,
		 flags: Int = 0
	) {
		self.escapeAction = escapeAction
		self.enterAction = enterAction
		if let bigBro = refNode.firstChild as? Screenable {
			super.init(bigBro, 0, 0, 4, 4, lambda: 0, flags: flags, asParent: false, asElderBigbro: false)
		} else {
			super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: flags)
		}
	}	
	required init(other: Node) {
		fatalError("init(other:) has not been implemented")
	}
}

/** EvanescentScreen does not need to be Openable since they are create/disconnect as needed. */
class EvanescentScreen : Node, Screenable, Openable {
	let escapeAction: (()->Void)?
	let enterAction: (()->Void)?
	
	/** Les écrans sont toujours ajoutés juste après l'ainé.
	* add 1 : 0->1,  add 2 : 0->{1,2},  add 3 : 0->{1,3,2},  add 4 : 0->{1,4,3,2}, ...
	* i.e. les deux premiers écrans sont le back et le front respectivement,
	* les autres sont au milieu. */
	init(_ refNode: Node,
		 escapeAction: (()->Void)?,
		 enterAction: (()->Void)?,
		 flags: Int = 0
	) {
		self.escapeAction = escapeAction
		self.enterAction = enterAction
		if let bigBro = refNode.firstChild as? Screenable {
			super.init(bigBro, 0, 0, 4, 4, lambda: 0, flags: flags, asParent: false, asElderBigbro: false)
		} else {
			super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: flags)
		}
	}
	required init(other: Node) {
		let theOther = other as! PersistentScreen
		self.escapeAction = theOther.escapeAction
		self.enterAction = theOther.enterAction
		super.init(other: theOther)
	}
}
*/

