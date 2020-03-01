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
    var gameEngine: GameEngineBase!
    var setForDrawing = Node.defaultSetForDrawing
    
    init(metalView: MTKView) {
        /*-- EventHandler et root de structure. --*/
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
        colorAtt.pixelFormat = metalView.colorPixelFormat //.bgra8Unorm
        colorAtt.isBlendingEnabled = true
        colorAtt.rgbBlendOperation = .add
        colorAtt.sourceRGBBlendFactor = .sourceAlpha
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
    func getPositionFrom(_ locationInWindow: NSPoint, invertedY: Bool) -> Vector2 {
        return Vector2((Float(locationInWindow.x) / width - 0.5) * frameFullWidth,
                      (invertedY ? -1 : 1) * (Float(locationInWindow.y) / height - 0.5) * frameFullHeight)
    }
    
    /*-- Private stuff --*/
    /*-- Dimensions de la vue --*/
    private var width: Float = 1 // En pixels
    private var height: Float = 1
    private var frameFullWidth: Float = 2
    private var frameFullHeight: Float = 2
    private var smR: SmoothPos = SmoothPos(1, 8)
    private var smG: SmoothPos = SmoothPos(1, 8)
    private var smB: SmoothPos = SmoothPos(1, 8)
    private var widthRatio = SmoothPos(1, 8)
    private var heightRatio = SmoothPos(1, 8)
    static private var bordRatio: Float = 0.95
    static private let usableRatioMin: Float = 0.54
    static private let usableRatioMax: Float = 1.85
    /*-- Metal Stuff --*/
    private let commandQueue: MTLCommandQueue!
    private let pipelineState: MTLRenderPipelineState!
    private let samplerState: MTLSamplerState!
    private var depthStencilState: MTLDepthStencilState?
}



extension Renderer: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        width = Float(view.bounds.size.width)
        height = Float(view.bounds.size.height)
        let ratio = width / height
        let usableWidth: Float
        let usableHeight: Float
        // TODO: À réviser avec la "safe zone des appareil type "iPhoneX" et plus.
        if width > height { // Landscape
            heightRatio.pos = Renderer.bordRatio
            widthRatio.pos = Renderer.bordRatio * min(1, Renderer.usableRatioMax/ratio)
            usableHeight = 2
            usableWidth = 2 * ratio * (widthRatio.realPos / heightRatio.realPos)
            
        } else {
            widthRatio.pos = Renderer.bordRatio
            heightRatio.pos = Renderer.bordRatio * min(1, ratio / Renderer.usableRatioMin)
            usableWidth = 2
            usableHeight = 2 * (heightRatio.realPos / widthRatio.realPos) / ratio
        }
        
        gameEngine.viewReshaped(usableWidth: usableWidth, usableHeight: usableHeight)
        view.isPaused = false
        GlobalChrono.isPaused = false
    }
    
    func draw(in view: MTKView) {
        func updatePerFrameUniforms() {
            // 2. Mise à jour de la matrice de projection
            if width > height { // Landscape
                frameFullHeight = 2 / heightRatio.pos
                frameFullWidth = width / height * frameFullHeight
            } else {
                frameFullWidth = 2 / widthRatio.pos
                frameFullHeight = height / width * frameFullWidth
            }
            PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
            PerFrameUniforms.pfu.projection.setToPerspective(
                nearZ: 0.1, farZ: 50, middleZ: gameEngine.root.z.pos,
                deltaX: frameFullWidth, deltaY: frameFullHeight)
        }
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
        Texture.currentTexture = nil
        
        // 1. Check le chrono/sleep.
        GlobalChrono.update()
        if GlobalChrono.shouldSleep {
            view.isPaused = true
            GlobalChrono.isPaused = true
        }
        
        // 2. Mise à jour des paramètres de la frame (matrice de projection et temps pour les shaders)
        updatePerFrameUniforms()
        commandEncoder.setVertexBytes(&PerFrameUniforms.pfu, length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu), index: 2)
        
        // 3. Action du game engine avant l'affichage.
        gameEngine.willDrawFrame(fullWidth: frameFullWidth, fullHeight: frameFullHeight)
        
        // 4. Mise à jour de la couleur de fond.
        view.clearColor = MTLClearColorMake(Double(smR.pos), Double(smG.pos), Double(smB.pos), 1)
        
        // 5. Boucle d'affichage (parcourt l'arbre de noeud de la structure)
        let sq = Squirrel(at: gameEngine.root)
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

private extension Surface {
    func draw(with commandEncoder: MTLRenderCommandEncoder) {
        // 1. Mise a jour de la mesh ?
        if (mesh !== Mesh.currentMesh) {
            Mesh.setMesh(newMesh: mesh, with: commandEncoder)
        }
        // 2. Mise a jour de la texture ?
        if tex !== Texture.currentTexture {
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
    func defaultSetForDrawing() -> Surface? {
        // 0. Cas Racine
        guard let theParent = parent else {
            guard let theRoot = self as? RootNode else {
                printerror("Root n'est pas une RootNode.")
                return nil
            }
            theRoot.setModelAsCamera()
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
        guard let surface = self as? Surface else {
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
