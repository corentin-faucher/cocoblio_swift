//
//  NodeInterfaces.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-31.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

/** Un noeud pouvant être activé (e.g. les boutons ordinaires).
* On utilise les flags selectable et selectableRoot pour les trouver. */
// Obsolete ? -> mieux de faire une base class "button"
// (une base class peut flager la branche par défaut, un protocol ne peut pas)
protocol Actionable : Node {
    func action()
}

protocol Cursorable : Node {
	func moveAt(_ pos: Vector2)
	func clickAt(_ pos: Vector2)
	func unclick()
}

/** Un noeud pouvant être reshapé (e.g. un screen).
* (Reshape: ajustement des positions/dimensions en fonction du cadre du parent).
* Return: True s'il y a eu changement du cadre, i.e. besoin d'un reshape pour les enfants. */
protocol Reshapable : Node {
    func reshape() -> Bool
}


