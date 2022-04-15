//
//  Value.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

enum Value {
    case integer(_ value: Int32)
    case decimal(_ value: Float)
    case point(_ value: MELPoint)
    case boolean(_ value: Bool)
    case string(_ value: String)
    case direction(_ value: MELDirection)
    case sprite(_ value: MELSpriteRef)
    case animation(_ value: MELAnimationDefinition)
    case animations(_ value: MELAnimationDefinitionList)
    case null

    func value(for property: String) -> Value {
        switch self {
        case .point(let point):
            switch property {
            case "x":
                return .decimal(point.x)
            case "y":
                return .decimal(point.y)
            default:
                break
            }
        case .direction(let direction):
            switch property {
            case "angle", "value":
                return .decimal(direction.value)
            case "reverse":
                return .direction(direction.reverse)
            default:
                break
            }
        case .sprite(let sprite):
            // TODO: Permettre l'accès aux animations
            switch property {
            case "direction":
                return .direction(sprite.pointee.direction)
            case "center":
                return .point(sprite.pointee.frame.origin)
            case "collidesWithWall":
                // TODO: Vérifier si le sprite est en contact avec un mur
                return .integer(0)
            case "isJumping":
                // TODO: Vérifier si le sprite est en train de sauter
                return .integer(0)
            case "animations":
                return .animations(sprite.pointee.definition.animations)
            default:
                break
            }
        case .animations(let animations):
            if let animation = animations.first(where: { $0.nameAsString == property }) {
                return .animation(animation)
            }
        case .animation(let animation):
            if property == "duration" {
                return .decimal(Float(animation.frameCount) * 1 / Float(animation.frequency))
            }
        default:
            break
        }
        return .null
    }

    func edited(bySetting value: Value, for property: String) -> Value {
        switch self {
        case .point(let point):
            if property == "x", case let .integer(rhs) = value {
                return .point(MELPoint(x: GLfloat(rhs), y: point.y))
            } else if property == "x", case let .decimal(rhs) = value {
                return .point(MELPoint(x: rhs, y: point.y))
            } else if property == "y", case let .integer(rhs) = value {
                return .point(MELPoint(x: point.x, y: GLfloat(rhs)))
            } else if property == "y", case let .decimal(rhs) = value {
                return .point(MELPoint(x: point.x, y: rhs))
            }
        case .sprite(let sprite):
            if property == "direction", case let .direction(direction) = value {
                sprite.pointee.direction = direction
            } else if property == "center", case let .point(point) = value {
                MELSpriteSetFrameOrigin(sprite, point)
            } else if property == "animation",
                      case let .string(animation) = value,
                      let animationIndex = sprite.pointee.definition.animations.firstIndex(where: { $0.nameAsString == animation }) {
                let animationDefinition = sprite.pointee.definition.animations.memory!.advanced(by: animationIndex)
                let animationRef = MELAnimationAlloc(animationDefinition)
                MELSpriteSetAnimation(sprite, animationRef)
            }
        default:
            break
        }
        return value
    }
}

extension Dictionary where Dictionary.Key == String, Dictionary.Value == Melia.Value {
    func value(at path: [String]) -> Value {
        if path.isEmpty {
            return .null
        }
        var value = self[path[0]] ?? .null
        for index in 1 ..< path.count {
            value = value.value(for: path[index])
        }
        return value
    }

    mutating func setValue(_ value: Value, at path: [String]) {
        if path.isEmpty {
            return
        }
        var lastValue = self[path[0]] ?? .null
        var values = [lastValue]
        for index in 1 ..< path.count {
            lastValue = lastValue.value(for: path[index])
            values.append(lastValue)
        }

        lastValue = value
        for index in 1 ..< path.count {
            lastValue = values[path.count - index - 1].edited(bySetting: lastValue, for: path[path.count - index])
        }
        self[path[0]] = lastValue
    }
}
