import 'package:live_cells_core/live_cells_core.dart';

import '../builder/index.dart';
import 'thunk.dart';

part 'runtime_context.dart';

/// Signature of a function defined by a cell.
///
/// [arguments] is a list of [ComputeFn]s that compute the values of the
/// function arguments.
typedef CellFunc = Function(List<Thunk> arguments);

/// Interface for evaluating a compiled expression.
///
/// [ValueSpec] objects are converter to [Evaluator] objects, which can then
/// be evaluated by calling [eval].
sealed class Evaluator {
  const Evaluator();

  /// Create an [Evaluator] that returns a constant [value].
  const factory Evaluator.constant(value) = ConstantEvaluator;

  /// Create an [Evaluator] that references the value of the cell identified by [id].
  const factory Evaluator.ref(CellId id) = RefEvaluator;

  /// Create an [Evaluator] that applies an [operator] to one or more [operands].
  const factory Evaluator.apply({
    required Evaluator operator,
    required List<Evaluator> operands
  }) = ApplyEvaluator;

  /// Create an [Evaluator] for a function defined by a cell.
  ///
  /// This evaluator returns a function that takes a single argument, containing
  /// the list of argument values as [Thunk]s. [external] is a map mapping
  /// external cell identifiers to their [Evaluator] objects. The function
  /// returns the result of evaluating [definition].
  const factory Evaluator.function({
    required CellId name,
    required List<CellId> arguments,
    required Map<CellId, Evaluator> external,
    required Map<CellId, Evaluator> locals,
    required Evaluator definition
  }) = FunctionEvaluator;

  dynamic eval(RuntimeContext context);
}

/// Evaluator that returns a constant value
class ConstantEvaluator<T> extends Evaluator {
  /// The constant value
  final T value;

  const ConstantEvaluator(this.value);

  @override
  T eval(RuntimeContext context) => value;
}

/// Evaluator that references the value of a cell.
class RefEvaluator extends Evaluator {
  /// The cell identifier
  final CellId id;

  const RefEvaluator(this.id);

  @override
  eval(RuntimeContext context) => context.refCell(id);
}

/// Evaluator that returns the result of applying [operator] to [operands].
class ApplyEvaluator extends Evaluator {
  /// Evaluator that returns the operator
  final Evaluator operator;

  /// List of evaluators for the operands
  final List<Evaluator> operands;

  const ApplyEvaluator({
    required this.operator,
    required this.operands
  });

  @override
  eval(RuntimeContext context) =>
      operator.eval(context)
        .call(operands.map((o) => Thunk(() => o.eval(context))).toList());
}

/// Evaluator that returns a function
class FunctionEvaluator extends Evaluator {
  /// The name of the function
  final CellId name;

  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// Map from external cell identifiers to their corresponding [Evaluator]s.
  final Map<CellId, Evaluator> external;

  /// Map of evaluators for cells local to the function
  final Map<CellId, Evaluator> locals;

  /// Evaluator for the expression defining the result of the cell
  final Evaluator definition;

  const FunctionEvaluator({
    required this.name,
    required this.arguments,
    required this.external,
    required this.locals,
    required this.definition
  });

  @override
  CellFunc eval(RuntimeContext context) => (List<Thunk> args) {
    checkArity(
        name: name,
        arity: arguments.length,
        arguments: args
    );

    final closure = external
        .map((id, eval) => MapEntry(id, Thunk(() => eval.eval(context))));
    
    return definition.eval(
        FunctionContext(
            parent: context,
            arguments: Map.fromIterables(arguments, args),
            closure: closure,
            locals: locals
        )
    );
  };
}

/// Check that the correct number of arguments were given to a function.
///
/// If [arguments] contains fewer or more elements than [arity], an exception is
/// thrown, with [name] used to refer to the cell, defining the function, in
/// the error message.
void checkArity({
  required CellId name,
  required int arity,
  required List<Thunk> arguments
}) {
  if (arguments.length != arity) {
    throw ArgumentError(
        '$name expected $arity arguments '
            'but was given ${arguments.length}.'
    );
  }
}
