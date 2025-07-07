import 'package:live_cell/builder/cell_spec.dart';

/// Represents an error during semantic analysis
abstract class AnalysisError implements Exception {
  /// Textual description of the error
  String get description;

  const AnalysisError();

  @override
  String toString() => 'Semantic Error: $description';
}

/// Thrown when a cyclic cell definition is discovered
class CyclicDefinitionError extends AnalysisError {
  /// The cell containing a cyclic definition
  final CellSpec cell;

  const CyclicDefinitionError(this.cell);

  @override
  String get description => 'Cycle detected in definition of `${cell.id}`.';
}

/// Thrown when an undefined cell is encountered
class UndefinedCellError extends AnalysisError {
  /// The cell
  final CellSpec cell;

  const UndefinedCellError(this.cell);

  @override
  String get description => 'No definition for `${cell.id}`.';
}