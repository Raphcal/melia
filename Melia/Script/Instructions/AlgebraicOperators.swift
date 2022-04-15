//
//  Operators.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

protocol AlgebraicOperator: Operator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T
}

protocol AlgebraicOperand {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
}
extension Int32: AlgebraicOperand {}
extension Float: AlgebraicOperand {}

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
            default:
                return .null
            }
        case let .decimal(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .decimal(apply(lhsValue, Float(rhsValue)))
            case let .decimal(rhsValue):
                return .decimal(apply(lhsValue, rhsValue))
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(lhsValue, rhsValue.x), y: apply(lhsValue, rhsValue.y)))
            default:
                return .null
            }
        case let .point(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, Float(rhsValue)), y: apply(lhsValue.y, Float(rhsValue))))
            case let .decimal(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, rhsValue), y: apply(lhsValue.y, rhsValue)))
            case let .point(rhsValue):
                return .point(MELPoint(x: apply(lhsValue.x, rhsValue.x), y: apply(lhsValue.y, rhsValue.y)))
            default:
                return .null
            }
        default:
            return .null
        }
    }
}

struct Add: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs + rhs
    }
}
struct Substract: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs - rhs
    }
}
struct Multiply: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs * rhs
    }
}
struct Divide: AlgebraicOperator {
    func apply<T: AlgebraicOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs / rhs
    }
}
