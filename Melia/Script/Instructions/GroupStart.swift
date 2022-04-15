//
//  GroupStart.swift
//  Melia
//
//  Created by Raphaël Calabro on 15/04/2022.
//

import Foundation

protocol GroupStart: Instruction {
    var whenDoneSetInstructionPointerTo: Int { get set }
}
