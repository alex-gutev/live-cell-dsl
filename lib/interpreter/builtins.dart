import '../builder/index.dart';
import '../runtime/thunk.dart';
import 'evaluator.dart';

/// Specification for a builtin function
class BuiltinSpec {
  /// The name of the function
  final CellId name;

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
      fn: add
    ),

    BuiltinSpec(
        name: NamedCellId('-', module: kCoreModel),
        arity: 2,
        fn: sub
    ),

    BuiltinSpec(
        name: NamedCellId('*', module: kCoreModel),
        arity: 2,
        fn: mul
    ),

    BuiltinSpec(
        name: NamedCellId('/', module: kCoreModel),
        arity: 2,
        fn: div
    ),

    BuiltinSpec(
        name: NamedCellId('%', module: kCoreModel),
        arity: 2,
        fn: mod
    ),

    BuiltinSpec(
        name: NamedCellId('==', module: kCoreModel),
        arity: 2,
        fn: eq
    ),

    BuiltinSpec(
        name: NamedCellId('!=', module: kCoreModel),
        arity: 2,
        fn: neq
    ),

    BuiltinSpec(
        name: NamedCellId('<', module: kCoreModel),
        arity: 2,
        fn: lt
    ),

    BuiltinSpec(
        name: NamedCellId('>', module: kCoreModel),
        arity: 2,
        fn: gt
    ),

    BuiltinSpec(
        name: NamedCellId('<=', module: kCoreModel),
        arity: 2,
        fn: lte
    ),

    BuiltinSpec(
        name: NamedCellId('>=', module: kCoreModel),
        arity: 2,
        fn: gte
    ),

    BuiltinSpec(
        name: NamedCellId('not', module: kCoreModel),
        arity: 1,
        fn: not
    ),

    BuiltinSpec(
        name: NamedCellId('and', module: kCoreModel),
        arity: 2,
        fn: and
    ),

    BuiltinSpec(
        name: NamedCellId('or', module: kCoreModel),
        arity: 2,
        fn: or
    ),

    BuiltinSpec(
      name: NamedCellId('select', module: kCoreModel),
      arity: 3,
      fn: select
    )
  };

  // Arithmetic

  /// The `+` function
  static num add(Argument a, Argument b) =>
      a.get<num>() + b.get<num>();

  /// The `-` function
  static num sub(Argument a, Argument b) =>
      a.get<num>() - b.get<num>();

  /// The `*` function
  static num mul(Argument a, Argument b) =>
      a.get<num>() * b.get<num>();

  /// The `/` function
  static num div(Argument a, Argument b) =>
      a.get<num>() / b.get<num>();

  /// The `%` function
  static num mod(Argument a, Argument b) =>
      a.get<num>() % b.get<num>();

  // Equality

  /// The `==` comparison function
  static bool eq(Argument a, Argument b) =>
      a.get() == b.get();

  /// The `!=` comparison function
  static bool neq(Argument a, Argument b) =>
      a.get() != b.get();

  // Comparison

  /// The `<` comparison function
  static bool lt(Argument a, Argument b) =>
      a.get<num>() < b.get<num>();

  /// The `>` comparison function
  static bool gt(Argument a, Argument b) =>
      a.get<num>() > b.get<num>();

  /// The `<=` comparison function
  static bool lte(Argument a, Argument b) =>
      a.get<num>() <= b.get<num>();

  /// The `>=` comparison function
  static bool gte(Argument a, Argument b) =>
      a.get<num>() >= b.get<num>();

  // Boolean

  /// The `!` negation function
  static bool not(Argument a) =>
      !a.get<bool>();

  /// The `and` function
  static bool and(Argument a, Argument b) =>
      a.get<bool>() && b.get<bool>();

  /// The `or` function
  static bool or(Argument a, Argument b) =>
      a.get<bool>() || b.get<bool>();

  // Branching

  static dynamic select(
      Argument condition,
      Argument ifTrue,
      Argument ifFalse
  ) => condition.get<bool>()
      ? ifTrue.get()
      : ifFalse.get();
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