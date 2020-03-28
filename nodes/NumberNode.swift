//
//  NumberNode.swift
//  testcocoblio
//
//  Created by Corentin Faucher on 2020-01-29.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

/** Noeud racine d'un nombre. Les enfants sont des Surfaces "digits".
 * (NumberNode pour ne pas interférer avec la class Number de Kotlin.) */
class NumberNode : Node {
    private var number: Int
    private var digitsTex: Texture
    private var unitDecimal: Int
    private var separator: Digit
    private var extraDigit: Digit?
    private var spacing: Float
    private var sepSpacing: Float
    
    init(_ refNode: Node?, number: Int,
         _ x: Float, _ y: Float, height: Float, lambda: Float = 0,
		 unitDecimal: Int = 0, digitsTex: Texture = Texture.blackDigits,
         separator: Digit = .dot, extraDigit: Digit? = nil,
         spacing: Float = 0.83, separatorSpacing: Float = 0.5) {
        self.digitsTex = digitsTex
        self.number = number
        self.unitDecimal = unitDecimal
        self.separator = separator
        self.extraDigit = extraDigit
        self.spacing = spacing
        self.sepSpacing = separatorSpacing
        super.init(refNode, x, y, 1, 1, lambda: lambda)
        scaleX.set(height)
        scaleY.set(height)
        
        update()
    }
    required init(other: Node) {
        let toCloneNumber = other as! NumberNode
        digitsTex = toCloneNumber.digitsTex
        number = toCloneNumber.number
        unitDecimal = toCloneNumber.unitDecimal
        separator = toCloneNumber.separator
        extraDigit = toCloneNumber.extraDigit
        spacing = toCloneNumber.spacing
        sepSpacing = toCloneNumber.sepSpacing
        super.init(other: other)
        update()
    }
    
    func update(newNumber: Int, newUnitDecimal: Int? = nil, newSeparator: Digit? = nil) {
        number = newNumber
        if let ud = newUnitDecimal { unitDecimal = ud }
        if let sep = newSeparator { separator = sep }

        update()
    }
    private func update() {
        // 0. Init...
        let refSurf = TiledSurface(nil, pngTex: digitsTex, 0, 0, 1)
        refSurf.scaleX.set(spacing)
        let sq = Squirrel(at: self)
        let displayedNumber: UInt = UInt(abs(number))
        let isNegative = number < 0
        let maxDigits = max(displayedNumber.getHighestDecimal(), unitDecimal)

        // 1. Signe "-"
        sq.goDownForced(refSurf)
        if (isNegative) {
            (sq.pos as? TiledSurface)?.updateTile(Digit.minus.rawValue, 0)
            sq.goRightForced(refSurf)
        }
        // 2. Chiffres avant le "separator"
        for i in (unitDecimal...maxDigits).reversed() {
            (sq.pos as? TiledSurface)?.updateTile(Int(displayedNumber.getTheDigitAt(i)), 0)
            if i > 0 {
                sq.goRightForced(refSurf)
            }
        }
        // 3. Separator et chiffres restants
        if(unitDecimal > 0) {
            (sq.pos as? TiledSurface)?.updateTile(separator.rawValue, 0)
            sq.pos.scaleX.set(sepSpacing)
            sq.goRightForced(refSurf)
            for i in (0...(unitDecimal-1)).reversed() {
                (sq.pos as? TiledSurface)?.updateTile(Int(displayedNumber.getTheDigitAt(i)), 0)
                if(i > 0) {
                    sq.goRightForced(refSurf)
                }
            }
        }
        // 4. Extra/"unit" digit
        if let ed = extraDigit {
            sq.goRightForced(refSurf)
            (sq.pos as? TiledSurface)?.updateTile(ed.rawValue, 0)
        }
        // 5. Nettoyage de la queue.
        while (sq.pos.littleBro != nil) {
            sq.pos.disconnectBro(big: false)
        }
        // 6. Alignement
        alignTheChildren(alignOpt: 0, ratio: 1)
        // 7. Vérifier s'il faut afficher... (live update)
        if(containsAFlag(Flag1.show)) {
            openBranch()
        }
    }
}
