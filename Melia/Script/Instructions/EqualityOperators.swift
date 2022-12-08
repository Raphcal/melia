//
//  EqualityOperators.swift
//  Melia
//
//  Created by Raphaël Calabro on 08/12/2022.
//

import Foundation

protocol EqualityOperator: Operator {
    func apply<T: Equatable>(_ lhs: T, _ rhs: T) -> Bool
}

extension EqualityOperator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        switch lhs {
        case let .integer(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            case let .decimal(rhsValue):
                return .boolean(apply(Float(lhsValue), rhsValue))
            default:
                return .boolean(false)
            }
        case let .decimal(lhsValue):
            switch rhs {
            case let .integer(rhsValue):
                return .boolean(apply(lhsValue, Float(rhsValue)))
            case let .decimal(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case let .point(lhsValue):
            switch rhs {
            case let .point(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case let .string(lhsValue):
            switch rhs {
            case let .string(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case let .animationName(lhsValue):
            switch rhs {
            case let .animationName(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case let .state(lhsValue):
            switch rhs {
            case let .state(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case let .direction(lhsValue):
            switch rhs {
            case let .direction(rhsValue):
                return .boolean(apply(lhsValue, rhsValue))
            default:
                return .boolean(false)
            }
        case .null:
            return .boolean(rhs == Value.null)
        default:
            return .null
        }
    }
}

struct Equals: EqualityOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Equatable {
        return lhs == rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is NotEquals
    }
}

struct NotEquals: EqualityOperator {
    func apply<T>(_ lhs: T, _ rhs: T) -> Bool where T : Equatable {
        return lhs != rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is NotEquals
    }
}

