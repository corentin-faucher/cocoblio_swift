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
    static let defaultVertex: Vertex = ((0, 0, 0), (0,0), (0,0,1))
    
	/*-- Fields --*/
	var vertices: [Vertex] = []
    var verticesSize: Int
	var indices: [UInt16] = []
	let primitiveType: MTLPrimitiveType
    let cullMode: MTLCullMode
    private(set) var verticesBuffer: MTLBuffer? = nil
    private(set) var indicesBuffer: MTLBuffer? = nil
    
    /*-- Methods --*/
	init(vertices: [Vertex], indices: [UInt16],
         primitive: MTLPrimitiveType = .triangle, cullMode: MTLCullMode = .none,
         withVerticesBuffer: Bool = false
	) {
		self.vertices = vertices
		self.indices = indices
        primitiveType = primitive
        self.cullMode = cullMode
		// Init buffers
        verticesSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        if withVerticesBuffer {
            verticesBuffer = Mesh.device.makeBuffer(bytes: vertices, length: verticesSize, options: [])
        }
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
    
    /** A utiliser pour mettre à jour le buffer des vertex SEULEMENT si on utilise le vertex buffer, i.e. pour un grand nombre de vertex.
     *  (pour quelques vertex on passe directement l'array de vertex au renderer, voir Surface.draw dans Renderer) */
    func updateVerticesBuffer(_ withVerticesBuffer: Bool = true)
    {
        verticesSize = vertices.count * MemoryLayout.size(ofValue: vertices[0])
        if withVerticesBuffer {
            verticesBuffer = Mesh.device.makeBuffer(bytes: vertices, length: verticesSize, options: [])
        } else {
            verticesBuffer = nil
        }
    }
    
    /*-- Statics: meshes de bases et gestion de la mesh présente. --*/
	/*-- Static fields --*/
	// Meshes de base
	static private(set) var sprite: Mesh!
	static private(set) var triangle: Mesh!
    
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
    }
}

class FanMesh: Mesh {
    init() {
        var vertices = Array<Vertex>(repeating: ((0, 0, 0), (0.5, 0.5), (0,0,1)), count: 10)
        for i in 1...9 {
            vertices[i].position = (-0.5 * sin(2 * .pi * (Float)(i-1) / 8),
                                        0.5 * cos(2 * .pi * (Float)(i-1) / 8), 0)
            vertices[i].uv = (0.5 - 0.5 * sin(2 * .pi * (Float)(i-1) / 8),
                                  0.5 - 0.5 * cos(2 * .pi * (Float)(i-1) / 8))
        }
        super.init(
            vertices: vertices,
            indices: [
                    0, 1, 2,  0, 2, 3,
                    0, 3, 4,  0, 4, 5,
                    0, 5, 6,  0, 6, 7,
                    0, 7, 8,  0, 8, 9])
    }
    func update(with ratio: Float) {
        for i in 1...9 {
            vertices[i].position = (-0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                        0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8), 0)
            vertices[i].uv = (0.5 - 0.5 * sin(ratio * 2 * .pi * (Float)(i-1) / 8),
                                  0.5 - 0.5 * cos(ratio * 2 * .pi * (Float)(i-1) / 8))
        }
    }
}

// Les vertex de GraphMesh en x,y demeurent dans le rectangle [-0.5, 0.5] x [-0.5, 0.5] (comme le sprite).
// De même, le domaine en x,y considéré pour z = f(x,y) est [-0.5, 0.5] x [-0.5, 0.5].
class GraphMesh: Mesh {
    let m: Int
    let n: Int
    init(m: Int, n: Int) {
        self.m = m
        self.n = n
        var vertices = Array<Vertex>(repeating: Mesh.defaultVertex, count: (m+1)*(n+1))
        var indices = Array<UInt16>(repeating: 0, count: m*n*6)
        for i in 0..<m {
            for j in 0..<n {
                let dec = i*n*6 + j*6
                indices[dec]     = UInt16(i*(n+1) + j)
                indices[dec + 1] = UInt16(i*(n+1) + j + 1)
                indices[dec + 2] = UInt16((i+1)*(n+1) + j)
                indices[dec + 3] = UInt16(i*(n+1) + j + 1)
                indices[dec + 4] = UInt16((i+1)*(n+1) + j + 1)
                indices[dec + 5] = UInt16((i+1)*(n+1) + j)
            }
        }
        for i in 0..<(m+1) {
            for j in 0..<(n+1) {
                vertices[i*(n+1) + j].uv = (Float(i) / Float(m), Float(j) / Float(n))
                let x = Float(i) / Float(m) - 0.5
                let y = Float(j) / Float(n) - 0.5
                vertices[i*(n+1) + j].position = (x, y, pow(x,2) + pow(y,2))
                
            }
        }
        super.init(vertices: vertices, indices: indices)
    }
    func updateZ(with f: (Float, Float)->Float) {
        for i in 0..<(m+1) {
            for j in 0..<(n+1) {
                vertices[i*(n+1) + j].uv = (Float(i) / Float(m), Float(j) / Float(n))
                let x = Float(i) / Float(m) - 0.5
                let y = Float(j) / Float(n) - 0.5
                vertices[i*(n+1) + j].position.2 = f(x,y)
            }
        }
    }
}

class PlotMesh: Mesh {
    // A priori, les xs/ys devraient êtr préformaté pour être contenu dans [-0.5, 0.5] x [-0.5, 0.5]...
    // delta: épaisseur des lignes.
    init(xs: [Float], ys: [Float], delta: Float = 0.02, ratio: Float = 1) {
        guard xs.count == ys.count, xs.count > 0, delta > 0 else {
            fatalError("Bad parameters...")
        }
        let n_lines = xs.count - 1
        let n_points = xs.count
        var vertices = Array<Vertex>(repeating: Mesh.defaultVertex, count: 4 * n_lines + 4 * n_points)
        var indices = Array<UInt16>(repeating: 0, count: n_lines * 6 + n_points * 6)
        for i in 0..<n_lines {
            let theta = atan((ys[i+1] - ys[i]) / (xs[i+1] - xs[i]))
            let deltax = delta * sin(theta) / ratio
            let deltay = delta * cos(theta)
            vertices[i * 4].position =     (xs[i]   - deltax, ys[i]   + deltay, 0)
            vertices[i * 4].uv =     (0, 0)
            vertices[i * 4 + 1].position = (xs[i]   + deltax, ys[i]   - deltay, 0)
            vertices[i * 4 + 1].uv = (0, 1)
            vertices[i * 4 + 2].position = (xs[i+1] - deltax, ys[i+1] + deltay, 0)
            vertices[i * 4 + 2].uv = (0.75, 0)
            vertices[i * 4 + 3].position = (xs[i+1] + deltax, ys[i+1] - deltay, 0)
            vertices[i * 4 + 3].uv = (0.75, 1)
            indices[i * 6] =     UInt16(i*4)
            indices[i * 6 + 1] = UInt16(i*4 + 1)
            indices[i * 6 + 2] = UInt16(i*4 + 2)
            indices[i * 6 + 3] = UInt16(i*4 + 1)
            indices[i * 6 + 4] = UInt16(i*4 + 2)
            indices[i * 6 + 5] = UInt16(i*4 + 3)
        }
        let vert_dec = 4 * n_lines
        let ind_dec = 6 * n_lines
        let pts_deltax = delta * 1.15 / ratio
        let pts_deltay = delta * 1.15
        for i in 0..<n_points {
            vertices[vert_dec + i * 4].position =     (xs[i] - pts_deltax, ys[i] + pts_deltay, 0)
            vertices[vert_dec + i * 4].uv =     (1, 0)
            vertices[vert_dec + i * 4 + 1].position = (xs[i] - pts_deltax, ys[i] - pts_deltay, 0)
            vertices[vert_dec + i * 4 + 1].uv = (1, 1)
            vertices[vert_dec + i * 4 + 2].position = (xs[i] + pts_deltax, ys[i] + pts_deltay, 0)
            vertices[vert_dec + i * 4 + 2].uv = (2, 0)
            vertices[vert_dec + i * 4 + 3].position = (xs[i] + pts_deltax, ys[i] - pts_deltay, 0)
            vertices[vert_dec + i * 4 + 3].uv = (2, 1)
            indices[ind_dec + i * 6] =     UInt16(vert_dec + i*4)
            indices[ind_dec + i * 6 + 1] = UInt16(vert_dec + i*4 + 1)
            indices[ind_dec + i * 6 + 2] = UInt16(vert_dec + i*4 + 2)
            indices[ind_dec + i * 6 + 3] = UInt16(vert_dec + i*4 + 1)
            indices[ind_dec + i * 6 + 4] = UInt16(vert_dec + i*4 + 2)
            indices[ind_dec + i * 6 + 5] = UInt16(vert_dec + i*4 + 3)
        }
        
        super.init(vertices: vertices, indices: indices, withVerticesBuffer: true)
    }
}

// Ensemble de lignes verticales (aux xs) et de lignes horizontales (aux ys).
// delta: épaisseur des lignes.
class GridMesh: Mesh {
    init(xmin: Float, xmax: Float, xR: Float, deltaX: Float,
         ymin: Float, ymax: Float, yR: Float, deltaY: Float,
         lineWidthRatio: Float = 0.1)
    {
        let x0 = xR - floor((xR - xmin) / deltaX) * deltaX
        let m = Int((xmax - x0) / deltaX) + 1
        let xlinedelta = deltaX * lineWidthRatio * 0.5
        let y0 = yR - floor((yR - ymin) / deltaY) * deltaY
        let n = Int((ymax - y0) / deltaY) + 1
        let ylinedelta = deltaY * lineWidthRatio * 0.5
        
        var vertices = Array<Vertex>(repeating: Mesh.defaultVertex, count: 4 * (m + n))
        var indices = Array<UInt16>(repeating: 0, count: 6 * (m + n))
        
        for i in 0..<m {
            let x = x0 + Float(i) * deltaX
            vertices[i*4].position = (x - xlinedelta, ymax, 0)
            vertices[i*4].uv = (0, 0)
            vertices[i*4 + 1].position = (x - xlinedelta, ymin, 0)
            vertices[i*4 + 1].uv = (0, 1)
            vertices[i*4 + 2].position = (x + xlinedelta, ymax, 0)
            vertices[i*4 + 2].uv = (1, 0)
            vertices[i*4 + 3].position = (x + xlinedelta, ymin, 0)
            vertices[i*4 + 3].uv = (1, 1)
            indices[i * 6] =     UInt16(i*4)
            indices[i * 6 + 1] = UInt16(i*4 + 1)
            indices[i * 6 + 2] = UInt16(i*4 + 2)
            indices[i * 6 + 3] = UInt16(i*4 + 1)
            indices[i * 6 + 4] = UInt16(i*4 + 2)
            indices[i * 6 + 5] = UInt16(i*4 + 3)
        }
        let vert_dec = 4 * m
        let ind_dec = 6 * m
        for i in 0..<n {
            let y = y0 + Float(i) * deltaY
            vertices[vert_dec + i*4].position = (xmin, y + ylinedelta, 0)
            vertices[vert_dec + i*4].uv = (0, 0)
            vertices[vert_dec + i*4 + 1].position = (xmin, y - ylinedelta, 0)
            vertices[vert_dec + i*4 + 1].uv = (0, 1)
            vertices[vert_dec + i*4 + 2].position = (xmax, y + ylinedelta, 0)
            vertices[vert_dec + i*4 + 2].uv = (1, 0)
            vertices[vert_dec + i*4 + 3].position = (xmax, y - ylinedelta, 0)
            vertices[vert_dec + i*4 + 3].uv = (1, 1)
            indices[ind_dec + i * 6] =     UInt16(vert_dec + i*4)
            indices[ind_dec + i * 6 + 1] = UInt16(vert_dec + i*4 + 1)
            indices[ind_dec + i * 6 + 2] = UInt16(vert_dec + i*4 + 2)
            indices[ind_dec + i * 6 + 3] = UInt16(vert_dec + i*4 + 1)
            indices[ind_dec + i * 6 + 4] = UInt16(vert_dec + i*4 + 2)
            indices[ind_dec + i * 6 + 5] = UInt16(vert_dec + i*4 + 3)
        }
        
        super.init(vertices: vertices, indices: indices, withVerticesBuffer: true)
    }
}
