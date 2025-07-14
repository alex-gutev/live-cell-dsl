import '../lexer/index.dart';
import 'cell_spec.dart';

/// Represents an error occurring while processing a declaration
class BuildError implements Exception {
  /// The location where the error occurred
  final Location location;

  /// The exception that was thrown
  final Exception error;

  const BuildError({
    required this.location,
    required this.error
  });

  @override
  String toString() => location.errorString(
      prefix: 'Error processing declaration',
      description: error.toString()
  );
}

/// Thrown when an empty block is encountered
class EmptyBlockError implements Exception {
  const EmptyBlockError();

  @override
  String toString() => 'Empty block.';
}

/// Thrown when a malformed cell definition declaration is encountered
class MalformedDefinitionError implements Exception {
  const MalformedDefinitionError();

  @override
  String toString() => 'Malformed cell definition.';
}

/// Thrown when a function definition with a malformed argument list is encountered
class MalformedFunctionArgumentListError implements Exception {
  final Location location;

  const MalformedFunctionArgumentListError({
    required this.location
  });

  @override
  String toString() => 'Malformed argument cell identifier in'
      ' function definition at ${location.line}:${location.column}.';
}

/// Thrown when multiple definitions for the same cell are encountered
class MultipleDefinitionError implements Exception {
  final CellId id;

  const MultipleDefinitionError({
    required this.id,
  });

  @override
  String toString() => 'Multiple definitions for cell `$id`';
}

/// Thrown when a malformed variable cell declaration is encountered
class MalformedVarDeclarationError implements Exception {
  const MalformedVarDeclarationError();

  @override
  String toString() => 'Malformed variable cell declaration.';
}

/// Thrown when a variable declaration is incompatible with the cell's definition.
class IncompatibleVarDeclarationError implements Exception {
  // TODO: Add reference to where cell is already defined

  const IncompatibleVarDeclarationError();

  @override
  String toString() =>
      'Variable cell declaration incompatible with existing cell definition.';
}

/// Thrown when a malformed `external` cell declaration is encountered.
class MalformedExternalDeclarationError implements Exception {
  const MalformedExternalDeclarationError();

  @override
  String toString() => 'Malformed external cell declaration.';
}

/// Thrown when a malformed import declaration is encountered
class MalformedImportError implements Exception {
  const MalformedImportError();

  @override
  String toString() => 'Malformed import declaration.';
}

/// Thrown when a malformed operator declaration is encountered.
class MalformedOperatorDeclarationError implements Exception {
  const MalformedOperatorDeclarationError();

  @override
  String toString() => 'Malformed operator declaration';
}