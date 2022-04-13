//
//  Value.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

enum Value {
    case integer(_ value: Int32)
    case duration(_ value: Int32, unit: DurationUnit)
    case point(_ value: MELIntPoint)
    case animation(_ value: String)
    case direction(_ value: MELDirection)
    case sprite(_ value: MELSpriteRef)
    case null

    var kind: Kind {
        switch self {
        case .integer:
            return .integer
        case .duration:
            return .duration
        case .point:
            return .point
        case .animation:
            return .animation
        case .direction:
            return .direction
        case .sprite:
            return .sprite
        case .null:
            return .null
        }
    }
}
