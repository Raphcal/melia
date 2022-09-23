//
//  FoundToken.swift
//  Melia
//
//  Created by Raphaël Calabro on 13/04/2022.
//

import MeliceFramework

struct FoundToken: Equatable {
    var token: Token
    var matches: [String]
    var range: Range<Int>

    var value: Value {
        switch token {
        case .valueInt:
            return .integer(
                Int32(matches[1]) ?? 0
            )
        case .valueDecimal:
            return .decimal(
                Float(matches[1]) ?? 0
            )
        case .valueDuration:
            do {
                let duration = try DurationUnit.named(matches[2])
                return .decimal(
                    duration.toTimeInterval(
                        MELTimeInterval(matches[1]) ?? 0
                    )
                )
            } catch {
                print("Unable to parse duration: \(error)")
            }
        case .valueBoolean:
            return .boolean(matches[1] == "true")
        case .valueAnimation:
            return .animationName(matches[1])
        case .valueString:
            return .string(
                matches[1]
                    .replacingOccurrences(of: "\\\"", with: "\"")
                    .replacingOccurrences(of: "\\\\", with: "\\")
            )
        case .valueDirection:
            do {
                return .direction(
                    try MELDirection.named(matches[1])
                )
            } catch {
                print("Unable to parse direction: \(error)")
            }
        case .valuePoint:
            let point = MELPoint(
                x: GLfloat(matches[1]) ?? 0,
                y: GLfloat(matches[2]) ?? 0)
            return .point(point)
        default:
            break
        }
        return .null
    }
}
