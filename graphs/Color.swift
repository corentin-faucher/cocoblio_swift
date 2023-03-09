//
//  Color.swift
//  AnimalTyping
//
//  Created by Corentin Faucher on 2021-09-29.
//  Copyright © 2021 Corentin Faucher. All rights reserved.
//

import Darwin

enum Color {
    static let black: Vector4 = [0, 0, 0, 1]
    static let black_back: Vector4 = [0.1, 0.1, 0.05, 1]
    static let white: Vector4 = [1, 1, 1, 1]
    static let white_beige: Vector4 = [0.95, 0.92, 0.85, 1]
    static let gray_dark: Vector4 = [0.40, 0.40, 0.40, 1]
    static let gray_dark2: Vector4 = [0.25, 0.25, 0.25, 0.7]
    static let gray: Vector4 = [0.6, 0.6, 0.6, 1]
    static let gray_light: Vector4 = [0.80, 0.80, 0.80, 1]
    static let gray2: Vector4 = [0.75, 0.75, 0.75, 0.9]
    static let gray3: Vector4 = [0.90, 0.90, 0.90, 0.70]
    static let red: Vector4 = [1, 0, 0, 1]
    static let red_vermilion: Vector4 = [1, 0.3, 0.1, 1]
    static let red_coquelicot: Vector4 = [1, 0.2, 0, 1]
    static let red_orange2: Vector4 = [1, 0.4, 0.4, 1]
    static let red_coral: Vector4 = [1, 0.5, 0.3, 1]
    static let red_dark: Vector4 = [0.2, 0.1, 0.1, 1]
    static let orange: Vector4 = [1, 0.6, 0, 1]
    static let orange_amber: Vector4 = [1, 0.5, 0, 1]
    static let orange_bronze: Vector4 = [0.8, 0.5, 0.2, 1]
    static let orange_saffron: Vector4 = [1.0, 0.6, 0.2, 1]
    static let orange_saffron2: Vector4 = [1.0, 0.7, 0.4, 1]
    static let yellow_cadmium: Vector4 = [1, 1, 0, 1]
    static let yellow_amber: Vector4 = [1, 0.75, 0, 1]
    static let yellow_citrine: Vector4 = [0.90, 0.82, 0.04, 1]
    static let yellow_lemon: Vector4 = [1, 0.95, 0.05, 1]
    static let green_electric: Vector4 = [0, 1, 0, 1]
    static let green_electric2: Vector4 = [0.25, 1, 0.25, 1]
    static let green_fluo: Vector4 = [0.5, 1, 0.5, 1]
    static let green_ao: Vector4 = [0.0, 0.55, 0.0, 1]
    static let green_spring: Vector4 = [0.2, 1, 0.5, 1]
    static let green_avocado: Vector4 = [0.34, 0.51, 0.01, 1]
    static let green_dark_cyan: Vector4 = [0.0, 0.55, 0.55, 1]
    static let aqua: Vector4 = [0, 1, 1, 1]
    static let blue: Vector4 = [0, 0.25, 1, 1]
    static let blue_sky: Vector4 = [0.40, 0.70, 1, 1]
    static let blue_sky2: Vector4 = [0.55, 0.77, 1, 1]
    static let blue_pale: Vector4 = [0.8, 0.9, 1, 1]
    static let blue_azure: Vector4 = [0.00, 0.50, 1, 1]
    static let blue_strong: Vector4 = [0, 0, 1, 1]
    static let purple: Vector4 = [0.8, 0, 0.8, 1]
    static let purble_china_pink: Vector4 = [0.87, 0.44, 0.63, 1]
    static let purble_electric_indigo: Vector4 = [0.44, 0.00, 1, 1]
    static let purble_blue_violet: Vector4 = [0.54, 0.17, 0.89, 1]
    
}

extension Float {
    /** Convertie un float [0, 1] en gradient de couleur de bleu (0 et moins) à rouge (1 et plus),
     * en passant par vert, jaune, orange. */
    func toColor() -> Vector4 {
        switch self {
            case ..<0.0:
                return Color.blue_pale
            case ..<0.3:
                let alpha = self / 0.3
                return alpha * Color.green_spring + (1 - alpha) * Color.blue_pale
            case ..<0.5:
                let alpha = (self - 0.3) / 0.2
                return alpha * Color.yellow_cadmium + (1 - alpha) * Color.green_spring
            case ..<0.8:
                let alpha = (self - 0.5) / 0.3
                return alpha * Color.red + (1 - alpha) * Color.yellow_cadmium
            case ..<1.0:
                let alpha = (self - 0.8) / 0.2
                return alpha * Color.red_dark + (1 - alpha) * Color.red
            default:
                return Color.red
        }
    }
}

extension Vector4 {
    func toGray(_ level: Float, _ alpha: Float) -> Vector4 {
        return Vector4((1-alpha)*xyz + level*alpha, w)
    }
    // Si lum_factor est petit, e.g. 0.2 -> lum out max ~0.2
    // lum_factor grand lum out est semblable à lum in, e.g. 100 -> lum out ~= lum in.
    func toDark(_ intensity: Float) -> Vector4 {
        let lum_in = (x + y + z) / 3
        // (factor = 1 -> pas de changement, factor = 0 -> completement noir.)
        let factor = (1 - expf(-intensity * lum_in)) / (lum_in * intensity)
        return Vector4(xyz * factor, w)
    }
    func toLight(_ intensity: Float) -> Vector4 {
        let compl = 1 - xyz
        let dark_in = 1 - (x + y + z) / 3
        let factor = (1 - expf(-intensity * dark_in)) / (dark_in * intensity)
        return Vector4(1 - factor * compl, w)
    }
}
