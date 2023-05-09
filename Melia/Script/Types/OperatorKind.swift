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
    case pow
    case and, or
    case lessThan, lessThanOrEquals, greaterThan, greaterThanOrEquals, equals, notEquals
    case modulo, bitshiftLeft, bitshiftRight

    static func from(found: FoundToken) -> OperatorKind? {
        switch found.token {
        case .addOrSubstract, .multiplyOrDivide, .unaryOperator, .andOrOr, .equalityOrComparison:
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
        case "^":
            return .pow
        case "&&", "and":
            return .add
        case "||", "or":
            return .or
        case "<":
            return .lessThan
        case "<=":
            return .lessThanOrEquals
        case ">":
            return .greaterThan
        case ">=":
            return .greaterThanOrEquals
        case "==":
            return .equals
        case "!=":
            return .notEquals
        case "%":
            return .modulo
        case "<<":
            return .bitshiftLeft
        case ">>":
            return .bitshiftRight
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
        case .pow:
            return Pow()
        case .and:
            return And()
        case .or:
            return Or()
        case .lessThan:
            return LessThan()
        case .lessThanOrEquals:
            return LessThanOrEquals()
        case .greaterThan:
            return GreaterThan()
        case .greaterThanOrEquals:
            return GreaterThanOrEquals()
        case .equals:
            return Equals()
        case .notEquals:
            return NotEquals()
        case .modulo:
            return Modulo()
        case .bitshiftLeft:
            return BitshiftLeft()
        case .bitshiftRight:
            return BitshiftRight()
        }
    }
}
