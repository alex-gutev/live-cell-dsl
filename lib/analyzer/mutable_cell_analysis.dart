import '../builder/index.dart';
import '../common/pipeline.dart';
import 'exceptions.dart';

/// Verifies mutable cell definitions.
///
/// This class checks all mutable cells to ensure that their initial values
/// are either constants or foldable cells.
class MutableCellAnalysis implements Operation {
  @override
  void run(CellTable scope) {
    scope.cells.forEach(_checkCell);
  }

  /// Verify the definition of a [cell].
  void _checkCell(CellSpec cell) {
    if (cell.definition case Variable(:final initialValue)) {
      if (!_isConstant(initialValue)) {
        throw InitialValueNotConstantError(cell);
      }
    }
  }

  /// Is [value] a constant?
  bool _isConstant(ValueSpec value) => switch (value) {
    Constant() => true,
    Stub() => true,
    CellRef(get: final cell) => cell is ValueCellSpec || cell.foldable(),
    _ => false
  };
}