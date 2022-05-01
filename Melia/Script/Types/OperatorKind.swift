//
//  Operator.swift
//  Melia
//
//  Created by Raphaël Calabro on 27/04/2022.
//

import Foundation

enum OperatorKind {
    case add, substract
    case multiply, divide
    case and, or

    static func from(found: FoundToken) -> OperatorKind? {
        switch found.token {
        case .addOrSubstract, .multiplyOrDivide, .unaryOperator, .andOrOr:
            return named(found.matches[1])
        default:
            return nil
        }
    }

    static func named(_ name: String) -> OperatorKind? {
        switch name {
        case "+":
            return .add
        case "-":
            return .substract
        case "*":
            return .multiply
        case "/":
            return .divide
        case "&&", "and":
            return .add
        case "||", "or":
            return .or
        default:
            return nil
        }
    }

    var priority: Int {
        switch self {
        case .add, .substract:
            return 1
        case .multiply, .divide:
            return 2
        default:
            return 0
        }
    }

    var instruction: Operator {
        switch self {
        case .add:
            return Add()
        case .substract:
            return Substract()
        case .multiply:
            return Multiply()
        case .divide:
            return Divide()
        case .and:
            return And()
        case .or:
            return Or()
        }
    }
}
