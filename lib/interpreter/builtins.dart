import '../builder/cell_spec.dart';

import 'thunk.dart';

/// Specification for a builtin function
class BuiltinSpec {
  /// Number of arguments
  final int arity;

  /// The Dart function implementing the builtin function
  final Function fn;

  const BuiltinSpec({
    required this.arity,
    required this.fn
  });
}

/// Contains the builtin functions
class Builtins {
  // TODO: Move this constant elsewhere
  static const kCoreModel = 'core';

  /// Map from external cell identifiers to the corresponding [BuiltinSpec]s.
  static final fns = {
    NamedCellId('+', module: kCoreModel): BuiltinSpec(
      arity: 2,
      fn: add
    ),

    NamedCellId('-', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: sub
    ),

    NamedCellId('*', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: mul
    ),

    NamedCellId('/', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: div
    ),

    NamedCellId('%', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: mod
    ),

    NamedCellId('==', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: eq
    ),

    NamedCellId('!=', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: neq
    ),

    NamedCellId('<', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: lt
    ),

    NamedCellId('>', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: gt
    ),

    NamedCellId('<=', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: lte
    ),

    NamedCellId('>=', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: gte
    ),

    NamedCellId('not', module: kCoreModel): BuiltinSpec(
        arity: 1,
        fn: not
    ),

    NamedCellId('and', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: and
    ),

    NamedCellId('or', module: kCoreModel): BuiltinSpec(
        arity: 2,
        fn: or
    ),
  };

  // Arithmetic

  /// The `+` function
  static num add(Thunk a, Thunk b) =>
      a.get<num>() + b.get<num>();

  /// The `-` function
  static num sub(Thunk a, Thunk b) =>
      a.get<num>() - b.get<num>();

  /// The `*` function
  static num mul(Thunk a, Thunk b) =>
      a.get<num>() * b.get<num>();

  /// The `/` function
  static num div(Thunk a, Thunk b) =>
      a.get<num>() / b.get<num>();

  /// The `%` function
  static num mod(Thunk a, Thunk b) =>
      a.get<num>() % b.get<num>();

  // Equality

  /// The `==` comparison function
  static bool eq(Thunk a, Thunk b) => a() == b();

  /// The `!=` comparison function
  static bool neq(Thunk a, Thunk b) => a() != b();

  // Comparison

  /// The `<` comparison function
  static bool lt(Thunk a, Thunk b) =>
      a.get<num>() < b.get<num>();

  /// The `>` comparison function
  static bool gt(Thunk a, Thunk b) =>
      a.get<num>() > b.get<num>();

  /// The `<=` comparison function
  static bool lte(Thunk a, Thunk b) =>
      a.get<num>() <= b.get<num>();

  /// The `>=` comparison function
  static bool gte(Thunk a, Thunk b) =>
      a.get<num>() >= b.get<num>();

  // Boolean

  /// The `!` negation function
  static bool not(Thunk a) =>
      !a.get<bool>();

  /// The `and` function
  static bool and(Thunk a, Thunk b) =>
      a.get<bool>() && b.get<bool>();

  /// The `or` function
  static bool or(Thunk a, Thunk b) =>
      a.get<bool>() || b.get<bool>();
}