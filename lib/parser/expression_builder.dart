import 'dart:collection';

import 'exceptions.dart';
import 'ast.dart';
import 'operators.dart';

/// Builds an expression from given operands and operators
///
/// This class allows building an expression in postfix notation by adding
/// operands, using [addOperand], and operators, use [addOperator], to the
/// top of the stack.
///
/// The [build] method converts the postfix expression to an [AstNode]
/// object.
class ExpressionBuilder {
  /// Add an operand to the stack
  void addOperand(AstNode arg) {
    _output.addLast(_Operand(arg));
  }

  /// Add an operator to the stack
  void addOperator(Operator operator) {
    while (_operators.lastOrNull?.$1.hasPrecedence(operator) ?? false) {
      _output.addLast(
          _makeOperator(_operators.removeLast())
      );
    }
    
    _operators.add((operator, OperatorType.infix));
  }

  /// Add a prefix operator to the stack
  void addPrefixOperator(Operator operator) {
    _operators.add((operator, OperatorType.prefix));
  }

  /// Build the expression
  AstNode build() {
    while (_operators.isNotEmpty) {
      _output.addLast(
          _makeOperator(_operators.removeLast())
      );
    }

    final expression = _popExpression();

    if (_output.isNotEmpty) {
      throw MalformedInfixExpression();
    }
    
    return expression;
  }

  final _operators = Queue<(Operator, OperatorType)>();
  final _output = Queue<_Item>();

  _Item _makeOperator((Operator, OperatorType) operator) => switch (operator.$2) {
    OperatorType.prefix => _PrefixOperator(operator.$1),
    OperatorType.infix => _InfixOperator(operator.$1),

    // TODO: Handle this case.
    OperatorType.postfix => throw UnimplementedError(),
  };

  /// Build the expression from the operator/operand at the top of the stack
  AstNode _popExpression() {
    if (_output.isEmpty) {
      throw MalformedInfixExpression();
    }

    switch (_output.removeLast()) {
      case _Operand(:final expression):
        return expression;

      case _PrefixOperator(operator: Operator(:final name)):
        return Application(
            operator: Name(name),
            operands: [
              _popExpression()
            ]
        );

      case _InfixOperator(operator: Operator(:final name)):
        final rhs = _popExpression();
        final lhs = _popExpression();

        return Application(
            operator: Name(name),
            operands: [
              lhs,
              rhs
            ],

            location: lhs.location,
        );
    }
  }
}

/// An item in the postfix expression stack
sealed class _Item {
  const _Item();
}

/// Represents an operand in the stack
class _Operand extends _Item {
  /// The operand expression
  final AstNode expression;

  const _Operand(this.expression);
}

/// Represents a prefix operator in the stack
class _PrefixOperator extends _Item {
  /// The operator
  final Operator operator;

  const _PrefixOperator(this.operator);
}

/// Represents an infix operator in the stack
class _InfixOperator extends _Item {
  /// The operator
  final Operator operator;

  const _InfixOperator(this.operator);
}