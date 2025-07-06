import 'exceptions.dart';
import '../builder/index.dart';

/// Checks that the cell definitions are semantically valid
/// 
/// This class ensures the following:
/// 
/// 1. There are no circular definitions e.g. `a = b + 1; b = a + 2`
class SemanticAnalyzer {
  /// The scope on which to perform semantic analysis.
  final CellTable scope;

  SemanticAnalyzer({
    required this.scope
  });

  /// Perform semantic analysis on the cells defined in [scope].
  void analyze() {
    // TODO: Check that all functions are called with correct number of arguments
    // TODO: Check that all cells are defined or are variable cells
    _checkCycles();
  }

  // Private

  /// Check for cyclic definitions
  void _checkCycles() {
    for (final cell in scope.cells) {
      _walkCell(cell);
    }
  }

  /// Check for cyclic definitions in a [cell] specification.
  ///
  /// [visited] is a maps [CellSpec]s to the following values:
  ///
  /// * `null` if the cell has not been visited
  ///
  /// * `true` if the cell is currently being visited, that is it is reachable
  ///   from [cell].
  ///
  /// * `false` if the cell and all its dependencies have been visited.
  void _walkCell(CellSpec cell, {
    Map<CellSpec, bool>? visited
  }) {
    visited ??= {};

    if (cell is! ValueCellSpec && cell.scope == scope) {
      switch (visited[cell]) {
        case false:
          break;

        case true:
          throw CyclicDefinitionError(cell);

        case null:
          visited[cell] = true;

          cell.definition.accept(
              _AnalysisVisitor(
                  analyzer: this,
                  visited: visited
              )
          );

          visited[cell] = false;

          cell.definition.accept(_FunctionAnalysisVisitor());
      }
    }
  }
}

/// Check for cycles in a given expression tree
class _AnalysisVisitor extends CellExpressionTreeVisitor {
  final SemanticAnalyzer analyzer;

  /// Map of visited cells
  final Map<CellSpec, bool> visited;

  _AnalysisVisitor({
    required this.analyzer,
    required this.visited
  });
  
  @override
  void visitRef(CellRef expression) {
    analyzer._walkCell(
        expression.get,
        visited: visited
    );
  }

  @override
  void visitFunction(FunctionExpression expression) {
  }
}

/// Performs semantic analysis in [FunctionExpression]s
class _FunctionAnalysisVisitor extends CellExpressionTreeVisitor {
  @override
  void visitFunction(FunctionExpression expression) {
    final analyzer = SemanticAnalyzer(scope: expression.scope);
    analyzer.analyze();
  }
}