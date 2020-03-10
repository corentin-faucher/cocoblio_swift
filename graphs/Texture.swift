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
    var string: String = ""
    var mtlTexture: MTLTexture? = nil
    var ptu = PerTextureUniforms()
    var ratio: Float = 1
    
    init(_ m: Int, _ n: Int, _ string: String) {
        self.m = m
        self.n = n
        self.string = string
        ptu.dim = (m: Float(m), n: Float(n))
    }
    
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
    
    
    /*-- Les textures de png --*/
    static func initPngTex(pngID: String, m: Int, n: Int) {
        guard pngList[pngID] == nil else {
            printerror("Texture du png \(pngID) déjà init.")
            return
        }
        let newTex = Texture(m, n, pngID)
        newTex.initAsPng()
        pngList[pngID] = newTex
    }
    static func getPngTex(pngID: String) -> Texture {
        guard let tex = pngList[pngID] else {
            printerror("Texture du png \(pngID) pas encore init.")
            return getConstantStringTex(string: pngID)
        }
        return tex
    }
    private static var pngList: [String: Texture] = [:]
    /*-- Les strings constantes --*/
    static func getConstantStringTex(string: String) -> Texture {
        if let tex = cstStringList[string] {
            print("String \(string) déjà init...")
            return tex
        }
        print("Création de texture pas défaut.")
        let newTex = Texture(1, 1, string)
        print("Init as string.")
        newTex.initAsString()
        cstStringList[string] = newTex
        return newTex
    }
    private static var cstStringList: [String: Texture] = [:]
    /*-- Les strings localisées. (Pas obligé d'init comme en kotlin).--*/
    static func getLocalizedStringTex(textID: String) -> Texture {
        if let tex = localizedStringList[textID] {
            return tex
        }
        let newTexture = Texture(1, 1, textID.localized ?? "")
        newTexture.initAsString()
        localizedStringList[textID] = newTexture
        return newTexture
    }
    static func updateAllLocalizedStrings() {
        for element in localizedStringList {
            element.value.string = element.key.localized ?? ""
            element.value.initAsString()
        }
    }
    private static var localizedStringList: [String: Texture] = [:]
    /*-- Les strings éditables --*/
    static func setEditableString(id: Int, newString: String) {
        if let tex = editableStringList[id] {
            tex.string = newString
            tex.initAsString()
            return
        }
        let newTexture = Texture(1, 1, newString)
        newTexture.initAsString()
        editableStringList[id] = newTexture
    }
    static func getEditableStringTex(id: Int) -> Texture {
        if let tex = editableStringList[id] {
            return tex
        }
        let newTexture = Texture(1, 1, "")
        editableStringList[id] = newTexture
        return newTexture
    }
    static func getEditableString(id: Int) -> String {
        guard let tex = editableStringList[id] else {
            printerror("EditableString pas dans la liste.")
            return "I am error"
        }
        return tex.string
    }
    static func getNewEditableStringID() -> Int {
        while editableStringList[currentFreeEditableStringID] != nil {
            currentFreeEditableStringID += 1
        }
        let returnID = currentFreeEditableStringID
        currentFreeEditableStringID += 1
        return returnID
    }
    private static var editableStringList: [Int: Texture] = [:]
    private static var currentFreeEditableStringID = 0
    
    
    // 2. Stuff pour Renderer
    static func setTexture(newTex: Texture, with commandEncoder: MTLRenderCommandEncoder) {
        currentTexture = newTex
        
        commandEncoder.setFragmentTexture(newTex.mtlTexture, index: 0)
        
        commandEncoder.setVertexBytes(&newTex.ptu, length: MemoryLayout<PerTextureUniforms>.size, index: 3)
    }
    static var currentTexture: Texture? = nil
    static var textureLoader: MTKTextureLoader!
    // 2.1 Textures de textes
    private static var fontSize: CGFloat = 128
    
}
