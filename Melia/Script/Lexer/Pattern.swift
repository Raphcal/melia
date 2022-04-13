//
//  Pattern.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import Foundation

struct Pattern {
    let regularExpression: NSRegularExpression
    init(pattern: String) {
        self.regularExpression = (try? NSRegularExpression(pattern: pattern)) ?? NSRegularExpression()
    }
    func matches(in value: String, from index: Int) -> [String]? {
        if let match = regularExpression.firstMatch(in: value, range: NSRange(location: index, length: value.count - index)) {
            if match.range(at: 0).location == index {
                return (0 ..< match.numberOfRanges).map { range in String(value[Range(match.range(at: range), in: value)!]) }
            }
        }
        return nil
    }
}
