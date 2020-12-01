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
    
	/*-- Fields --*/
	var vertices: [Vertex] = []
    let verticesSize: Int
	var indices: [UInt16] = []
	let primitiveType: MTLPrimitiveType
    let cullMode: MTLCullMode
//    private(set) var verticesBuffer: MTLBuffer? = nil
    private(set) var indicesBuffer: MTLBuffer? = nil
    
    /*-- Methods --*/
	init(vertices: [Vertex], indices: [UInt16],
		primitive: MTLPrimitiveType = .triangle, cullMode: MTLCullMode = .none
	) {
		self.vertices = vertices
		self.indices = indices
        primitiveType = primitive
        self.cullMode = cullMode
		// Init buffers
        verticesSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
//		verticesBuffer = Mesh.device.makeBuffer(bytes: vertices, length: verticesSize, options: [])
		if !indices.isEmpty {
			let indDataSize = indices.count * MemoryLayout.size(ofValue: indices[0])
			indicesBuffer = Mesh.device.makeBuffer(bytes: indices, length: indDataSize, options: [])
		}
    }
	init(other: Mesh) {
		vertices = other.vertices
        verticesSize = other.verticesSize
		indices = other.indices
		primitiveType = other.primitiveType
		cullMode = other.cullMode
		// Init bufferss
//		verticesBuffer = Mesh.device.makeBuffer(bytes: vertices, length: dataSize, options: [])
		if !indices.isEmpty {
			let indDataSize = indices.count * MemoryLayout.size(ofValue: indices[0])
			indicesBuffer = Mesh.device.makeBuffer(bytes: indices, length: indDataSize, options: [])
		}
	}
    
//	func updateVerticesBuffer() {
//		verticesBuffer?.contents().copyMemory(from: vertices, byteCount: verticesSize)
//	}
    
    /*-- Statics: meshes de bases et gestion de la mesh présente. --*/
	/*-- Static fields --*/
	// Meshes de base
	static private(set) var sprite: Mesh!
	static private(set) var triangle: Mesh!
	static private(set) var fan: Mesh!
	/** Graph z = f(x,y) */
	static private(set) var graph: Mesh!
	static let gridM = 20 // Nomebre de cases dans une grille (vertex = gridM+1)
	/** Réference ver le "gpu" pour setter les buffers. */
	private static var device: MTLDevice!
	
	/*-- Static methods --*/
    static func setDeviceAndInitBasicMeshes(_ device: MTLDevice) {
		// 0. Set device.
		Mesh.device = device
        // 1. sprite
		sprite = Mesh(vertices:
			[((-0.5, 0.5, 0), (0,0), (0,0,1)),
			 ((-0.5,-0.5, 0), (0,1), (0,0,1)),
			 (( 0.5, 0.5, 0), (1,0), (0,0,1)),
			 (( 0.5,-0.5, 0), (1,1), (0,0,1))],
			indices: [], primitive: .triangleStrip)
        // 2. triangle
		triangle = Mesh(vertices:
			[(( 0.0, 0.5, 0),   (0.5,0), (0,0,1)),
			 ((-0.433,-0.25, 0), (0.067,0.75), (0,0,1)),
			 (( 0.433,-0.25, 0), (0.933,0.75), (0,0,1))],
			indices: [])
        // 3. fan
		// Préparation des vertices de la fan.
		var vertices = Array<Vertex>(repeating: ((0, 0, 0), (0,0), (0,0,1)), count: 10)
		for i in 1...9 {
			vertices[i].position = (-0.5 * sin(2 * .pi * (Float)(i-1) / 8),
										0.5 * cos(2 * .pi * (Float)(i-1) / 8), 0)
			vertices[i].uv = (0.5 - 0.5 * sin(2 * .pi * (Float)(i-1) / 8),
								  0.5 - 0.5 * cos(2 * .pi * (Float)(i-1) / 8))
		}
		fan = Mesh(
			vertices: vertices,
			indices:
			[0, 1, 2,
			 0, 2, 3,
			 0, 3, 4,
			 0, 4, 5,
			 0, 5, 6,
			 0, 6, 7,
			 0, 7, 8,
			 0, 8, 9]
		)
        // 4. Grid
		// Préparation des vertices et indices de la grille.
        vertices = Array(repeating: ((0, 0, 0), (0,0), (0,0,1)), count: (gridM+1)*(gridM+1))
        var indices = Array<UInt16>(repeating: 0, count: gridM*gridM*6)
        for i in 0..<gridM {
            for j in 0..<gridM {
                let dec = i*gridM*6 + j*6
                indices[dec]     = UInt16(i*(gridM+1) + j)
                indices[dec + 1] = UInt16(i*(gridM+1) + j + 1)
                indices[dec + 2] = UInt16((i+1)*(gridM+1) + j)
                indices[dec + 3] = UInt16(i*(gridM+1) + j + 1)
                indices[dec + 4] = UInt16((i+1)*(gridM+1) + j + 1)
                indices[dec + 5] = UInt16((i+1)*(gridM+1) + j)
            }
        }
        for i in 0..<(gridM+1) {
            for j in 0..<(gridM+1) {
                vertices[i*(gridM+1) + j].uv = (Float(i) / Float(gridM), Float(j) / Float(gridM))
                let x = 2 * Float(i) / Float(gridM) - 1
                let y = 2 * Float(j) / Float(gridM) - 1
                vertices[i*(gridM+1) + j].position = (x, y, pow(x,2) + pow(y,2))
                
            }
        }
		graph = Mesh(vertices: vertices, indices: indices)
    }
    static func setTheFan(with ratio: Float) {
        if fan.vertices.count < 10 {printerror("Fan pas init."); return}
        for i in 1...9 {
            fan.vertices[i].position = (-0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                        0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8), 0)
            fan.vertices[i].uv = (0.5 - 0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                  0.5 - 0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8))
        }
//		fan.updateVerticesBuffer()
    }
}
