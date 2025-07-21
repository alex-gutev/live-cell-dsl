import 'package:live_cells_core/live_cells_core.dart';

import '../builder/index.dart';

part 'runtime_context.dart';

/// Signature of a function defined by a cell.
///
/// [arguments] is a list of [Evaluator]s that compute the values of the
/// function arguments.
typedef CellFunc = Function(List<Evaluator> arguments);

/// Interface for evaluating a compiled expression.
///
/// [ValueSpec] objects are converter to [Evaluator] objects, which can then
/// be evaluated by calling [eval].
abstract class Evaluator {
  const Evaluator();

  /// Create an [Evaluator] that returns a constant [value].
  const factory Evaluator.constant(value) = ConstantEvaluator;

  /// Create an [Evaluator] that references the value of the cell identified by [id].
  const factory Evaluator.ref(RuntimeCellId id) = RefEvaluator;

  /// Create an [Evaluator] that applies an [operator] to one or more [operands].
  const factory Evaluator.apply({
    required Evaluator operator,
    required List<Evaluator> operands
  }) = ApplyEvaluator;

  /// Create an [Evaluator] for a function defined by a cell.
  ///
  /// This evaluator returns a function that takes a single argument -- the
  /// argument list. Each element of the argument list is an [Evaluator] that
  /// computes the value of the argument.
  ///
  /// [arguments] is a list holding the runtime cell identifiers of the
  /// positional arguments.
  ///
  /// [locals] is a map, indexed by runtime cell id, holding the [Evaluator]
  /// objects for the cells local to the function.
  ///
  /// The function returns the result of evaluating [definition] in a new
  /// [FunctionContext].
  const factory Evaluator.function({
    required CellId name,
    required List<RuntimeCellId> arguments,
    required Map<RuntimeCellId, Evaluator> locals,
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
  final RuntimeCellId id;

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
        .call(operands.map((o) => o.inContext(context)).toList());
}

/// Evaluator that returns a function
class FunctionEvaluator extends Evaluator {
  /// The name of the function
  final CellId name;

  /// List of argument cell identifiers
  final List<RuntimeCellId> arguments;

  /// Map of evaluators for cells local to the function
  final Map<RuntimeCellId, Evaluator> locals;

  /// Evaluator for the expression defining the result of the cell
  final Evaluator definition;

  const FunctionEvaluator({
    required this.name,
    required this.arguments,
    required this.locals,
    required this.definition
  });

  @override
  CellFunc eval(RuntimeContext context) => (List<Evaluator> args) {
    checkArity(
        name: name,
        arity: arguments.length,
        arguments: args
    );

    return definition.eval(
        FunctionContext(
            parent: context,
            arguments: Map.fromIterables(arguments, args),
            locals: locals
        )
    );
  };
}

// An [Evaluator] that evaluates another [evaluator] in a given [context]
class ContextEvaluator extends Evaluator {
  /// The original evaluator
  final Evaluator evaluator;

  /// The context in which to evaluate [evaluator].
  final RuntimeContext context;

  const ContextEvaluator({
    required this.evaluator,
    required this.context
  });

  @override
  eval(RuntimeContext _) => evaluator.eval(context);

  /// Evaluate the [evaluator], in [context], and check its type.
  ///
  /// If the [evaluator] does not produce a value of type [T] a [TypeError] is
  /// thrown.
  T get<T>() => switch (eval(context)) {
    final T value => value,
    _ => throw TypeError()
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
  required List<Evaluator> arguments
}) {
  if (arguments.length != arity) {
    throw ArgumentError(
        '$name expected $arity arguments '
            'but was given ${arguments.length}.'
    );
  }
}

extension InContextEvaluatorExtension on Evaluator {
  /// Create a new [Evaluator] that evaluates [this] in a given [context].
  ///
  /// The returned [Evaluator] evaluates this evaluator in [context], regardless
  /// of the context that is provided to its [Evaluator.eval] method.
  Evaluator inContext(RuntimeContext context) => ContextEvaluator(
      evaluator: this,
      context: context
  );
}