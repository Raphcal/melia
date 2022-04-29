//
//  BooleanOperators.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol BooleanOperator: Operator {
    func apply(_ lhs: Bool, _ rhs: Bool) -> Bool
}

extension BooleanOperator {
    func apply(_ lhs: Value, _ rhs: Value) -> Value {
        if case let .boolean(lhsValue) = lhs,
           case let .boolean(rhsValue) = rhs {
            return .boolean(apply(lhsValue, rhsValue))
        } else {
            return .null
        }
    }
}

struct And: BooleanOperator {
    func apply(_ lhs: Bool, _ rhs: Bool) -> Bool {
        return lhs && rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is And
    }
}

struct Or: BooleanOperator {
    func apply(_ lhs: Bool, _ rhs: Bool) -> Bool {
        return lhs || rhs
    }
    func equals(other: Instruction) -> Bool {
        return other is Or
    }
}
