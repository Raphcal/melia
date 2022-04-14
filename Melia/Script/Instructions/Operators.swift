//
//  Operators.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

protocol Operator: Instruction {
    func apply<T: Operand>(_ lhs: T, _ rhs: T) -> T
    func apply(_ lhs: Value, _ rhs: Value) -> Value
}

protocol Operand {
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
}
extension Int32: Operand {}
extension Float: Operand {}

extension Operator {
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

    func update(context: Script.ExecutionContext) -> Script.ExecutionContext {
        var newContext = context
        let rhs = newContext.stack.removeLast()
        let lhs = newContext.stack.removeLast()
        newContext.stack.append(apply(lhs, rhs))
        return newContext
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
    func apply<T: Operand>(_ lhs: T, _ rhs: T) -> T {
        return lhs + rhs
    }
}
struct Substract: Operator {
    func apply<T: Operand>(_ lhs: T, _ rhs: T) -> T {
        return lhs - rhs
    }
}
struct Multiply: Operator {
    func apply<T: Operand>(_ lhs: T, _ rhs: T) -> T {
        return lhs * rhs
    }
}
struct Divide: Operator {
    func apply<T: Operand>(_ lhs: T, _ rhs: T) -> T {
        return lhs / rhs
    }
}
