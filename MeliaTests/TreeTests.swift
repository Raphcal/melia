//
//  TreeTests.swift
//  MeliaTests
//
//  Created by Raphaël Calabro on 29/04/2022.
//

import XCTest
import MeliceFramework
@testable import Melia

final class TreeTests: XCTestCase {
    func testSetAnimationAndWait() throws {
        let result = TokenTree(code: """
state main:
    self.animation = stand
    during 2s:
        wait
    self.animation = walk
    during 500ms:
        wait
""")!
        XCTAssertFalse(result.children.isEmpty, "L'arbre ne doit pas être vide")
    }

    func testMultiplyPriority() throws {
        let result = TokenTree(code: "result = 2 + 3 * 4 + 5")!
        XCTAssertFalse(result.children.isEmpty, "L'arbre ne doit pas être vide")
    }

    func testBraces() throws {
        let result = TokenTree(code: "result = (2 + 3) * (4 + 5)")!
        XCTAssertFalse(result.children.isEmpty, "L'arbre ne doit pas être vide")
    }
}
