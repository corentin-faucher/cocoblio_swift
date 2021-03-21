//
//  coqMeshes.swift
//  Renderer
//
//  Created by Corentin Faucher on 2018-10-25.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//
import MetalKit
import CoreGraphics

class Renderer : NSObject {
	/*-- Struct related to Renderer --*/
    /** Les propriétés d'affichage d'un objet/instance (un noeud typiquement). */
    struct PerInstanceUniforms { // Doit être multiple de 16octets.
        var model = float4x4(1) // 16 float -> 64 oct
        var color = Vector4(repeating: 1)
        var tile: (i: Float32, j: Float32) = (0,0)
        var emph: Float32 = 0
        var flags: Int32 = 0
        
        static let isOneSided: Int32 = 1
    }
	/** Constante de l'affichage d'une frame pour les shaders. */
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
    
	
	/*-- Fields --*/
    
    /// App structure to display.
//    unowned var root: AppRootBase! // (owned by MetalView)
	/// Fonction de préparation des Surfaces avant l'affichage (customizable)
    var setForDrawing = Node.defaultSetForDrawing
	/** Le vrai frame de la vue y compris les bords où il ne devrait pas y avoir d'objet importants). */
//	private(set) var fullFrame = CGSize(width: 2, height: 2)
	/** Le frame utilisable (sans les bords, les dimensions "utiles"). */
//	private(set) var usableFrame = CGSize(width: 2, height: 2)
	// Fond d'écran
	private var smR: SmoothPos = SmoothPos(1, 8)
	private var smG: SmoothPos = SmoothPos(1, 8)
	private var smB: SmoothPos = SmoothPos(1, 8)
	// Present frame stuff: command encoder, used mesh, used texture.
	fileprivate var currentMesh: Mesh? = nil
	fileprivate var currentPrimitiveType: MTLPrimitiveType = .triangle
	fileprivate var currentVertexCount: Int = 0
	// La texture présentement utilisée
	fileprivate var currentTexture: Texture? = nil
	// Metal Stuff
	// fileprivate var commandEncoder: MTLRenderCommandEncoder!
	private let commandQueue: MTLCommandQueue!
	private let pipelineState: MTLRenderPipelineState!
	private let samplerState: MTLSamplerState!
	private let depthStencilState: MTLDepthStencilState?
	
	
	/*-- Methods --*/
	
	init(metalView: MTKView, withDepth: Bool) {
        /*-- Init de device et commandQueue --*/
		guard let device = metalView.device else {
            fatalError("No GPU in metalView.")
        }
        commandQueue = device.makeCommandQueue()
        
        /*-- Init de la vue. --*/
        metalView.depthStencilPixelFormat = .depth32Float
        
        /*-- Init du pipeline --*/
        let library = device.makeDefaultLibrary()
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
		#if os(OSX)
        renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function")
		#else
		if #available(iOS 14.0, *) {
			renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function")
		} else {
			renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function_ios13")
		}
		#endif
        renderPipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_function")
        renderPipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        let colorAtt: MTLRenderPipelineColorAttachmentDescriptor = renderPipelineDescriptor.colorAttachments[0]
		colorAtt.pixelFormat = metalView.colorPixelFormat //.bgra8Unorm
        colorAtt.isBlendingEnabled = true
        colorAtt.rgbBlendOperation = .add
        #if os(OSX)
        colorAtt.sourceRGBBlendFactor = .sourceAlpha
        #else
		if #available(iOS 14.0, *) {
			colorAtt.sourceRGBBlendFactor = .sourceAlpha
		} else {
			colorAtt.sourceRGBBlendFactor = .one
		}
        #endif
        colorAtt.destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
		
		/*-- Sampler state pour les textures --*/
        let samplerDescr = MTLSamplerDescriptor()
        samplerDescr.magFilter = .linear
        samplerDescr.minFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescr)
		
		/*-- Depth (si besoin) --*/
		if withDepth {
			let depthStencilDescriptor = MTLDepthStencilDescriptor()
			depthStencilDescriptor.depthCompareFunction = .less
			depthStencilDescriptor.isDepthWriteEnabled = true
			depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
		} else {
			depthStencilState = nil
		}
        
        /*-- Init des Texture avec device (gpu) car utilisé pour loader les pngs. --*/
		Texture.initWith(device: device, drawableSize: metalView.drawableSize)
        
        /*-- Init de Mesh avec device (gpu) car utilisé pour créer les buffers. --*/
		Mesh.setDeviceAndInitBasicMeshes(device)
        
        super.init()
    }
    func initClearColor(rgb: Vector3) {
        smR.set(rgb.x); smG.set(rgb.y); smB.set(rgb.z)
    }
    func updateClearColor(rgb: Vector3) {
        smR.pos = rgb.x; smG.pos = rgb.y; smB.pos = rgb.z
    }
	
    /*-- Static constants --*/
	static fileprivate let metalVerticesBufferIndex = 0
	static fileprivate let metalTextureIndex = 0
	static fileprivate let metalPtuIndex = 3
}

extension Renderer: MTKViewDelegate {
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		guard let metalView = view as? CoqMetalView else {
			printerror("Not attach to CoqMetalView.")
			return
		}
        
		Texture.checkFontSize(with: size)
		
        metalView.isPaused = false
        
        #if os(OSX)
        guard let window = view.window else {printerror("No window."); return}
        let headerHeight = window.styleMask.contains(.fullScreen) ? 22 : window.frame.height - window.contentLayoutRect.height
        metalView.root?.updateFrame(to: metalView.frame.size,
                                    withMargin: headerHeight, 0, 0, 0)
        #else
        let sa = view.safeAreaInsets
        metalView.root?.updateFrame(to: metalView.frame.size,
                                    withMargin: sa.top, sa.left, sa.bottom, sa.right)
        #endif		
	}
	
	func draw(in view: MTKView) {
		guard let metalView = view as? CoqMetalView, let root = metalView.root else {
			printerror("Pas une MetalView."); return
		}
		guard !view.isPaused else { return }
		#if !os(OSX)
		if metalView.isTransitioning, let theFrame = metalView.layer.presentation()?.bounds.size {
            let sa = view.safeAreaInsets
            root.updateFrame(to: theFrame,
                             withMargin: sa.top, sa.left, sa.bottom, sa.right,
                             inTransition: true)
		}
		#endif
        
        currentMesh = nil
        currentTexture = nil
        
        // 1. Check le chrono/sleep.
        GlobalChrono.update()
        if GlobalChrono.shouldSleep, metalView.canPauseWhenResignActive {
            view.isPaused = true
        }
        
        // 2. Mise à jour des paramètres de la frame (matrice de projection et temps pour les shaders)
        PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
        root.setProjectionMatrix(&PerFrameUniforms.pfu.projection)
        // 3. Action du game engine avant l'affichage.
        root.willDrawFrame()
        // 4. Mise à jour de la couleur de fond.
        view.clearColor = MTLClearColorMake(Double(smR.pos), Double(smG.pos), Double(smB.pos), 1)
		
		// 0. Init du commandEncoder/commandBuffer, mesh, text...
        guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
		guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
		guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
			printerror("Error loading commandEncoder"); return}
        // *** On pourrait changer le sampler en fonction de la texture, e.g. pour texture linear ou nearest. ***
		renderEncoder.setFragmentSamplerState(samplerState, index: 0)
		renderEncoder.setRenderPipelineState(pipelineState)
		if let dss = depthStencilState {
			renderEncoder.setDepthStencilState(dss)
		}
		renderEncoder.setVertexBytes(&PerFrameUniforms.pfu,
							  length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu),
							  index: 2)
		// 5. Boucle d'affichage (parcourt l'arbre de noeud de la structure)
		let sq = Squirrel(at: root)
		repeat {
			if let surface = setForDrawing(sq.pos)() {
				surface.draw(with: renderEncoder, and: self)
			}
		} while sq.goToNextToDisplay()
		// 6. Fin. Soumettre au gpu...
		renderEncoder.endEncoding()
        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
		commandBuffer.commit()
	}
	
}

private extension Surface {
	func draw(with renderEncoder: MTLRenderCommandEncoder, and renderer: Renderer) {
        // 1. Mise a jour de la mesh ?
		if (mesh !== renderer.currentMesh) {
			renderer.currentMesh = mesh
            renderer.currentPrimitiveType = mesh.primitiveType
            renderer.currentVertexCount = mesh.vertices.count
            renderEncoder.setCullMode(mesh.cullMode)
            renderEncoder.setVertexBytes(mesh.vertices, length: mesh.verticesSize, index: Renderer.metalVerticesBufferIndex)
//                commandEncoder.setVertexBuffer(newMesh.verticesBuffer,
//                                               offset: 0,
//                                               index: Renderer.metalVerticesBufferIndex)
        }
        // 2. Mise a jour de la texture ?
		if tex !== renderer.currentTexture {
			renderer.currentTexture = tex
            renderEncoder.setFragmentTexture(tex.mtlTexture,
                                              index: Renderer.metalTextureIndex)
            renderEncoder.setVertexBytes(&tex.ptu,
                                          length: MemoryLayout<Texture.PerTextureUniforms>.size,
                                          index: Renderer.metalPtuIndex)
        }
        // 3. Mise à jour des "PerInstanceUniforms"
		renderEncoder.setVertexBytes(&piu,
							length: MemoryLayout<Renderer.PerInstanceUniforms>.size,
							index: 1)
        // 4. Dessiner
        if mesh.indices.count < 1 {
			renderEncoder.drawPrimitives(type: renderer.currentPrimitiveType,
								vertexStart: 0,
								vertexCount: renderer.currentVertexCount)
        } else {
			renderEncoder.drawIndexedPrimitives(type: renderer.currentPrimitiveType,
										indexCount: mesh.indices.count,
										indexType: .uint16,
										indexBuffer: mesh.indicesBuffer!,
										indexBufferOffset: 0)
        }
    }
}

/** La fonction utilisé par défaut pour CoqRenderer.setNodeForDrawing.
 * Retourne la surface à afficher (le noeud présent si c'est une surface). */
private extension Node {
    func defaultSetForDrawing() -> Surface? {
        // 0. Cas Racine
        if containsAFlag(Flag1.isRoot) {
            (self as! RootNode).setModelMatrix()
        }
        guard let theParent = parent else {
            printerror("Root n'est pas une RootNode.")
            return nil
        }
        // 2. Cas branche
        if firstChild != nil {
            piu.model.setAndTranslate(ref: theParent.piu.model, with: [x.pos, y.pos, z.pos])
            piu.model.scale(with: [scaleX.pos, scaleY.pos, 1])
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
        guard alpha > 0 else { return nil }
        
        piu.model.setAndTranslate(ref: theParent.piu.model, with: [x.pos, y.pos, z.pos])
        if (containsAFlag(Flag1.poping)) {
            piu.model.scale(with: [width.pos * alpha, height.pos * alpha, 1])
        } else {
            piu.model.scale(with: [width.pos, height.pos, 1])
        }
        return surface
    }
}


// GARBAGE

/*
func getPositionFrom(_ locationInWindow: CGPoint, viewSize: CGSize, invertedY: Bool) -> Vector2 {
return Vector2(Float((locationInWindow.x / viewSize.width - 0.5) * fullFrame.width),
Float((invertedY ? -1 : 1) * (locationInWindow.y / viewSize.height - 0.5) * fullFrame.height))
}
func setFrameFrom(viewFrame: CGRect, safeAreaFrame: CGRect?, alsoSetUsableFrame: Bool) {
let ratio = viewFrame.width / viewFrame.height
// 1. Full Frame
if ratio > 1 { // Landscape
fullFrame.width = 2 * ratio / Renderer.defaultBordRatio
fullFrame.height = 2 / Renderer.defaultBordRatio
}
else {
fullFrame.width = 2 / Renderer.defaultBordRatio
fullFrame.height = 2 / (ratio * Renderer.defaultBordRatio)
}
if !alsoSetUsableFrame {
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
}
*/
