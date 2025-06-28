part of 'cell_spec.dart';

/// Visitor interface for [CellExpression]s.
abstract interface class CellExpressionVisitor<R> {
  R visitStub(StubExpression expression);
  R visitConstantValue<T>(ConstantValue<T> expression);
  R visitVariableValue(VariableValue expression);
  R visitRef(CellRef expression);
  R visitApplication(CellApplication expression);
  R visitDeferred(DeferredExpression expression);
  R visitFunction(FunctionExpression expression);
}

/// A visitor that visits each node of a [CellExpression] tree.
abstract class CellExpressionTreeVisitor extends CellExpressionVisitor<void> {
  @override
  void visitApplication(CellApplication expression) {
    expression.operator.accept(this);
    
    for (final operand in expression.operands) {
      operand.accept(this);
    }
  }

  @override
  void visitConstantValue<T>(ConstantValue<T> expression) {
  }

  @override
  void visitDeferred(DeferredExpression expression) {
    expression.build().accept(this);
  }

  @override
  void visitFunction(FunctionExpression expression) {
    expression.definition.accept(this);
  }

  @override
  void visitRef(CellRef expression) {
  }

  @override
  void visitStub(StubExpression expression) {
  }

  @override
  void visitVariableValue(VariableValue expression) {
  }
}