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

    static func ==(lhs: RendererContext, rhs: RendererContext) -> Bool {
        return lhs.map.nameAsString == rhs.map.nameAsString
            && lhs.spriteDefinitions.count == rhs.spriteDefinitions.count
            && lhs.definitionIndex == rhs.definitionIndex
    }
}

struct Renderer {
    var mutableMap: MELMutableMap?
    var sprite: MELSpriteRef?
    var definitionIndex = -1

    var textureAtlas: MELTextureAtlas?
    var texture: UnsafeMutablePointer<MELUInt32Color>?
    var spriteManager: MELSpriteManager?
    var melMapRenderer: MELMapRenderer?
    var renderer = MELRendererZero

    var oldTime: MELTimeInterval = 0

    mutating func load(context: RendererContext) {
        let mutableMap = context.map
        if var textureAtlas = textureAtlas, self.mutableMap!.palette.name != mutableMap.palette.name {
            MELTextureAtlasDeinit(&textureAtlas)
            self.textureAtlas = nil
        }
        let textureAtlas = self.textureAtlas ?? createAtlas(mutableMap.palette, context.spriteDefinitions)

        if var melMapRenderer = melMapRenderer, self.mutableMap!.nameAsString != mutableMap.nameAsString {
            MELMapRendererDeinit(&melMapRenderer)
            self.melMapRenderer = nil
        }
        let melMapRenderer = self.melMapRenderer ?? MELMapRendererMakeWithMapAndAtlas(mutableMap.super, textureAtlas)

        var spriteManager = self.spriteManager ?? MELSpriteManagerMake(context.spriteDefinitions, textureAtlas, melMapRenderer.layerSurfaces!, 0, nil)

        if self.definitionIndex != context.definitionIndex {
            if let sprite = sprite {
                MELSpriteDeinit(sprite)
            }
            sprite = MELSpriteAlloc(&spriteManager, spriteManager.definitions[context.definitionIndex], 0)
        }

        self.mutableMap = mutableMap
        self.textureAtlas = textureAtlas
        self.melMapRenderer = melMapRenderer
        self.spriteManager = spriteManager
        self.definitionIndex = context.definitionIndex
    }

    mutating func unload() {
        if let sprite = sprite {
            MELSpriteDeinit(sprite)
            self.sprite = nil
        }
        if var spriteManager = spriteManager {
            MELSpriteManagerDeinit(&spriteManager)
            self.spriteManager = nil
        }
        if var melMapRenderer = melMapRenderer {
            MELMapRendererDeinit(&melMapRenderer)
            self.melMapRenderer = nil
        }
        if var textureAtlas = textureAtlas {
            MELTextureAtlasDeinit(&textureAtlas)
            self.textureAtlas = nil
        }
        self.definitionIndex = -1
    }
    func renderFrame() {
        if let melMapRenderer = melMapRenderer {
            MELMapRendererDraw(melMapRenderer)
        }
    }
    mutating func update(elasped time: TimeInterval) {
        if var spriteManager = spriteManager {
            MELSpriteManagerUpdate(&spriteManager, oldTime - MELTimeInterval(time))
            self.oldTime = MELTimeInterval(time)
            self.spriteManager = spriteManager
        }
    }

    fileprivate func createAtlas(_ palette: MELPaletteRef, _ spriteDefinitions: MELSpriteDefinitionList) -> MELTextureAtlas {
        var elements = MELPackMapElementListEmpty
        MELPackMapElementListPushPalette(&elements, palette)
        // TODO: Ajouter toutes les images de toutes les animations et mettre à jour les "frames" de chaque animationdef.
        MELPackMapElementListPushOneFrameOfEachSpriteDefinitionFromList(&elements, spriteDefinitions)
        var packMap = MELPackMapMakeWithElements(elements)
        MELPackMapElementListDeinit(&elements)
        
        var atlasContent = MELRefListEmpty
        for index in 0 ..< palette.count {
            MELRefListPush(&atlasContent, palette.tileRef(at: index))
        }
        for index in 0 ..< Int(spriteDefinitions.count) {
            MELRefListPush(&atlasContent, spriteDefinitions.memory!.advanced(by: index))
        }
        
        var textureAtlas = MELTextureAtlasMakeWithPackMapAndRefList(packMap, atlasContent)
        MELRefListDeinit(&atlasContent)
        MELPackMapDeinit(&packMap)

        MELTextureLoad(&textureAtlas.texture)

        return textureAtlas
    }
}
