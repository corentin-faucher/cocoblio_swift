//
//  Mesh.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-27.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

/** Structure utilisée pour les maillages de surfaces.
 * Classe (par référence) car les noeuds ne font que y référer. */
class Mesh {
    /** La structure des vertex pour les meshes du projet:
     *  position (3 floats), uv (2 floats), vecteur normal (3 floats). */
    typealias Vertex = (position: (Float, Float, Float),
        uv: (Float, Float), normal: (Float, Float, Float))
    
    let primitiveType: MTLPrimitiveType
    let cullMode: MTLCullMode
    var vertices: [Vertex] = []
    var indices: [UInt16] = []
    private(set) var verticesBuffer: MTLBuffer? = nil
    private(set) var indicesBuffer: MTLBuffer? = nil
    
    static let gridM = 20 // En case et non en vertex.
    
    init(primitive: MTLPrimitiveType = .triangleStrip, cullMode: MTLCullMode = .none) {
        primitiveType = primitive
        self.cullMode = cullMode
    }
    
    func initBuffers(with device: MTLDevice) {
        let dataSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        verticesBuffer = device.makeBuffer(bytes: vertices, length: dataSize, options: [])
        if !indices.isEmpty {
            let indDataSize = indices.count * MemoryLayout.size(ofValue: indices[0])
            indicesBuffer = device.makeBuffer(bytes: indices, length: indDataSize, options: [])
        }
    }
    
    func updateVertices() {
        let dataSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        verticesBuffer?.contents().copyMemory(from: vertices, byteCount: dataSize)
    }
    
    /*-- Statics: meshes de bases et gestion de la mesh présente. --*/
    /* (Pourrait être des sous-classes de Mesh, mais pas nécessaire pour l'instant...) */
    static let sprite = Mesh()
    static let triangle = Mesh(primitive: .triangle)
    static let fan = Mesh(primitive: .triangle)
    static let grid = Mesh(primitive: .triangle)
    static func initBasicMeshes(with device: MTLDevice) {
        // 1. sprite
        sprite.vertices = [((-0.5, 0.5, 0), (0,0), (0,0,1)),
                           ((-0.5,-0.5, 0), (0,1), (0,0,1)),
                           (( 0.5, 0.5, 0), (1,0), (0,0,1)),
                           (( 0.5,-0.5, 0), (1,1), (0,0,1))]
        sprite.initBuffers(with: device)
        // 2. triangle
        triangle.vertices = [(( 0.0, 0.5, 0),   (0.5,0), (0,0,1)),
                            ((-0.433,-0.25, 0), (0.067,0.75), (0,0,1)),
                            (( 0.433,-0.25, 0), (0.933,0.75), (0,0,1))]
        triangle.initBuffers(with: device)
        // 3. fan
        fan.vertices = Array(repeating: ((0, 0, 0), (0,0), (0,0,1)), count: 10)
        fan.vertices[0].uv = (0.5, 0.5)
        for i in 1...9 {
            fan.vertices[i].position = (-0.5 * sin(2 * .pi * (Float)(i-1) / 8),
                                        0.5 * cos(2 * .pi * (Float)(i-1) / 8), 0)
            fan.vertices[i].uv = (0.5 - 0.5 * sin(2 * .pi * (Float)(i-1) / 8),
                                  0.5 - 0.5 * cos(2 * .pi * (Float)(i-1) / 8))
        }
        fan.indices = [0, 1, 2,
                       0, 2, 3,
                       0, 3, 4,
                       0, 4, 5,
                       0, 5, 6,
                       0, 6, 7,
                       0, 7, 8,
                       0, 8, 9]
        fan.initBuffers(with: device)
        // 4. Grid
        grid.vertices = Array(repeating: ((0, 0, 0), (0,0), (0,0,1)), count: (gridM+1)*(gridM+1))
        grid.indices = Array(repeating: 0, count: gridM*gridM*6)
        for i in 0..<gridM {
            for j in 0..<gridM {
                let dec = i*gridM*6 + j*6
                grid.indices[dec]     = UInt16(i*(gridM+1) + j)
                grid.indices[dec + 1] = UInt16(i*(gridM+1) + j + 1)
                grid.indices[dec + 2] = UInt16((i+1)*(gridM+1) + j)
                grid.indices[dec + 3] = UInt16(i*(gridM+1) + j + 1)
                grid.indices[dec + 4] = UInt16((i+1)*(gridM+1) + j + 1)
                grid.indices[dec + 5] = UInt16((i+1)*(gridM+1) + j)
            }
        }
        for i in 0..<(gridM+1) {
            for j in 0..<(gridM+1) {
                grid.vertices[i*(gridM+1) + j].uv = (Float(i) / Float(gridM), Float(j) / Float(gridM))
                let x = 2 * Float(i) / Float(gridM) - 1
                let y = 2 * Float(j) / Float(gridM) - 1
                grid.vertices[i*(gridM+1) + j].position = (x, y, pow(x,2) + pow(y,2))
                
            }
        }
        grid.initBuffers(with: device)
    }
    static func setTheFan(with ratio: Float) {
        if fan.vertices.count < 10 {printerror("Fan pas init."); return}
        for i in 1...9 {
            fan.vertices[i].position = (-0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                        0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8), 0)
            fan.vertices[i].uv = (0.5 - 0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                  0.5 - 0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8))
        }
        fan.updateVertices()
    }
    
    static func setMesh(newMesh: Mesh, with commandEncoder: MTLRenderCommandEncoder) {
        currentMesh = newMesh
        currentPrimitiveType = newMesh.primitiveType
        currentVertexCount = newMesh.vertices.count
        
        commandEncoder.setCullMode(newMesh.cullMode)
        commandEncoder.setVertexBuffer(newMesh.verticesBuffer, offset: 0, index: 0)
    }
    static var currentMesh: Mesh? = nil
    // Autres donnée utiles (pour draw)
    static var currentPrimitiveType: MTLPrimitiveType = .triangle
    static var currentVertexCount: Int = 0
}
