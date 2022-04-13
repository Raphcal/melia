//
//  Operators.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

protocol Operator: Instruction {
    func apply(_ lhs: Int32, _ rhs: Int32) -> Int32
    func apply(_ lhs: Value, _ rhs: Value) -> Value
}

extension Operator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        switch lhs {
        case let .integer(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .integer(apply(lhsValue, rhsValue))
            case let .duration(rhsValue, unit):
                return .duration(apply(lhsValue, rhsValue), unit: unit)
            case let .point(rhsValue):
                return .point(MELIntPoint(x: apply(lhsValue, rhsValue.x), y: apply(lhsValue, rhsValue.y)))
            default:
                return .null
            }
        case let .duration(lhsValue, lhsUnit):
            switch rhs {
            case let .integer(rhsValue):
                return .duration(apply(lhsValue, rhsValue), unit: lhsUnit)
            case let .duration(rhsValue, rhsUnit):
                if lhsUnit.toMilliseconds < rhsUnit.toMilliseconds {
                    return .duration(apply(lhsValue, rhsValue * (rhsUnit.toMilliseconds / lhsUnit.toMilliseconds)), unit: lhsUnit)
                } else {
                    return .duration(apply(lhsValue * (lhsUnit.toMilliseconds / rhsUnit.toMilliseconds), rhsValue), unit: rhsUnit)
                }
            default:
                return .null
            }
        case let .point(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .point(MELIntPoint(x: apply(lhsValue.x, rhsValue), y: apply(lhsValue.y, rhsValue)))
            case let .point(rhsValue):
                return .point(MELIntPoint(x: apply(lhsValue.x, rhsValue.x), y: apply(lhsValue.y, rhsValue.y)))
            default:
                return .null
            }
        default:
            return .null
        }
    }

    func update(stack: inout [Value], heap: inout [String : Value], delta: MELTimeInterval) {
        let rhs = stack.removeLast()
        let lhs = stack.removeLast()
        stack.append(apply(lhs, rhs))
    }
}

func operatorNamed(_ name: String) throws -> Operator {
    switch name {
    case "+":
        return Add()
    case "-":
        return Substract()
    case "*":
        return Multiply()
    case "/":
        return Divide()
    default:
        throw LookUpError.badName(name)
    }
}

struct Add: Operator {
    func apply(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        return lhs + rhs
    }
}
struct Substract: Operator {
    func apply(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        return lhs - rhs
    }
}
struct Multiply: Operator {
    func apply(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        return lhs * rhs
    }
}
struct Divide: Operator {
    func apply(_ lhs: Int32, _ rhs: Int32) -> Int32 {
        return lhs / rhs
    }
}
