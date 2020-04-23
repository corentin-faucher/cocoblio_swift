//
//  ScreenBase.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/*
protocol Screenable : Reshapable, Openable {
	var escapeAction: (()->Void)? { get }
	var enterAction: (()->Void)? { get }
}

extension Screenable {
	func open() {
		alignScreenElements(isOpening: true)
	}
	func reshape() -> Bool {
		alignScreenElements(isOpening: false)
		return true
	}
	func alignScreenElements(isOpening: Bool) {
		guard let theParent = parent else {printerror("Pas de parent."); return}
		if !containsAFlag(Flag1.dontAlignScreenElements) {
			let ceiledScreenRatio = theParent.width.realPos / theParent.height.realPos
			var alignOpt = AlignOpt.respectRatio | AlignOpt.setSecondaryToDefPos
			if (ceiledScreenRatio < 1) {
				alignOpt |= AlignOpt.vertically
			}
			if (isOpening) {
				alignOpt |= AlignOpt.fixPos
			}
			
			self.alignTheChildren(alignOpt: alignOpt, ratio: ceiledScreenRatio)
			
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
*/

class ScreenBase : Node, Reshapable, Openable {
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
		if let bigBro = refNode.firstChild as? ScreenBase {
			super.init(bigBro, 0, 0, 4, 4, lambda: 0, flags: flags, asParent: false, asElderBigbro: false)
		} else {
			super.init(refNode, 0, 0, 4, 4, lambda: 0, flags: flags)
		}
	}
	required init(other: Node) {
		let theOther = other as! ScreenBase
		self.escapeAction = theOther.escapeAction
		self.enterAction = theOther.enterAction
		super.init(other: theOther)
	}
	
	func open() {
		alignScreenElements(isOpening: true)
	}
	
	func reshape() -> Bool {
		alignScreenElements(isOpening: false)
		return true
	}
	
	func alignScreenElements(isOpening: Bool) {
		guard let theParent = parent else {printerror("Pas de parent."); return}
		if !containsAFlag(Flag1.dontAlignScreenElements) {
			let ceiledScreenRatio = theParent.width.realPos / theParent.height.realPos
			var alignOpt = AlignOpt.respectRatio | AlignOpt.setSecondaryToDefPos
			if (ceiledScreenRatio < 1) {
				alignOpt |= AlignOpt.vertically
			}
			if (isOpening) {
				alignOpt |= AlignOpt.fixPos
			}
			
			self.alignTheChildren(alignOpt: alignOpt, ratio: ceiledScreenRatio)
			
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

