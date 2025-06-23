/// Base token class
sealed class Token {
  const Token();
}

/// An identifier
class IdToken extends Token {
  /// The name of the identifier
  final String name;

  const IdToken({
    required this.name
  });
}

/// A literal constant value of type [T]
class Literal<T> extends Token {
  /// The parsed literal value
  final T value;

  const Literal({required this.value});
}

/// A declaration terminator
class Terminator extends Token {
  /// Is this a soft terminator?
  ///
  /// If true it indicates that this terminator was added implicitly by the
  /// lexer. Otherwise it indicates that this terminator was explicitly
  /// written in the source.
  final bool soft;

  const Terminator({
    required this.soft
  });
}

/// Argument separator ','
class Separator extends Token {
  const Separator();
}

/// Opening parenthesis '('
class ParenOpen extends Token {
  const ParenOpen();
}

/// Closing parenthesis ')'
class ParenClose extends Token {
  const ParenClose();
}

/// Opening brace '{'
class BraceOpen extends Token {
  const BraceOpen();
}

/// Closing brace '}'
class BraceClose extends Token {
  const BraceClose();
}