import 'index.dart';

/// Represents an error that occurred during lexical analysis
abstract class TokenizationError implements Exception {
  /// The location where the error occurred
  final Location location;

  /// A string describing the error
  String get description;

  const TokenizationError({
    required this.location
  });

  @override
  String toString() => location.errorString(
      prefix: 'Lexical analysis error',
      description: description
  );
}

/// Exception thrown when an invalid character is encountered
class InvalidTokenError extends TokenizationError {
  /// The string starting with the invalid character
  final String data;

  const InvalidTokenError({
    required super.location,
    required this.data
  });

  @override
  String get description => 'Invalid token character: ${data[0]}';
}

/// Thrown when end of input is reached before an open string is closed
class UnclosedStringError extends TokenizationError {
  // TODO: Add details of where string was opened

  const UnclosedStringError({
    required super.location,
  });

  @override
  String get description => 'Unclosed string';
}

/// Provides the [errorString] extension method
extension DescribeLocationExtension on Location {
  /// Create an error description referencing a given location
  ///
  /// [prefix] is concatenated into the string prior to the location reference,
  /// while [description] is concatenated after the location reference.
  String errorString({
    required String prefix,
    required String description
  }) {
    final input = path ?? 'input';

    return '$prefix in $input at $line:$column: $description';
  }
}