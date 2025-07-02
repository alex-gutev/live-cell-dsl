import 'package:live_cell/lexer/tokens.dart';

/// Identifies the form that was expected while parsing
enum ExpectedFormType {
  terminator,
  subExpression,
  parenClose,
  separator,
  braceClose;
  
  @override
  String toString() => switch (this) {
    ExpectedFormType.terminator => 'terminator',
    ExpectedFormType.subExpression => 'sub-expression',
    ExpectedFormType.parenClose => 'closing parenthesis',
    ExpectedFormType.separator => 'comma',
    ExpectedFormType.braceClose => 'closing brace'
  };
}

/// Base class representing an error occurring while parsing
abstract class ParseError implements Exception {
  /// The token at which parsing failed
  final Token token;
  
  const ParseError({
    required this.token
  });
  
  @override
  String toString() => 'Parse error at ${token.line}:${token.column}';
}

/// Thrown when an unexpected token is encountered while parsing
class UnexpectedTokenParseError extends ParseError {
  /// The form that was expected
  final ExpectedFormType expected;
  
  const UnexpectedTokenParseError({
    required super.token,
    required this.expected
  });
  
  @override
  String toString() => '${super.toString()}: Expected $expected, '
      'found ${_describeToken(token)}';
  
  static String _describeToken(Token token) => switch (token) {
    IdToken(:final name) => 'identifier `$name`',
    Literal() => 'literal value',
    Terminator() => 'terminator',
    Separator() => "comma ','",
    EndOfInput() => 'end of input',
    ParenOpen() => "open parenthesis '('",
    ParenClose() => "closing parenthesis ')'",
    BraceOpen() => "open brace '{'",
    BraceClose() => "closing brace '}'",
  };
}

/// Thrown when parsing a malformed expression.
///
/// An expression is malformed if there are two many operands or not enough
/// operands for an operator.
class MalformedInfixExpression implements Exception {
  @override
  String toString() => 'Malformed infix expression';
}