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
        let tree = TokenTree(code: "2 + 3 * 4 + 5")!
        XCTAssertFalse(tree.children.isEmpty, "L'arbre ne doit pas être vide")

        let result = tree.script.run()
        XCTAssertEqual(result.stack.last!, .integer(19))

        let reducedTree = tree.reduceByInliningValues(from: [:])
        XCTAssertEqual(reducedTree.children.count, 1)
        XCTAssertEqual((reducedTree.children[0] as! ConstantNode).value, .integer(19))
    }

    func testBraces() throws {
        let tree = TokenTree(code: "(2 + 3) * (4 + 5)")!
        XCTAssertFalse(tree.children.isEmpty, "L'arbre ne doit pas être vide")

        let result = tree.script.run()
        XCTAssertEqual(result.stack.last!, .integer(45))

        let reducedTree = tree.reduceByInliningValues(from: [:])
        XCTAssertEqual(reducedTree.children.count, 1)
        XCTAssertEqual((reducedTree.children[0] as! ConstantNode).value, .integer(45))
    }
}
