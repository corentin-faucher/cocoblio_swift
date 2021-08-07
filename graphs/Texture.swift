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

//fileprivate let defaultFont: MyFont = .verdana

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
    var scaleX: Float = 1
    var scaleY: Float = 1
    let fontname: String?
	
	/*-- Methods --*/
    func updateAsMutableString(_ string: String) {
        guard type == .mutableString else {
			printerror("N'est pas une texture de string mutable."); return
		}
		self.name = string
		drawAsString()
	}
	    
	// Private methods
    private init(name: String, type: TextureType, fontname: String?) {
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
            self.fontname = nil
            drawAsPng()
        } else {
            m = 1; n = 1
            self.fontname = fontname
            drawAsString()
        }
    }
    private init() {
        self.name = "null"
        self.type = .png // (pas vrament un png, mais couleur uniforme... compte comme image)
        m = 1; n = 1
        fontname = nil
        // (ptu reste aux valeurs par défaut)
    }
    
	deinit {
//		printdebug("Remove texture \(string)")
	}
	
    private func drawAsString() {
		// 1. Font et dimension de la string
        let font: NSFont
        let fontinfo: FontInfo
        if let fontname = fontname {
            if let fonttmp = NSFont(name: fontname, size: FontManager.current.pointSize) {
                font = fonttmp
            } else {
                printerror("Cannot load font \(fontname).")
                font = FontManager.current
            }
            fontinfo = FontManager.getFontInfo(fontname)
        } else {
            font = FontManager.current
            fontinfo = FontManager.currentInfo
        }
		#if os(OSX)
		let color = NSColor.white
		#else
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
		let str: NSString
		if name.count > 0 {
            if type == .localizedString {
				str = NSString(string: name.localized)
			} else {
				str = NSString(string: name)
			}
		} else {
			str = " "
		}
		// 5. Mesure des dimensions de la string
		// (tester avec "j"...)
		let strSizes = str.size(withAttributes: attributes)
        let extraWidth: CGFloat = 0.55 * fontinfo.size_x * font.xHeight
        let contextHeight: CGFloat = 2.00 * fontinfo.size_y * font.xHeight
        let contextWidth =  ceil(strSizes.width) + extraWidth
        
        scaleY = Float(1 / fontinfo.size_y)
        scaleX = Float(strSizes.width / contextWidth)
        
		// 6. Création d'un context CoreGraphics
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		guard let context = CGContext(data: nil,
									  width: Int(contextWidth), height: Int(contextHeight),
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
        let ypos = 0.43 * contextHeight - (font.xHeight/2 - font.descender)
        str.draw(at: NSPoint(x: 0.5 * extraWidth, y: ypos), withAttributes: attributes)
//        str.draw(in: NSRect(x: 0, y: ydelta, width: contextWidth,
//                            height: strSizes.height + 0),
//				 withAttributes: attributes)
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
    static let justColor = Texture() // Cas pas besoin de texture. "justColor" est alors un "place holder" pour le tex d'une surface.
    static let defaultPng = Texture(name: "the_cat", type: .png, fontname: nil)
    static let defaultString = Texture(name: "🦆", type: .constantString, fontname: nil)
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
    // Après changement ou redimension de font... 
    static func redrawAllStrings() {
        allStringTextures.strip()
        for weaktexture in allStringTextures {
            if let texture = weaktexture.value {
                texture.drawAsString()
            }
        }
    }
    // Lors d'un changement de langue...
    static func updateAllLocStrings() {
        allLocalizedStringTextures.strip()
        for (_, weaktexture) in allLocalizedStringTextures {
            if let texture = weaktexture.value {
                texture.drawAsString()
            }
        }
    }
    
	/** La texture d'une string mutable n'est pas partagé.
	* Pour une string non mutable (constant), on garde une weak reference pour éviter les duplicas. */
    static func getConstantString(_ string: String, fontname: String? = nil) -> Texture {
        if let we = allConstantStringTextures[string], let tex = we.value {
            return tex
        }
        let newCstStr = Texture(name: string, type: .constantString, fontname: fontname)
        allConstantStringTextures[string] = WeakElement(newCstStr)
        allStringTextures.append(WeakElement(newCstStr))
        return newCstStr
    }
    static func getNewMutableString(_ string: String = "", fontname: String? = nil) -> Texture {
        let newMutStr = Texture(name: string, type: .mutableString, fontname: fontname)
        allStringTextures.append(WeakElement(newMutStr))
        return newMutStr
    }
    static func getLocalizedString(_ string: String, fontname: String? = nil) -> Texture {
        if let we = allLocalizedStringTextures[string], let tex = we.value {
            return tex
        }
        let newLocStr = Texture(name: string, type: .localizedString, fontname: fontname)
        allLocalizedStringTextures[string] = WeakElement(newLocStr)
        allStringTextures.append(WeakElement(newLocStr))
        return newLocStr
    }
    
    static func getPng(_ pngName: String) -> Texture {
        // 1. Cas déjà init.
        if let we = allPngTextures[pngName], let tex = we.value {
            return tex
        }
        let newPng = Texture(name: pngName, type: .png, fontname: nil)
        allPngTextures[pngName] = WeakElement(newPng)
        return newPng
    }
    
	/** Init du loader de png avec le gpu (device). */
	static func initWith(device: MTLDevice, drawableSize: CGSize) {
        FontManager.updateCurrentSize(with: drawableSize)
		textureLoader = MTKTextureLoader(device: device)
		loaded = true
	}
    
    /** Texture loader de Metal. Doit être initialisé par le renderer avec la device (gpu). */
    private static var textureLoader: MTKTextureLoader!
	static private(set) var loaded: Bool = false
}

