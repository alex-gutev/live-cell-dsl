import 'package:live_cells_core/live_cells_core.dart';

import '../runtime/index.dart';

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

  /// Create an [Evaluator] that references the value of the effect identified by [id].
  const factory Evaluator.refEffect(int id) = EffectRefEvaluator;

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

  /// Create an [Evaluator] that assigns a [value] to a cell.
  ///
  /// This evaluator sets the value of the cell identified by [cellId] to
  /// the value computed by [value]. The assigned value is returned by the
  /// evaluator.
  const factory Evaluator.assign({
    required RuntimeCellId cellId,
    required Evaluator value
  }) = AssignEvaluator;

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

/// Evaluator that references the state of a side effect.
class EffectRefEvaluator extends Evaluator {
  /// The identifier of the referenced effect
  final int id;

  const EffectRefEvaluator(this.id);

  @override
  eval(RuntimeContext context) => context.refEffect(id);
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
  eval(RuntimeContext context) {
    final op = operator.eval(context);

    if (op is! CellFunc) {
      throw InvalidOperatorError(op);
    }

    return op.call(operands.map((o) => o.inContext(context)).toList());
  }
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

/// An evaluator that assigns a [value] to the value of a cell.
class AssignEvaluator extends Evaluator {
  /// ID of the cell, of which the value is being assigned
  final RuntimeCellId cellId;

  /// Evaluator that computes the value to assign
  final Evaluator value;

  const AssignEvaluator({
    required this.cellId,
    required this.value
  });

  @override
  eval(RuntimeContext context) {
    final value = this.value.eval(context);
    context.setCellValue(cellId, value);

    return value;
  }
}

/// Evaluator that evaluates a list of [evaluators] and returns the value of the last one.
class BlockEvaluator extends Evaluator {
  /// List of evaluators to evaluate.
  final List<Evaluator> evaluators;

  const BlockEvaluator(this.evaluators);

  @override
  eval(RuntimeContext context) => evaluators
      .map((e) => e.eval(context))
      .lastOrNull;
}

// An [Evaluator] that evaluates another [evaluator] in a given [context]
class ContextEvaluator extends Evaluator implements Argument {
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
  @override
  T get<T>() => switch (eval(context)) {
    final T value => value,
    // TODO: Exception type with more details
    _ => throw TypeError()
  };
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