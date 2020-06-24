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
    /** Les infos d'une texture pour le shader. */
	struct PerTextureUniforms  { // Doit être multiple de 16octets.
        var sizes: (width: Float, height: Float) = (1,1) // Mieux des float pour aller avec les coord. UV.
        var dim: (m: Float, n: Float) = (1,1)
    }
    /*-- Fields --*/
    let m: Int
    let n: Int
    private(set) var string: String = ""
    private(set) var mtlTexture: MTLTexture? = nil
    var ptu = PerTextureUniforms()
    private(set) var ratio: Float = 1
	let isString: Bool
	let isMutable: Bool
	let isLocalized: Bool
	
	/*-- Methods --*/
	func updateAsMutableString(_ string: String) {
		guard isString, isMutable else {
			printerror("N'est pas une texture de string ou n'est pas mutable."); return
		}
		self.string = string
		drawAsString()
	}
	    
	// Private methods
	/** Init comme png... */
	private init(pngName: String, m: Int, n: Int) {
		self.m = m
		self.n = n
		self.string = pngName
		isString = false
		isMutable = false
		isLocalized = false
		ptu.dim = (m: Float(m), n: Float(n))
		drawAsPng()
		Texture.allPngTextures.append(WeakElement(self))
	}
	/** Les texture de string sont soit constantes (mutable = false) soit modifiable.
	 * Setter privé, car pour les constantes on stock dans un array pour évité les duplicas. */
	private init(string: String, isMutable: Bool, isLocalized: Bool) {
		m = 1
		n = 1
		self.string = string
		isString = true
		self.isMutable = isMutable
		self.isLocalized = isLocalized
		drawAsString()
		Texture.allStringTextures.append(WeakElement(self))
	}
	deinit {
//		printdebug("Remove texture \(string)")
	}
	private func drawAsString() {
		// 1. Font et dimension de la string
		#if os(OSX)
		let font = NSFont(name: "American Typewriter", size: 100)// Texture.fontSize)
		let color = NSColor.white
		#else
		let font = UIFont(name: "American Typewriter", size: 100)// Texture.fontSize)
		let color = UIColor.white
		#endif
		// 2. Paragraph style
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = NSTextAlignment.center
		paragraphStyle.lineBreakMode = NSLineBreakMode.byTruncatingTail
		// 3. Attributs de la string (color, font, paragraph style)
		var attributes: [NSAttributedString.Key : Any] = [:]
		attributes[.font] = font
		attributes[.foregroundColor] = color
		attributes[.paragraphStyle] = paragraphStyle
		// 4. Init de la NSString
		let str: NSString
		if string.count > 0 {
			if isLocalized {
				str = NSString(string: string.localizedOrDucked)
			} else {
				str = NSString(string: string)
			}
		} else {
			str = " "
		}
		// 5. Mesure des dimensions de la string
		// (tester avec "j"...)
		let strSizes = str.size(withAttributes: attributes)
		let contextHeight = Int(ceil(strSizes.height)) + 2
		let contextWidth =  Int(ceil(strSizes.width) + strSizes.height * Texture.characterSpacing)
		// 6. Création d'un context CoreGraphics
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		guard let context = CGContext(data: nil,
									  width: contextWidth, height: contextHeight,
									  bitsPerComponent: 8, bytesPerRow: 0,
									  space: colorSpace,
									  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
			else {
				printerror("Ne peut charger le CGContext pour : \"\(string)\"."); return
		}
		// (lettres remplies avec le contour)
		context.setTextDrawingMode(CGTextDrawingMode.fillStroke)
		
		// 7. Dessiner la string dans le context
		// (set context CoreGraphics dans context NSGraphics pour dessiner la NSString.)
		#if os(OSX)
		NSGraphicsContext.saveGraphicsState()
		let nsgcontext = NSGraphicsContext(cgContext: context, flipped: false)
		NSGraphicsContext.current = nsgcontext
		// Si on place à (0,0) la lettre est coller sur le bord du haut... D'où cet ajustement pour être centré.
		let ypos: Int = Int(strSizes.height)/2 - contextHeight/2
		str.draw(in: NSRect(x: 0, y: ypos, width: contextWidth, height: contextHeight),
				 withAttributes: attributes)
		NSGraphicsContext.restoreGraphicsState()
		#else
		UIGraphicsPushContext(context)
		// Si on laise le scaling à (1, 1) et la pos à (0, 0), la lettre est à l'envers collé en bas...
		context.scaleBy(x: 1, y: -1)
		let ypos: Int = -Int(strSizes.height)/2 - contextHeight/2
		let xpos: Int = -Int(strSizes.width)/2 + contextWidth/2
//		str.draw(in: CGRect(x: 0, y: ypos, width: contextWidth, height: contextWidth), withAttributes: attributes)
		str.draw(at: CGPoint(x: xpos, y: ypos), withAttributes: attributes)
		UIGraphicsPopContext()
		#endif
		
		// 8. Créer une image du context et en faire une texture.
		let image = context.makeImage()
		mtlTexture = try! Texture.textureLoader.newTexture(cgImage: image!, options: nil)
		setDims()
	}
	private func drawAsPng() {
		guard let url = Bundle.main.url(forResource: string, withExtension: "png", subdirectory: "pngs") else {
			printerror("Ne peut pas charger la surface \(string).")
			drawAsString()
			return
		}
		mtlTexture = try!
			Texture.textureLoader.newTexture(URL: url,
											 options: [MTKTextureLoader.Option.SRGB : false
			])
		setDims()
	}
	private func setDims() {
		guard let mtlTex = mtlTexture else {printerror("MTLTexture non chargé."); return}
		ptu.sizes = (Float(mtlTex.width), Float(mtlTex.height))
		ratio = ptu.sizes.width / ptu.sizes.height * ptu.dim.n / ptu.dim.m
	}
	
	/*-- Static fields --*/
	/*-- Les textures disponible par défault. --*/
	static let characterSpacing: CGFloat = 0.23
	static private(set) var fontSize: CGFloat = 64
	static let defaultString = Texture(string: "🦆", isMutable: false, isLocalized: false)
	static let testFrame = getNewPng("test_frame", m: 1, n: 1, showWarning: false)
	static let blackDigits = getNewPng("digits_black", m: 12, n: 2, showWarning: false)
	// On garde une référence pour libérer l'espace des textures quand on met l'application en pause (background)
	private static var allStringTextures: [WeakElement<Texture>] = []
	private static var allPngTextures: [WeakElement<Texture>] = []
	// Liste (weak) des string constantes (non mutable) déjà définies
	// (si plus besoin, la texture de la string disparait)
	private static var cstStringsTex: [String: WeakElement<Texture>] = [:]
	// Liste weak des string localisées
	private static var locStringsTex: [String: WeakElement<Texture>] = [:]
	// liste weak des png (juste pour être sur qu'il n'est pas déjà init)
	private static var pngsTex: [String: WeakElement<Texture>] = [:]
	/** Texture loader de Metal. Doit être initialisé par le renderer avec la device (gpu). */
    private static var textureLoader: MTKTextureLoader!
	
	/*-- Static method --*/
	static func suspend() {
		guard loaded else {printwarning("Textures already unloaded."); return}
		loaded = false
		allStringTextures.strip()
		allPngTextures.strip()
		for weaktexture in allStringTextures {
			if let texture = weaktexture.value {
				texture.mtlTexture = nil
			}
		}
		for weaktexture in allPngTextures {
			if let texture = weaktexture.value {
				texture.mtlTexture = nil
			}
		}
	}
	static func resume() {
		guard !loaded else {printwarning("Textures already loaded."); return}
		loaded = true
		for weaktexture in allStringTextures {
			if let texture = weaktexture.value {
				texture.drawAsString()
			}
		}
		for weaktexture in allPngTextures {
			if let texture = weaktexture.value {
				texture.drawAsPng()
			}
		}
	}
	static func checkFontSize(with drawableSize: CGSize) {
		let candidateFontSize = getCandidateFontSize(from: drawableSize)
		// On redesine les strings seulement si un changement significatif.
		guard (candidateFontSize/fontSize > 1.25) || (candidateFontSize/fontSize < 0.75) else {	return }
		fontSize = candidateFontSize
		allStringTextures.strip()
		for weaktexture in allStringTextures {
			if let texture = weaktexture.value {
				texture.drawAsString()
			}
		}
	}
	/** La texture d'une string mutable n'est pas partagé.
	* Pour une string non mutable (constant), on garde une weak reference pour éviter les duplicas. */
	static func getAsString(_ string: String, isMutable: Bool) -> Texture {
		// Cas string mutable (editable, localisable), on donne une nouvelle texture.
		if isMutable {
			return Texture(string: string, isMutable: true, isLocalized: false)
		}
		// Cas "constant", on garde en mémoire dans cstStringsTex pour évité les duplicas
		if let we = cstStringsTex[string], let tex = we.value {
			return tex
		}
		let newTex = Texture(string: string, isMutable: false, isLocalized: false)
		cstStringsTex[string] = WeakElement(newTex)
		return newTex
	}
	/** Les strings localisées sont un peu comme les constantes (mais change quand on change de langue). */
	static func getAsLocString(_ string: String) -> Texture {
		// Vérif si déjà init...
		if let we = locStringsTex[string], let tex = we.value {
			return tex
		}
		let newTex = Texture(string: string, isMutable: false, isLocalized: true)
		locStringsTex[string] = WeakElement(newTex)
		return newTex
	}
	static func updateAllLocStrings() {
		// cleaning...
		locStringsTex.strip()
		// redraw...
		for (_, weaktexture) in locStringsTex {
			if let texture = weaktexture.value {
				texture.drawAsString()
			}
		}
	}
	/** Les textures de png sont traités comme les texture de constant string,
	* i.e. on garde une weak reference pour éviter les duplicas. */
	static func getNewPng(_ pngName: String, m: Int, n: Int, showWarning: Bool = true) -> Texture {
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
	static func tryToGetExistingPng(_ pngName: String) -> Texture? {
		guard let we = pngsTex[pngName], let tex = we.value else { return nil }
		return tex
	}
	
	/** Init du loader de png avec le gpu (device). */
	static func initWith(device: MTLDevice, drawableSize: CGSize) {
		fontSize = getCandidateFontSize(from: drawableSize)
		textureLoader = MTKTextureLoader(device: device)
		loaded = true
	}
	
	static private(set) var loaded: Bool = false
	static private func getCandidateFontSize(from drawableSize: CGSize) -> CGFloat {
		return min(max(fontSizeRatio * min(drawableSize.width, drawableSize.height), minFontSize), maxFontSize)
	}
	static private let fontSizeRatio: CGFloat = 0.065
	static private let minFontSize: CGFloat = 24
	static private let maxFontSize: CGFloat = 128
}

