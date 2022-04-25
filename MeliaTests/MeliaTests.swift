//
//  MeliaTests.swift
//  MeliaTests
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import XCTest
import MeliceFramework
@testable import Melia

class MeliaTests: XCTestCase {
    func testSetAnimationAndWait() throws {
        let script = try parse(code: """
state main:
    self.animation = stand
    during 2s:
        wait
    self.animation = walk
    during 500ms:
        wait
""")
        let surfaceArray = UnsafeMutablePointer<MELSurfaceArray>.allocate(capacity: 1)
        surfaceArray.pointee = MELSurfaceArrayMake()
        let motion = MELNoMotionAlloc()

        var animationDefinitions = MELAnimationDefinitionListMake()
        MELAnimationDefinitionListPush(&animationDefinitions, MELAnimationDefinition(name: MELStringCopy("stand"), frameCount: 0, frames: nil, images: nil, frequency: 10, type: MELAnimationTypeNone, isScrolling: false))
        MELAnimationDefinitionListPush(&animationDefinitions, MELAnimationDefinition(name: MELStringCopy("walk"), frameCount: 0, frames: nil, images: nil, frequency: 10, type: MELAnimationTypeNone, isScrolling: false))
        let animation = MELNoAnimationAlloc(animationDefinitions.memory)

        let definition = MELSpriteDefinition(name: nil, type: 1, palette: nil, animations: animationDefinitions, motionName: nil, loadScript: nil)

        var sprite = MELSprite(parent: nil, definition: definition, type: Int32(definition.type), frame: MELRectangleMake(32, 32, 32, 32), direction: MELDirectionRight, layer: 0, surface: MELSurface(parent: surfaceArray, vertex: 0, texture: 0, color: 0), isRemoved: false, hitbox: nil, motion: motion, animationIndex: 0, animation: animation)

        var context = script.run(sprite: &sprite)
        XCTAssertEqual(context.yield, true)
        XCTAssertEqual(sprite.animation.pointee.definition!.pointee.nameAsString, "stand")

        if case let .decimal(duration) = context.heap["duration"] {
            XCTAssertEqual(duration, 2)
        } else {
            XCTFail("duration not found")
        }
        if case let .decimal(progress) = context.heap["progress"] {
            XCTAssertEqual(progress, 0)
        } else {
            XCTFail("progress not found")
        }
        if case let .decimal(time) = context.heap["time"] {
            XCTAssertEqual(time, 0)
        } else {
            XCTFail("time not found")
        }

        context = script.run(sprite: &sprite, delta: 2, resumeWith: context)
        if case let .decimal(progress) = context.heap["progress"] {
            XCTAssertEqual(progress, 1)
        } else {
            XCTFail("progress not found")
        }
        if case let .decimal(time) = context.heap["time"] {
            XCTAssertEqual(time, 2)
        } else {
            XCTFail("time not found")
        }

        context = script.run(sprite: &sprite, resumeWith: context)
        XCTAssertEqual(sprite.animation.pointee.definition!.pointee.nameAsString, "walk")

        MELSpriteDeinit(&sprite)
        surfaceArray.deallocate()
    }

    func testMultiplyPriority() throws {
        let result = try parse(code: "2 + 3 * 4 + 5").run()
        XCTAssertEqual(result.stack.last!, .integer(19))
    }

    func testBraces() throws {
        let result = try parse(code: "(2 + 3) * (4 + 5)").run()
        XCTAssertEqual(result.stack.last!, .integer(45))
    }
}
