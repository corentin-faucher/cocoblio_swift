//
//  coqMeshes.swift
//  Renderer
//
//  Created by Corentin Faucher on 2018-10-25.
//  Copyright © 2018 Corentin Faucher. All rights reserved.
//
import MetalKit
import CoreGraphics

protocol CoqMetalView : MTKView {
	var root: AppRootBase! { get }
	var renderer: Renderer! {get }
	var isTransitioning: Bool { get set }
	
	/** Le vrai frame de la vue y compris les bords où il ne devrait pas y avoir d'objet importants). */
	var fullFrame: CGSize { get set }
	/** Le frame utilisable un rectangle dans fullFrame, i.e. les dimensions "utiles", sans les bords. */
	var usableFrame: CGRect { get set }
	
	func setBackground(color: Vector3, isDark: Bool)
	
	// Pour la détection du scrolling dans iOS...
	func addScrollingViewIfNeeded(with slidingMenu: SlidingMenu)
	func removeScrollingView()
}

fileprivate let ratioMin: CGFloat = 0.54
fileprivate let ratioMax: CGFloat = 1.85

extension CoqMetalView {
	func getNormalizePositionFrom(_ locationInView: CGPoint, invertedY: Bool) -> Vector2 {
		return Vector2(Float((locationInView.x / bounds.width - 0.5) * fullFrame.width),
					   Float((invertedY ? -1 : 1) * (locationInView.y / bounds.height - 0.5) * fullFrame.height - usableFrame.origin.y))
	}
	func getLocationFrom(_ normalizedPos: Vector2, invertedY: Bool) -> CGPoint {
		return CGPoint(x: (CGFloat(normalizedPos.x) / fullFrame.width + 0.5) * bounds.width,
					   y: ((CGFloat(normalizedPos.y) + usableFrame.origin.y) / (fullFrame.height * (invertedY ? -1 : 1)) + 0.5) * bounds.height)
	}
	func getFrameFrom(_ pos: Vector2, deltas: Vector2, invertedY: Bool) -> CGRect {
		let width = 2 * CGFloat(deltas.x) / fullFrame.width * bounds.width
		let height = 2 * CGFloat(deltas.y) / fullFrame.height * bounds.height
		return CGRect(x: (CGFloat(pos.x - deltas.x) / fullFrame.width + 0.5) * bounds.width,
					  y: ((CGFloat(pos.y - (invertedY ? -1 : 1) * deltas.y) + usableFrame.origin.y) / (fullFrame.height * (invertedY ? -1 : 1)) + 0.5) * bounds.height,
					  width: width,
					  height: height)
	}
	func updateFrame() {
		let realRatio = frame.width / frame.height
		#if os(OSX)
		guard let window = window else {printerror("No window."); return}
		let headerHeight = window.styleMask.contains(.fullScreen) ? 22 : window.frame.height - window.contentLayoutRect.height
		
		let ratioT: CGFloat = headerHeight / window.frame.height + 0.005
		let ratioB: CGFloat = 0.005
		let ratioLR: CGFloat = 0.01
		#else
		let sa = safeAreaInsets
		let ratioT: CGFloat = sa.top / frame.height + 0.01
		let ratioB: CGFloat = sa.bottom / frame.height + 0.01
		let ratioLR: CGFloat = (sa.left + sa.right) / frame.width + 0.015
		#endif
		
		// 1. Full Frame
		if realRatio > 1 { // Landscape
			fullFrame.height = 2 / ( 1 - ratioT - ratioB)
			fullFrame.width = realRatio * fullFrame.height
		}
		else {
			fullFrame.width = 2 / (1 - ratioLR)
			fullFrame.height = fullFrame.width / realRatio
		}
		// 2. Usable Frame
		if realRatio > 1 { // Landscape
			usableFrame.size.width = min((1 - ratioLR) * fullFrame.width, 2 * ratioMax)
			usableFrame.size.height = 2
		}
		else {
			usableFrame.size.width = 2
			usableFrame.size.height = min((1 - ratioT - ratioB) * fullFrame.height, 2 / ratioMin)
		}
		usableFrame.origin.x = 0
		usableFrame.origin.y = (ratioB - ratioT) * fullFrame.height / 2
	}
	#if !os(OSX)	
	func updateFrameInTransition() {
		guard let tmpBounds = layer.presentation()?.bounds else {
			printerror("Pas de presentation layer."); return
		}
		let sa = safeAreaInsets
		let ratioT: CGFloat = sa.top / frame.height + 0.01
		let ratioB: CGFloat = sa.bottom / frame.height + 0.01
		let ratioLR: CGFloat = (sa.left + sa.right) / frame.width + 0.015
		
		let realRatio = tmpBounds.width / tmpBounds.height
		// 1. Full Frame
		if realRatio > 1 { // Landscape
			fullFrame.height = 2 / ( 1 - ratioT - ratioB)
			fullFrame.width = realRatio * fullFrame.height
		}
		else {
			fullFrame.width = 2 / (1 - ratioLR)
			fullFrame.height = fullFrame.width / realRatio		}
	}
	#endif
}

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
	fileprivate var currentMesh: Mesh? = nil {
		didSet {
			if let newMesh = currentMesh, let cmdenc = commandEncoder {
				currentPrimitiveType = newMesh.primitiveType
				currentVertexCount = newMesh.vertices.count
				cmdenc.setCullMode(newMesh.cullMode)
				cmdenc.setVertexBuffer(newMesh.verticesBuffer,
											   offset: 0,
											   index: Renderer.metalVerticesBufferIndex)
			}
		}
	}
	fileprivate var currentPrimitiveType: MTLPrimitiveType = .triangle
	fileprivate var currentVertexCount: Int = 0
	// La texture présentement utilisée
	fileprivate var currentTexture: Texture? = nil {
		didSet {
			if let newTexture = currentTexture, let cmdenc = commandEncoder  {
				cmdenc.setFragmentTexture(newTexture.mtlTexture,
												  index: Renderer.metalTextureIndex)
				cmdenc.setVertexBytes(&newTexture.ptu,
											  length: MemoryLayout<Texture.PerTextureUniforms>.size,
											  index: Renderer.metalPtuIndex)
			}
		}
	}
	// Metal Stuff
	fileprivate var commandEncoder: MTLRenderCommandEncoder?
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
        renderPipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertex_function")
        renderPipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragment_function")
        renderPipelineDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        let colorAtt: MTLRenderPipelineColorAttachmentDescriptor = renderPipelineDescriptor.colorAttachments[0]
		colorAtt.pixelFormat = metalView.colorPixelFormat //.bgra8Unorm
        colorAtt.isBlendingEnabled = true
        colorAtt.rgbBlendOperation = .add
        #if os(OSX)
        colorAtt.sourceRGBBlendFactor = .sourceAlpha
        #else
        colorAtt.sourceRGBBlendFactor = .one
        #endif
        colorAtt.destinationRGBBlendFactor = .oneMinusSourceAlpha
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
		
		/*-- Sampler state pour les textures --*/
        let samplerDescr = MTLSamplerDescriptor()
		samplerDescr.magFilter = MTLSamplerMinMagFilter.linear
		samplerDescr.minFilter = MTLSamplerMinMagFilter.linear
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
	static private let metalVerticesBufferIndex = 0
	static private let metalTextureIndex = 0
	static private let metalPtuIndex = 3
}

extension Renderer: MTKViewDelegate {
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		guard let metalView = view as? CoqMetalView else {
			printerror("Not attach to CoqMetalView.")
			return
		}
	
		Texture.checkFontSize(with: size)
		
		metalView.updateFrame()
		if let root = metalView.root {
			root.reshapeBranch()
		}
		view.isPaused = false
		GlobalChrono.isPaused = false
	}
	
	func draw(in view: MTKView) {
		guard let metalView = view as? CoqMetalView, let root = metalView.root else {
			printerror("Pas une MetalView."); return
		}
		guard !view.isPaused else { return }
		#if !os(OSX)
		if metalView.isTransitioning {
			metalView.updateFrameInTransition()
		}
		#endif
		
		// 0. Init du commandEncoder/commandBuffer, mesh, text...
		guard let drawable = view.currentDrawable,
			let renderPassDescriptor = view.currentRenderPassDescriptor
			else {return}
		let commandBuffer = commandQueue.makeCommandBuffer()
		guard let cmdenc = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
			print("Error loading commandEncoder"); return}
		commandEncoder = cmdenc
		cmdenc.setFragmentSamplerState(samplerState, index: 0)
		cmdenc.setRenderPipelineState(pipelineState)
		if let dss = depthStencilState {
			cmdenc.setDepthStencilState(dss)
		}
		
		currentMesh = nil
		currentTexture = nil
		
		// 1. Check le chrono/sleep.
		GlobalChrono.update()
		if GlobalChrono.shouldSleep {
			view.isPaused = true
		}
		
		// 2. Mise à jour des paramètres de la frame (matrice de projection et temps pour les shaders)
		PerFrameUniforms.pfu.time = GlobalChrono.elapsedSec
		root.setProjectionMatrix(&PerFrameUniforms.pfu.projection)
		cmdenc.setVertexBytes(&PerFrameUniforms.pfu,
							  length: MemoryLayout.size(ofValue: PerFrameUniforms.pfu),
							  index: 2)
		
		// 3. Action du game engine avant l'affichage.
		root.willDrawFrame()
		
		// 4. Mise à jour de la couleur de fond.
		view.clearColor = MTLClearColorMake(Double(smR.pos), Double(smG.pos), Double(smB.pos), 1)
		
		// 5. Boucle d'affichage (parcourt l'arbre de noeud de la structure)
		let sq = Squirrel(at: root)
		repeat {
			if let surface = setForDrawing(sq.pos)() {
				surface.draw(with: cmdenc, and: self)
			}
		} while sq.goToNextToDisplay()
		// 6. Fin. Soumettre au gpu...
		cmdenc.endEncoding()
		commandEncoder = nil
		commandBuffer?.present(drawable)
		commandBuffer?.commit()
	}
	
}

private extension Surface {
	func draw(with cmdenc: MTLRenderCommandEncoder, and renderer: Renderer) {
        // 1. Mise a jour de la mesh ?
		if (mesh !== renderer.currentMesh) {
			renderer.currentMesh = mesh
        }
        // 2. Mise a jour de la texture ?
		if tex !== renderer.currentTexture {
			renderer.currentTexture = tex
        }
        // 3. Mise à jour des "PerInstanceUniforms"
		cmdenc.setVertexBytes(&piu,
							length: MemoryLayout<Renderer.PerInstanceUniforms>.size,
							index: 1)
        // 4. Dessiner
        if mesh.indices.count < 1 {
			cmdenc.drawPrimitives(type: renderer.currentPrimitiveType,
								vertexStart: 0,
								vertexCount: renderer.currentVertexCount)
        } else {
			cmdenc.drawIndexedPrimitives(type: renderer.currentPrimitiveType,
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
