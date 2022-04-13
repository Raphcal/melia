//
//  Kind.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum Kind {
    case point, integer, duration, direction, animation, sprite, null

    static func named(_ name: String) throws -> Kind {
        switch name {
        case "point":
            return .point
        case "integer":
            return .integer
        case "duration":
            return .duration
        case "animation":
            return .animation
        case "sprite":
            return .sprite
        case "null":
            return .null
        default:
            throw LookUpError.badName(name)
        }
    }
}
