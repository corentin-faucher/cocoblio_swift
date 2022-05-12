//
//  InterpolatedAngle.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2020-04-03.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import Foundation

struct InterpolatedAngle {
	/*-- Fields --*/
	private(set) var pos: Float = 0
	private(set) var vit: Float = 0
	private var lastIndex = 0
	private var currIndex = 0
	private var vX: [Float]
	private var vT: [Int64]
	
	/*-- Methods --*/
	init(size: Int, refPos: Float) {
		vX = Array<Float>(repeating: refPos, count: size)
		vT = Array(repeating: 0, count: size)
	}
	
	mutating func push(newPos: Float) {
		let time = RenderingChrono.elapsedMS
		guard time != vT[lastIndex] else {return}
		
		vX[currIndex] = newPos.toNormalizedAngle()
		vT[currIndex] = time
		
		let vXr = vX.map({($0 - vX[currIndex]).toNormalizedAngle()})
		let vTr = vT.map({Float($0 - vT[currIndex]) / 1000})
		
		let n = Float(vX.count)
		let sumPrTX: Float = zip(vXr, vTr).map(*).reduce(0,+)
		let sumT: Float = vTr.reduce(0, +)
		let sumX: Float = vXr.reduce(0, +)
		let sumT2: Float = vTr.map({$0*$0}).reduce(0, +)
		let det = n * sumT2 - sumT * sumT
		guard det != 0, sumT != 0 else {
			printerror("Error interpolation")
			return
		}
		
		// Interpolation
		vit = (n * sumPrTX - sumT * sumX) / det
		pos = (sumPrTX - vit * sumT2) / sumT + vX[currIndex]
		
		lastIndex = currIndex
		currIndex = (currIndex + 1) % vX.count
	}
}
