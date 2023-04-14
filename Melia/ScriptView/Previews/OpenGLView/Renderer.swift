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
    var origin: MELPoint = .zero
    var instance: UnsafeMutablePointer<MELSpriteInstance>?
    var tokens = [FoundToken]()

    static func ==(lhs: RendererContext, rhs: RendererContext) -> Bool {
        return lhs.map.nameAsString == rhs.map.nameAsString
            && lhs.spriteDefinitions.count == rhs.spriteDefinitions.count
            && lhs.definitionIndex == rhs.definitionIndex
            && lhs.tokens == rhs.tokens
    }
}

class Renderer {
    var mutableMap = MELMutableMapEmpty
    var sprite: MELSpriteRef?
    var camera: MELPoint = .zero
    var definitionIndex = -1
    var script: Script = .empty
    var tokens = [FoundToken]()
    var executionContext: Script.ExecutionContext?

    var textureAtlas = MELTextureAtlasEmpty
    var spriteManager = MELSpriteManagerEmpty
    var melMapRenderer = MELMapRendererEmpty
    var renderer = MELRendererZero

    var oldTime: MELTimeInterval = 0

    var isParsing = false

    deinit {
        // Le renderer est libéré après la désallocation du contexte OpenGL.
        textureAtlas.texture.name = 0

        // TODO: Vérifier que tout est bien libéré
        unload()
    }

    func load(context: RendererContext) {
        isParsing = true
        if sprite != nil {
            MELSpriteManagerRemoveAllSprites(&spriteManager)
            self.sprite = nil
        }
        if !MELPaletteRefEquals(mutableMap.palette, context.map.palette) || mutableMap.nameAsString != context.map.nameAsString {
            // TODO: Ne décharger que melMapRenderer et spriteManager si seulement la carte a changé
            unload()
        }
        mutableMap = context.map

        if textureAtlas.texture.pixels == nil {
            textureAtlas = createAtlas(mutableMap.palette, context.spriteDefinitions)

            melMapRenderer = MELMapRendererMakeWithRendererAndMapAndAtlas(&renderer, &mutableMap.super, textureAtlas)
            spriteManager = MELSpriteManagerMake(MELSpriteDefinitionListMakeWithListAndCopyFunction(context.spriteDefinitions, MELSpriteDefinitionMakeWithSpriteDefinition) , textureAtlas, melMapRenderer.layerSurfaces!, 0, nil)
        }

        let solid = mutableMap.layers.firstIndex(where: { $0.isSolid }) ?? 0
        if context.definitionIndex < spriteManager.definitions.count && solid < mutableMap.layers.count {
            let sprite = MELSpriteAlloc(&spriteManager, spriteManager.definitions[context.definitionIndex], UInt32(solid))
            MELSpriteSetFrameOrigin(sprite, context.origin)
            sprite.pointee.instance = context.instance
            self.sprite = sprite
            definitionIndex = context.definitionIndex
        }

        if tokens != context.tokens {
            tokens = context.tokens
            script = .empty
            if let sprite = sprite {
                MELSpriteSetFrameOrigin(sprite, context.origin)
            }

            DispatchQueue.parse.async { [self] in
                let newScript = TokenTree(tokens: self.tokens).script
                DispatchQueue.main.sync {
                    let executionContext = newScript.executionContext(spriteManager: &self.spriteManager)

                    self.script = newScript
                    self.executionContext = executionContext
                    self.isParsing = false
                }
            }
        }
    }

    func unload() {
        MELSpriteManagerDeinit(&spriteManager)
        MELTextureAtlasDeinit(&textureAtlas)
        MELMapRendererDeinit(&melMapRenderer)
        self.definitionIndex = -1
    }
    func renderFrame(size frameSize: MELSize) {
        if let sprite = sprite {
            let halfFrameSize = frameSize / MELSize(width: 2, height: 2)
            let mapSize = MELSize(mutableMap.size * mutableMap.palette.pointee.tileSize)
            let origin = sprite.pointee.frame.origin
            camera = MELPoint(
                x: max(0, min(origin.x - halfFrameSize.width, mapSize.width - frameSize.width)),
                y: max(0, min(origin.y - halfFrameSize.height, mapSize.height - frameSize.height)))
        } else {
            camera = .zero
        }
        MELRendererRefApplyFlatOrthographicProjection(&renderer, frameSize)
        MELRendererClearWithColor(mutableMap.backgroundColor)
        MELMapRendererDrawTranslated(melMapRenderer, camera)
    }
    func update(elasped time: TimeInterval) {
        // TODO: Calculer le temps écoulé en fonction du temps donné.
        let elapsedTime: MELTimeInterval = 1 / 60
        if !isParsing {
            executionContext = script.run(sprite: sprite, map: nil, delta: elapsedTime, resumeWith: executionContext)
        }
        MELSpriteManagerUpdate(&spriteManager, elapsedTime)
    }

    fileprivate func createAtlas(_ palette: MELPaletteRef, _ spriteDefinitions: MELSpriteDefinitionList) -> MELTextureAtlas {
        // TODO: Faire une fonction C AtlasMake pour ça
        var elements = MELPackMapElementListEmpty
        MELPackMapElementListPushPalette(&elements, palette)
        // TODO: Supprimer l'allocation des frames de cette méthode car l'indice dans l'atlas n'est pas bon. Elements ne contient pas les images vides de la palette donc les indices sont décalés.
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
                    animation.frames![index].atlasIndex = Int32(atlasContent.count)
                    MELRefListPush(&atlasContent, animation.images!.advanced(by: index))
                }
            }
        }

        var textureAtlas = MELTextureAtlasMakeWithPackMapAndRefList(packMap, atlasContent)
        MELRefListDeinit(&atlasContent)
        MELPackMapDeinit(&packMap)

        MELTextureLoad(&textureAtlas.texture)
        if textureAtlas.texture.name == 0 {
            // Réessaie de charger la texture en cas d'erreur.
            MELTextureLoad(&textureAtlas.texture)
        }

        var outputStream = MELOutputStreamOpen("/tmp/texture.bmp");
        if (outputStream.file != nil) {
            MELBitmapSaveToOutputStreamWithPremultiplication(&outputStream, textureAtlas.texture.pixels!, textureAtlas.texture.size, false);
        }

        return textureAtlas
    }
}
