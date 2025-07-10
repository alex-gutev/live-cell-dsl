import 'dart:async';

import 'exceptions.dart';
import '../lexer/index.dart';
import 'ast.dart';
import 'expression_builder.dart';
import 'operators.dart';

/// A stream transformer that parses [AstNode]s from a [Token] stream.
///
/// This transformer consumes the tokens in the input [Token] stream, and
/// parses [AstNode]s from them, until the [EndOfInput] token or the end
/// of the stream is reached.
class Parser extends StreamTransformerBase<Token, AstNode> {
  /// Operator table
  /// 
  /// This stores information about prefix, infix and postfix operators, and
  /// is used to parse infix expressions.
  final OperatorTable operatorTable;

  Parser(this.operatorTable);

  @override
  Stream<AstNode> bind(Stream<Token> stream) {
    final parser = _Parser(
        tokens: StreamIterator(stream),
        operatorTable: operatorTable
    );
    return parser.parse();
  }
}

/// Maintains the state of the parser
class _Parser {
  /// The operator table
  final OperatorTable operatorTable;

  /// Input [Token] stream
  final StreamIterator<Token> tokens;

  /// The current token consumed from the token stream
  late Token _current;

  /// Should soft terminators be skipped when advancing the stream position
  var _skipSoftTerminators = false;

  _Parser({
    required this.operatorTable,
    required this.tokens
  });

  /// Parse a stream of [AstNode]s from the token stream
  Stream<AstNode> parse() async* {
    try {
      await _advance();

      while (true) {
        final declaration = await _parseDeclaration();

        if (declaration != null) {
          yield declaration;
        }
        else {
          break;
        }
      }
    }
    finally {
      tokens.cancel();
    }
  }

  /// Advance the token stream to the next position
  ///
  /// If the end of the stream is reached, [_current] is set to an [EndOfInput]
  /// token.
  Future<Token> _advance() async {
    if (await _moveNext()) {
      _current = tokens.current;
    }
    else {
      _current = const EndOfInput();
    }

    return _current;
  }

  /// Move to the next position in the stream.
  ///
  /// If [_skipSoftTerminators] is true, the stream is advanced past
  /// soft terminator tokens.
  Future<bool> _moveNext() async {
    if (!_skipSoftTerminators) {
      return await tokens.moveNext();
    }

    while (await tokens.moveNext()) {
      switch (tokens.current) {
        case Terminator(soft: true):
          break;

        default:
          return true;
      }
    }

    return false;
  }

  /// Run a function [f] with [_skipSoftTerminators] set to true.
  ///
  /// When [f] returns, The value of [_skipSoftTerminators] is restored to
  /// what it was before calling this method.
  Future<T> _withSkipSoft<T>(Future<T> Function() f) async {
    final prev = _skipSoftTerminators;

    try {
      _skipSoftTerminators = true;
      return await f();
    }
    finally {
      _skipSoftTerminators = prev;
    }
  }

  /// Parse a declaration from the token stream.
  ///
  /// A declaration is an expression followed by a terminator token.
  ///
  /// This method advances the position of the stream to the first non
  /// [Terminator] token that follows the expression.
  ///
  /// Additionally this method skips terminator tokens at the current
  /// position of the stream.
  Future<AstNode?> _parseDeclaration() async {
    await _skipTerminators();

    if (_current is EndOfInput) {
      return null;
    }

    final expr = await _parseExpression();
    await _parseTerminator();

    return expr;
  }

  /// Parse a terminator token
  ///
  /// This method consumes all terminator tokens in the stream and advances
  /// the position to the first token that is not a [Terminator]
  Future<void> _parseTerminator() async {
    switch (_current) {
      case Terminator():
        await _skipTerminators();

      case EndOfInput():
        break;

      default:
        throw UnexpectedTokenParseError(
            token: _current, 
            expected: ExpectedFormType.terminator
        );
    }
  }

  /// Advance the stream position to the first non-[Terminator] token.
  Future<void> _skipTerminators() async {
    while (_current is Terminator) {
      await _advance();
    }
  }

  /// Parse an expression.
  ///
  /// The difference between a declaration and expression is that an expression
  /// is not necessarily followed by a [Terminator] token.
  Future<AstNode> _parseExpression() async {
    final builder = ExpressionBuilder();
    builder.addOperand(await _parseOperand());

    while (true) {
      final operator = await _parseInfixOperator();

      if (operator == null) {
        break;
      }

      builder.addOperator(operator);
      builder.addOperand(await _parseOperand());
    }

    return builder.build();
  }

  /// Parse an infix operator at the current position in the stream.
  ///
  /// If the current token in the stream is an infix operator in [_operatorTable],
  /// it is consumed and returned. Otherwise null is returned.
  Future<Operator?> _parseInfixOperator() async {
    switch (_current) {
      case IdToken(:final name):
        final operator = operatorTable.find(
            name: name,
            type: OperatorType.infix,
            minPrecedence: 0
        );

        if (operator != null) {
          await _advance();
        }

        return operator;

      default:
        return null;
    }
  }

  /// Parse an operand of an infix expression.
  ///
  /// An operand may be a function application or a parenthesized expression
  /// but not an expression of an infix operator.
  Future<AstNode> _parseOperand() async {
    var op = await _parseSubExpression();

    while (_current is ParenOpen) {
      op = Application(
          operator: op,
          operands: await _parseArgList(),
          location: op.location,
      );
    }

    return op;
  }

  /// Parse an expression that is not a function application
  Future<AstNode> _parseSubExpression() async {
    switch (_current) {
      case IdToken(:final name, :final location):
        await _advance();
        return Name(name,
          location: location,
        );

      case Literal literal:
        await _advance();
        return literal.accept(_LiteralToConstantVisitor());

      case ParenOpen():
        return await _parseParenExpression();

      case BraceOpen():
        return await _parseBlock();

      default:
        throw UnexpectedTokenParseError(
            token: _current,
            expected: ExpectedFormType.subExpression
        );
    }
  }

  /// Parse a parenthesized expression
  Future<AstNode> _parseParenExpression() async {
    final expr = await _withSkipSoft(() async {
      await _advance();
      final expr = await _parseExpression();

      if (_current is! ParenClose) {
        throw UnexpectedTokenParseError(
            token: _current,
            expected: ExpectedFormType.parenClose
        );
      }

      return expr;
    });

    await _advance();
    return expr;
  }

  /// Parse the argument list of a function application expression
  Future<List<AstNode>> _parseArgList() async {
    final args = <AstNode>[];

    await _withSkipSoft(() async {
      await _advance();

      if (_current is! ParenClose) {
        args.add(await _parseExpression());

        while (_current is! ParenClose) {
          if (_current is! Separator) {
            throw UnexpectedTokenParseError(
                token: _current,
                expected: ExpectedFormType.separator
            );
          }

          await _advance();
          args.add(await _parseExpression());
        }
      }
    });

    await _advance();
    return args;
  }

  /// Parse a block of expressions delimited by {...}
  Future<Block> _parseBlock() async {
    final location = _current.location;

    await _advance();

    final expressions = <AstNode>[];

    while (_current is! BraceClose) {
      switch (_current) {
        case Terminator():
          await _advance();
          break;

        case EndOfInput():
          throw UnexpectedTokenParseError(
              token: _current,
              expected: ExpectedFormType.braceClose
          );

        default:
          expressions.add(await _parseExpression());

          if (_current is! BraceClose) {
            await _parseTerminator();
          }
      }
    }

    await _advance();

    return Block(
        expressions: expressions,
        location: location,
    );
  }
}

/// Converts a [Literal] to a [Value] holding the same value.
///
/// *NOTE*: This visitor is necessary to preserve the [Literal]'s type.
class _LiteralToConstantVisitor extends LiteralVisitor<AstNode> {
  @override
  AstNode visitLiteral<T>(Literal<T> token) =>
      Value<T>(token.value,
        location: token.location,
      );
}