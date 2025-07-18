import '../common/pipeline.dart';
import 'exceptions.dart';
import '../builder/index.dart';

/// Checks that the cell definitions are semantically valid
/// 
/// This class ensures the following:
/// 
/// 1. There are no circular definitions e.g. `a = b + 1; b = a + 2`
class SemanticAnalyzer implements Operation {
  /// The scope on which to perform semantic analysis.
  late final CellTable scope;

  @override
  void run(CellTable scope) {
    this.scope = scope;

    // TODO: Check that all functions are called with correct number of arguments
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
                  visited: visited,
                  cell: cell
              )
          );

          visited[cell] = false;

          cell.definition.accept(_FunctionAnalysisVisitor());
      }
    }
  }
}

/// Check for cycles in a given [ValueSpec] tree
class _AnalysisVisitor extends ValueSpecTreeVisitor {
  /// The cell of which the definition is being analysed
  final CellSpec cell;

  final SemanticAnalyzer analyzer;

  /// Map of visited cells
  final Map<CellSpec, bool> visited;

  _AnalysisVisitor({
    required this.analyzer,
    required this.visited,
    required this.cell
  });
  
  @override
  void visitRef(CellRef expression) {
    analyzer._walkCell(
        expression.get,
        visited: visited
    );
  }

  @override
  void visitStub(Stub expression) {
    if (!cell.isExternal() && !cell.isArgument()) {
      throw UndefinedCellError(cell);
    }
  }

  @override
  void visitFunction(FunctionSpec expression) {
  }
}

/// Performs semantic analysis in [FunctionSpec]s
class _FunctionAnalysisVisitor extends ValueSpecTreeVisitor {
  @override
  void visitFunction(FunctionSpec spec) {
    final analyzer = SemanticAnalyzer();
    analyzer.run(spec.scope);
  }
}