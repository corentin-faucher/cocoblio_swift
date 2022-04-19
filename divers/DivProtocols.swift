//
//  DivProtocols.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2022-03-30.
//  Copyright © 2022 Corentin Faucher. All rights reserved.
//

import Foundation

protocol Copyable {
    init(other: Self)
}

extension Copyable {
    func copy() -> Self {
        return Self.init(other: self)
    }
}

/** Pour ajouter un état à un objet sous la forme d'un ensemble de "flag" binaires. */
protocol Flagable: AnyObject {
    associatedtype FlagInt: FixedWidthInteger
    var flags: FlagInt { get set }
}

extension Flagable {
    func removeFlags(_ toRemove: FlagInt) {
        flags &= ~toRemove
    }
    /** Ajouter des flags au noeud. */
    func addFlags(_ toAdd: FlagInt) {
        flags |= toAdd
    }
    func addRemoveFlags(_ toAdd: FlagInt, _ toRemove: FlagInt) {
        flags = (flags | toAdd) & ~toRemove
    }
    func containsAFlag(_ flagsRef: FlagInt) -> Bool {
        return (flags & flagsRef) != 0
    }
    func setFlag(_ toSet: FlagInt, isOn: Bool) {
        if isOn {
            flags |= toSet
        } else {
            flags &= ~toSet
        }
    }
}

// Pour un curseur à afficher... (pas utilisé, utile ?)
protocol Cursorable {
    func moveAt(_ pos: Vector2)
    func clickAt(_ pos: Vector2)
    func unclick()
}
