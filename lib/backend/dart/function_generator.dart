import 'package:code_builder/code_builder.dart';

/// Interface for generating the Dart code defining a function.
///
/// Subclasses should defer building of the [definition] to when [definition]
/// is referenced or [generate] is called. However, [reference] should
/// be able to return an [Expression] for referencing the function without
/// building its definition.
abstract interface class FunctionGenerator {
  /// An expression that references the function
  Expression get reference;

  /// A [Spec] containing the code defining the function.
  Spec get definition;

  const FunctionGenerator();

  /// Ensure that [definition] has been generated.
  ///
  /// The first call to this method should build [definition] and return it.
  /// Further calls to this method should return the [Spec] that was returned
  /// during the first call.
  Spec generate();
}

/// Generator for a global function or a function without a local closure.
///
/// This generator should only be used for functions with an empty closure or a
/// closure consisting only of globally defined cells, i.e. functions that
/// can safely be defined using a global [Method].
///
/// A [Method] is generated for this function.
class GlobalFunction implements FunctionGenerator {
  /// The name of the [Method] to generate.
  final String name;

  /// A function that returns the [Method] when called.
  final Method Function() build;

  @override
  Expression get reference => refer(name);

  @override
  Spec get definition => generate();

  GlobalFunction({
    required this.name,
    required this.build
  });

  @override
  Spec generate() => _method ??= build();

  // Private

  /// The built method or [null] if it hasn't been built yet
  Method? _method;
}

/// Generator for a function that references cells nested in other cell.
///
/// This generator is used for functions that have a closure containing cells
/// that are nested in other functions. Since Dart does not support mutual
/// recursion in nested functions, a global class is generated with a
/// constructor that takes the cells in the function's closure.
class NestedFunction implements FunctionGenerator {
  /// The name of the class to generate.
  final String name;

  /// Map of the [Expression]s referencing the function's closure, indexed by variable name.
  final Map<String, Expression> closure;


  /// A function that returns the [Class] when called
  final Class Function() build;

  @override
  Expression get reference => refer(name)
      .call([], closure);

  @override
  Spec get definition => generate();

  NestedFunction({
    required this.name,
    required this.closure,
    required this.build
  });

  @override
  Spec generate() => _class ??= build();

  // Private

  Class? _class;
}