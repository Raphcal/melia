//
//  Operators.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework
import Foundation

protocol AlgebraicOperator: Operator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T
    func apply(_ lhs: String, _ rhs: String) -> String?
}

infix operator ^^ : MultiplicationPrecedence
protocol AlgebraicOperand {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
    static func ^^ (lhs: Self, rhs: Self) -> Self
}
extension Int32: AlgebraicOperand {
    static func ^^ (radix: Int32, power: Int32) -> Int32 {
        return Int32(pow(Double(radix), Double(power)))
    }
}
extension Float: AlgebraicOperand {
    static func ^^ (radix: Float, power: Float) -> Float {
        return Float(pow(Double(radix), Double(power)))
    }
}

extension AlgebraicOperator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        switch lhs {
        case let .integer(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .integer(apply(lhsValue, rhsValue))
            case let .decimal(rhsValue):
                return .decimal(apply(Float(lhsValue), rhsValue))
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(Float(lhsValue), rhsValue.x), y: apply(Float(lhsValue), rhsValue.y)))
            case let .string(rhsValue):
                if let result = apply(String(lhsValue), rhsValue) {
                    return .string(result)
                }
            default:
                break
            }
        case let .decimal(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .decimal(apply(lhsValue, Float(rhsValue)))
            case let .decimal(rhsValue):
                return .decimal(apply(lhsValue, rhsValue))
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(lhsValue, rhsValue.x), y: apply(lhsValue, rhsValue.y)))
            case let .string(rhsValue):
                if let result = apply(String(lhsValue), rhsValue) {
                    return .string(result)
                }
            default:
                break
            }
        case let .point(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, Float(rhsValue)), y: apply(lhsValue.y, Float(rhsValue))))
            case let .decimal(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, rhsValue), y: apply(lhsValue.y, rhsValue)))
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, rhsValue.x), y: apply(lhsValue.y, rhsValue.y)))
            case let .direction(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, rhsValue == MELDirectionLeft ? -1.0 : 1.0), y: apply(lhsValue.y, rhsValue == MELDirectionUp ? -1.0 : 1.0)))
            case let .string(rhsValue):
                if let result = apply("(x: \(lhsValue.x), y: \(lhsValue.y)", rhsValue) {
                    return .string(result)
                }
            default:
                break
            }
        case let .boolean(lhsValue):
            switch rhs {
            case let .string(rhsValue):
                if let result = apply(String(lhsValue), rhsValue) {
                    return .string(result)
                }
            default:
                break
            }
        case let .direction(lhsValue):
            switch rhs {
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(lhsValue == MELDirectionLeft ? -1.0 : 1.0, rhsValue.x), y: apply(lhsValue == MELDirectionUp ? -1.0 : 1.0, rhsValue.y)))
            case let .string(rhsValue):
                if let result = apply(lhsValue.name, rhsValue) {
                    return .string(result)
                }
            default:
                break
            }
        case let .string(lhsValue):
            let result: String?
            switch rhs {
            case let .integer(rhsValue):
                result = apply(lhsValue, String(rhsValue))
            case let .decimal(rhsValue):
                result = apply(lhsValue, String(rhsValue))
            case let .point(rhsValue):
                result = apply(lhsValue, "(x: \(rhsValue.x), y: \(rhsValue.y)")
            case let .boolean(rhsValue):
                result = apply(lhsValue, String(rhsValue))
            case let .direction(rhsValue):
                result = apply(lhsValue, rhsValue.name)
            case let .state(rhsValue):
                result = apply(lhsValue, "state \(rhsValue)")
            case let .string(rhsValue):
                result = apply(lhsValue, rhsValue)
            default:
                result = nil
            }
            if let result = result {
                return .string(result)
            }
        default:
            break
        }
        return .null
    }

    func apply(_ lhs: String, _ rhs: String) -> String? {
        return nil
    }
}

struct Add: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs + rhs
    }
    func apply(_ lhs: String, _ rhs: String) -> String? {
        return lhs + rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Add
    }
}
struct Substract: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs - rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Substract
    }
}
struct Multiply: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs * rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Multiply
    }
}
struct Divide: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs / rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Divide
    }
}
struct Pow: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs ^^ rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Pow
    }
}
