import 'dart:async';

import 'package:live_cell/lexer/index.dart';
import 'package:live_cell/parser/declarations.dart';

/// A stream transformer that parses [Expression]s from a [Token] stream.
///
/// This transformer consumes the tokens in the input [Token] stream, and
/// parses [Expression]s from them, until the [EndOfInput] token or the end
/// of the stream is reached.
class Parser extends StreamTransformerBase<Token, Expression> {
  @override
  Stream<Expression> bind(Stream<Token> stream) {
    final parser = _Parser(StreamIterator(stream));
    return parser.parse();
  }
}

/// Maintains the state of the parser
class _Parser {
  /// Input [Token] stream
  final StreamIterator<Token> tokens;

  _Parser(this.tokens);

  /// Parse a stream of [Expression]s from the token stream
  Stream<Expression> parse() async* {
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

    // TODO: Close token stream
  }

  // Private

  /// The current token consumed from the token stream
  late Token _current;

  /// Advance the token stream to the next position
  ///
  /// If the end of the stream is reached, [_current] is set to an [EndOfInput]
  /// token.
  Future<Token> _advance() async {
    if (await tokens.moveNext()) {
      _current = tokens.current;
    }
    else {
      _current = const EndOfInput();
    }

    return _current;
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
        // TODO: Proper exception type
        throw Exception('Parse Error');
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
    final op = await _parseSubExpression();

    switch (_current) {
      case ParenOpen():
        return Operation(
            operator: op,
            args: await _parseArgList()
        );

      default:
        return op;
    }
  }

  /// Parse an expression that is not a function application
  Future<Expression> _parseSubExpression() async {
    switch (_current) {
      case IdToken(:final name):
        await _advance();
        return NamedCell(name);

      case Literal<int>(:final value):
        await _advance();
        return Constant(value);

      case Literal<num>(:final value):
        await _advance();
        return Constant(value);

      case Literal<String>(:final value):
        await _advance();
        return Constant(value);

      case ParenOpen():
        return await _parseParenExpression();

      case BraceOpen():
        // TODO: Handle this case.
        throw UnimplementedError();

      default:
        // TODO: Proper exception type
        throw Exception('Parse Error');
    }
  }

  /// Parse a parenthesized expression
  Future<Expression> _parseParenExpression() async {
    await _advance();

    final expr = await _parseExpression();

    if (_current is! ParenClose) {
      // TODO: Proper exception type
      throw Exception('Parse Error');
    }

    await _advance();
    return expr;
  }

  /// Parse the argument list of a function application expression
  Future<List<Expression>> _parseArgList() async {
    final args = <Expression>[];

    await _advance();

    if (_current is! ParenClose) {
      args.add(await _parseExpression());

      while (_current is! ParenClose) {
        if (_current is! Separator) {
          // TODO: Proper exception type
          throw Exception('Parse Error');
        }

        await _advance();
        args.add(await _parseExpression());
      }
    }

    await _advance();
    return args;
  }
}
