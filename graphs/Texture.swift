//
//  Texture.swift
//  MyTemplate
//
//  Created by Corentin Faucher on 2020-01-27.
//  Copyright © 2020 Corentin Faucher. All rights reserved.
//

import MetalKit

typealias Tiling = (m: Int, n: Int)

enum TextureType {
    case png
    case constantString
    case mutableString
    case localizedString
}

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
    private(set) var name: String = ""
    private(set) var mtlTexture: MTLTexture? = nil
    var ptu = PerTextureUniforms()  // Doit être mutable pour passer au MTLRenderCommandEncoder...
    private(set) var ratio: Float = 1
	let type: TextureType
	
	/*-- Methods --*/
	func updateAsMutableString(_ string: String) {
        guard type == .mutableString else {
			printerror("N'est pas une texture de string mutable."); return
		}
		self.name = string
		drawAsString()
	}
	    
	// Private methods
    private init(name: String, type: TextureType) {
        self.name = name
        self.type = type
        
        if type == .png {
            if let tiling = Texture.pngNameToTiling[name] {
                m = tiling.m; n = tiling.n
                ptu.dim = (m: Float(m), n: Float(n))
            } else {
                printwarning("Pas de tiling pour png \(name).")
                m = 1; n = 1
            }
            drawAsPng()
        } else {
            m = 1; n = 1
            drawAsString()
        }
    }
    private init() {
        self.name = "null"
        self.type = .png // (pas vrament un png, mais couleur uniforme... compte comme image)
        m = 1; n = 1
        // (ptu reste aux valeurs par défaut)
    }
    
	deinit {
//		printdebug("Remove texture \(string)")
	}
	
    private func drawAsString() {
		// 1. Font et dimension de la string
		#if os(OSX)
		let font = NSFont(name: "American Typewriter", size: Texture.fontSize)
		let color = NSColor.white
		#else
		let font = UIFont(name: "American Typewriter", size: Texture.fontSize)
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
		if name.count > 0 {
            if type == .localizedString {
				str = NSString(string: name.localizedOrDucked)
			} else {
				str = NSString(string: name)
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
				printerror("Ne peut charger le CGContext pour : \"\(name)\"."); return
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
		guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "pngs") else {
			printerror("Ne peut pas charger la surface \(name).")
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
    // Textures accessibles par défaut...
    static let justColor = Texture() // Cas pas besoin de texture...
    static let defaultPng = Texture(name: "the_cat", type: .png)
    static let defaultString = Texture(name: "🦆", type: .constantString)
    static let testFrame = getPng("test_frame")
    static let blackDigits = getPng("digits_black")
    private static let defaultTiling: Tiling = (m: 1, n: 1)
    static var pngNameToTiling: [String: Tiling] = [
        "bar_in" : (m: 1, n: 1),
        "digits_black" : (m: 12, n: 2),
        "test_frame" : (m: 1, n: 1),
        "scroll_bar_back" : (m: 1, n: 3),
        "scroll_bar_front" : (m: 1, n: 3),
        "switch_back" : (m: 1, n: 1),
        "switch_front" : (m: 1, n: 1),
        "the_cat" : (m: 1, n: 1),
    ]
	
    // On garde une référence pour libérer l'espace et pour le resizing des strings.
    private static var allStringTextures: [WeakElement<Texture>] = []
    // On garde aussi les liste des constant et localized pour éviter les duplicats
    private static var allConstantStringTextures: [String: WeakElement<Texture>] = [:]
    private static var allLocalizedStringTextures: [String: WeakElement<Texture>] = [:]
    // Pour les pngs la liste est pour le suspend/resume et éviter les duplicats.
    private static var allPngTextures: [String: WeakElement<Texture>] = [:]
    
	/*-- Static method --*/
    // Chargement et libération des textures (lors de pauses)
	static func suspend() {
		guard loaded else {printwarning("Textures already unloaded."); return}
		loaded = false
		allStringTextures.strip()
		for weaktexture in allStringTextures {
			if let texture = weaktexture.value {
				texture.mtlTexture = nil
			}
		}
        allPngTextures.strip()
        for (_, weaktexture) in allPngTextures {
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
        for (_, weaktexture) in allPngTextures {
            if let texture = weaktexture.value {
                texture.drawAsPng()
            }
        }
	}
    
    // Taille des strings...
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
    static private func getCandidateFontSize(from drawableSize: CGSize) -> CGFloat {
        return min(max(fontSizeRatio * min(drawableSize.width, drawableSize.height), minFontSize), maxFontSize)
    }
    static let characterSpacing: CGFloat = 0.23
    static private(set) var fontSize: CGFloat = 64
    static private let fontSizeRatio: CGFloat = 0.065
    static private let minFontSize: CGFloat = 24
    static private let maxFontSize: CGFloat = 120
    
	/** La texture d'une string mutable n'est pas partagé.
	* Pour une string non mutable (constant), on garde une weak reference pour éviter les duplicas. */
    static func getConstantString(_ string: String) -> Texture {
        if let we = allConstantStringTextures[string], let tex = we.value {
            return tex
        }
        let newCstStr = Texture(name: string, type: .constantString)
        allConstantStringTextures[string] = WeakElement(newCstStr)
        allStringTextures.append(WeakElement(newCstStr))
        return newCstStr
    }
    static func getNewMutableString(_ string: String = "") -> Texture {
        let newMutStr = Texture(name: string, type: .mutableString)
        allStringTextures.append(WeakElement(newMutStr))
        return newMutStr
    }
    static func getLocalizedString(_ string: String) -> Texture {
        if let we = allLocalizedStringTextures[string], let tex = we.value {
            return tex
        }
        let newLocStr = Texture(name: string, type: .localizedString)
        allLocalizedStringTextures[string] = WeakElement(newLocStr)
        allStringTextures.append(WeakElement(newLocStr))
        return newLocStr
    }
    // Lors d'un changement de langue...
	static func updateAllLocStrings() {
		// cleaning...
        allLocalizedStringTextures.strip()
		// redraw...
		for (_, weaktexture) in allLocalizedStringTextures {
			if let texture = weaktexture.value {
				texture.drawAsString()
			}
		}
	}
    static func getPng(_ pngName: String) -> Texture {
        // 1. Cas déjà init.
        if let we = allPngTextures[pngName], let tex = we.value {
            return tex
        }
        let newPng = Texture(name: pngName, type: .png)
        allPngTextures[pngName] = WeakElement(newPng)
        return newPng
    }
    
    
	/** Init du loader de png avec le gpu (device). */
	static func initWith(device: MTLDevice, drawableSize: CGSize) {
		fontSize = getCandidateFontSize(from: drawableSize)
		textureLoader = MTKTextureLoader(device: device)
		loaded = true
	}
    /** Texture loader de Metal. Doit être initialisé par le renderer avec la device (gpu). */
    private static var textureLoader: MTKTextureLoader!
	static private(set) var loaded: Bool = false
}

