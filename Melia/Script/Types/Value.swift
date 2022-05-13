//
//  Value.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

enum Value: Equatable {
    case integer(_ value: Int32)
    case decimal(_ value: Float)
    case point(_ value: MELPoint)
    case boolean(_ value: Bool)
    case string(_ value: String)
    case direction(_ value: MELDirection)
    case sprite(_ value: MELSpriteRef)
    case animationName(_ value: String)
    case animation(_ value: MELAnimationDefinition)
    case animations(_ value: MELAnimationDefinitionList)
    case map(_ value: MELMap)
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
            switch property {
            case "direction":
                return .direction(sprite.pointee.direction)
            case "center":
                return .point(sprite.pointee.frame.origin)
            case "frame":
                // TODO: Ajouter un type rectangle pour le cadre
                return .point(sprite.pointee.frame.origin)
            case "collidesWithWall":
                // TODO: Vérifier si le sprite est en contact avec un mur
                return .boolean(false)
            case "isJumping":
                // TODO: Vérifier si le sprite est en train de sauter
                return .boolean(false)
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
                      case let .animationName(animation) = value {
                guard sprite.animation.definition.nameAsString != animation,
                      let animationIndex = sprite.pointee.definition.animations.firstIndex(where: { $0.nameAsString == animation })
                else {
                    return .sprite(sprite)
                }
                let animationDefinition = sprite.pointee.definition.animations.memory!.advanced(by: animationIndex)
                let animationRef = MELAnimationAlloc(animationDefinition)
                MELSpriteSetAnimation(sprite, animationRef)
            }
            return .sprite(sprite)
        default:
            break
        }
        return value
    }

    var isInlineable: Bool {
        switch self {
        case .integer(_), .decimal(_), .boolean(_), .point(_), .direction(_):
            return true
        default:
            return false
        }
    }

    func isInlineable(property: String) -> Bool {
        switch self {
        case .point(_):
            if property == "x" {
                return true
            } else if property == "y" {
                return true
            }
        case .sprite(_):
            if property == "animation" {
                return true
            }
        default:
            break
        }
        return false
    }

    static func == (lhs: Value, rhs: Value) -> Bool {
        switch lhs {
        case .integer(let lhsValue):
            if case let .integer(rhsValue) = rhs {
                return lhsValue == rhsValue
            } else if case let .decimal(rhsValue) = rhs {
                return Float(lhsValue) == rhsValue
            }
        case .decimal(let lhsValue):
            if case let .decimal(rhsValue) = rhs {
                return lhsValue == rhsValue
            } else if case let .integer(rhsValue) = rhs {
                return lhsValue == Float(rhsValue)
            }
        case .point(let lhsValue):
            if case let .point(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
        case .boolean(let lhsValue):
            if case let .boolean(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
        case .string(let lhsValue):
            if case let .string(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
        case .direction(let lhsValue):
            if case let .direction(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
        case .animationName(let lhsValue):
            if case let .animationName(rhsValue) = rhs {
                return lhsValue == rhsValue
            }
        case .null:
            return rhs == .null
        default:
            break
        }
        return false
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

    func inlineableValue(at path: [String]) -> Value? {
        if path.isEmpty {
            return nil
        }
        var value = self[path[0]] ?? .null
        var index = 1
        while index < path.count && value.isInlineable {
            value = value.value(for: path[index])
            index += 1
        }
        return value.isInlineable ? value : nil
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

    func string(for name: String) -> String? {
        if case let .string(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func integer(for name: String) -> Int32? {
        if case let .integer(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func decimal(for name: String) -> Float? {
        if case let .decimal(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func point(for name: String) -> MELPoint? {
        if case let .point(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func boolean(for name: String) -> Bool? {
        if case let .boolean(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func direction(for name: String) -> MELDirection? {
        if case let .direction(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func animationName(for name: String) -> String? {
        if case let .animationName(value) = self[name] {
            return value
        } else {
            return nil
        }
    }

    func sprite(for name: String) -> MELSpriteRef? {
        if case let .sprite(value) = self[name] {
            return value
        } else {
            return nil
        }
    }
}
