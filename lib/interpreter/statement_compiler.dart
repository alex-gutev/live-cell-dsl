import '../builder/index.dart';
import 'evaluator.dart';
import 'runtime_compiler.dart';

/// Compiles [StatementSpec]s to [Evaluator] objects.
class StatementCompiler {
  /// The compiler to use for compiling [ValueSpec]s to [Evaluator]s.
  final RuntimeCompiler compiler;

  StatementCompiler({
    required this.compiler
  });

  /// Create an [Evaluator] for a given statement [spec].
  Evaluator makeEvaluator(StatementSpec spec) => switch (spec) {
    AssignStatement(
      :final cell,
      :final value
    ) => Evaluator.assign(
        cellId: compiler.idForCell(cell.get),
        value: makeEvaluator(value)
    ),

    BlockStatement(:final statements) => BlockEvaluator(
      statements.map(makeEvaluator).toList()
    ),

    ExpressionStatement(:final expression) =>
      compiler.makeEvaluator(expression),
  };
}