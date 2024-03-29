//
//  coq3D.swift
//  MetalTestIOS
//
//  Created by Corentin Faucher on 2018-10-15.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//

/*------------------*/
/*** Dans simd les matrices sont des tuples () de columns (accéder avec "columns")
 ***  et les columns sont des "array" [] de float... ***/

import simd

typealias Vector2 = SIMD2<Float>
typealias Vector3 = SIMD3<Float>
typealias Vector4 = SIMD4<Float>

extension Vector4 {
    var xyz: Vector3 {
        return Vector3(x, y, z)
    }
}

extension float4x4 {
    mutating func scale(with scale: Vector3) {
        self.columns.0 *= scale.x
        self.columns.1 *= scale.y
        self.columns.2 *= scale.z
    }
    
    mutating func translate(with t: Vector3) {
        self.columns.3.x += self.columns.0.x * t.x + self.columns.1.x * t.y + self.columns.2.x * t.z
        self.columns.3.y += self.columns.0.y * t.x + self.columns.1.y * t.y + self.columns.2.y * t.z
        self.columns.3.z += self.columns.0.z * t.x + self.columns.1.z * t.y + self.columns.2.z * t.z
    }
    
    mutating func setAndTranslate(ref: float4x4, with t: Vector3) {
        self.columns.0 = ref.columns.0
        self.columns.1 = ref.columns.1
        self.columns.2 = ref.columns.2
        self.columns.3 = [
            ref.columns.3.x + ref.columns.0.x * t.x + ref.columns.1.x * t.y + ref.columns.2.x * t.z,
            ref.columns.3.y + ref.columns.0.y * t.x + ref.columns.1.y * t.y + ref.columns.2.y * t.z,
            ref.columns.3.z + ref.columns.0.z * t.x + ref.columns.1.z * t.y + ref.columns.2.z * t.z,
            ref.columns.3.w
        ]
    }
    
    mutating func rotateX(ofRadian theta: Float) {
        let c = cosf(theta)
        let s = sinf(theta)
        
        let v1: Vector4 = self.columns.1
        let v2: Vector4 = self.columns.2
        
        self.columns.1 = c*v1 + s*v2 // Ou au long x,y,z ? et pas w ?
        self.columns.2 = c*v2 - s*v1
    }
    
    mutating func rotateY(ofRadian theta: Float) {
        let c = cosf(theta)
        let s = sinf(theta)
        
        let v0: Vector4 = self.columns.0
        let v2: Vector4 = self.columns.2
        
        self.columns.0 = c*v0 - s*v2 // Ou au long x,y,z ? et pas w ?
        self.columns.2 = s*v0 + c*v2
    }
    
    mutating func rotateZ(ofRadian theta: Float) {
        let c = cosf(theta)
        let s = sinf(theta)
        
        let v0: Vector4 = self.columns.0
        let v1: Vector4 = self.columns.1
        
        self.columns.0 = c*v0 - s*v1 // Ou au long x,y,z ? et pas w ?
        self.columns.1 = s*v0 + c*v1
    }
    mutating func rotateYandTranslateYZ(thetaY: Float, ty: Float, tz: Float) {
        let c = cosf(thetaY)
        let s = sinf(thetaY)
        
        let v0: Vector4 = self.columns.0
        let v2: Vector4 = self.columns.2
        
        self.columns.0 = c*v0 - s*v2 // Ou au long x,y,z ? et pas w ?
        self.columns.2 = s*v0 + c*v2
        
        self.columns.3.x += self.columns.1.x * ty + self.columns.2.x * tz
        self.columns.3.y += self.columns.1.y * ty + self.columns.2.y * tz
        self.columns.3.z += self.columns.1.z * ty + self.columns.2.z * tz
    }
    
    mutating func setRotateYandTranslateYZ(ref: float4x4, thetaY: Float, ty: Float, tz: Float) {
        let c = cosf(thetaY)
        let s = sinf(thetaY)
        
        let v2_rot: Vector4 = s*ref.columns.0 + c*ref.columns.2
        
        self.columns.0 = c*ref.columns.0 - s*ref.columns.2
        self.columns.1 = ref.columns.1
        self.columns.2 = v2_rot
        self.columns.3 = [
            ref.columns.3.x + ref.columns.1.x * ty + v2_rot.x * tz,
            ref.columns.3.y + ref.columns.1.y * ty + v2_rot.y * tz,
            ref.columns.3.z + ref.columns.1.z * ty + v2_rot.z * tz,
            ref.columns.3.w
        ]
    }
    
    mutating func setToLookAt(eye: Vector3, center: Vector3, up: Vector3)
    {
        let n: Vector3 = normalize(eye - center)
        let u: Vector3 = normalize(cross(up, n))
        let v: Vector3 = cross(n, u)
        
        self.columns = ([u.x, v.x, n.x, 0],
                     [u.y, v.y, n.y, 0],
                     [u.z, v.z, n.z, 0],
                     [-dot(u, eye), -dot(v, eye), -dot(n, eye), 1])
    }
    
    mutating func setToPerspective(fovRadian theta: Float, aspect ratio: Float,
                                  nearZ: Float, farZ: Float) {
        let cotan = 1.0 / tanf(theta/2.0)
        self.columns = ([cotan / ratio, 0, 0, 0],
                        [0, cotan, 0, 0],
                        [0, 0, (farZ + nearZ) / (nearZ - farZ), -1],
                        [0, 0, (2 * farZ * nearZ) / (nearZ - farZ), 0])
    }
    
    
    mutating func setToPerspective(nearZ: Float, farZ: Float, middleZ: Float,
                         deltaX: Float, deltaY: Float)
    {
        self.columns = ([2 * middleZ / deltaX, 0, 0, 0],
                        [0, 2 * middleZ / deltaY, 0, 0],
                        [0, 0, (farZ + nearZ) / (nearZ - farZ), -1],
                        [0, 0, (2 * farZ * nearZ) / (nearZ - farZ), 0])
    }
    
}

enum Digit: Int {
    case zero
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case space
    case unused1
    case underscore
    case plus
    case minus
    case mult
    case div
    case dot
    case comma
    case second
    case percent
    case equal
    case question
    case unused2
}

extension Float {
    static func random(mean: Float, delta: Float) -> Float {
        return Float.random(in: mean-delta...mean+delta)
    }
    /// Retourne une angle dans l'interval [-pi, pi].
    func toNormalizedAngle() -> Float {
        return self - ceilf((self - .pi) / (2 * .pi)) * 2 * .pi
    }
	
    // kotlin like utils...
	func roundToInt() -> Int {
		return Int(roundf(self))
	}
    func toInt() -> Int {
        return Int(self)
    }
    /** Retourne la plus grosse "subdivision" pour le nombre présent en base 10.
     * Le premier chiffre peut être : 1, 2 ou 5. Utile pour les axes de graphiques.
     * e.g.: 792 -> 500, 192 -> 100, 385 -> 200. */
    func toRoundedSubDiv() -> Float {
        let pow10 = powf(10, floorf(log10f(self)))
        let mantissa = self / pow10
        if mantissa < 2 {
            return pow10
        }
        if mantissa < 5 {
            return pow10 * 2
        }
        return pow10 * 5
    }
    /**-- Fonction "coupé", "en S", i.e.  __/
     *                                   /    */
    func truncated(delta: Float) -> Float {
        if self > 0 {
            return max(0, self - delta)
        } else {
            return min(0, self + delta)
        }
    }
}

extension Int {
    func containsFlag(_ flag: Int) -> Bool {
        return (self & flag) != 0
    }
}

extension UInt32 {
    func getHighestDecimal() -> Int {
        let highestDecimal = UInt32.pow2numberOfDigit[(self != 0) ? 31 - self.leadingZeroBitCount : 0]
        return highestDecimal + ((self > UInt32.pow10m1[highestDecimal]) ? 1 : 0)
    }
    
    func getTheDigitAt(_ decimal: Int) -> UInt32 {
        return (self / UInt32.pow10[decimal]) % 10
    }
    
    private static let pow10: [UInt32] = [
        1,       10,       100,
        1000,    10000,    100000,
        1000000, 10000000, 100000000,
        1000000000]
    private static let pow10m1: [UInt32] = [
        9,       99,       999,
        9999,    99999,    999999,
        9999999, 99999999, 999999999,
        4294967295]
    private static let pow2numberOfDigit: [Int] = [
        0, 0, 0, 0, 1, 1, 1, 2, 2, 2, // 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, ...
        3, 3, 3, 3, 4, 4, 4, 5, 5, 5,
        6, 6, 6, 6, 7, 7, 7, 8, 8, 8,
        9, 9, 9]
}

extension String {
	func toUInt32Key() -> UInt32 {
		if isEmpty {
			printerror("Empty string, no UInt32Key.")
			return 0
		}
		var tmp = self
		
		switch (utf8CString.count-1) % 4 {
			case 1: tmp += "abc"
			case 2: tmp += "ef"
			case 3: tmp += "g"
			default: break
		}
		
		guard let data = tmp.data(using: .utf8) else {
			printerror("No string?"); return 0
		}
		let uintArr: [UInt32] = data.toArray(type: UInt32.self)
		var key: UInt32 = 0
		for uint in uintArr {
			key ^= uint
			key = key << 1 ^ key >> 1
		}
		return key
	}
}


// Garbage
/*
 enum CoqMath {
 
 
 // Private stuff...
 /// Décimal la plus élevé pour ce nombre. 100 -> 2, 2 -> 0, 2000 -> 3, 0 -> 0
 static func getHighestDecimal(_ number: UInt32) -> Int {
 let highestDecimal = pow2numberOfDigit[(number != 0) ? 31 - number.leadingZeroBitCount : 0]
 return highestDecimal + ((number > pow10m1[highestDecimal]) ? 1 : 0)
 }
 
 static func getTheDigitOf(_ number: UInt32, at decimal: Int) -> UInt8 {
 return UInt8((number / pow10[decimal]) % 10)
 }
 
 private static let pow10: [UInt32] = [
 1,       10,       100,
 1000,    10000,    100000,
 1000000, 10000000, 100000000,
 1000000000]
 private static let pow10m1: [UInt32] = [
 9,       99,       999,
 9999,    99999,    999999,
 9999999, 99999999, 999999999,
 4294967295]
 private static let pow2numberOfDigit: [Int] = [
 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, // 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, ...
 3, 3, 3, 3, 4, 4, 4, 5, 5, 5,
 6, 6, 6, 6, 7, 7, 7, 8, 8, 8,
 9, 9, 9]
 }

 /// Vérifier si le nombre peut s'afficher avec le nombre de décimals demandé.
 /// (115, 2) -> 99 + warning d'overflow...
 static func checkNumber(_ number: inout UInt32, withAllowedDigits digits: Int) {
 if digits < 1 {printerror("!digits"); number = 0; return}
 if getHighestDecimal(number) >= digits {
 printerror("Overflow")
 number = pow10m1[digits-1]
 }
 }

 */
