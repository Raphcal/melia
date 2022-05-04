//
//  ParseDispatchQueue.swift
//  Melia
//
//  Created by Raphaël Calabro on 04/05/2022.
//

import Foundation

fileprivate let parseDispatchQueue = DispatchQueue(label: "fr.rca.melia.parse")

extension DispatchQueue {
    static var parse: DispatchQueue {
        return parseDispatchQueue
    }
}
