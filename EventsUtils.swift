//
//  EventsHandler.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-04-07.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation
#if os(OSX)
import AppKit
import Carbon
import Carbon.HIToolbox
#endif

/*
protocol EventsHandler {
	func singleTap(pos: Vector2)
	func initTouchDrag()
	func touchDrag(posNow: Vector2)
	func letTouchDrag(vit: Vector2)
	
	func keyDown(key: KeyboardKey)
	func keyUp(key: KeyboardKey)
	func modifiersChangedTo(_ newModifiers: UInt)
	
	func appStart()
	func configurationChanged()
	func appPaused()
	
	func willDrawFrame()
}
*/

protocol KeyboardKey {
	var keycode: UInt16 { get }
	var keymod: UInt { get }
	var isVirtual: Bool { get }
}

struct KeyData : KeyboardKey {
	var keycode: UInt16
	var keymod: UInt
	var isVirtual: Bool
}

/** MyKeyCode... */
enum MKC {
	static let space = 51
	static let delete = 52
	static let return_ = 53
	static let escape = 54
	static let tab = 55
	static let capsLock = 60
	static let control = 61
	static let shift = 62
	static let option = 63
	static let command = 64
	static let rightControl = 65
	static let rightShift = 66
	static let rightOption = 67
	static let rightCommand = 68
	static let empty = 99
}

enum Keycode {
	#if os(OSX)
	// Touches modifier
	static let command: UInt16 = 0x37
	static let shift: UInt16 = 0x38
	static let capsLock: UInt16 = 0x39
	static let option: UInt16 = 0x3A
	static let control: UInt16 = 0x3B
	static let rightCommand: UInt16 = 0x36
	static let rightShift: UInt16 = 0x3C
	static let rightOption: UInt16 = 0x3D
	static let rightControl: UInt16 = 0x3E
	// Touche "importantes"
	static let return_: UInt16 = 0x24
	static let keypadEnter: UInt16 = 0x4C
	static let tab: UInt16 = 0x30
	static let space: UInt16 = 0x31
	static let delete: UInt16 = 0x33
	static let forwardDelete: UInt16 = 0x75
	static let escape: UInt16 = 0x35
	// Touches de directions
	static let leftArrow : UInt16 = 0x7B
	static let rightArrow: UInt16 = 0x7C
	static let downArrow: UInt16 = 0x7D
	static let upArrow: UInt16 = 0x7E
	// Touches spéciales ANSI, ISO, JIS
	static let ANSI_Backslash: UInt16 = 0x2A
	static let ANSI_Grave = 0x32
	static let ISO_section: UInt16 = 0x0A
	static let JIS_Yen: UInt16 = 0x5D
	static let JIS_Underscore: UInt16 = 0x5E
	#else
	// Touches modifier
	static let capsLock: UInt16 = 0x39
	static let control: UInt16 = 0xE0
	static let shift: UInt16 = 0xE1
	static let option: UInt16 = 0xE2
	static let command: UInt16 = 0xE3
	static let rightControl: UInt16 = 0xE4
	static let rightShift: UInt16 = 0xE5
	static let rightOption: UInt16 = 0xE6
	static let rightCommand: UInt16 = 0xE7
	// Touche "importantes"
	static let return_: UInt16 = 0x28
	static let keypadEnter: UInt16 = 0x58
	static let tab: UInt16 = 0x2B
	static let space: UInt16 = 0x2C
	static let delete: UInt16 = 0x2A
	static let forwardDelete: UInt16 = 0x4C
	static let escape: UInt16 = 0x29
	// Touches de directions
	static let leftArrow : UInt16 = 0x50
	static let rightArrow: UInt16 = 0x4F
	static let downArrow: UInt16 = 0x51
	static let upArrow: UInt16 = 0x52
	// Touches spéciales ANSI, ISO, JIS
	static let ANSI_Backslash: UInt16 = 0x31
	static let ANSI_Grave = 0x35
	static let ISO_Backslash: UInt16 = 0x32
	static let ISO_section: UInt16 = 0x64
	static let JIS_Yen: UInt16 = 0x89
	static let JIS_Underscore: UInt16 = 0x87
	#endif
	// Dummy "empty" (touche "vide" ne faisant rien)
	static let empty: UInt16 = 0xFF
}

enum Modifier {
	#if os(OSX)
	static let command: UInt = NSEvent.ModifierFlags.command.rawValue
	static let shift: UInt = NSEvent.ModifierFlags.shift.rawValue
	static let capsLock: UInt = NSEvent.ModifierFlags.capsLock.rawValue
	static let option: UInt = NSEvent.ModifierFlags.option.rawValue
	static let control: UInt = NSEvent.ModifierFlags.control.rawValue
	#else
	static let command: UInt =  0x100000
	static let shift: UInt =    0x020000
	static let capsLock: UInt = 0x010000
	static let option: UInt =   0x080000
	static let control: UInt =  0x040000
	#endif
	static let shiftOrOption = shift | option
}
