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

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        let script = """
state main:
    set self.animation = stand
    during 1s:
        wait
    set self.animation = walk
    during 1s:
        wait
""".script
        var surfaceArray = MELSurfaceArray()
        let motion = MELNoMotionAlloc()

        var animationDefinitions = MELAnimationDefinitionListMake()
        MELAnimationDefinitionListPush(&animationDefinitions, MELAnimationDefinition(name: MELStringCopy("stand"), frameCount: 0, frames: nil, images: nil, frequency: 10, type: MELAnimationTypeNone, isScrolling: false))
        MELAnimationDefinitionListPush(&animationDefinitions, MELAnimationDefinition(name: MELStringCopy("walk"), frameCount: 0, frames: nil, images: nil, frequency: 10, type: MELAnimationTypeNone, isScrolling: false))
        let animation = MELNoAnimationAlloc(animationDefinitions.memory)

        var definition = MELSpriteDefinition(name: nil, type: 1, palette: nil, animations: animationDefinitions, motionName: nil, loadScript: nil)

        var sprite = MELSprite(parent: nil, definition: definition, type: Int32(definition.type), frame: MELRectangleMake(32, 32, 32, 32), direction: MELDirectionRight, layer: 0, surface: MELSurface(parent: &surfaceArray, vertex: 0, texture: 0, color: 0), isRemoved: false, hitbox: nil, motion: motion, animationIndex: 0, animation: animation)

        let context = script.run(sprite: &sprite)
        XCTAssertEqual(context.yield, true)
        XCTAssertEqual(context.yield, true)

        animation.deallocate()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
