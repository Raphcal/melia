//
//  ComparisonOperators.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol ComparisonOperator: Operator {
    func apply<T: Comparable>(_ lhs: T, _ rhs: T) -> Bool
}

extension ComparisonOperator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        switch lhs {
        case let .integer(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            case let .decimal(rhsValue):
                return .boolean(apply(Float(lhsValue), rhsValue))
            default:
                return .null
            }
        case let .decimal(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .boolean(apply(lhsValue, Float(rhsValue)))
            case let .decimal(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .null
            }
        default:
            return .null
        }
    }
}

struct LessThan: ComparisonOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Comparable {
        return lhs < rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is LessThan
    }
}

struct LessThanOrEquals: ComparisonOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Comparable {
        return lhs <= rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is LessThanOrEquals
    }
}

struct GreaterThan: ComparisonOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Comparable {
        return lhs > rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is GreaterThan
    }
}

struct GreaterThanOrEquals: ComparisonOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Comparable {
        return lhs >= rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is GreaterThanOrEquals
    }
}
