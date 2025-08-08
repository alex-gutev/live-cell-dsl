import '../builder/index.dart';

/// Thrown when an external cell is declared without a definition
class MissingExternalCellError extends Error {
  /// The name of the cell
  final CellId name;

  MissingExternalCellError(this.name);

  @override
  String toString() => 'Missing implementation for external cell $name.';
}