import '../builder/index.dart';

/// Determines which cells can be folded.
/// 
/// If a cell can be folded, it means references to the cell can be replaced
/// with its definition.
/// 
/// When calling [run] is called, the cells in [scope] are analyzed. The
/// attribute named by [Attributes.fold] is set to true for those cells, which
/// can be folded. For those cells, which shouldn't be folded, the attribute
/// is set to false.
class CellFolder {
  /// The scope to analyze
  final CellTable scope;
  
  CellFolder({
    required this.scope
  });

  /// Perform cell folding analysis
  void run() {
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

  /// Determine whether a given [expression] evaluates to a constant value.
  bool _isConstant(CellExpression expression) => switch (expression) {
    StubExpression() => false,
    ConstantValue() => true,
    VariableValue() => false,

    CellRef(get: final cell) => 
        _isFolded(cell),

    CellApplication(
      :final operator,
      :final operands
    ) => _isConstant(operator) &&
        operands.every(_isConstant),

    DeferredExpression() => 
        _isConstant(expression.build()),
  
    FunctionExpression() => true,
  };

  /// Determine whether a given [cell] can be folded.
  bool _isFolded(CellSpec cell) {
    _visitCell(cell);
    return cell.foldable();
  }
}

/// Visitor that performs cell folding analysis in the local scope of a [FunctionExpression].
class _FunctionAnalysisVisitor extends CellExpressionTreeVisitor {
  @override
  void visitFunction(FunctionExpression expression) {
    final folder = CellFolder(
        scope: expression.scope
    );

    folder.run();
  }
}