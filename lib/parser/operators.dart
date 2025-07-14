/// The type of operator
enum OperatorType {
  /// A unary operator preceding its operand
  prefix,

  /// A binary operator appearing between its operands
  infix,

  /// A unary operator following its operand
  postfix;

  factory OperatorType.fromName(String name) => switch(name) {
    'prefix' => OperatorType.prefix,
    'infix' => OperatorType.infix,
    'postfix' => OperatorType.postfix,
    _ => throw Exception('Unknown operator type "$name"')
  };
}

/// Information about an prefix/infix/postfix operator
class Operator {
  /// Name identifying the operator
  final String name;

  /// The type of operator
  final OperatorType type;

  /// The precedence of the operator
  final int precedence;

  /// Is this a left associative operator (true) or right associative (false)
  final bool leftAssoc;

  const Operator({
    required this.name,
    required this.type,
    required this.precedence,
    required this.leftAssoc
  });

  /// Does this operator have precedence over [other]?
  bool hasPrecedence(Operator other) => precedence > other.precedence ||
      (precedence == other.precedence && leftAssoc);
}

/// Table of registered operators
class OperatorTable {
  /// Create an operator table with a given list of [operators].
  OperatorTable(Iterable<Operator> operators) {
    for (final op in operators) {
      _opTable(op.type)[op.name] = op;
    }
  }

  /// Lookup an operator in the table.
  ///
  /// An operator identified by [name] of a given [type] is looked up in the
  /// table. Only if operators with a precedence greater than [minPrecedence]
  /// are returned.
  Operator? find({
    required String name,
    required OperatorType type,
    int minPrecedence = 0
  }) {
    final op = _opTable(type)[name];

    if (op != null && op.precedence >= minPrecedence) {
      return op;
    }

    return null;
  }

  /// Add a new [operator] to the table
  void add(Operator operator) {
    final table = _opTable(operator.type);

    if (table.containsKey(operator.name)) {
      throw DuplicateOperatorError(
          name: operator.name,
          type: operator.type
      );
    }

    table[operator.name] = operator;
  }

  // Private

  /// Map of infix operators
  final _infix = <String, Operator>{};

  /// Map of prefix operators
  final _prefix = <String, Operator>{};

  /// Map of postfix operators
  final _postfix = <String, Operator>{};

  /// Get the map holding operators of a given [type].
  Map<String, Operator> _opTable(OperatorType type) => switch (type) {
    OperatorType.prefix => _prefix,
    OperatorType.infix => _infix,
    OperatorType.postfix => _postfix,
  };
}

/// Thrown when attempting to register an operator that has already been registered.
class DuplicateOperatorError implements Exception {
  final String name;
  final OperatorType type;

  const DuplicateOperatorError({
    required this.name,
    required this.type
  });

  @override
  String toString() => '${type.name} operator `$name` already registered.';
}