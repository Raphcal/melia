//
//  FoundToken.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

struct FoundToken: Equatable {
    var token: Token
    var matches: [String]
    var range: Range<Int>
}
