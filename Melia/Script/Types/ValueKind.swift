//
//  ValueKind.swift
//  Melia
//
//  Created by Raphaël Calabro on 01/05/2022.
//

import Foundation

enum ValueKind: Equatable {
    case integer
    case decimal
    case point
    case boolean
    case string
    case direction
    case state
    case sprite
    case animationName
    case animation
    case animations
    case map
    case shootingStyle
    case null

    func kind(for property: String) -> ValueKind {
        switch self {
        case .point:
            switch property {
            case "x", "y", "width", "height":
                return .decimal
            default:
                break
            }
        case .direction:
            switch property {
            case "angle", "value":
                return .decimal
            case "reverse":
                return .direction
            default:
                break
            }
        case .sprite:
            switch property {
            case "direction":
                return .direction
            case "center":
                return .point
            case "size":
                return .point
            case "instance":
                return .point
            case "collidesWithWall", "isJumping":
                return .boolean
            case "animation":
                return .animation
            case "animations":
                return .animations
            default:
                break
            }
        case .animations:
            return .animation
        case .animation:
            if property == "duration" {
                return .decimal
            }
        default:
            break
        }
        return .null
    }
}

extension Value {
    var kind: ValueKind {
        switch self {
        case .integer(_):
            return .integer
        case .decimal(_):
            return .decimal
        case .point(_):
            return .point
        case .boolean(_):
            return .boolean
        case .string(_):
            return .string
        case .direction(_):
            return .direction
        case .sprite(_):
            return .sprite
        case .animationName(_):
            return .animationName
        case .animation(_):
            return .animation
        case .animations(_):
            return .animations
        case .map(_):
            return .map
        case .state(_):
            return .state
        case .shootingStyle(_):
            return .shootingStyle
        case .null:
            return .null
        }
    }
}

extension Dictionary where Dictionary.Key == String, Dictionary.Value == ValueKind {
    func valueKind(for name: String) -> ValueKind {
        let path = name.components(separatedBy: ".")
        if path.isEmpty {
            return .null
        }
        var valueKind = self[path[0]] ?? .null
        for index in 1 ..< path.count {
            valueKind = valueKind.kind(for: path[index])
        }
        return valueKind
    }
}

extension Dictionary where Dictionary.Key == String, Dictionary.Value == ConstantNode {
    func valueKind(for name: String) -> ValueKind {
        let path = name.components(separatedBy: ".")
        if path.isEmpty {
            return .null
        }
        if let constant = self[path[0]] {
            var valueKind = constant.value.kind
            for index in 1 ..< path.count {
                valueKind = valueKind.kind(for: path[index])
            }
            return valueKind
        } else {
            return .null
        }
    }
}
