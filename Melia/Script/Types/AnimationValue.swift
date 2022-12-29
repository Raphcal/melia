//
//  Animation.swift
//  Melia
//
//  Created by Raphaël Calabro on 29/12/2022.
//

import Foundation
import MeliceFramework

class AnimationValue {
    var animationRef: MELAnimationRef?
    var definition: MELAnimationDefinition
    var isStrongRef = false

    init(animationRef: MELAnimationRef) {
        self.animationRef = animationRef
        self.definition = animationRef.definition
    }

    init(animationDefinition: MELAnimationDefinition) {
        self.animationRef = nil
        self.definition = animationDefinition
    }

    deinit {
        if isStrongRef, let animationRef {
            MELAnimationDealloc(animationRef)
        }
    }

    func getAnimationRef() -> MELAnimationRef {
        if let animationRef {
            return animationRef
        } else {
            let animationRef = MELAnimationAlloc(&definition)
            self.animationRef = animationRef
            isStrongRef = true
            return animationRef
        }
    }
}
