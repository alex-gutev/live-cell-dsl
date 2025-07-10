import '../lexer/index.dart';
import 'cell_spec.dart';

/// Represents an error occurring while processing a declaration
abstract class BuildError implements Exception {
  /// The location where the error occurred
  final Location location;

  /// Description of the error
  String get description;

  const BuildError({
    required this.location
  });

  @override
  String toString() => location.errorString(
      prefix: 'Error processing declaration',
      description: description
  );
}

/// Thrown when an empty block is encountered
class EmptyBlockError extends BuildError {
  @override
  String get description => 'Empty block.';

  const EmptyBlockError({
    required super.location
  });
}

/// Thrown when a malformed cell definition declaration is encountered
class MalformedDefinitionError extends BuildError {
  @override
  String get description => 'Malformed cell definition.';

  const MalformedDefinitionError({
    required super.location
  });
}

/// Thrown when a function definition with a malformed argument list is encountered
class MalformedFunctionArgumentListError extends BuildError {
  @override
  String get description => 'Malformed argument list in function definition.';

  const MalformedFunctionArgumentListError({
    required super.location
  });
}

/// Thrown when multiple definitions for the same cell are encountered
class MultipleDefinitionError extends BuildError {
  final CellId id;

  const MultipleDefinitionError({
    required this.id,
    required super.location
  });

  @override
  String get description => 'Multiple definitions for cell `$id`';
}

/// Thrown when a malformed variable cell declaration is encountered
class MalformedVarDeclarationError extends BuildError {
  @override
  String get description => 'Malformed variable cell declaration.';

  const MalformedVarDeclarationError({
    required super.location
  });
}

/// Thrown when a variable declaration is incompatible with the cell's definition.
class IncompatibleVarDeclarationError extends BuildError {
  // TODO: Add reference to where cell is already defined

  @override
  String get description => 'Variable cell declaration incompatible with existing cell definition.';

  const IncompatibleVarDeclarationError({
    required super.location
  });
}

/// Thrown when a malformed `external` cell declaration is encountered.
class MalformedExternalDeclarationError extends BuildError {
  @override
  String get description => 'Malformed external cell declaration.';

  const MalformedExternalDeclarationError({
    required super.location
  });
}