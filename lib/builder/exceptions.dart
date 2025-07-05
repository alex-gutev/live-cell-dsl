import 'cell_spec.dart';

/// Represents an error occurring while processing a declaration
abstract class BuildError implements Exception {
  // TODO: Add source file information

  /// The line where the declaration is located
  final int line;

  /// The column where the declaration is located
  final int column;

  /// Description of the error
  String get description;

  const BuildError({
    required this.line,
    required this.column
  });

  @override
  String toString() =>
      'Error processing declaration at $line:$column: $description';
}

/// Thrown when an empty block is encountered
class EmptyBlockError extends BuildError {
  @override
  String get description => 'Empty block.';

  const EmptyBlockError({
    required super.line,
    required super.column
  });
}

/// Thrown when a malformed cell definition declaration is encountered
class MalformedDefinitionError extends BuildError {
  @override
  String get description => 'Malformed cell definition.';

  const MalformedDefinitionError({
    required super.line,
    required super.column
  });
}

/// Thrown when a function definition with a malformed argument list is encountered
class MalformedFunctionArgumentListError extends BuildError {
  @override
  String get description => 'Malformed argument list in function definition.';

  const MalformedFunctionArgumentListError({
    required super.line,
    required super.column
  });
}

/// Thrown when multiple definitions for the same cell are encountered
class MultipleDefinitionError extends BuildError {
  final CellId id;

  MultipleDefinitionError({
    required this.id,
    required super.line,
    required super.column
  });

  @override
  String get description => 'Multiple definitions for cell `$id`';
}

/// Thrown when a malformed variable cell declaration is encountered
class MalformedVarDeclarationError extends BuildError {
  @override
  String get description => 'Malformed variable cell declaration.';

  const MalformedVarDeclarationError({
    required super.line,
    required super.column
  });
}

/// Thrown when the a variable declaration is incompatible with the cell's definition.
class IncompatibleVarDeclarationError extends BuildError {
  // TODO: Add reference to where cell is already defined

  @override
  String get description => 'Variable cell declaration incompatible with existing cell definition.';

  const IncompatibleVarDeclarationError({
    required super.line,
    required super.column
  });
}