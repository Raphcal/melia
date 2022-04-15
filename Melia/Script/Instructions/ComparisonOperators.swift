//
//  ComparisonOperators.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol ComparisonOperator: Operator {
    func apply<T: Comparable & Equatable>(_ lhs: T, _ rhs: T) -> Bool
}

