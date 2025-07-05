import 'dart:async';

import 'exceptions.dart';
import '../lexer/index.dart';
import 'declarations.dart';
import 'expression_builder.dart';
import 'operators.dart';

/// A stream transformer that parses [Expression]s from a [Token] stream.
///
/// This transformer consumes the tokens in the input [Token] stream, and
/// parses [Expression]s from them, until the [EndOfInput] token or the end
/// of the stream is reached.
class Parser extends StreamTransformerBase<Token, Expression> {
  /// Operator table
  /// 
  /// This stores information about prefix, infix and postfix operators, and
  /// is used to parse infix expressions.
  final OperatorTable operatorTable;

  Parser(this.operatorTable);

  @override
  Stream<Expression> bind(Stream<Token> stream) {
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

  /// Parse a stream of [Expression]s from the token stream
  Stream<Expression> parse() async* {
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
  Future<Expression?> _parseDeclaration() async {
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
  Future<Expression> _parseExpression() async {
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
  Future<Expression> _parseOperand() async {
    var op = await _parseSubExpression();

    while (_current is ParenOpen) {
      op = Operation(
          operator: op,
          args: await _parseArgList(),
          line: op.line,
          column: op.column
      );
    }

    return op;
  }

  /// Parse an expression that is not a function application
  Future<Expression> _parseSubExpression() async {
    switch (_current) {
      case IdToken(:final name, :final line, :final column):
        await _advance();
        return NamedCell(name,
          line: line,
          column: column
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
  Future<Expression> _parseParenExpression() async {
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
  Future<List<Expression>> _parseArgList() async {
    final args = <Expression>[];

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
    final line = _current.line;
    final column = _current.column;

    await _advance();

    final expressions = <Expression>[];

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
      }
    }

    await _advance();

    return Block(
        expressions: expressions,
        line: line,
        column: column
    );
  }
}

/// Converts a [Literal] to a [Constant] holding the same value.
///
/// *NOTE*: This visitor is necessary to preserve the [Literal]'s type.
class _LiteralToConstantVisitor extends LiteralVisitor<Expression> {
  @override
  Expression visitLiteral<T>(Literal<T> token) =>
      Constant<T>(token.value,
        line: token.line,
        column: token.column
      );
}