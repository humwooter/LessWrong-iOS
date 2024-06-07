//
//  ColorFuncs.swift
//  LessWrong iOS
//
//  Created by Katyayani G. Raman on 6/6/24.
//

import Foundation
import SwiftUI


func getTopBackgroundColor(colorScheme: ColorScheme) -> Color {
    if colorScheme == .light {
        return Color("Background Color Light Light")
    } else {
        return .clear
    }
}

func getBackgroundColor(colorScheme: ColorScheme) -> Color {
    if colorScheme == .dark {
        return .brown.opacity(0.2)
    } else {
        return Color("Background Color Light Dark")
    }
}

func getColor(colorScheme: ColorScheme) -> Color {
    if colorScheme == .dark {
        return .white
    } else {
        return .black
    }
}

func getSectionColor(colorScheme: ColorScheme) -> Color {
    if colorScheme == .light {
        return .white
    } else {
        return .white.opacity(0.2)
    }
}
