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
    case animation(_ value: AnimationValue)
    case animations(_ value: MELAnimationDefinitionList)
    case map(_ value: MELMap)
    case state(_ name: String)
    case null

    func value(for property: String) -> Value {
        switch self {
        case .point(let point):
            switch property {
            case "x", "width":
                return .decimal(point.x)
            case "y", "height":
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
            case "size":
                let size = sprite.pointee.frame.size
                return .point(MELPoint(x: size.width, y: size.height))
            case "frame":
                // TODO: Ajouter un type rectangle pour le cadre
                return .point(sprite.pointee.frame.origin)
            case "collidesWithWall":
                // TODO: Vérifier si le sprite est en contact avec un mur
                return .boolean(false)
            case "isJumping":
                // TODO: Vérifier si le sprite est en train de sauter
                return .boolean(false)
            case "animation":
                return .animation(AnimationValue(animationRef: sprite.animation))
            case "animations":
                return .animations(sprite.pointee.definition.animations)
            default:
                break
            }
        case .animations(let animations):
            if let animation = animations.first(where: { $0.nameAsString == property }) {
                return .animation(AnimationValue(animationDefinition: animation))
            }
        case .animation(let animation):
            if let animationRef = animation.animationRef {
                if property == "duration" {
                    return .decimal(Float(animationRef.definition.frameCount) / (Float(animationRef.definition.frequency) * Float(animationRef.pointee.speed)))
                } else if property == "speed" {
                    return .decimal(Float(animationRef.pointee.speed))
                }
            } else {
                if property == "duration" {
                    return .decimal(Float(animation.definition.frameCount) / Float(animation.definition.frequency))
                } else if property == "speed" {
                    return .decimal(1)
                }
            }
        default:
            break
        }
        return .null
    }

    func edited(bySetting value: Value, for property: String) -> Value {
        switch self {
        case .point(let point):
            if property == "x" || property == "width", case let .integer(rhs) = value {
                return .point(MELPoint(x: GLfloat(rhs), y: point.y))
            } else if property == "x" || property == "width", case let .decimal(rhs) = value {
                return .point(MELPoint(x: rhs, y: point.y))
            } else if property == "y" || property == "height", case let .integer(rhs) = value {
                return .point(MELPoint(x: point.x, y: GLfloat(rhs)))
            } else if property == "y" || property == "height", case let .decimal(rhs) = value {
                return .point(MELPoint(x: point.x, y: rhs))
            }
        case .sprite(let sprite):
            if property == "direction", case let .direction(direction) = value {
                sprite.pointee.direction = direction
            } else if property == "center", case let .point(point) = value {
                MELSpriteSetFrameOrigin(sprite, point)
            } else if property == "size", case let .point(point) = value {
                var frame = sprite.pointee.frame
                frame.size = MELSize(width: point.x, height: point.y)
                MELSpriteSetFrame(sprite, frame)
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
            } else if property == "animation",
                      case let .animation(animation) = value {
                MELSpriteSetAnimation(sprite, animation.getAnimationRef())
                animation.isStrongRef = false
            }
            return .sprite(sprite)
        case .animation(let animation):
            let animationRef = animation.getAnimationRef()
            if property == "duration", case let .integer(duration) = value {
                animationRef.pointee.speed = MELTimeInterval(animation.definition.frameCount) / (MELTimeInterval(duration) * MELTimeInterval(animation.definition.frequency))
            } else if property == "duration", case let .decimal(duration) = value {
                animationRef.pointee.speed = MELTimeInterval(animation.definition.frameCount) / (MELTimeInterval(duration) * MELTimeInterval(animation.definition.frequency))
            } else if property == "speed", case let .integer(speed) = value {
                animationRef.pointee.speed = MELTimeInterval(speed)
            } else if property == "speed", case let .decimal(speed) = value {
                animationRef.pointee.speed = MELTimeInterval(speed)
            }
            return .animation(animation)
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

    /// Indique s'il possible d'inliner la propriété ou un de ses descendants
    func isInlineable(property: String) -> Bool {
        switch self {
        case .point(_):
            return ["x", "y", "width", "height"].contains(property)
        case .sprite(_):
            return property == "animations"
        case .animations(_):
            return true
        case .animation(_):
            return property == "duration"
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
        case .state(let lhsValue):
            if case let .state(rhsValue) = rhs {
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
        while index < path.count && value.isInlineable(property: path[index]) {
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
