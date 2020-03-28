//
//  Texture.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-27.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

/** Info d'une texture. m et n est le découpage en tiles.
 * Classe (par référence) car les noeuds ne font que y référer. */
class Texture {
    // Utile car passé à métal...
    struct PerTextureUniforms { // Doit être multiple de 16octets.
        var sizes: (width: Float, height: Float) = (1,1) // Mieux des float pour aller avec les coord. UV.
        var dim: (m: Float, n: Float) = (1,1)
    }
    
    let m: Int
    let n: Int
    private(set) var string: String = ""
    private(set) var mtlTexture: MTLTexture? = nil
    private(set) var ptu = PerTextureUniforms()
    private(set) var ratio: Float = 1
	let isString: Bool
	let isMutable: Bool
	
	static func getAsString(_ string: String, isMutable: Bool) -> Texture {
		// Cas string mutable (editable, localisable), on donne une nouvelle texture.
		if isMutable {
			return Texture(string: string, isMutable: true)
		}
		// Cas "constant", on garde en mémoire dans cstStringsTex pour évité les duplicas
		if let we = cstStringsTex[string], let tex = we.value {
			return tex
		}
		let newTex = Texture(string: string, isMutable: false)
		cstStringsTex[string] = WeakElement(newTex)
		return newTex
	}
	static func getAsPng(_ pngName: String, m: Int, n: Int, showWarning: Bool = true) -> Texture {
		if let we = pngsTex[pngName], let tex = we.value {
			if showWarning {
				printwarning("\(pngName) already init with \(tex.m)x\(tex.n) vs \(m)x\(n)")
			}
			return tex
		}
		let newTex = Texture(pngName: pngName, m: m, n: n)
		pngsTex[pngName] = WeakElement(newTex)
		return newTex
	}
	static func getExistingPng(_ pngName: String) -> Texture {
		guard let we = pngsTex[pngName], let tex = we.value else {
			printerror("\(pngName) not init")
			return Texture.testFrame
		}
		return tex
	}
	func updateString(_ string: String) {
		guard isString, isMutable else {
			printerror("N'est pas une texture de string ou n'est pas mutable."); return
		}
		self.string = string
		initAsString()
	}
	    
	// Init comme png...
	private init(pngName: String, m: Int, n: Int) {
		self.m = m
		self.n = n
		self.string = pngName
		isString = false
		isMutable = false
		ptu.dim = (m: Float(m), n: Float(n))
		initAsPng()
		Texture.allTextures.append(WeakElement(self))
	}
	// Les texture de string sont soit constantes (mutable = false) soit modifiable.
	// Setter privé, car pour les constantes on stock dans un array pour évité les duplicas.
	private init(string: String, isMutable: Bool) {
		m = 1
		n = 1
		self.string = string
		isString = true
		self.isMutable = isMutable
		initAsString()
		Texture.allTextures.append(WeakElement(self))
	}
	// On garde une référence pour libérer l'espace des textures quand on met l'application en pause (background)
	private static var allTextures: [WeakElement<Texture>] = []
	// Liste (weak) des string constantes (non mutable) déjà définies
	// (si plus besoin, la texture de la string disparait)
	private static var cstStringsTex: [String: WeakElement<Texture>] = [:]
	// liste weak des png (juste pour être sur qu'il n'est pas déjà init)
	private static var pngsTex: [String: WeakElement<Texture>] = [:]
	
    private func initAsString() {
        // Font, dimension,... pour dessiner la string.
        let str: NSString = NSString(string: string)
        #if os(OSX)
        let font = NSFont(name: "American Typewriter", size: 64)
        #else
        let font = UIFont(name: "American Typewriter", size: 64)
        #endif
        let strSizes = str.size(withAttributes: [NSAttributedString.Key.font : font as Any])
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil, width: Int(strSizes.width), height: Int(strSizes.height),
                bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else {
                printerror("Ne peut charger le CGContext."); return
        }
        context.setTextDrawingMode(CGTextDrawingMode.fillStroke)
        
        // Dessiner la string sur le context CoreGraphics
        #if os(OSX)
        NSGraphicsContext.saveGraphicsState()
        let context2 = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = context2
        str.draw(at: NSPoint(x: 0, y: 0), withAttributes: [NSAttributedString.Key.font : font as Any])
        NSGraphicsContext.restoreGraphicsState()
        #else
        UIGraphicsPushContext(context)
        context.scaleBy(x: 1, y: -1)
        print("strSize \(strSizes)")
        str.draw(at: CGPoint(x: 0, y: -strSizes.height), withAttributes: [NSAttributedString.Key.font : font as Any])
        UIGraphicsPopContext()
        #endif
        // Créer une image et en faire une texture.
        let image = context.makeImage()
        mtlTexture = try! Texture.textureLoader.newTexture(cgImage: image!, options: nil)
        setDims()
    }
    private func initAsPng() {
        guard let url = Bundle.main.url(forResource: string, withExtension: "png", subdirectory: "pngs") else {
            printerror("Ne peut pas charger la surface \(string).")
            initAsString()
            return
        }
        mtlTexture = try!
            Texture.textureLoader.newTexture(URL: url, options: [MTKTextureLoader.Option.SRGB : false])
		
        setDims()
    }
    private func setDims() {
        guard let mtlTex = mtlTexture else {printerror("MTLTexture non chargé."); return}
        ptu.sizes = (Float(mtlTex.width), Float(mtlTex.height))
        ratio = ptu.sizes.width / ptu.sizes.height * ptu.dim.n / ptu.dim.m
    }
    
    /*-- Les textures disponible par défault. --*/
	static let defaultString = Texture(string: "🦆", isMutable: false)
	static let testFrame = getAsPng("test_frame", m: 1, n: 2, showWarning: false)
	static let blackDigits = getAsPng("digits_black", m: 12, n: 2, showWarning: false)
    // 2. Stuff pour Renderer
    static func setTexture(newTex: Texture, with commandEncoder: MTLRenderCommandEncoder) {
        current = newTex
        
        commandEncoder.setFragmentTexture(newTex.mtlTexture, index: 0)
        
        commandEncoder.setVertexBytes(&newTex.ptu, length: MemoryLayout<PerTextureUniforms>.size, index: 3)
    }
    static var current: Texture? = nil
    static var textureLoader: MTKTextureLoader!
    // Taille des strings
    private static var fontSize: CGFloat = 64
    
	
}

