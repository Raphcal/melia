//
//  Renderer.swift
//  Malice
//
//  Created by Raphaël Calabro on 20/10/2021.
//

import Foundation
import MeliceFramework

struct RendererContext: Equatable {
    var map: MELMutableMap
    var spriteDefinitions: MELSpriteDefinitionList
    var definitionIndex: Int
    var frameSize: MELSize = .zero

    static func ==(lhs: RendererContext, rhs: RendererContext) -> Bool {
        return lhs.map.nameAsString == rhs.map.nameAsString
            && lhs.spriteDefinitions.count == rhs.spriteDefinitions.count
            && lhs.definitionIndex == rhs.definitionIndex
    }
}

class Renderer {
    var mutableMap = MELMutableMapEmpty
    var sprite: MELSpriteRef?
    var definitionIndex = -1

    var textureAtlas = MELTextureAtlasEmpty
    var spriteManager = MELSpriteManagerEmpty
    var melMapRenderer = MELMapRendererEmpty
    var renderer = MELRendererZero

    var oldTime: MELTimeInterval = 0

    deinit {
        // TODO
    }

    func load(context: RendererContext) {
        let mutableMap = context.map
        if !MELPaletteRefEquals(self.mutableMap.palette, mutableMap.palette) || self.definitionIndex != context.definitionIndex {
            unload()
        }

        textureAtlas = createAtlas(mutableMap.palette, context.spriteDefinitions)
        melMapRenderer = MELMapRendererMakeWithRendererAndMapAndAtlas(&renderer, mutableMap.super, textureAtlas)
        spriteManager = MELSpriteManagerMake(context.spriteDefinitions, textureAtlas, melMapRenderer.layerSurfaces!, 0, nil)

        let solid = mutableMap.layers.firstIndex(where: { $0.isSolid }) ?? 0

        let sprite = MELSpriteAlloc(&spriteManager, spriteManager.definitions[context.definitionIndex], UInt32(solid))
        MELSpriteSetFrame(sprite, MELRectangle(x: 32, y: 32, width: 32, height: 32))
        self.sprite = sprite
        definitionIndex = context.definitionIndex
    }

    func unload() {
        if let sprite = sprite {
            MELSpriteDeinit(sprite)
        }
        MELSpriteManagerDeinit(&spriteManager)
        MELTextureAtlasDeinit(&textureAtlas)
        MELMapRendererDeinit(&melMapRenderer)
        self.definitionIndex = -1
    }
    func renderFrame(size frameSize: MELSize) {
        MELRendererRefApplyFlatOrthographicProjection(&renderer, frameSize)
        MELRendererClearWithColor(mutableMap.backgroundColor)
        MELMapRendererDraw(melMapRenderer)
    }
    func update(elasped time: TimeInterval) {
        let elapsedTime: MELTimeInterval
        if oldTime == 0 {
            elapsedTime = 0
            oldTime = MELTimeInterval(time)
        } else {
            elapsedTime = MELTimeInterval(time) - oldTime
            oldTime = MELTimeInterval(time)
        }
        MELSpriteManagerUpdate(&spriteManager, elapsedTime)
    }

    fileprivate func createAtlas(_ palette: MELPaletteRef, _ spriteDefinitions: MELSpriteDefinitionList) -> MELTextureAtlas {
        print("Renderer#createAtlas")
        var elements = MELPackMapElementListEmpty
        MELPackMapElementListPushPalette(&elements, palette)
        MELPackMapElementListPushSpriteDefinitionList(&elements, spriteDefinitions)

        var packMap = MELPackMapMakeWithElements(elements)
        MELPackMapElementListDeinit(&elements)

        var atlasContent = MELRefListEmpty
        for index in 0 ..< palette.count {
            MELRefListPush(&atlasContent, palette.tileRef(at: index))
        }
        for spriteDefinition in spriteDefinitions {
            for animation in spriteDefinition.animations {
                for index in 0 ..< Int(animation.frameCount) {
                    MELRefListPush(&atlasContent, animation.images!.advanced(by: index))
                }
            }
        }

        var textureAtlas = MELTextureAtlasMakeWithPackMapAndRefList(packMap, atlasContent)
        MELRefListDeinit(&atlasContent)
        MELPackMapDeinit(&packMap)

        MELTextureLoad(&textureAtlas.texture)
        print("Texture loaded: \(textureAtlas.texture.name != 0)")

        return textureAtlas
    }
}
