import '../runtime/index.dart';
import 'evaluator.dart';

/// Specification for a builtin function
class BuiltinSpec {
  /// The name of the function
  final CellId name;

  /// The name of the Dart function
  final String functionName;

  /// Number of arguments
  final int arity;

  /// The Dart function implementing the builtin function
  final Function fn;

  /// An evaluator that returns a [CellFunc].
  late final evaluator = _BuiltinEvaluator(
    name: name,
    arity: arity,
    fn: fn
  );

  BuiltinSpec({
    required this.name,
    required this.functionName,
    required this.arity,
    required this.fn
  });
}

/// Contains the builtin functions
class Builtins {
  // TODO: Move this constant elsewhere
  static const kCoreModel = 'core';

  /// Map of [BuiltinSpec]s representing external functions.
  static final fns =
    Map.fromEntries(_fns.map((spec) => MapEntry(spec.name, spec)));

  static final _fns = {
    BuiltinSpec(
      name: NamedCellId('+', module: kCoreModel),
      arity: 2,
      fn: add,
      functionName: 'add'
    ),

    BuiltinSpec(
        name: NamedCellId('-', module: kCoreModel),
        arity: 2,
        fn: sub,
        functionName: 'sub'
    ),

    BuiltinSpec(
        name: NamedCellId('*', module: kCoreModel),
        arity: 2,
        fn: mul,
        functionName: 'mul'
    ),

    BuiltinSpec(
        name: NamedCellId('/', module: kCoreModel),
        arity: 2,
        fn: div,
        functionName: 'div'
    ),

    BuiltinSpec(
        name: NamedCellId('%', module: kCoreModel),
        arity: 2,
        fn: mod,
        functionName: 'mod'
    ),

    BuiltinSpec(
        name: NamedCellId('==', module: kCoreModel),
        arity: 2,
        fn: eq,
        functionName: 'eq'
    ),

    BuiltinSpec(
        name: NamedCellId('!=', module: kCoreModel),
        arity: 2,
        fn: neq,
        functionName: 'neq'
    ),

    BuiltinSpec(
        name: NamedCellId('<', module: kCoreModel),
        arity: 2,
        fn: lt,
        functionName: 'lt'
    ),

    BuiltinSpec(
        name: NamedCellId('>', module: kCoreModel),
        arity: 2,
        fn: gt,
        functionName: 'gt'
    ),

    BuiltinSpec(
        name: NamedCellId('<=', module: kCoreModel),
        arity: 2,
        fn: lte,
        functionName: 'lte'
    ),

    BuiltinSpec(
        name: NamedCellId('>=', module: kCoreModel),
        arity: 2,
        fn: gte,
        functionName: 'gte'
    ),

    BuiltinSpec(
        name: NamedCellId('not', module: kCoreModel),
        arity: 1,
        fn: not,
        functionName: 'not'
    ),

    BuiltinSpec(
        name: NamedCellId('and', module: kCoreModel),
        arity: 2,
        fn: and,
        functionName: 'and'
    ),

    BuiltinSpec(
        name: NamedCellId('or', module: kCoreModel),
        arity: 2,
        fn: or,
        functionName: 'or'
    ),

    BuiltinSpec(
        name: NamedCellId('select', module: kCoreModel),
        arity: 3,
        fn: select,
        functionName: 'select'
    )
  };
}

/// An evaluator that returns a function for calling a builtin function.
class _BuiltinEvaluator implements Evaluator {
  /// The name of the builtin function
  final CellId name;

  /// The number of arguments accepted by the function
  final int arity;

  /// The builtin function
  final Function fn;

  const _BuiltinEvaluator({
    required this.name,
    required this.arity,
    required this.fn
  });

  @override
  eval(RuntimeContext context) => (List<Evaluator> args) {
    checkArity(
        name: name,
        arity: arity,
        arguments: args
    );

    return Function.apply(fn, args.cast<Argument>());
  };
}