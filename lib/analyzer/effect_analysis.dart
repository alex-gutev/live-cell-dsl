import '../builder/index.dart';
import '../common/pipeline.dart';

/// Removes effect-less statements from side-effects.
///
/// Each effect in the given scope is analyzed, and all statements which are
/// known to not have any side-effect are removed. **NOTE**: The effect
/// specifications are modified in place.
class EffectAnalysis implements Operation {
  /// The scope on which to perform effect analysis.
  late final CellTable scope;

  @override
  void run(CellTable scope) {
    this.scope = scope;

    scope.effects.forEach(_analyzeEffect);
  }

  /// Perform effect-less statement removal on a given effect [spec].
  void _analyzeEffect(EffectSpec spec) {
    spec.statements.removeWhere((s) => !_keepStatement(s));
  }

  /// Should a given [statement] be kept in the effect?
  static bool _keepStatement(StatementSpec statement) => switch (statement) {
    AssignStatement() => true,
    ExpressionStatement() => false,
    BlockStatement(:final statements) => statements.any(_keepStatement),
  };
}