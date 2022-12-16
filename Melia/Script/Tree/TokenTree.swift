//
//  TokenTree.swift
//  Melia
//
//  Created by Raphaël Calabro on 25/04/2022.
//

import MeliceFramework

struct TokenTree: Equatable {
    var children: [TreeNode]

    static func == (lhs: TokenTree, rhs: TokenTree) -> Bool {
        return lhs.children == rhs.children
    }
}

extension TokenTree {
    static let empty = TokenTree(children: [])

    init(code: String) {
        var nodes = [TreeNode]()
        var childBuilder: NodeBuilder?

        Tokenizer().tokenize(code: code) { found in
            guard found.token != .comment else {
                return
            }
            TokenTree.feedNode(found, children: &nodes, childBuilder: &childBuilder)
        }
        self.children = nodes
    }

    init(tokens: [FoundToken]) {
        var nodes = [TreeNode]()
        var childBuilder: NodeBuilder?

        for found in tokens {
            guard found.token != .comment else {
                continue
            }
            TokenTree.feedNode(found, children: &nodes, childBuilder: &childBuilder)
        }
        self.children = nodes
    }

    fileprivate static func feedNode(_ found: FoundToken, children: inout [TreeNode], childBuilder: inout NodeBuilder?) {
        var consumed = false
        if let builder = childBuilder {
            consumed = builder.consume(found: found)
            if let result = builder.result {
                children.append(result)
                childBuilder = nil
            }
        }
        if !consumed && childBuilder == nil {
            childBuilder = TokenTree.childBuilder(for: found)
        }
    }

    fileprivate static func childBuilder(for found: FoundToken) -> NodeBuilder? {
        if let builder = StateBuilder(found: found) {
            return builder
        } else if let builder = StatementBuilder(found: found) {
            return builder
        } else if let builder = OperationBuilder(found: found) {
            return builder
        } else {
            return nil
        }
    }
}

/// Constructeur de nœud.
protocol NodeBuilder: AnyObject {
    var result: TreeNode? { get set }
    func consume(found: FoundToken) -> Bool
}

/// Constructeur de nœud utilisant des sous-constructeurs .
protocol CompositeNodeBuilder: NodeBuilder {
    var builder: NodeBuilder? { get set }

    func consumeInner(found: FoundToken) -> Bool
    func builderDidProduce(result: TreeNode)
}

extension CompositeNodeBuilder {
    func consume(found: FoundToken) -> Bool {
        return feedChildBuilderAndCallInner(with: found)
    }

    func feedChildBuilderAndCallInner(with found: FoundToken) -> Bool {
        var consumed = false
        if let builder = builder {
            consumed = builder.consume(found: found)
            if let result = builder.result {
                builderDidProduce(result: result)
                self.builder = nil
            }
        }
        if !consumed && result == nil {
            consumed = consumeInner(found: found)
        }
        return consumed
    }
}

/// Constructeur de bloc (exemple : state, during).
protocol BlockNodeBuilder: CompositeNodeBuilder {
    var expectNextTokenToBeIndent: Bool { get set }
    func blockDidEnd()
}

extension BlockNodeBuilder {
    func consume(found: FoundToken) -> Bool {
        if expectNextTokenToBeIndent && found.token != .newLine {
            expectNextTokenToBeIndent = false
            if found.token != .indent {
                if let builder = builder {
                    _ = builder.consume(found: found)
                    if let result = builder.result {
                        builderDidProduce(result: result)
                        self.builder = nil
                    }
                }
                blockDidEnd()
                return false
            } else {
                return true
            }
        }
        expectNextTokenToBeIndent = found.token == .newLine
        return feedChildBuilderAndCallInner(with: found)
    }
}

/// Construit un état.
final class StateBuilder: BlockNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?
    var expectNextTokenToBeIndent = false

    let name: String
    var children = [TreeNode]()

    init?(found: FoundToken) {
        guard [Token.state, .constructor].contains(found.token) else {
            return nil
        }
        name = found.token == .state ? found.matches[1] : StateNode.constructorName
    }

    func builderDidProduce(result: TreeNode) {
        children.append(result)
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = StatementBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }

    func blockDidEnd() {
        result = StateNode(name: name, children: children)
    }
}

/// Construit un groupe (during, while).
final class GroupBuilder: BlockNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?
    var expectNextTokenToBeIndent = false

    let name: String
    var arguments = [ArgumentNode]()
    var children = [TreeNode]()

    init?(found: FoundToken) {
        guard found.token == .groupStart else {
            return nil
        }
        name = found.matches[1]
        builder = ArgumentBuilder(argumentName: GroupBuilder.defaultArgumentName(for: found.matches[1]))
    }

    static func defaultArgumentName(for groupName: String) -> String {
        switch groupName {
        case "during":
            return During.durationArgument
        case "if":
            return If.testArgument
        case "while":
            return While.testArgument
        default:
            return "default"
        }
    }

    func builderDidProduce(result: TreeNode) {
        if let result = result as? ArgumentNode {
            arguments.append(result)
        } else {
            children.append(result)
        }
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = ArgumentBuilder(found: found) {
            self.builder = builder
        } else if let builder = StatementBuilder(found: found) {
            self.builder = builder
        } else if found.token != .groupEnd {
            return false
        }
        return true
    }

    func blockDidEnd() {
        result = GroupNode(name: name, arguments: arguments, children: children)
    }
}

/// Construit un appel à une instruction, une affectation ou le démarrage d'un groupe.
final class StatementBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    init?(found: FoundToken) {
        if let builder = GroupBuilder(found: found) {
            self.builder = builder
        } else if let builder = SetBuilder(found: found) {
            self.builder = builder
        } else if let builder = InstructionBuilder(found: found) {
            self.builder = builder
        } else {
            return nil
        }
    }

    func consumeInner(found: FoundToken) -> Bool {
        return false
    }
    
    func builderDidProduce(result: TreeNode) {
        self.result = result
    }
}

/// Construit une affectation.
final class SetBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    let variable: String

    init?(found: FoundToken) {
        guard found.token == .setStart else {
            return nil
        }
        variable = found.matches[1]
    }

    func builderDidProduce(result: TreeNode) {
        self.result = SetNode(variable: variable, value: result)
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = OperationBuilder(found: found) {
            self.builder = builder
        } else if let builder = InstructionBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }
}

/// Construit un appel à une instruction.
final class InstructionBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    let instructionName: String
    var arguments = [ArgumentNode]()

    init?(found: FoundToken) {
        guard found.token == .instructionStart else {
            return nil
        }
        instructionName = found.matches[1]
    }

    func builderDidProduce(result: TreeNode) {
        if let result = result as? ArgumentNode {
            arguments.append(result)
        }
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = ArgumentBuilder(found: found) {
            self.builder = builder
        } else {
            result = InstructionNode(name: instructionName, arguments: arguments)
            return false
        }
        return true
    }
}

/// Construit un argument d'une instruction ou d'un groupe.
final class ArgumentBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    let argumentName: String

    init?(found: FoundToken) {
        guard found.token == .instructionArgument else {
            return nil
        }
        argumentName = found.matches[1]
    }

    init(argumentName: String) {
        self.argumentName = argumentName
    }

    func builderDidProduce(result: TreeNode) {
        self.result = ArgumentNode(name: argumentName, value: result)
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = OperationBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }
}

/// Construit une opération mathématique, le renvoie d'une valeur constante ou la valeur d'une variable.
final class OperationBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    var root: TreeNode?
    var `operator`: OperatorKind?

    init?(found: FoundToken) {
        if let builder = UnaryOperationBuilder(found: found) {
            self.builder = builder
        } else if let builder = BracesBuilder(found: found) {
            self.builder = builder
        } else if let builder = ValueBuilder(found: found) {
            self.builder = builder
        } else {
            return nil
        }
    }

    func builderDidProduce(result: TreeNode) {
        if let root = root {
            self.root = root.appended(operator: `operator`!, value: result)
            self.operator = nil
        } else {
            root = result
        }
    }

    func consumeInner(found: FoundToken) -> Bool {
        if self.operator == nil {
            self.operator = OperatorKind.from(found: found)
        } else {
            if let builder = UnaryOperationBuilder(found: found) {
                self.builder = builder
            } else if let builder = BracesBuilder(found: found) {
                self.builder = builder
            } else if let builder = ValueBuilder(found: found) {
                self.builder = builder
            } else {
                return false
            }
        }
        if self.operator == nil && self.builder == nil,
           let root = root {
            result = root
            return false
        }
        return true
    }
}

final class BinaryOperationBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    var lhs: TreeNode?
    var `operator`: OperatorKind?

    init?(found: FoundToken) {
        if let builder = UnaryOperationBuilder(found: found) {
            self.builder = builder
        } else if let builder = ValueBuilder(found: found) {
            self.builder = builder
        } else {
            return nil
        }
    }

    func builderDidProduce(result: TreeNode) {
        if let lhs = lhs {
            self.result = BinaryOperationNode(lhs: lhs, operator: self.operator!, rhs: result)
        } else {
            lhs = result
        }
    }

    func consumeInner(found: FoundToken) -> Bool {
        if self.operator == nil {
            self.operator = OperatorKind.from(found: found)
        } else if let builder = UnaryOperationBuilder(found: found) {
            self.builder = builder
        } else if let builder = BracesBuilder(found: found) {
            self.builder = builder
        } else if let builder = ValueBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }
}

final class UnaryOperationBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    let `operator`: String

    init?(found: FoundToken) {
        if found.token != .unaryOperator {
            return nil
        }
        self.operator = found.matches[1]
    }

    func builderDidProduce(result: TreeNode) {
        self.result = UnaryOperationNode(operator: self.operator, value: result)
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let builder = BracesBuilder(found: found) {
            self.builder = builder
        } else if let builder = ValueBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }
}

final class BracesBuilder: CompositeNodeBuilder {
    var result: TreeNode?
    var builder: NodeBuilder?

    var child: TreeNode?

    init?(found: FoundToken) {
        guard found.token == .braceOpen else {
            return nil
        }
    }

    func builderDidProduce(result: TreeNode) {
        self.child = result
    }

    func consumeInner(found: FoundToken) -> Bool {
        if let child = child, found.token == .braceClose {
            self.result = BracesNode(child: child)
        } else if child == nil, let builder = OperationBuilder(found: found) {
            self.builder = builder
        } else {
            return false
        }
        return true
    }
}

final class ValueBuilder: NodeBuilder {
    var result: TreeNode?

    init?(found: FoundToken) {
        switch found.token {
        case .valueDuration, .valueInt, .valueDecimal, .valueBoolean, .valuePoint, .valueDirection, .valueAnimation, .valueString:
            result = ConstantNode(value: found.value)
        case .valueVariable:
            result = VariableNode(name: found.matches[1])
        default:
            return nil
        }
    }

    func consume(found: FoundToken) -> Bool {
        return false
    }
}

fileprivate extension TreeNode {
    func appended(`operator`: OperatorKind, value: TreeNode) -> TreeNode {
        if var node = self as? BinaryOperationNode,
           node.operator.priority < `operator`.priority {
            node.rhs = node.rhs.appended(operator: `operator`, value: value)
            return node
        } else {
            return BinaryOperationNode(lhs: self, operator: `operator`, rhs: value)
        }
    }
}
