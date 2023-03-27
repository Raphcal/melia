//
//  IntegerOperators.swift
//  Melia
//
//  Created by Raphaël Calabro on 27/03/2023.
//

import MeliceFramework

protocol IntegerOperator: Operator {
    func apply<T: IntegerOperand>(_ lhs: T, _ rhs: T) -> T
}

protocol IntegerOperand {
    static func % (lhs: Self, rhs: Self) -> Self
    static func >> (lhs: Self, rhs: Self) -> Self
    static func << (lhs: Self, rhs: Self) -> Self
}
extension Int32: IntegerOperand {}

extension IntegerOperator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        switch lhs {
        case let .integer(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .integer(apply(lhsValue, rhsValue))
            case let .decimal(rhsValue):
                return .integer(apply(lhsValue, Int32(rhsValue)))
            case let .point(rhsValue):
                return .point(MELPoint(x: Float(apply(lhsValue, Int32(rhsValue.x))), y: Float(apply(lhsValue, Int32(rhsValue.y)))))
            default:
                return .null
            }
        case let .decimal(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .integer(apply(Int32(lhsValue), rhsValue))
            case let .decimal(rhsValue):
                return .integer(apply(Int32(lhsValue), Int32(rhsValue)))
            case let .point(rhsValue):
                return .point(MELPoint(x: Float(apply(Int32(lhsValue), Int32(rhsValue.x))), y: Float(apply(Int32(lhsValue), Int32(rhsValue.y)))))
            default:
                return .null
            }
        case let .point(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .point(MELPoint(x: Float(apply(Int32(lhsValue.x), rhsValue)), y: Float(apply(Int32(lhsValue.y), rhsValue))))
            case let .decimal(rhsValue):
                return .point(MELPoint(x: Float(apply(Int32(lhsValue.x), Int32(rhsValue))), y: Float(apply(Int32(lhsValue.y), Int32(rhsValue)))))
            case let .point(rhsValue):
                return .point(MELPoint(x: Float(apply(Int32(lhsValue.x), Int32(rhsValue.x))), y: Float(apply(Int32(lhsValue.y), Int32(rhsValue.y)))))
            default:
                return .null
            }
        default:
            return .null
        }
    }
}

struct Modulo: IntegerOperator {
    func apply<T: IntegerOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs % rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Modulo
    }
}

struct BitshiftLeft: IntegerOperator {
    func apply<T: IntegerOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs << rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is BitshiftLeft
    }
}

struct BitshiftRight: IntegerOperator {
    func apply<T: IntegerOperand>(_ lhs: T, _ rhs: T) -> T {
        return lhs >> rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is BitshiftRight
    }
}
