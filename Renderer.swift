//
//  coqMeshes.swift
//  MetalTest
//
//  Created by Corentin Faucher on 2018-10-25.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//
import MetalKit
import CoreGraphics

class Renderer : NSObject {
    /** Les propriétés d'affichage d'un objet/instance (un noeud typiquement). */
    struct PerInstanceUniforms { // Doit être multiple de 16octets.
        var model = float4x4(1) // 16 float -> 64 oct
        var color = float4(1)
        var tile: (i: Float32, j: Float32) = (0,0)
        var emph: Float32 = 0
        var flags: Int32 = 0
        
        static let isOneSided: Int32 = 1
    }

    struct PerFrameUniforms {
        var projection: float4x4
        var time: Float32
        var unused1,unused2,unused3: Float32
        
        init() {
            projection = float4x4(1)
            time = 0
            unused1 = 0; unused2 = 0; unused3 = 0
        }
        static var pfu = PerFrameUniforms()
    }
    
    /*-- Doivent être initialisé pour qu'il se passe quelque chose... */
    var eventsHandler: EventsHandler? = nil
    var root: Node? = nil
    
    /*-- Metal Stuff --*/
    static var device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    let samplerState: MTLSamplerState!
    let depthStencilState: MTLDepthStencilState!
    
    init(metalView: MTKView) {
        /*-- EventHandler et root de structure. --*/
        /*-- Init de device et commandQueue --*/
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Pas de GPU.")
        }
        Renderer.device = device
        commandQueue = device.makeCommandQueue()
        
        /*-- Init de la vue. --*/
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.depthStencilPixelFormat = .depth32Float
        
        
        /*-- Init du pipeline --*/
        let library = device.makeDefaultLibrary()
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function")
        renderPipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_function")
        renderPipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        let colorAtt: MTLRenderPipelineColorAttachmentDescriptor = renderPipelineDescriptor.colorAttachments[0]
        colorAtt.pixelFormat = metalView.colorPixelFormat //.bgra8Unorm
        colorAtt.isBlendingEnabled = true
        colorAtt.rgbBlendOperation = .add
        colorAtt.sourceRGBBlendFactor = .sourceAlpha
        colorAtt.destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        
        samplerState = device.makeSamplerState(descriptor: MTLSamplerDescriptor())
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        /*-- Texture loader --*/
        Texture.textureLoader = MTKTextureLoader(device: device)
        
        /*-- Init des meshes --*/
        Mesh.initBasicMeshes(with: device)
        
        super.init()
        
        metalView.delegate = self
    }
    
    static func draw(piu: inout PerInstanceUniforms, tex: Texture, mesh: Mesh,
                     with commandEncoder: MTLRenderCommandEncoder) {
        // 1. Mise a jour de la mesh ?
        if (mesh !== Mesh.currentMesh) {
            Mesh.setMesh(newMesh: mesh, with: commandEncoder)
        }
        // 2. Mise a jour de la texture ?
        if tex !== Texture.currentTexture {
            Texture.setTexture(newTex: tex, with: commandEncoder)
        }
        // 3. Mise à jour des "PerInstanceUniforms"
        commandEncoder.setVertexBytes(&piu, length: MemoryLayout<PerInstanceUniforms>.size,
                                      index: 1)
        // 4. Dessiner
        if mesh.indices.count < 1 {
            commandEncoder.drawPrimitives(type: Mesh.currentPrimitiveType,
                                          vertexStart: 0,
                                          vertexCount: Mesh.currentVertexCount)
        } else {
            commandEncoder.drawIndexedPrimitives(type: Mesh.currentPrimitiveType, indexCount: mesh.indices.count, indexType: .uint16, indexBuffer: mesh.indicesBuffer!, indexBufferOffset: 0)
        }
    }
    
    static func initClearColor(rgb: float3) {
        smR.realPos = rgb.x; smG.realPos = rgb.y; smB.realPos = rgb.z
    }
    static func updateClearColor(rgb: float3) {
        smR.pos = rgb.x; smG.pos = rgb.y; smB.pos = rgb.z
    }
    static func getPositionFrom(_ locationInWindow: NSPoint, invertedY: Bool) -> float2 {
        return float2((Float(locationInWindow.x) / width - 0.5) * frameFullWidth,
                      (invertedY ? -1 : 1) * (Float(locationInWindow.y) / height - 0.5) * frameFullHeight)
    }
    private static func updatePerFrameUniforms() {
        // 2. Mise à jour de la matrice de projection
        if width > height { // Landscape
            frameFullHeight = 2 / smoothRatioHeight.pos
            frameFullWidth = width / height * frameFullHeight
        } else {
            frameFullWidth = 2 / smoothRatioWidth.pos
            frameFullHeight = height / width * frameFullWidth
        }
        PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
        PerFrameUniforms.pfu.projection.makePerspective(nearZ: 0.1, farZ: 50, middleZ: 5,
                                                        deltaX: frameFullWidth, deltaY: frameFullHeight)
    }
    private static func updateViewDims(_ view: MTKView, _ widthUsedRatio: Float, _ heightUsedRatio: Float) {
        width = Float(view.bounds.size.width)
        height = Float(view.bounds.size.height)
        smoothRatioWidth.pos = max(0.5, min(1, widthUsedRatio))
        smoothRatioHeight.pos = max(0.5, min(1, heightUsedRatio))
        
        if width > height { // Landscape
            frameUsableWidth = 2 * width / height *
                (smoothRatioWidth.realPos / smoothRatioHeight.realPos)
            frameUsableHeight = 2
        } else {
            frameUsableWidth = 2
            frameUsableHeight = 2 * height / width *
                (smoothRatioHeight.realPos / smoothRatioWidth.realPos)
        }
    }
    /*-- Private stuff --*/
    static private(set) var width: Float = 1 // En pixels
    static private(set) var height: Float = 1
    static private(set) var frameUsableWidth: Float = 2
    static private(set) var frameUsableHeight: Float = 2
    static private(set) var frameFullWidth: Float = 2
    static private(set) var frameFullHeight: Float = 2
    static private var smR: SmPos = SmPos(1, 8)
    static private var smG: SmPos = SmPos(1, 8)
    static private var smB: SmPos = SmPos(1, 8)
    static private var smoothRatioWidth = SmPos(1, 8)
    static private var smoothRatioHeight = SmPos(1, 8)
}


extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        Renderer.updateViewDims(view, 1, 1)
        eventsHandler?.reshapeAction()
        view.isPaused = false
        GlobalChrono.isPaused = false
    }
    
    func draw(in view: MTKView) {
        // 0. Init du commandEncoder/commandBuffer
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor
            else {return}
        let commandBuffer = commandQueue.makeCommandBuffer()
        guard let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Error loading commandEncoder"); return}
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setRenderPipelineState(pipelineState)
        commandEncoder.setDepthStencilState(depthStencilState)
        GlobalChrono.update()
        Renderer.updatePerFrameUniforms()
        commandEncoder.setVertexBytes(&PerFrameUniforms.pfu, length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu), index: 2)
        
        // 1. Mise à jour de la couleur de fond.
        view.clearColor = MTLClearColorMake(Double(Renderer.smR.pos), Double(Renderer.smG.pos), Double(Renderer.smB.pos), 1)
        
        // 2. Setter à nil la mesh et texture courante.
        Mesh.currentMesh = nil
        Texture.currentTexture = nil
        
        // 3. Action du game engine et affichage
        eventsHandler?.everyFrameAction()
        if GlobalChrono.shouldSleep {
            view.isPaused = true
            GlobalChrono.isPaused = true
        }
//        ViewManager.setFrame(of: view, with: commandEncoder)
        
        // 2. Boucle sur tout les noeuds de la structure
        guard let theRoot = root else {return}
        let sq = Squirrel(at: theRoot)
        while sq.goToNextToDisplay() {
            if let surface = sq.pos.setForDrawing() {
                Renderer.draw(piu: &surface.piu, tex: surface.tex, mesh: surface.mesh, with: commandEncoder)
            }
        }
        
        // 3. Fin. Soumettre au gpu...
        commandEncoder.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}


/*
 enum ViewManager {
 /** Dessiner un objet (GraphData d'un noeud). */
 static func draw(piu: inout PerInstanceUniforms, tex: Texture, mesh: Mesh,
 with commandEncoder: MTLRenderCommandEncoder) {
 // 1. Mise a jour de la mesh ?
 if (mesh !== Mesh.currentMesh) {
 Mesh.setMesh(newMesh: mesh, with: commandEncoder)
 }
 // 2. Mise a jour de la texture ?
 if tex !== Texture.currentTexture {
 Texture.setTexture(newTex: tex, with: commandEncoder)
 }
 // 3. Mise à jour des "PerInstanceUniforms"
 commandEncoder.setVertexBytes(&piu, length: MemoryLayout<PerInstanceUniforms>.size,
 index: 1)
 // 4. Dessiner
 if mesh.indices.count < 1 {
 commandEncoder.drawPrimitives(type: Mesh.currentPrimitiveType, vertexStart: 0, vertexCount: Mesh.currentVertexCount)
 } else {
 commandEncoder.drawIndexedPrimitives(type: Mesh.currentPrimitiveType, indexCount: mesh.indices.count, indexType: .uint16, indexBuffer: mesh.indicesBuffer!, indexBufferOffset: 0)
 }
 }
 
 static func initClearColor(rgb: float3) {
 smR.realPos = rgb.x; smG.realPos = rgb.y; smB.realPos = rgb.z
 }
 static func updateClearColor(rgb: float3) {
 smR.pos = rgb.x; smG.pos = rgb.y; smB.pos = rgb.z
 }
 
 static func reshape(_ view: MTKView, widthUsedRatio: Float, heightUsedRatio: Float) {
 width = Float(view.bounds.size.width)
 height = Float(view.bounds.size.height)
 smoothRatioWidth.pos = max(0.5, min(1, widthUsedRatio))
 smoothRatioHeight.pos = max(0.5, min(1, widthUsedRatio))
 
 if width > height { // Landscape
 frameUsableWidth = 2 * width / height *
 (smoothRatioWidth.realPos / smoothRatioHeight.realPos)
 frameUsableHeight = 2
 } else {
 frameUsableWidth = 2
 frameUsableHeight = 2 * height / width *
 (smoothRatioHeight.realPos / smoothRatioWidth.realPos)
 }
 }
 
 static func setFrame(of view: MTKView, with commandEncoder: MTLRenderCommandEncoder) {
 // 1. Mise à jour de la couleur de fond.
 view.clearColor = MTLClearColorMake(Double(smR.pos), Double(smG.pos), Double(smB.pos), 1)
 // 2. Mise à jour de la matrice de projection
 if width > height { // Landscape
 frameFullHeight = 2 / smoothRatioHeight.pos
 frameFullWidth = width / height * frameFullHeight
 } else {
 frameFullWidth = 2 / smoothRatioWidth.pos
 frameFullHeight = height / width * frameFullWidth
 }
 PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
 PerFrameUniforms.pfu.projection.makePerspective(nearZ: 0.1, farZ: 50, middleZ: 5,
 deltaX: frameFullWidth, deltaY: frameFullHeight)
 commandEncoder.setVertexBytes(&PerFrameUniforms.pfu, length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu), index: 2)
 
 // 3. Set pour init de mesh et texture.
 Mesh.currentMesh = nil
 Texture.currentTexture = nil
 }
 static func getPositionFrom(_ locationInWindow: NSPoint, invertedY: Bool) -> float2 {
 return float2((Float(locationInWindow.x) / width - 0.5) * frameFullWidth,
 (invertedY ? -1 : 1) * (Float(locationInWindow.y) / height - 0.5) * frameFullHeight)
 }
 
 static private(set) var width: Float = 1 // En pixels
 static private(set) var height: Float = 1
 static private(set) var frameUsableWidth: Float = 2
 static private(set) var frameUsableHeight: Float = 2
 static private(set) var frameFullWidth: Float = 2
 static private(set) var frameFullHeight: Float = 2
 static private var smR: SmPos = SmPos(1, 8)
 static private var smG: SmPos = SmPos(1, 8)
 static private var smB: SmPos = SmPos(1, 8)
 static private var smoothRatioWidth = SmPos(1, 8)
 static private var smoothRatioHeight = SmPos(1, 8)
 
 /*
 static func resumeMetal(with device: MTLDevice) {
 // 1. Chargement des textures des surfaces.
 let textureLoader = MTKTextureLoader(device: device)
 for tex in TexEnum.texArray {
 if !tex.initAsPng(with: textureLoader) {
 printerror("png \(tex.string) pas loadé.")
 }
 }
 
 // 2. Chargement des meshes.
 Mesh.initBasicMeshes(with: device)
 }
 */
 }
 
 */
