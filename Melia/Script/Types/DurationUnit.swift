//
//  DurationUnit.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

enum DurationUnit {
    case millisecond
    case second
    case minute

    static func named(_ name: String) throws -> DurationUnit {
        switch name {
        case "ms":
            return .millisecond
        case "s":
            return .second
        case "min":
            return .minute
        default:
            throw LookUpError.badName(name)
        }
    }

    var toMilliseconds: MELTimeInterval {
        switch self {
        case .millisecond:
            return 1
        case .second:
            return 1000
        case .minute:
            return 60000
        }
    }

    func toTimeInterval(_ value: MELTimeInterval) -> MELTimeInterval {
        return (value * toMilliseconds) / 1000
    }
}

