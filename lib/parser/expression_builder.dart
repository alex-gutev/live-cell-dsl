import 'dart:collection';

import 'declarations.dart';
import 'operators.dart';

/// Builds an expression from given operands and operators
///
/// This class allows building an expression in postfix notation by adding
/// operands, using [addOperand], and operators, use [addOperator], to the
/// top of the stack.
///
/// The [build] method converts the postfix expression to an [Expression]
/// object.
class ExpressionBuilder {
  /// Add an operand to the stack
  void addOperand(Expression arg) {
    _output.addLast(_Operand(arg));
  }

  /// Add an operator to the stack
  void addOperator(Operator operator) {
    while (_operators.lastOrNull?.hasPrecedence(operator) ?? false) {
      _output.addLast(_Operator(_operators.removeLast()));
    }
    
    _operators.add(operator);
  }

  /// Build the expression
  Expression build() {
    while (_operators.isNotEmpty) {
      _output.addLast(_Operator(_operators.removeLast()));
    }

    final expression = _popExpression();

    if (_output.isNotEmpty) {
      // TODO: Proper exception type
      throw Exception('Parse Error');
    }
    
    return expression;
  }

  final _operators = Queue<Operator>();
  final _output = Queue<_Item>();

  /// Build the expression from the operator/operand at the top of the stack
  Expression _popExpression() {
    if (_output.isEmpty) {
      // TODO: Proper exception type
      throw Exception('Parse Error');
    }

    switch (_output.removeLast()) {
      case _Operand(:final expression):
        return expression;

      case _Operator(operator: Operator(:final name)):
        final rhs = _popExpression();
        final lhs = _popExpression();

        return Operation(
            operator: NamedCell(name),
            args: [
              lhs,
              rhs
            ]
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
  final Expression expression;

  const _Operand(this.expression);
}

/// Represents an operator in the stack
class _Operator extends _Item {
  /// The operator
  final Operator operator;

  const _Operator(this.operator);
}