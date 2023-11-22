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
		drawAsString(withTmp: false)
	}
	    
	// Private methods
    private init(name: String, type: TextureType, fontname: String?) {
        self.name = name
        self.type = type
        
        if type == .png {
            if let tiling = Texture.tilingOfPngNamed[name] {
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
            drawAsString(withTmp: true)
        }
    }
//    private init() {
//        self.name = "null"
//        self.type = .png // (pas vrament un png, mais couleur uniforme... compte comme image)
//        m = 1; n = 1
//        fontname = nil
//        // (ptu reste aux valeurs par défaut)
//    }
    
	deinit {
//		printdebug("Remove texture \(name)")
	}
	
    private func drawAsString(withTmp: Bool) {
		// 1. Font et dimension de la string
        #if os(OSX)
        let color = NSColor.white
        let font: NSFont
        #else
        let color = UIColor.white
        let font: UIFont
        #endif
        let spreading: CGSize
        if let fontname = fontname {
            if let fonttmp = FontManager.getFont(name: fontname) {
                font = fonttmp
            } else {
                printerror("Cannot load font \(fontname).")
                font = FontManager.current
            }
            spreading = FontManager.getFontSpreading(fontname)
        } else {
            font = FontManager.current
            spreading = FontManager.currentSpreading
        }
		
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
        guard strSizes.width > 0 else {
            printerror("str width 0?")
            return
        }
        let extraWidth: CGFloat = 0.55 * spreading.width * font.xHeight
        let contextHeight: CGFloat = 2.00 * spreading.height * font.xHeight
        let contextWidth =  ceil(strSizes.width) + extraWidth
        let strHeight = strSizes.height
        // On met tout de suite à jour les dimensions
        scaleY = Float(1 / spreading.height)  // (overlapping)
        scaleX = Float(strSizes.width / contextWidth)
//        printdebug("scaleX \(scaleX), scaleY \(scaleY) pour \(self.name).")
        setDims(Int(contextWidth), Int(contextHeight))
        // Texture placeholder en attendant de générer la vrai texture.
        if withTmp {
            switch name.count {
                case 0...1:
                    mtlTexture = Texture.tempStringTextures[safe: 0]?.mtlTexture
                case 2...3:
                    mtlTexture = Texture.tempStringTextures[safe: 1]?.mtlTexture
                case 4...8:
                    mtlTexture = Texture.tempStringTextures[safe: 2]?.mtlTexture
                default:
                    mtlTexture = Texture.tempStringTextures[safe: 3]?.mtlTexture
            }
        }
        // Création de la vrai texture (dans une thread).
        Texture.textureQueue.async { [self] in
            if let newMtlTexture = Texture.drawMetalTextureForString(str: str, font: font,
                    contextWidth: contextWidth, contextHeight: contextHeight,
                    extraWidth: extraWidth, strHeight: strHeight,
                    attributes: attributes)
            {
                DispatchQueue.main.async {
                    self.mtlTexture = newMtlTexture
                }
            }
        }
	}
    
    private static func drawMetalTextureForString(str: NSString, font: Font,
                                                  contextWidth: CGFloat, contextHeight: CGFloat,
                                                  extraWidth: CGFloat, strHeight: CGFloat,
                                                  attributes: [NSAttributedString.Key : Any]) -> MTLTexture?
    {
        // 6. Création d'un context CoreGraphics
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: Int(contextWidth), height: Int(contextHeight),
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else {
                printerror("Ne peut charger le CGContext pour : \"\(str)\".")
                return nil
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
        let ypos: CGFloat = 0.5 * contextHeight + (Texture.y_string_rel_shift - 0.5) * font.xHeight + font.descender
        str.draw(at: NSPoint(x: 0.5 * extraWidth, y: ypos), withAttributes: attributes)
        NSGraphicsContext.restoreGraphicsState()
        #else
        UIGraphicsPushContext(context)
        // Si on laise le scaling à (1, 1) et la pos à (0, 0), la lettre est à l'envers collé en bas...
        context.scaleBy(x: 1, y: -1)
        let ypos: CGFloat = -strHeight - font.descender + (0.5 - Texture.y_string_rel_shift) * font.xHeight - 0.5 * contextHeight
        str.draw(at: CGPoint(x: 0.5 * extraWidth, y: ypos), withAttributes: attributes)
        UIGraphicsPopContext()
        #endif
        
        // 8. Créer une image du context et en faire une texture.
        let image = context.makeImage()
        guard let newMtlTexture = try? Texture.textureLoader.newTexture(cgImage: image!, options: nil)
        else {
            printerror("cannot generate metal texture of \(str)")
            return nil
        }
        return newMtlTexture
    }
    
	private func drawAsPng() {
        let pngUrl: URL
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: Texture.pngsDirName) {
            pngUrl = url
        } else if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: Texture.defaultPngsDirName) {
            pngUrl = url
        } else {
            printerror("Ne peut pas charger la surface \(name).")
            drawAsString(withTmp: false)
            return
        }
        // 1. Si pas de mini, dessiner tout de suite la texture au complet.
        guard let mini = Texture.miniMtlTextureNamed[name] else {
            guard let newMtlTexture = try? Texture.textureLoader.newTexture(URL: pngUrl,
                                             options:  [MTKTextureLoader.Option.SRGB : false])
            else {
                printerror("Cannot init mtltexture")
                return
            }
            mtlTexture = newMtlTexture
            setDims(newMtlTexture.width, newMtlTexture.height)
            return
        }
        // 2. Si mini, mettre le mini et charger la vrai texture en arrière plan.
        mtlTexture = mini
        setDims(mini.width, mini.height)
        Texture.textureQueue.async {
            guard let newMtlTexture = try? Texture.textureLoader.newTexture(URL: pngUrl,
                                                                 options:  [MTKTextureLoader.Option.SRGB : false
                                                                           ])
            else {
                printerror("Cannot init mtltexture")
                return
            }
            DispatchQueue.main.async { [self] in
                mtlTexture = newMtlTexture
                setDims(newMtlTexture.width, newMtlTexture.height)
            }
        }
	}
    private func setDims(_ width: Int, _ height: Int) {
		ptu.sizes = (Float(width), Float(height))
		ratio = ptu.sizes.width / ptu.sizes.height * ptu.dim.n / ptu.dim.m
	}
    
	
	/*-- Static fields --*/
    static private(set) var loaded: Bool = false
    // Textures accessibles par défaut...
    // ** Les variables globales/static en swift sont initialisées de façon "lazy".
    // Donc, c'est correct ici. Il faut juste s'assurer que Texture.initWith est callé au début pour
    // initialiser le MTKTextureLoader.
    static let y_string_rel_shift: CGFloat = -0.15
    static let defaultPng = Texture(name: "the_cat", type: .png, fontname: nil)
    static let defaultString = Texture(name: "🦆", type: .constantString, fontname: nil)
    static let testFrame = getPng("test_frame")
    static let blackDigits = getPng("digits_black")
    static let white = getPng("white")
    
    
	/*-- Static method --*/
	/** Init du loader de png avec le gpu (device). */
	static func initWith(device: MTLDevice, drawableSize: CGSize) {
        FontManager.updateCurrentSize(with: drawableSize)
		textureLoader = MTKTextureLoader(device: device)
        tempStringTextures = [
            Texture(name: " ", type: .constantString, fontname: nil),
            Texture(name: "abc", type: .constantString, fontname: nil),
            Texture(name: "lorem", type: .constantString, fontname: nil),
            Texture(name: "Lorem ipsum", type: .constantString, fontname: nil),
        ]
        // Textures de pngs par défaut (pas de mini pour les textures par defaut,
        // voir valeurs initiales de -> tilingOfPngNamed.
        defaultPngTextures = tilingOfPngNamed.map { getPng($0.key) }
		loaded = true
	}
    /** Ajoute le tiling pour un nom de png et tente de précharger sa "mini". */
    static func addPngTilingsAndMinis(_ tilingOfPng: [String: Tiling]) {
        for (name, tiling) in tilingOfPng {
            tilingOfPngNamed.putIfAbsent(key: name, value: tiling, showWarning: true)
            // Ajout du mini?
            guard miniMtlTextureNamed[name] == nil,
                  let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "pngs_mini")
            else { continue }
            guard let miniTex = try? textureLoader.newTexture(URL: url, options: [MTKTextureLoader.Option.SRGB : false])
            else {
                printerror("Cannot create mini-texture \(name).")
                continue
            }
            miniMtlTextureNamed[name] = miniTex
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
        temporyAddStrongRef(string, newCstStr)
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
        temporyAddStrongRef(string, newLocStr)
        return newLocStr
    }
    static func getPng(_ pngName: String) -> Texture {
        // 1. Cas déjà init.
        if let we = allPngTextures[pngName], let tex = we.value {
            return tex
        }
        let newPng = Texture(name: pngName, type: .png, fontname: nil)
        allPngTextures[pngName] = WeakElement(newPng)
        temporyAddStrongRef(pngName, newPng)
        return newPng
    }
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
                texture.drawAsString(withTmp: true)
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
                texture.drawAsString(withTmp: true)
            }
        }
    }
    // Lors d'un changement de langue...
    static func updateAllLocStrings() {
        allLocalizedStringTextures.strip()
        for (_, weaktexture) in allLocalizedStringTextures {
            if let texture = weaktexture.value {
                texture.drawAsString(withTmp: true)
            }
        }
    }
    
    /*-- Private stuff...  --*/
    private static let pngsDirName: String = {
        if #unavailable(iOS 13.0) {
            return "pngs_small"
        } else {
            return "pngs"
        }
    }()
    private static let defaultPngsDirName: String = "pngs"
    private static let textureQueue = DispatchQueue(label: "texture.queue")
    private static var textureLoader: MTKTextureLoader!
    // Le tiling associé à un png (init avec les "defaultPngTextures").
    private static var tilingOfPngNamed: [String: Tiling] = [
        "bar_in" : (m: 1, n: 1),
        "digits_black" : (m: 12, n: 2),
        "scroll_bar_back" : (m: 1, n: 3),
        "scroll_bar_front" : (m: 1, n: 3),
        "sliding_menu_back" : (m: 1, n: 1),
        "switch_back" : (m: 1, n: 1),
        "switch_front" : (m: 1, n: 1),
        "test_frame" : (m: 1, n: 1),
        "the_cat" : (m: 1, n: 1),
        "white" : (m: 1, n: 1),
    ]
    // Strong ref. des png par defaut (pour quelles reste en mémoire)
    private static var defaultPngTextures: [Texture] = []
    // Les str temporaire en attendant que la vrai string soit créée.
    private static var tempStringTextures: [Texture] = []
    // Les "minis" en attendant que la vrai texture soit chargé.
    private static var miniMtlTextureNamed: [String: MTLTexture] = [:]
    
    private static func temporyAddStrongRef(_ name:String, _ tex: Texture) {
        guard tempStrongTextureRefs[name] == nil else { return }
        tempStrongTextureRefs[name] = tex
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
            tempStrongTextureRefs.removeValue(forKey: name)
        }
    }
    // Liste strong de toutes les textures. Pour éviter les efface/création à répétition.
    // pas sûr que c'est une bonne solution...
    private static var tempStrongTextureRefs: [String: Texture] = [:]
//    private static var tempStrongTexture: [String: (Timer, Texture)] = [:]
    // On garde une référence pour libérer l'espace et pour le resizing des strings.
    private static var allStringTextures: [WeakElement<Texture>] = []
    // On garde aussi les liste des constant et localized pour éviter les duplicats
    private static var allConstantStringTextures: [String: WeakElement<Texture>] = [:]
    private static var allLocalizedStringTextures: [String: WeakElement<Texture>] = [:]
    // Pour les pngs la liste est pour le suspend/resume et éviter les duplicats.
    private static var allPngTextures: [String: WeakElement<Texture>] = [:]
}

