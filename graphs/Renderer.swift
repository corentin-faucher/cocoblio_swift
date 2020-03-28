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
        var color = Vector4(repeating: 1)
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
    /// La structure à afficher
    var root: RootNode!
    /// Le gestionnaire d'events (le gameEngine)
    var eventHandler: EventsHandler!
    var setForDrawing = Node.defaultSetForDrawing
    
    init(metalView: MTKView) {
        /*-- Init de device et commandQueue --*/
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Pas de GPU.")
        }
        commandQueue = device.makeCommandQueue()
        
        /*-- Init de la vue. --*/
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        /*-- Init du pipeline --*/
        let library = device.makeDefaultLibrary()
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function")
        renderPipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_function")
        renderPipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        let colorAtt: MTLRenderPipelineColorAttachmentDescriptor = renderPipelineDescriptor.colorAttachments[0]
        colorAtt.pixelFormat = .bgra8Unorm // metalView.colorPixelFormat //.bgra8Unorm
        colorAtt.isBlendingEnabled = true
        colorAtt.rgbBlendOperation = .add
        #if os(OSX)
        colorAtt.sourceRGBBlendFactor = .sourceAlpha
        #else
        colorAtt.sourceRGBBlendFactor = .one
        #endif
        colorAtt.destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        
        samplerState = device.makeSamplerState(descriptor: MTLSamplerDescriptor())
        
        /*-- Texture loader --*/
        Texture.textureLoader = MTKTextureLoader(device: device)
        
        /*-- Init des meshes --*/
        Mesh.initBasicMeshes(with: device)
        
        super.init()
        
        metalView.delegate = self
    }
    func addDepth(device: MTLDevice) {
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func initClearColor(rgb: Vector3) {
        smR.set(rgb.x); smG.set(rgb.y); smB.set(rgb.z)
    }
    func updateClearColor(rgb: Vector3) {
        smR.pos = rgb.x; smG.pos = rgb.y; smB.pos = rgb.z
    }
    func getPositionFrom(_ locationInWindow: CGPoint, viewSize: CGSize, invertedY: Bool) -> Vector2 {
        return Vector2(Float((locationInWindow.x / viewSize.width - 0.5) * fullFrame.width),
                       Float((invertedY ? -1 : 1) * (locationInWindow.y / viewSize.height - 0.5) * fullFrame.height))
    }
    
    
    /*-- Private stuff --*/
    func setFrameFromViewSize(_ viewSize: CGSize, justSetFullFrame: Bool) {
        let ratio = viewSize.width / viewSize.height
        // 1. Full Frame
        if ratio > 1 { // Landscape
            fullFrame.width = 2 * ratio / Renderer.defaultBordRatio
            fullFrame.height = 2 / Renderer.defaultBordRatio
        }
        else {
            fullFrame.width = 2 / Renderer.defaultBordRatio
            fullFrame.height = 2 / (ratio * Renderer.defaultBordRatio)
        }
        if justSetFullFrame {
            return
        }
        // 2. Usable Frame
        if ratio > 1 { // Landscape
            usableFrame.width = min(2 * ratio, 2 * Renderer.ratioMax)
            usableFrame.height = 2
        }
        else {
            usableFrame.width = 2
            usableFrame.height = min(2 / ratio, 2 / Renderer.ratioMin)
        }
        root.reshapeBranch()
    }
    
    private var smR: SmoothPos = SmoothPos(1, 8)
    private var smG: SmoothPos = SmoothPos(1, 8)
    private var smB: SmoothPos = SmoothPos(1, 8)
        
    /** Le vrai frame de la vue y compris les bords où il ne devrait pas y avoir d'objet importants). */
    private(set) var fullFrame = CGSize(width: 2, height: 2)
    // * Le frame utilisable (sans les bords, les dimensions "utiles").
    private(set) var usableFrame = CGSize(width: 2, height: 2)
    
    static private let defaultBordRatio: CGFloat = 0.95
    static private let ratioMin: CGFloat = 0.54
    static private let ratioMax: CGFloat = 1.85
    
    /*-- Metal Stuff --*/
    private let commandQueue: MTLCommandQueue!
    private let pipelineState: MTLRenderPipelineState!
    private let samplerState: MTLSamplerState!
    private var depthStencilState: MTLDepthStencilState?
}



extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        setFrameFromViewSize(size, justSetFullFrame: false)
        
        view.isPaused = false
        GlobalChrono.isPaused = false
    }
    
    func draw(in view: MTKView) {
        guard let metalView = view as? MetalView else {
            printerror("Pas une MetalView."); return
        }
        #if !os(OSX)
        if metalView.isTransitioning {
            guard let tmpSize = view.layer.presentation()?.bounds.size else {
                printerror("Pas de presentation layer."); return
            }
            setFrameFromViewSize(tmpSize, justSetFullFrame: true)
        }
        #endif

        // 0. Init du commandEncoder/commandBuffer, mesh, text...
        guard let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor
            else {return}
        let commandBuffer = commandQueue.makeCommandBuffer()
        guard let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            print("Error loading commandEncoder"); return}
        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setRenderPipelineState(pipelineState)
        //commandEncoder.setDepthStencilState(depthStencilState)
        Mesh.currentMesh = nil
        Texture.current = nil
        
        // 1. Check le chrono/sleep.
        GlobalChrono.update()
        if GlobalChrono.shouldSleep {
            view.isPaused = true
            GlobalChrono.isPaused = true
        }
        
        // 2. Mise à jour des paramètres de la frame (matrice de projection et temps pour les shaders)
        PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
        root.setProjectionMatrix(&PerFrameUniforms.pfu.projection)
        commandEncoder.setVertexBytes(&PerFrameUniforms.pfu, length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu), index: 2)
        
        // 3. Action du game engine avant l'affichage.
        eventHandler.willDrawFrame()
        
        // 4. Mise à jour de la couleur de fond.
        view.clearColor = MTLClearColorMake(Double(smR.pos), Double(smG.pos), Double(smB.pos), 1)
        
        // 5. Boucle d'affichage (parcourt l'arbre de noeud de la structure)
        let sq = Squirrel(at: root)
        repeat {
            if let surface = setForDrawing(sq.pos)() {
                surface.draw(with: commandEncoder)
            }
        } while sq.goToNextToDisplay()
        // 6. Fin. Soumettre au gpu...
        commandEncoder.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

private extension Surface2 {
    func draw(with commandEncoder: MTLRenderCommandEncoder) {
        // 1. Mise a jour de la mesh ?
        if (mesh !== Mesh.currentMesh) {
            Mesh.setMesh(newMesh: mesh, with: commandEncoder)
        }
        // 2. Mise a jour de la texture ?
        if tex !== Texture.current {
            Texture.setTexture(newTex: tex, with: commandEncoder)
        }
        // 3. Mise à jour des "PerInstanceUniforms"
        commandEncoder.setVertexBytes(&piu, length: MemoryLayout<Renderer.PerInstanceUniforms>.size,
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
}

/** La fonction utilisé par défaut pour CoqRenderer.setNodeForDrawing.
 * Retourne la surface à afficher (le noeud présent si c'est une surface). */
private extension Node {
    func defaultSetForDrawing() -> Surface2? {
        // 0. Cas Racine
        if let root = self as? RootNode {
            root.setModelAsCamera()
            return nil
        }
        guard let theParent = parent else {
            printerror("Root n'est pas une RootNode.")
            return nil
        }
        // 1. Init de la matrice model avec le parent.
        piu.model = theParent.piu.model
        // 2. Cas branche
        if firstChild != nil {
            piu.model.translate(with: Vector3(x.pos, y.pos, z.pos))
            piu.model.scale(with: Vector3(scaleX.pos, scaleY.pos, 1))
            return nil
        }
        // 3. Cas feuille
        // Laisser faire si n'est pas affichable...
        guard let surface = self as? Surface2 else {
            return nil
        }
        // Facteur d'"affichage"
        let alpha = surface.trShow.setAndGet(isOn: containsAFlag(Flag1.show))
        piu.color[3] = alpha
        // Rien à afficher...
        if alpha == 0 { return nil }

        piu.model.translate(with: [x.pos, y.pos, z.pos])
        if (containsAFlag(Flag1.poping)) {
            piu.model.scale(with: [width.pos * alpha, height.pos * alpha, 1])
        } else {
            piu.model.scale(with: [width.pos, height.pos, 1])
        }
        return surface
    }
}
