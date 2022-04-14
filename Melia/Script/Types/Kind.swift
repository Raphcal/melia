//
//  Kind.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

enum Kind {
    case point, integer, decimal, direction, animation, sprite, string, null

    static func named(_ name: String) throws -> Kind {
        switch name {
        case "point":
            return .point
        case "integer":
            return .integer
        case "decimal":
            return .decimal
        case "sprite":
            return .sprite
        case "string":
            return .string
        case "null":
            return .null
        default:
            throw LookUpError.badName(name)
        }
    }
}
