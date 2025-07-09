import '../builder/index.dart';
import '../common/pipeline.dart';

/// Determines which cells can be folded.
/// 
/// If a cell can be folded, it means references to the cell can be replaced
/// with its definition.
/// 
/// When calling [run] is called, the cells in [scope] are analyzed. The
/// attribute named by [Attributes.fold] is set to true for those cells, which
/// can be folded. For those cells, which shouldn't be folded, the attribute
/// is set to false.
class CellFolder implements Operation {
  /// The scope to analyze
  late final CellTable scope;

  /// Perform cell folding analysis
  @override
  void run(CellTable scope) {
    this.scope = scope;

    for (final cell in scope.cells) {
      _visitCell(cell);
    }

    for (final cell in scope.cells) {
      cell.definition.accept(
          _FunctionAnalysisVisitor()
      );
    }
  }

  // Private
  
  /// Set of cells that have been visited
  final _visited = <CellSpec>{};
  
  /// Analyze a [cell].
  void _visitCell(CellSpec cell) {
    if (!_visited.contains(cell) && cell.scope == scope) {
      _visited.add(cell);

      cell.setAttribute(
          Attributes.fold,
          _isConstant(cell.definition)
      );
    }
  }

  /// Determine whether a given [spec] represents a constant value.
  bool _isConstant(ValueSpec spec) => switch (spec) {
    Stub() => false,
    Constant() => true,
    Variable() => false,

    CellRef(get: final cell) => 
        _isFolded(cell),

    ApplySpec(
      :final operator,
      :final operands
    ) => _isConstant(operator) &&
        operands.every(_isConstant),

    DeferredSpec() => 
        _isConstant(spec.build()),
  
    FunctionSpec() => true,
  };

  /// Determine whether a given [cell] can be folded.
  bool _isFolded(CellSpec cell) {
    _visitCell(cell);
    return cell.foldable();
  }
}

/// Visitor that performs cell folding analysis in the local scope of a [FunctionSpec].
class _FunctionAnalysisVisitor extends ValueSpecTreeVisitor {
  @override
  void visitFunction(FunctionSpec spec) {
    final folder = CellFolder();
    folder.run(spec.scope);
  }
}