/// Represents an error that occurred during lexical analysis
abstract class TokenizationError implements Exception {
  /// The line in the source where the error occurred
  final int line;

  /// The column at which the error occurred
  final int column;

  /// A string describing the error
  String get description;

  const TokenizationError({
    required this.line,
    required this.column
  });

  @override
  String toString() => 'Error during lexical analysis at $line:$column: $description';
}

/// Exception thrown when an invalid character is encountered
class InvalidTokenError extends TokenizationError {
  /// The string starting with the invalid character
  final String data;

  const InvalidTokenError({
    required super.line,
    required super.column,
    required this.data
  });

  @override
  String get description => 'Invalid token character: ${data[0]}';
}

/// Thrown when end of input is reached before an open string is closed
class UnclosedStringError extends TokenizationError {
  // TODO: Add details of where string was opened

  const UnclosedStringError({
    required super.line,
    required super.column
  });

  @override
  String get description => 'Unclosed string';
}