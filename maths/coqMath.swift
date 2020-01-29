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

extension float4x4 {
    mutating func scale(with scale: float3) {
        self.columns.0 *= scale.x
        self.columns.1 *= scale.y
        self.columns.2 *= scale.z
    }
    
    mutating func translate(with t: float3) {
        self.columns.3.x += self.columns.0.x * t.x + self.columns.1.x * t.y + self.columns.2.x * t.z
        self.columns.3.y += self.columns.0.y * t.x + self.columns.1.y * t.y + self.columns.2.y * t.z
        self.columns.3.z += self.columns.0.z * t.x + self.columns.1.z * t.y + self.columns.2.z * t.z
    }
    
    mutating func rotateY(ofRadian theta: Float) {
        let c = cosf(theta)
        let s = sinf(theta)
        
        let v0: float4 = self.columns.0
        let v2: float4 = self.columns.2
        
        self.columns.0 = c*v0 - s*v2 // Ou au long x,y,z ? et pas w ?
        
        self.columns.2 = s*v0 + c*v2
    }
    
    mutating func rotateZ(ofRadian theta: Float) {
        let c = cosf(theta)
        let s = sinf(theta)
        
        let v0: float4 = self.columns.0
        let v1: float4 = self.columns.1
        
        self.columns.0 = c*v0 - s*v1 // Ou au long x,y,z ? et pas w ?
        self.columns.1 = s*v0 + c*v1
    }
    
    mutating func makePerspective(fovRadian theta: Float, aspect ratio: Float,
                                  nearZ: Float, farZ: Float) {
        let cotan = 1.0 / tanf(theta/2.0)
        self.columns = ([cotan / ratio, 0, 0, 0],
                        [0, cotan, 0, 0],
                        [0, 0, (farZ + nearZ) / (nearZ - farZ), -1],
                        [0, 0, (2 * farZ * nearZ) / (nearZ - farZ), 0])
    }
    
    
    mutating func makePerspective(nearZ: Float, farZ: Float, middleZ: Float,
                         deltaX: Float, deltaY: Float)
    {
        self.columns = ([2 * middleZ / deltaX, 0, 0, 0],
                        [0, 2 * middleZ / deltaY, 0, 0],
                        [0, 0, (farZ + nearZ) / (nearZ - farZ), -1],
                        [0, 0, (2 * farZ * nearZ) / (nearZ - farZ), 0])
    }
    
    mutating func makeLookAt(eye: float3, center: float3, up: float3)
    {
        let n: float3 = normalize(eye - center)
        let u: float3 = normalize(cross(up, n))
        let v: float3 = cross(n, u)
        
        self.columns = ([u.x, v.x, n.x, 0],
                     [u.y, v.y, n.y, 0],
                     [u.z, v.z, n.z, 0],
                     [-dot(u, eye), -dot(v, eye), -dot(n, eye), 1])
    }
}


extension Float {
    static func random(mean: Float, delta: Float) -> Float {
        return Float.random(in: mean-delta...mean+delta)
    }
    /// Retourne une angle dans l'interval [-pi, pi].
    mutating func normalizeAngle() {
        self = self - floorf((self + .pi) / (2 * .pi)) * 2 * .pi
    }
}

extension Int {
    func getHighestDecimal() -> Int {
        let highestDecimal = Int.pow2numberOfDigit[(self != 0) ? 31 - self.leadingZeroBitCount : 0]
        return highestDecimal + ((self > Int.pow10m1[highestDecimal]) ? 1 : 0)
    }
    
    func getTheDigitAt(_ decimal: Int) -> Int {
        return (self / Int.pow10[decimal]) % 10
    }
    
    private static let pow10: [Int] = [
        1,       10,       100,
        1000,    10000,    100000,
        1000000, 10000000, 100000000,
        1000000000]
    private static let pow10m1: [Int] = [
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
